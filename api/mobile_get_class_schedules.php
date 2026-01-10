<?php
/**
 * Obtener horarios de clases para Aplicación Móvil
 * Endpoint específico para apps móviles
 */

// Headers para CORS y JSON
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept, Cookie, X-Session-ID');
header('Access-Control-Allow-Credentials: true');

// Manejar preflight OPTIONS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Solo permitir GET
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Método no permitido'
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

// Incluir dependencias primero
require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/auth.php';

// Intentar restaurar sesión desde header X-Session-ID (para apps móviles)
restoreSessionFromHeader();

// Iniciar sesión (necesario para la clase Auth)
// Si restoreSessionFromHeader() ya inició la sesión, esto no hará nada
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

try {
    // Verificar autenticación
    $auth = new Auth();
    if (!$auth->isAuthenticated()) {
        http_response_code(401);
        echo json_encode([
            'success' => false,
            'message' => 'No autenticado'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $db = getDB();
    
    // Obtener parámetros opcionales
    $clase_id = isset($_GET['clase_id']) ? (int)$_GET['clase_id'] : null;
    $activo = isset($_GET['activo']) ? (int)$_GET['activo'] : null;
    $dia_semana = isset($_GET['dia_semana']) ? (int)$_GET['dia_semana'] : null;
    
    // Construir query
    $sql = "
        SELECT 
            ch.id,
            ch.clase_id,
            ch.dia_semana,
            ch.hora_inicio,
            ch.hora_fin,
            ch.activo,
            c.nombre as clase_nombre,
            c.capacidad_maxima,
            c.duracion_minutos,
            u.nombre as instructor_nombre,
            u.apellido as instructor_apellido,
            CASE ch.dia_semana
                WHEN 1 THEN 'Lunes'
                WHEN 2 THEN 'Martes'
                WHEN 3 THEN 'Miércoles'
                WHEN 4 THEN 'Jueves'
                WHEN 5 THEN 'Viernes'
                WHEN 6 THEN 'Sábado'
                WHEN 7 THEN 'Domingo'
            END as dia_nombre
        FROM clase_horarios ch
        INNER JOIN clases c ON ch.clase_id = c.id
        LEFT JOIN usuarios u ON c.instructor_id = u.id
        WHERE 1=1
    ";
    
    $params = [];
    
    if ($clase_id !== null) {
        $sql .= " AND ch.clase_id = :clase_id";
        $params[':clase_id'] = $clase_id;
    }
    
    if ($activo !== null) {
        $sql .= " AND ch.activo = :activo";
        $params[':activo'] = $activo;
    }
    
    if ($dia_semana !== null) {
        $sql .= " AND ch.dia_semana = :dia_semana";
        $params[':dia_semana'] = $dia_semana;
    }
    
    $sql .= " ORDER BY ch.dia_semana ASC, ch.hora_inicio ASC";
    
    $stmt = $db->prepare($sql);
    $stmt->execute($params);
    $horarios = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Debug: Log de lo que se encontró
    error_log("mobile_get_class_schedules: Total horarios encontrados: " . count($horarios));
    if (count($horarios) > 0) {
        error_log("mobile_get_class_schedules: Primer horario: " . json_encode($horarios[0]));
    }
    
    // Convertir tipos de datos para JSON
    foreach ($horarios as &$horario) {
        $horario['id'] = (int)$horario['id'];
        $horario['clase_id'] = (int)$horario['clase_id'];
        $horario['dia_semana'] = (int)$horario['dia_semana'];
        $horario['activo'] = (int)$horario['activo'];
        if ($horario['capacidad_maxima'] !== null) {
            $horario['capacidad_maxima'] = (int)$horario['capacidad_maxima'];
        }
        if ($horario['duracion_minutos'] !== null) {
            $horario['duracion_minutos'] = (int)$horario['duracion_minutos'];
        }
        // Asegurar que las horas vengan como string
        $horario['hora_inicio'] = (string)$horario['hora_inicio'];
        $horario['hora_fin'] = (string)$horario['hora_fin'];
    }
    unset($horario);
    
    echo json_encode([
        'success' => true,
        'horarios' => $horarios
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    
} catch (Exception $e) {
    error_log("Error en mobile_get_class_schedules.php: " . $e->getMessage());
    error_log("Stack trace: " . $e->getTraceAsString());
    
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al obtener los horarios: ' . $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
?>

