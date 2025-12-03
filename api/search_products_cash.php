<?php
/**
 * Buscar productos para la caja (solo con stock)
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

$search = $_GET['search'] ?? '';

try {
    $db = getDB();
    
    // Solo buscar si hay un término de búsqueda
    if (empty($search)) {
        echo json_encode([
            'success' => true,
            'productos' => []
        ]);
        exit;
    }
    
    $sql = "SELECT id, nombre, descripcion, precio, stock, categoria, imagen 
            FROM productos 
            WHERE activo = 1 
            AND (nombre LIKE :search1 OR descripcion LIKE :search2 OR categoria LIKE :search3)
            ORDER BY nombre ASC LIMIT 50";
    
    $searchTerm = '%' . $search . '%';
    $params = [
        ':search1' => $searchTerm,
        ':search2' => $searchTerm,
        ':search3' => $searchTerm
    ];
    
    $stmt = $db->prepare($sql);
    $stmt->execute($params);
    $productos = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Formatear datos
    foreach ($productos as &$producto) {
        $producto['precio_formateado'] = '$' . number_format($producto['precio'], 0, ',', '.');
        if ($producto['imagen']) {
            $producto['imagen_url'] = '../../../../uploads/productos/' . $producto['imagen'];
        } else {
            $producto['imagen_url'] = null;
        }
    }
    
    echo json_encode([
        'success' => true,
        'productos' => $productos
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
}
?>

