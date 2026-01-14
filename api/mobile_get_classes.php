<?php
/**
 * Obtener clases para Aplicación Móvil
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
    $usuario_id = $_SESSION['usuario_id'] ?? null;
    // El rol se guarda como 'usuario_rol' en auth.php, no como 'rol'
    $rol_usuario = $_SESSION['usuario_rol'] ?? null;
    
    error_log("mobile_get_classes: usuario_id = " . ($usuario_id ?? 'null'));
    error_log("mobile_get_classes: rol_usuario = " . ($rol_usuario ?? 'null'));
    
    // Obtener parámetros opcionales
    $activo = isset($_GET['activo']) ? (int)$_GET['activo'] : null;
    $instructor_id = isset($_GET['instructor_id']) ? (int)$_GET['instructor_id'] : null;
    
    // Si el usuario es entrenador (no admin), solo mostrar sus propias clases
    if ($rol_usuario === 'entrenador' && $instructor_id === null) {
        $instructor_id = $usuario_id;
        error_log("mobile_get_classes: Filtrado por instructor_id (entrenador) = $instructor_id");
    }
    
    // Construir query
    $sql = "
        SELECT 
            c.id,
            c.nombre,
            c.descripcion,
            c.instructor_id,
            c.capacidad_maxima,
            c.duracion_minutos,
            c.activo,
            u.nombre as instructor_nombre,
            u.apellido as instructor_apellido,
            u.foto as instructor_foto,
            (SELECT COUNT(*) FROM clase_horarios ch WHERE ch.clase_id = c.id) as total_horarios
        FROM clases c
        LEFT JOIN usuarios u ON c.instructor_id = u.id
        WHERE 1=1
    ";
    
    $params = [];
    
    if ($activo !== null) {
        $sql .= " AND c.activo = :activo";
        $params[':activo'] = $activo;
    }
    
    if ($instructor_id !== null) {
        $sql .= " AND c.instructor_id = :instructor_id";
        $params[':instructor_id'] = $instructor_id;
    }
    
    $sql .= " ORDER BY c.nombre ASC";
    
    $stmt = $db->prepare($sql);
    $stmt->execute($params);
    $clases = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    error_log("mobile_get_classes: Total clases encontradas: " . count($clases));
    
    // Convertir tipos de datos para JSON
    foreach ($clases as &$clase) {
        $clase['id'] = (int)$clase['id'];
        $clase['activo'] = (int)$clase['activo'];
        $clase['total_horarios'] = (int)$clase['total_horarios'];
        if ($clase['instructor_id'] !== null) {
            $clase['instructor_id'] = (int)$clase['instructor_id'];
        }
        if ($clase['capacidad_maxima'] !== null) {
            $clase['capacidad_maxima'] = (int)$clase['capacidad_maxima'];
        }
        if ($clase['duracion_minutos'] !== null) {
            $clase['duracion_minutos'] = (int)$clase['duracion_minutos'];
        }
    }
    unset($clase);
    
    echo json_encode([
        'success' => true,
        'clases' => $clases
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    
} catch (Exception $e) {
    error_log("Error en mobile_get_classes.php: " . $e->getMessage());
    error_log("Stack trace: " . $e->getTraceAsString());
    
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al obtener las clases: ' . $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
?>

