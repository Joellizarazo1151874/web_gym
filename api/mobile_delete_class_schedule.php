<?php
/**
 * Eliminar horario de clase para Aplicación Móvil
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
            'message' => 'No autorizado. Solo administradores y entrenadores pueden eliminar horarios.'
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

    $horario_id = isset($input['id']) ? (int)$input['id'] : 0;

    if ($horario_id <= 0) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'ID de horario inválido'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // Verificar que el horario existe y obtener la clase asociada
    $stmt = $db->prepare("
        SELECT ch.id, ch.clase_id, c.instructor_id 
        FROM clase_horarios ch
        INNER JOIN clases c ON ch.clase_id = c.id
        WHERE ch.id = :id
    ");
    $stmt->execute([':id' => $horario_id]);
    $horario_data = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$horario_data) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Horario no encontrado'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // Si es entrenador, solo puede eliminar horarios de sus propias clases
    if ($rol_usuario === 'entrenador' && $horario_data['instructor_id'] != $usuario_id) {
        http_response_code(403);
        echo json_encode([
            'success' => false,
            'message' => 'No tienes permiso para eliminar este horario'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // Eliminar el horario
    $stmt = $db->prepare("DELETE FROM clase_horarios WHERE id = :id");
    $stmt->execute([':id' => $horario_id]);

    echo json_encode([
        'success' => true,
        'message' => 'Horario eliminado exitosamente'
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    error_log("Error en mobile_delete_class_schedule.php: " . $e->getMessage());
    error_log("Stack trace: " . $e->getTraceAsString());

    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al eliminar el horario: ' . $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
?>
