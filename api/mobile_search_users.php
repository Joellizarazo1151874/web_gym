<?php
/**
 * Buscar usuarios por nombre/apellido/email para enviar solicitud de chat
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
    error_log("[mobile_search_users] 401 No autenticado. SID=" . session_id() . " SESSION=" . json_encode($_SESSION));
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

    $q = isset($_GET['q']) ? trim($_GET['q']) : '';
    if ($q === '') {
        echo json_encode([
            'success' => true,
            'usuarios' => [],
            'total' => 0,
        ]);
        exit;
    }

$like = '%' . $q . '%';
$safeId = (int)$usuarioId;

    // Nota: MySQL con prepared statements nativos no permite repetir el mismo
    // placeholder nombrado varias veces. Usamos placeholders posicionales.
    $stmt = $db->prepare("
        SELECT 
            id,
            nombre,
            apellido,
            email
        FROM usuarios
        WHERE estado != 'suspendido'
          AND id != ?
          AND (
              nombre LIKE ?
              OR apellido LIKE ?
              OR email LIKE ?
          )
        ORDER BY nombre, apellido
        LIMIT 20
    ");
    $stmt->execute([
        $safeId,
        $like,
        $like,
        $like,
    ]);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $filtered = [];
    foreach ($rows as $r) {
        $r['id'] = (int)$r['id'];
        // Evitar retornarse a sí mismo por seguridad
        if ($r['id'] === $safeId) {
            continue;
        }
        $r['nombre_completo'] = trim(($r['nombre'] ?? '') . ' ' . ($r['apellido'] ?? ''));
        $filtered[] = $r;
    }

    echo json_encode([
        'success' => true,
        'usuarios' => $filtered,
        'total' => count($filtered),
    ]);
} catch (Exception $e) {
    error_log("[mobile_search_users] Error: " . $e->getMessage() . " SID=" . session_id() . " SESSION=" . json_encode($_SESSION));
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al buscar usuarios',
    ]);
}

