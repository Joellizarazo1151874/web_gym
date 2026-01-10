<?php
/**
 * Crear un nuevo chat (por ahora, chat grupal simple tipo "Chat del gimnasio")
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

    $nombre = trim($input['nombre'] ?? '');

    if ($nombre === '') {
        $nombre = 'Chat del gimnasio';
    }

    // Crear chat
    $stmt = $db->prepare("
        INSERT INTO chats (nombre, es_grupal, creado_por, creado_en)
        VALUES (:nombre, 1, :creado_por, NOW())
    ");
    $stmt->execute([
        ':nombre' => $nombre,
        ':creado_por' => $usuarioId,
    ]);

    $chatId = (int)$db->lastInsertId();

    // Agregar al creador como participante
    $stmtPart = $db->prepare("
        INSERT INTO chat_participantes (chat_id, usuario_id, agregado_en)
        VALUES (:chat_id, :usuario_id, NOW())
    ");
    $stmtPart->execute([
        ':chat_id' => $chatId,
        ':usuario_id' => $usuarioId,
    ]);

    echo json_encode([
        'success' => true,
        'message' => 'Chat creado correctamente',
        'chat_id' => $chatId,
        'nombre' => $nombre,
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al crear chat: ' . $e->getMessage(),
    ]);
}

