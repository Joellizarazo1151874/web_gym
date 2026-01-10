<?php
/**
 * Aceptar o rechazar una solicitud de chat.
 * Si se acepta, se crea un chat privado entre los dos usuarios.
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

    $requestId = isset($input['request_id']) ? (int)$input['request_id'] : 0;
    $accion = strtolower(trim($input['accion'] ?? ''));

    if ($requestId <= 0 || !in_array($accion, ['aceptar', 'rechazar'], true)) {
        echo json_encode([
            'success' => false,
            'message' => 'Datos inválidos',
        ]);
        exit;
    }

    // Obtener solicitud y verificar que pertenece al usuario actual
    $stmt = $db->prepare("
        SELECT * 
        FROM friend_requests 
        WHERE id = :id AND para_usuario_id = :para AND estado = 'pendiente'
    ");
    $stmt->execute([
        ':id' => $requestId,
        ':para' => $usuarioId,
    ]);
    $req = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$req) {
        echo json_encode([
            'success' => false,
            'message' => 'Solicitud no encontrada o ya respondida',
        ]);
        exit;
    }

    $nuevoEstado = $accion === 'aceptar' ? 'aceptada' : 'rechazada';

    // Actualizar estado de la solicitud
    $stmtUp = $db->prepare("
        UPDATE friend_requests 
        SET estado = :estado, respondido_en = NOW()
        WHERE id = :id
    ");
    $stmtUp->execute([
        ':estado' => $nuevoEstado,
        ':id' => $requestId,
    ]);

    $chatCreado = null;

    if ($accion === 'aceptar') {
        // Crear chat privado entre ambos usuarios
        $deUsuarioId = (int)$req['de_usuario_id'];

        // Nombre del chat: nombre del otro usuario (emisor)
        $stmtUser = $db->prepare("
            SELECT nombre, apellido 
            FROM usuarios 
            WHERE id = :id
        ");
        $stmtUser->execute([':id' => $deUsuarioId]);
        $u = $stmtUser->fetch(PDO::FETCH_ASSOC);
        $nombreChat = $u ? trim(($u['nombre'] ?? '') . ' ' . ($u['apellido'] ?? '')) : 'Chat privado';

        // Crear chat
        $stmtChat = $db->prepare("
            INSERT INTO chats (nombre, es_grupal, creado_por, creado_en)
            VALUES (:nombre, 0, :creado_por, NOW())
        ");
        $stmtChat->execute([
            ':nombre' => $nombreChat,
            ':creado_por' => $usuarioId,
        ]);
        $chatId = (int)$db->lastInsertId();

        // Añadir participantes (ambos usuarios)
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
            ':user' => $deUsuarioId,
        ]);

        $chatCreado = [
            'id' => $chatId,
            'nombre' => $nombreChat,
            'es_grupal' => false,
            'creado_en' => date('c'),
        ];
    }

    echo json_encode([
        'success' => true,
        'message' => $accion === 'aceptar'
            ? 'Solicitud aceptada. Se ha creado un chat.'
            : 'Solicitud rechazada.',
        'chat' => $chatCreado,
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al responder solicitud: ' . $e->getMessage(),
    ]);
}

