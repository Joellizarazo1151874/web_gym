<?php
/**
 * Obtener solicitudes de chat recibidas por el usuario autenticado
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

    $stmt = $db->prepare("
        SELECT 
            fr.id,
            fr.de_usuario_id,
            fr.para_usuario_id,
            fr.estado,
            fr.creado_en,
            u.nombre,
            u.apellido,
            u.email
        FROM friend_requests fr
        INNER JOIN usuarios u ON u.id = fr.de_usuario_id
        WHERE fr.para_usuario_id = :usuario_id
          AND fr.estado = 'pendiente'
        ORDER BY fr.creado_en DESC
    ");
    $stmt->execute([':usuario_id' => $usuarioId]);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    foreach ($rows as &$r) {
        $r['de_usuario_id'] = (int)$r['de_usuario_id'];
        $r['para_usuario_id'] = (int)$r['para_usuario_id'];
        $r['id'] = (int)$r['id'];
        $r['nombre_completo'] = trim(($r['nombre'] ?? '') . ' ' . ($r['apellido'] ?? ''));
    }

    error_log("[mobile_get_friend_requests] usuario={$usuarioId} total=" . count($rows) . " SID=" . session_id());

    echo json_encode([
        'success' => true,
        'solicitudes' => $rows,
        'total' => count($rows),
    ]);
} catch (Exception $e) {
    error_log("[mobile_get_friend_requests] Error: " . $e->getMessage() . " SID=" . session_id());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al obtener solicitudes: ' . $e->getMessage(),
    ]);
}

