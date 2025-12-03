<?php
/**
 * Obtener planes disponibles para venta de membresías
 */
session_start();
header('Content-Type: application/json');
require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/auth.php';

$auth = new Auth();
if (!$auth->isAuthenticated() || !$auth->hasRole(['admin', 'entrenador', 'empleado'])) {
    http_response_code(403);
    echo json_encode(['success' => false, 'message' => 'No autorizado']);
    exit;
}

try {
    $db = getDB();
    
    $stmt = $db->query("
        SELECT id, nombre, tipo, precio, precio_app, descripcion
        FROM planes 
        WHERE activo = 1 
        ORDER BY nombre ASC
    ");
    
    $planes = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Formatear precios
    foreach ($planes as &$plan) {
        $plan['precio_formateado'] = '$' . number_format($plan['precio'], 0, ',', '.');
        $plan['precio_app_formateado'] = '$' . number_format($plan['precio_app'], 0, ',', '.');
    }
    
    echo json_encode([
        'success' => true,
        'planes' => $planes
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
}
?>


