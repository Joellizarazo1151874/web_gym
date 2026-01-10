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
    if ($chatId <= 0) {
        echo json_encode([
            'success' => false,
            'message' => 'Chat inválido',
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
        SELECT 
            m.id,
            m.chat_id,
            m.remitente_id,
            m.mensaje,
            m.creado_en,
            m.leido,
            u.nombre,
            u.apellido
        FROM chat_mensajes m
        INNER JOIN usuarios u ON u.id = m.remitente_id
        WHERE m.chat_id = :chat_id
        ORDER BY m.creado_en ASC
    ");
    $stmt->execute([':chat_id' => $chatId]);
    $mensajes = $stmt->fetchAll(PDO::FETCH_ASSOC);

    foreach ($mensajes as &$msg) {
        $msg['leido'] = (bool)$msg['leido'];
        $msg['remitente_nombre'] = trim(($msg['nombre'] ?? '') . ' ' . ($msg['apellido'] ?? ''));
    }

    echo json_encode([
        'success' => true,
        'mensajes' => $mensajes,
        'total' => count($mensajes),
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al obtener mensajes: ' . $e->getMessage(),
    ]);
}

