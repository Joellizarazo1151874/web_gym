<?php
/**
 * Actualizar clase para Aplicación Móvil
 * Endpoint específico para apps móviles
 * Si el usuario es entrenador, solo puede actualizar sus propias clases
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
            'message' => 'No autorizado. Solo administradores y entrenadores pueden actualizar clases.'
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

    $clase_id = isset($input['id']) ? (int)$input['id'] : 0;

    if ($clase_id <= 0) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'ID de clase inválido'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // Verificar que la clase existe y obtener su instructor_id
    $stmt = $db->prepare("SELECT id, instructor_id FROM clases WHERE id = :id");
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

    // Si es entrenador, solo puede actualizar sus propias clases
    if ($rol_usuario === 'entrenador' && $clase['instructor_id'] != $usuario_id) {
        http_response_code(403);
        echo json_encode([
            'success' => false,
            'message' => 'No tienes permiso para actualizar esta clase'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $nombre = trim($input['nombre'] ?? '');
    $descripcion = trim($input['descripcion'] ?? '');
    $instructor_id = isset($input['instructor_id']) && $input['instructor_id'] !== '' ? (int)$input['instructor_id'] : null;
    $capacidad_maxima = isset($input['capacidad_maxima']) && $input['capacidad_maxima'] !== '' ? (int)$input['capacidad_maxima'] : null;
    $duracion_minutos = isset($input['duracion_minutos']) && $input['duracion_minutos'] !== '' ? (int)$input['duracion_minutos'] : null;
    $activo = isset($input['activo']) ? (int)$input['activo'] : 1;

    // Validaciones
    if (empty($nombre)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'El nombre de la clase es requerido'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    if ($capacidad_maxima !== null && $capacidad_maxima < 1) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'La capacidad máxima debe ser mayor a 0'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    if ($duracion_minutos !== null && $duracion_minutos < 15) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'La duración mínima es de 15 minutos'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // Si es entrenador, mantener su instructor_id
    if ($rol_usuario === 'entrenador') {
        $instructor_id = $usuario_id;
    } elseif ($rol_usuario === 'admin' && $instructor_id !== null) {
        // Si es admin y se proporcionó instructor_id, validar que existe
        $stmt = $db->prepare("
            SELECT id FROM usuarios 
            WHERE id = :id 
            AND rol_id IN (SELECT id FROM roles WHERE nombre IN ('entrenador', 'admin'))
        ");
        $stmt->execute([':id' => $instructor_id]);
        if (!$stmt->fetch()) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'El instructor seleccionado no es válido'
            ], JSON_UNESCAPED_UNICODE);
            exit;
        }
    } else {
        // Si es admin y no se proporcionó instructor_id, mantener el actual
        $instructor_id = $clase['instructor_id'];
    }

    // Actualizar clase
    $stmt = $db->prepare("
        UPDATE clases 
        SET nombre = :nombre,
            descripcion = :descripcion,
            instructor_id = :instructor_id,
            capacidad_maxima = :capacidad_maxima,
            duracion_minutos = :duracion_minutos,
            activo = :activo,
            updated_at = NOW()
        WHERE id = :id
    ");

    $stmt->execute([
        ':id' => $clase_id,
        ':nombre' => $nombre,
        ':descripcion' => $descripcion ?: null,
        ':instructor_id' => $instructor_id,
        ':capacidad_maxima' => $capacidad_maxima,
        ':duracion_minutos' => $duracion_minutos,
        ':activo' => $activo
    ]);

    // Obtener la clase actualizada
    $stmt = $db->prepare("
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
            (SELECT COUNT(*) FROM clase_horarios ch WHERE ch.clase_id = c.id) as total_horarios
        FROM clases c
        LEFT JOIN usuarios u ON c.instructor_id = u.id
        WHERE c.id = :id
    ");
    $stmt->execute([':id' => $clase_id]);
    $clase_actualizada = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($clase_actualizada) {
        $clase_actualizada['id'] = (int)$clase_actualizada['id'];
        $clase_actualizada['activo'] = (int)$clase_actualizada['activo'];
        $clase_actualizada['total_horarios'] = (int)$clase_actualizada['total_horarios'];
        if ($clase_actualizada['instructor_id'] !== null) {
            $clase_actualizada['instructor_id'] = (int)$clase_actualizada['instructor_id'];
        }
        if ($clase_actualizada['capacidad_maxima'] !== null) {
            $clase_actualizada['capacidad_maxima'] = (int)$clase_actualizada['capacidad_maxima'];
        }
        if ($clase_actualizada['duracion_minutos'] !== null) {
            $clase_actualizada['duracion_minutos'] = (int)$clase_actualizada['duracion_minutos'];
        }
    }

    echo json_encode([
        'success' => true,
        'message' => 'Clase actualizada exitosamente',
        'clase' => $clase_actualizada
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);

} catch (Exception $e) {
    error_log("Error en mobile_update_class.php: " . $e->getMessage());
    error_log("Stack trace: " . $e->getTraceAsString());

    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al actualizar la clase: ' . $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
?>
