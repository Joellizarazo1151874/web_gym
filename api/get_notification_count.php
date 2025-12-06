<?php
/**
 * Obtener contador de notificaciones no leídas
 * Endpoint API para obtener el número de notificaciones no leídas
 */

session_start();
header('Content-Type: application/json');
require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/auth.php';

// Verificar autenticación
$auth = new Auth();
if (!$auth->isAuthenticated()) {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'count' => 0,
        'message' => 'No autenticado'
    ]);
    exit;
}

try {
    $db = getDB();
    $usuario_id = $_SESSION['usuario_id'] ?? null;
    
    $stmt = $db->prepare("
        SELECT COUNT(*) as total 
        FROM notificaciones 
        WHERE (usuario_id = :usuario_id OR usuario_id IS NULL) AND leida = 0
    ");
    $stmt->execute([':usuario_id' => $usuario_id]);
    $result = $stmt->fetch();
    $count = (int)$result['total'];
    
    echo json_encode([
        'success' => true,
        'count' => $count
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'count' => 0,
        'message' => 'Error al obtener contador: ' . $e->getMessage()
    ]);
}

