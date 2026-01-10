<?php
/**
 * Agregar participante a un chat (por email)
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
    $email = trim($input['email'] ?? '');

    if ($chatId <= 0 || $email === '') {
        echo json_encode([
            'success' => false,
            'message' => 'Datos incompletos',
        ]);
        exit;
    }

    // Verificar que el usuario que agrega pertenece al chat
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

    // Buscar usuario por email
    $stmtUser = $db->prepare("
        SELECT id, nombre, apellido 
        FROM usuarios 
        WHERE email = :email
          AND estado != 'suspendido'
    ");
    $stmtUser->execute([':email' => $email]);
    $user = $stmtUser->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        echo json_encode([
            'success' => false,
            'message' => 'No se encontró un usuario con ese email',
        ]);
        exit;
    }

    $targetUserId = (int)$user['id'];

    // Verificar si ya es participante
    $stmtExists = $db->prepare("
        SELECT 1 FROM chat_participantes 
        WHERE chat_id = :chat_id AND usuario_id = :usuario_id
    ");
    $stmtExists->execute([
        ':chat_id' => $chatId,
        ':usuario_id' => $targetUserId,
    ]);

    if ($stmtExists->fetch()) {
        echo json_encode([
            'success' => false,
            'message' => 'El usuario ya es participante de este chat',
        ]);
        exit;
    }

    // Agregar participante
    $stmtAdd = $db->prepare("
        INSERT INTO chat_participantes (chat_id, usuario_id, agregado_en)
        VALUES (:chat_id, :usuario_id, NOW())
    ");
    $stmtAdd->execute([
        ':chat_id' => $chatId,
        ':usuario_id' => $targetUserId,
    ]);

    echo json_encode([
        'success' => true,
        'message' => 'Participante agregado correctamente',
        'usuario_id' => $targetUserId,
        'nombre' => trim(($user['nombre'] ?? '') . ' ' . ($user['apellido'] ?? '')),
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al agregar participante: ' . $e->getMessage(),
    ]);
}

