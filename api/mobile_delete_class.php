<?php
/**
 * Eliminar clase para Aplicación Móvil
 * Endpoint específico para apps móviles
 * Si el usuario es entrenador, solo puede eliminar sus propias clases
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
            'message' => 'No autorizado. Solo administradores y entrenadores pueden eliminar clases.'
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

    // Si es entrenador, solo puede eliminar sus propias clases
    if ($rol_usuario === 'entrenador' && $clase['instructor_id'] != $usuario_id) {
        http_response_code(403);
        echo json_encode([
            'success' => false,
            'message' => 'No tienes permiso para eliminar esta clase'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // Eliminar horarios asociados primero (cascada)
    $stmt = $db->prepare("DELETE FROM clase_horarios WHERE clase_id = :clase_id");
    $stmt->execute([':clase_id' => $clase_id]);

    // Eliminar la clase
    $stmt = $db->prepare("DELETE FROM clases WHERE id = :id");
    $stmt->execute([':id' => $clase_id]);

    echo json_encode([
        'success' => true,
        'message' => 'Clase eliminada exitosamente'
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    error_log("Error en mobile_delete_class.php: " . $e->getMessage());
    error_log("Stack trace: " . $e->getTraceAsString());

    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al eliminar la clase: ' . $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
?>
