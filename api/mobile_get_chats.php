<?php
/**
 * Obtener la lista de chats del usuario autenticado
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

    $sql = "
        SELECT 
            c.id,
            c.nombre,
            c.es_grupal,
            c.creado_en,
            m.mensaje AS ultimo_mensaje,
            m.creado_en AS ultimo_mensaje_en,
            u.nombre AS ultimo_remitente_nombre,
            u.apellido AS ultimo_remitente_apellido
        FROM chats c
        INNER JOIN chat_participantes cp ON cp.chat_id = c.id
        LEFT JOIN chat_mensajes m ON m.id = (
            SELECT cm2.id 
            FROM chat_mensajes cm2 
            WHERE cm2.chat_id = c.id 
            ORDER BY cm2.creado_en DESC 
            LIMIT 1
        )
        LEFT JOIN usuarios u ON u.id = m.remitente_id
        WHERE cp.usuario_id = :usuario_id
        ORDER BY m.creado_en DESC, c.creado_en DESC
    ";

    $stmt = $db->prepare($sql);
    $stmt->execute([':usuario_id' => $usuarioId]);
    $chats = $stmt->fetchAll(PDO::FETCH_ASSOC);

    foreach ($chats as &$chat) {
        $chat['es_grupal'] = (bool)$chat['es_grupal'];
        if (empty($chat['nombre'])) {
            // Nombre por defecto
            $chat['nombre'] = $chat['es_grupal'] ? 'Chat del gimnasio' : 'Chat privado';
        }
        if (!empty($chat['ultimo_remitente_nombre']) || !empty($chat['ultimo_remitente_apellido'])) {
            $chat['ultimo_remitente'] = trim(($chat['ultimo_remitente_nombre'] ?? '') . ' ' . ($chat['ultimo_remitente_apellido'] ?? ''));
        } else {
            $chat['ultimo_remitente'] = null;
        }
    }

    echo json_encode([
        'success' => true,
        'chats' => $chats,
        'total' => count($chats),
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al obtener chats: ' . $e->getMessage(),
    ]);
}

