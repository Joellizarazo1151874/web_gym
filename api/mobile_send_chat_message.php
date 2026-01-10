<?php
/**
 * Enviar mensaje a un chat
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
    $mensaje = trim($input['mensaje'] ?? '');
     $imagenUrl = isset($input['imagen_url']) ? trim($input['imagen_url']) : null;

    if ($chatId <= 0 || ($mensaje === '' && $imagenUrl === null)) {
        echo json_encode([
            'success' => false,
            'message' => 'Datos incompletos',
        ]);
        exit;
    }

    // Verificar participación
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

    $stmt = $db->prepare("
        INSERT INTO chat_mensajes (chat_id, remitente_id, mensaje, imagen_url, creado_en, leido)
        VALUES (:chat_id, :remitente_id, :mensaje, :imagen_url, NOW(), 0)
    ");
    $stmt->execute([
        ':chat_id' => $chatId,
        ':remitente_id' => $usuarioId,
        ':mensaje' => $mensaje,
        ':imagen_url' => $imagenUrl !== '' ? $imagenUrl : null,
    ]);

    $mensajeId = (int)$db->lastInsertId();

    // Verificar si hay más de 200 mensajes en el chat
    $stmtCount = $db->prepare("SELECT COUNT(*) as total FROM chat_mensajes WHERE chat_id = :chat_id");
    $stmtCount->execute([':chat_id' => $chatId]);
    $totalMensajes = $stmtCount->fetch(PDO::FETCH_ASSOC)['total'];

    $maxMensajes = 200; // Límite máximo de mensajes por chat

    if ($totalMensajes > $maxMensajes) {
        // Obtener el mensaje más antiguo
        $stmtOldest = $db->prepare("
            SELECT id, imagen_url 
            FROM chat_mensajes 
            WHERE chat_id = :chat_id 
            ORDER BY creado_en ASC 
            LIMIT 1
        ");
        $stmtOldest->execute([':chat_id' => $chatId]);
        $oldestMsg = $stmtOldest->fetch(PDO::FETCH_ASSOC);

        if ($oldestMsg) {
            // Eliminar el mensaje más antiguo
            $stmtDeleteOldest = $db->prepare("DELETE FROM chat_mensajes WHERE id = :id");
            $stmtDeleteOldest->execute([':id' => $oldestMsg['id']]);

            // Eliminar imagen asociada si existe
            if (!empty($oldestMsg['imagen_url'])) {
                $imagePath = str_replace(getSiteUrl(), __DIR__ . '/../', $oldestMsg['imagen_url']);
                if (file_exists($imagePath)) {
                    unlink($imagePath);
                }
            }
        }
    }

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
        'message' => 'Mensaje enviado correctamente',
        'data' => $msg, // El mensaje enviado
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al enviar mensaje: ' . $e->getMessage(),
    ]);
}

