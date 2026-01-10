<?php
/**
 * Editar mensaje de chat (solo texto)
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
    $nuevoMensaje = trim($input['mensaje'] ?? '');

    if ($mensajeId <= 0 || $nuevoMensaje === '') {
        echo json_encode([
            'success' => false,
            'message' => 'Datos incompletos',
        ]);
        exit;
    }

    // Verificar que el mensaje pertenece al usuario
    $stmtCheck = $db->prepare("
        SELECT id, remitente_id 
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
            'message' => 'No tienes permiso para editar este mensaje',
        ]);
        exit;
    }

    // Actualizar mensaje
    $stmtUpdate = $db->prepare("
        UPDATE chat_mensajes 
        SET mensaje = :mensaje 
        WHERE id = :id
    ");
    $stmtUpdate->execute([
        ':mensaje' => $nuevoMensaje,
        ':id' => $mensajeId,
    ]);

    // Obtener mensaje actualizado
    $stmtMsg = $db->prepare("
        SELECT 
            m.id,
            m.chat_id,
            m.remitente_id,
            m.mensaje,
            m.imagen_url,
            m.creado_en,
            m.leido,
            u.nombre,
            u.apellido
        FROM chat_mensajes m
        INNER JOIN usuarios u ON u.id = m.remitente_id
        WHERE m.id = :id
    ");
    $stmtMsg->execute([':id' => $mensajeId]);
    $msg = $stmtMsg->fetch(PDO::FETCH_ASSOC);

    if ($msg) {
        $msg['leido'] = (bool)$msg['leido'];
        $msg['remitente_nombre'] = trim(($msg['nombre'] ?? '') . ' ' . ($msg['apellido'] ?? ''));
    }

    echo json_encode([
        'success' => true,
        'message' => 'Mensaje editado correctamente',
        'data' => $msg,
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al editar mensaje: ' . $e->getMessage(),
    ]);
}
