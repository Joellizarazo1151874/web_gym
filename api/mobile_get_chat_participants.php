<?php
/**
 * Obtener participantes de un chat
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

    $stmt = $db->prepare("
        SELECT 
            u.id,
            u.nombre,
            u.apellido,
            u.email
        FROM chat_participantes cp
        INNER JOIN usuarios u ON u.id = cp.usuario_id
        WHERE cp.chat_id = :chat_id
        ORDER BY u.nombre, u.apellido
    ");
    $stmt->execute([':chat_id' => $chatId]);
    $participantes = $stmt->fetchAll(PDO::FETCH_ASSOC);

    foreach ($participantes as &$p) {
        $p['nombre_completo'] = trim(($p['nombre'] ?? '') . ' ' . ($p['apellido'] ?? ''));
    }

    echo json_encode([
        'success' => true,
        'participantes' => $participantes,
        'total' => count($participantes),
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al obtener participantes: ' . $e->getMessage(),
    ]);
}

