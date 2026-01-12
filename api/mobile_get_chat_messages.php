<?php
/**
 * Obtener mensajes de un chat
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
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

    $chatId = isset($_GET['chat_id']) ? (int)$_GET['chat_id'] : 0;
    $limite = isset($_GET['limite']) ? (int)$_GET['limite'] : 15;
    $offset = isset($_GET['offset']) ? (int)$_GET['offset'] : 0;

    if ($chatId <= 0) {
        echo json_encode([
            'success' => false,
            'message' => 'Chat inválido',
        ]);
        exit;
    }

    // Asegurar límites razonables
    $limite = max(1, min($limite, 50)); // Entre 1 y 50

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

    // Marcar como leídos los mensajes entrantes pendientes para este usuario
    $stmtMarkRead = $db->prepare("
        UPDATE chat_mensajes
        SET leido = 1
        WHERE chat_id = :chat_id
          AND remitente_id <> :usuario_id
          AND (leido = 0 OR leido IS NULL)
    ");
    $stmtMarkRead->execute([
        ':chat_id' => $chatId,
        ':usuario_id' => $usuarioId,
    ]);

    // Obtener cuántos quedan sin leer después de marcar
    $stmtUnread = $db->prepare("
        SELECT COUNT(*) AS unread_after
        FROM chat_mensajes
        WHERE chat_id = :chat_id
          AND remitente_id <> :usuario_id
          AND (leido = 0 OR leido IS NULL)
    ");
    $stmtUnread->execute([
        ':chat_id' => $chatId,
        ':usuario_id' => $usuarioId,
    ]);
    $unreadAfter = (int)($stmtUnread->fetch(PDO::FETCH_ASSOC)['unread_after'] ?? 0);

    // Obtener el total de mensajes
    $stmtTotal = $db->prepare("SELECT COUNT(*) as total FROM chat_mensajes WHERE chat_id = :chat_id");
    $stmtTotal->execute([':chat_id' => $chatId]);
    $totalMensajes = $stmtTotal->fetch(PDO::FETCH_ASSOC)['total'];

    // Obtener mensajes con paginación (los más recientes primero, luego invertimos)
    $stmt = $db->prepare("
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
        WHERE m.chat_id = :chat_id
        ORDER BY m.creado_en DESC
        LIMIT :limite OFFSET :offset
    ");
    $stmt->bindValue(':chat_id', $chatId, PDO::PARAM_INT);
    $stmt->bindValue(':limite', $limite, PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
    $stmt->execute();
    $mensajes = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Invertir el orden para que los más antiguos estén primero (orden cronológico)
    $mensajes = array_reverse($mensajes);

    foreach ($mensajes as &$msg) {
        $msg['leido'] = (bool)$msg['leido'];
        $msg['remitente_nombre'] = trim(($msg['nombre'] ?? '') . ' ' . ($msg['apellido'] ?? ''));
    }

    echo json_encode([
        'success' => true,
        'mensajes' => $mensajes,
        'total' => $totalMensajes,
        'cargados' => count($mensajes),
        'hayMas' => ($offset + count($mensajes)) < $totalMensajes,
        'unread_after' => $unreadAfter,
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al obtener mensajes: ' . $e->getMessage(),
    ]);
}

