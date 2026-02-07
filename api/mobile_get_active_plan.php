<?php
/**
 * API para obtener el plan de entrenamiento activo del día
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept, X-Session-ID');
header('Access-Control-Allow-Credentials: true');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

try {
    require_once __DIR__ . '/../database/config.php';
    require_once __DIR__ . '/auth.php';

    restoreSessionFromHeader();
    if (session_status() === PHP_SESSION_NONE)
        session_start();

    $auth = new Auth();
    if (!$auth->isAuthenticated()) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'No autenticado']);
        exit;
    }

    $userId = $_SESSION['usuario_id'];
    $db = getDB();

    // Obtener el plan de hoy
    $stmt = $db->prepare("SELECT titulo, ejercicios_json FROM plan_entrenamiento WHERE usuario_id = ? AND fecha = CURDATE() LIMIT 1");
    $stmt->execute([$userId]);
    $plan = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($plan) {
        echo json_encode([
            'success' => true,
            'titulo' => $plan['titulo'],
            'ejercicios' => json_decode($plan['ejercicios_json'], true)
        ], JSON_UNESCAPED_UNICODE);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'No hay plan para hoy'
        ]);
    }

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
