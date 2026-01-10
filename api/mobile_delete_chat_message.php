<?php
/**
 * Eliminar mensaje de chat
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept, Cookie, X-Session-ID');
header('Access-Control-Allow-Credentials: true');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/auth.php';

restoreSessionFromHeader();

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

$auth = new Auth();
if (!$auth->isAuthenticated()) {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'message' => 'No autenticado',
    ]);
    exit;
}

try {
    $db = getDB();
    $usuarioId = $_SESSION['usuario_id'] ?? null;

    $input = json_decode(file_get_contents('php://input'), true);
    if (!is_array($input)) {
        $input = $_POST;
    }

    $mensajeId = isset($input['mensaje_id']) ? (int)$input['mensaje_id'] : 0;

    if ($mensajeId <= 0) {
        echo json_encode([
            'success' => false,
            'message' => 'Mensaje inválido',
        ]);
        exit;
    }

    // Verificar que el mensaje pertenece al usuario y obtener datos
    $stmtCheck = $db->prepare("
        SELECT id, imagen_url, remitente_id 
        FROM chat_mensajes 
        WHERE id = :id
    ");
    $stmtCheck->execute([':id' => $mensajeId]);
    $mensaje = $stmtCheck->fetch(PDO::FETCH_ASSOC);

    if (!$mensaje) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Mensaje no encontrado',
        ]);
        exit;
    }

    // Verificar que el mensaje es del usuario actual
    if ($mensaje['remitente_id'] != $usuarioId) {
        http_response_code(403);
        echo json_encode([
            'success' => false,
            'message' => 'No tienes permiso para eliminar este mensaje',
        ]);
        exit;
    }

    // Eliminar mensaje
    $stmtDel = $db->prepare("DELETE FROM chat_mensajes WHERE id = :id");
    $stmtDel->execute([':id' => $mensajeId]);

    // Eliminar imagen asociada si existe
    if (!empty($mensaje['imagen_url'])) {
        $imagePath = str_replace(getSiteUrl(), __DIR__ . '/../', $mensaje['imagen_url']);
        if (file_exists($imagePath)) {
            unlink($imagePath);
        }
    }

    echo json_encode([
        'success' => true,
        'message' => 'Mensaje eliminado correctamente',
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al eliminar mensaje: ' . $e->getMessage(),
    ]);
}
