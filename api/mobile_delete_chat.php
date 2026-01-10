<?php
/**
 * Eliminar un chat completo
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

    $chatId = isset($input['chat_id']) ? (int)$input['chat_id'] : 0;
    if ($chatId <= 0) {
      echo json_encode([
          'success' => false,
          'message' => 'Chat inválido',
      ]);
      exit;
    }

    // Verificar que el usuario pertenece al chat
    $stmtCheck = $db->prepare("
        SELECT 1 FROM chat_participantes 
        WHERE chat_id = :chat_id AND usuario_id = :usuario_id
    ");
    $stmtCheck->execute([
        ':chat_id' => $chatId,
        ':usuario_id' => $usuarioId,
    ]);
    if (!$stmtCheck->fetch()) {
        http_response_code(403);
        echo json_encode([
            'success' => false,
            'message' => 'No tienes acceso a este chat',
        ]);
        exit;
    }

    // Eliminar chat (ON DELETE CASCADE borra mensajes y participantes)
    $stmtDel = $db->prepare("DELETE FROM chats WHERE id = :id");
    $stmtDel->execute([':id' => $chatId]);

    echo json_encode([
        'success' => true,
        'message' => 'Chat eliminado correctamente',
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al eliminar chat: ' . $e->getMessage(),
    ]);
}

