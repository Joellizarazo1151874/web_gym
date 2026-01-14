<?php
/**
 * Crear horario de clase para Aplicación Móvil
 * Endpoint específico para apps móviles
 */

// Headers para CORS y JSON
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept, Cookie, X-Session-ID');
header('Access-Control-Allow-Credentials: true');

// Manejar preflight OPTIONS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Solo permitir POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Método no permitido'
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

// Incluir dependencias
require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/auth.php';

// Intentar restaurar sesión desde header X-Session-ID (para apps móviles)
restoreSessionFromHeader();

// Iniciar sesión
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

    // Verificar rol (solo admin o entrenador)
    if (!$auth->hasRole(['admin', 'entrenador'])) {
        http_response_code(403);
        echo json_encode([
            'success' => false,
            'message' => 'No autorizado. Solo administradores y entrenadores pueden crear horarios.'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $db = getDB();
    $usuario_id = $_SESSION['usuario_id'] ?? null;
    $rol_usuario = $_SESSION['usuario_rol'] ?? null;

    // Obtener datos del body (JSON)
    $input = json_decode(file_get_contents('php://input'), true);
    if (!is_array($input)) {
        $input = $_POST;
    }

    $clase_id = isset($input['clase_id']) ? (int)$input['clase_id'] : 0;
    $dia_semana = isset($input['dia_semana']) ? (int)$input['dia_semana'] : 0;
    $hora_inicio = trim($input['hora_inicio'] ?? '');
    $hora_fin = trim($input['hora_fin'] ?? '');
    $activo = isset($input['activo']) ? (int)$input['activo'] : 1;

    // Validaciones
    if ($clase_id <= 0) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'ID de clase inválido'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    if ($dia_semana < 1 || $dia_semana > 7) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Día de la semana inválido (debe ser entre 1 y 7)'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    if (empty($hora_inicio) || empty($hora_fin)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Las horas de inicio y fin son requeridas'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // Validar formato de hora (HH:MM)
    if (!preg_match('/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/', $hora_inicio) || 
        !preg_match('/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/', $hora_fin)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Formato de hora inválido (debe ser HH:MM)'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // Verificar que la hora de fin sea mayor que la de inicio
    if (strtotime($hora_fin) <= strtotime($hora_inicio)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'La hora de fin debe ser mayor que la hora de inicio'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // Verificar que la clase existe y que el usuario tiene permiso
    $stmt = $db->prepare("
        SELECT c.id, c.instructor_id 
        FROM clases c 
        WHERE c.id = :id
    ");
    $stmt->execute([':id' => $clase_id]);
    $clase = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$clase) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Clase no encontrada'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // Si es entrenador, solo puede crear horarios para sus propias clases
    if ($rol_usuario === 'entrenador' && $clase['instructor_id'] != $usuario_id) {
        http_response_code(403);
        echo json_encode([
            'success' => false,
            'message' => 'No tienes permiso para crear horarios para esta clase'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // Verificar si ya existe un horario para este día y hora
    $stmt = $db->prepare("
        SELECT id FROM clase_horarios 
        WHERE clase_id = :clase_id 
        AND dia_semana = :dia_semana 
        AND (
            (hora_inicio <= :hora_inicio1 AND hora_fin > :hora_inicio2) OR
            (hora_inicio < :hora_fin1 AND hora_fin >= :hora_fin2) OR
            (hora_inicio >= :hora_inicio3 AND hora_fin <= :hora_fin3)
        )
        AND activo = 1
    ");
    $stmt->execute([
        ':clase_id' => $clase_id,
        ':dia_semana' => $dia_semana,
        ':hora_inicio1' => $hora_inicio,
        ':hora_inicio2' => $hora_inicio,
        ':hora_inicio3' => $hora_inicio,
        ':hora_fin1' => $hora_fin,
        ':hora_fin2' => $hora_fin,
        ':hora_fin3' => $hora_fin
    ]);

    if ($stmt->fetch()) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Ya existe un horario activo para esta clase en este día y hora'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // Insertar horario
    $stmt = $db->prepare("
        INSERT INTO clase_horarios (clase_id, dia_semana, hora_inicio, hora_fin, activo)
        VALUES (:clase_id, :dia_semana, :hora_inicio, :hora_fin, :activo)
    ");

    $stmt->execute([
        ':clase_id' => $clase_id,
        ':dia_semana' => $dia_semana,
        ':hora_inicio' => $hora_inicio,
        ':hora_fin' => $hora_fin,
        ':activo' => $activo
    ]);

    $horario_id = $db->lastInsertId();

    // Obtener el horario creado
    $stmt = $db->prepare("
        SELECT 
            ch.id,
            ch.clase_id,
            ch.dia_semana,
            ch.hora_inicio,
            ch.hora_fin,
            ch.activo,
            c.nombre as clase_nombre,
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
        WHERE ch.id = :id
    ");
    $stmt->execute([':id' => $horario_id]);
    $horario = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($horario) {
        $horario['id'] = (int)$horario['id'];
        $horario['clase_id'] = (int)$horario['clase_id'];
        $horario['dia_semana'] = (int)$horario['dia_semana'];
        $horario['activo'] = (int)$horario['activo'];
    }

    echo json_encode([
        'success' => true,
        'message' => 'Horario creado exitosamente',
        'horario' => $horario
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);

} catch (Exception $e) {
    error_log("Error en mobile_create_class_schedule.php: " . $e->getMessage());
    error_log("Stack trace: " . $e->getTraceAsString());

    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al crear el horario: ' . $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
?>
