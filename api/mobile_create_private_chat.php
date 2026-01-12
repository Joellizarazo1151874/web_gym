<?php
/**
 * Crear o reutilizar un chat privado entre el usuario autenticado y otro usuario (contacto).
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

    $contactoId = isset($input['contacto_id']) ? (int)$input['contacto_id'] : 0;
    if ($contactoId <= 0 || $contactoId === (int)$usuarioId) {
        echo json_encode([
            'success' => false,
            'message' => 'Contacto inválido',
        ]);
        exit;
    }

    // Verificar que el contacto exista y no esté suspendido
    $stmtUser = $db->prepare("
        SELECT id, nombre, apellido
        FROM usuarios
        WHERE id = :id AND estado != 'suspendido'
    ");
    $stmtUser->execute([':id' => $contactoId]);
    $contacto = $stmtUser->fetch(PDO::FETCH_ASSOC);

    if (!$contacto) {
        echo json_encode([
            'success' => false,
            'message' => 'El contacto no existe o está suspendido',
        ]);
        exit;
    }

    // Buscar si ya existe chat privado entre ambos (no grupal)
    $stmtChat = $db->prepare("
        SELECT c.id, c.nombre, c.creado_en
        FROM chats c
        INNER JOIN chat_participantes p1 ON p1.chat_id = c.id AND p1.usuario_id = :u1
        INNER JOIN chat_participantes p2 ON p2.chat_id = c.id AND p2.usuario_id = :u2
        WHERE c.es_grupal = 0
        LIMIT 1
    ");
    $stmtChat->execute([
        ':u1' => $usuarioId,
        ':u2' => $contactoId,
    ]);
    $chat = $stmtChat->fetch(PDO::FETCH_ASSOC);

    if ($chat) {
        echo json_encode([
            'success' => true,
            'message' => 'Chat ya existe',
            'chat' => [
                'id' => (int)$chat['id'],
                'nombre' => $chat['nombre'],
                'es_grupal' => false,
                'creado_en' => $chat['creado_en'],
            ],
        ]);
        exit;
    }

    // Crear chat privado
    $nombreChat = trim(($contacto['nombre'] ?? '') . ' ' . ($contacto['apellido'] ?? ''));
    if ($nombreChat === '') {
        $nombreChat = 'Chat privado';
    }

    $stmtInsChat = $db->prepare("
        INSERT INTO chats (nombre, es_grupal, creado_por, creado_en)
        VALUES (:nombre, 0, :creado_por, NOW())
    ");
    $stmtInsChat->execute([
        ':nombre' => $nombreChat,
        ':creado_por' => $usuarioId,
    ]);
    $chatId = (int)$db->lastInsertId();

    // Agregar participantes
    $stmtPart = $db->prepare("
        INSERT INTO chat_participantes (chat_id, usuario_id, agregado_en)
        VALUES (:chat, :user, NOW())
    ");
    $stmtPart->execute([
        ':chat' => $chatId,
        ':user' => $usuarioId,
    ]);
    $stmtPart->execute([
        ':chat' => $chatId,
        ':user' => $contactoId,
    ]);

    echo json_encode([
        'success' => true,
        'message' => 'Chat creado',
        'chat' => [
            'id' => $chatId,
            'nombre' => $nombreChat,
            'es_grupal' => false,
            'creado_en' => date('c'),
        ],
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al crear chat: ' . $e->getMessage(),
    ]);
}

