<?php
/**
 * Enviar solicitud de chat / amistad a otro usuario
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
    $deUsuarioId = $_SESSION['usuario_id'] ?? null;

    $input = json_decode(file_get_contents('php://input'), true);
    if (!is_array($input)) {
        $input = $_POST;
    }

    $paraUsuarioId = isset($input['para_usuario_id']) ? (int)$input['para_usuario_id'] : 0;

    if ($paraUsuarioId <= 0 || $paraUsuarioId === (int)$deUsuarioId) {
        echo json_encode([
            'success' => false,
            'message' => 'Usuario destinatario inválido',
        ]);
        exit;
    }

    // Verificar que el usuario destino exista
    $stmtUser = $db->prepare("SELECT id, nombre, apellido FROM usuarios WHERE id = :id AND estado != 'suspendido'");
    $stmtUser->execute([':id' => $paraUsuarioId]);
    $user = $stmtUser->fetch(PDO::FETCH_ASSOC);
    if (!$user) {
        echo json_encode([
            'success' => false,
            'message' => 'El usuario no existe o está suspendido',
        ]);
        exit;
    }

    // Verificar si ya existe una solicitud
    $stmtReq = $db->prepare("
        SELECT id, estado 
        FROM friend_requests 
        WHERE de_usuario_id = :de AND para_usuario_id = :para
    ");
    $stmtReq->execute([
        ':de' => $deUsuarioId,
        ':para' => $paraUsuarioId,
    ]);
    $req = $stmtReq->fetch(PDO::FETCH_ASSOC);

    if ($req && $req['estado'] === 'pendiente') {
        echo json_encode([
            'success' => false,
            'message' => 'Ya enviaste una solicitud pendiente a este usuario',
        ]);
        exit;
    }

    if ($req && $req['estado'] === 'aceptada') {
        echo json_encode([
            'success' => false,
            'message' => 'Ya tienes un chat activo con este usuario',
        ]);
        exit;
    }

    if ($req && $req['estado'] === 'rechazada') {
        // Reabrir solicitud
        $stmtUpdate = $db->prepare("
            UPDATE friend_requests 
            SET estado = 'pendiente', creado_en = NOW(), respondido_en = NULL 
            WHERE id = :id
        ");
        $stmtUpdate->execute([':id' => $req['id']]);
        $requestId = (int)$req['id'];
    } else {
        // Crear nueva solicitud
        $stmtIns = $db->prepare("
            INSERT INTO friend_requests (de_usuario_id, para_usuario_id, estado, creado_en)
            VALUES (:de, :para, 'pendiente', NOW())
        ");
        $stmtIns->execute([
            ':de' => $deUsuarioId,
            ':para' => $paraUsuarioId,
        ]);
        $requestId = (int)$db->lastInsertId();
    }

    error_log("[mobile_send_friend_request] OK de={$deUsuarioId} para={$paraUsuarioId} request_id={$requestId} SID=" . session_id());

    echo json_encode([
        'success' => true,
        'message' => 'Solicitud enviada correctamente',
        'request_id' => $requestId,
    ]);
} catch (Exception $e) {
    error_log("[mobile_send_friend_request] Error: " . $e->getMessage() . " SID=" . session_id());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al enviar solicitud: ' . $e->getMessage(),
    ]);
}

