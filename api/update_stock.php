<?php
/**
 * API: Actualizar Stock de Producto
 * Actualiza la cantidad en stock de un producto
 */

session_start();
header('Content-Type: application/json');
require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/auth.php';

// Verificar autenticación
$auth = new Auth();
if (!$auth->isAuthenticated()) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'No autenticado']);
    exit;
}

// Verificar rol
if (!$auth->hasRole(['admin', 'entrenador'])) {
    http_response_code(403);
    echo json_encode(['success' => false, 'message' => 'No autorizado']);
    exit;
}

// Verificar método
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Método no permitido']);
    exit;
}

try {
    $db = getDB();
    
    // Obtener datos del formulario
    $product_id = $_POST['product_id'] ?? null;
    $stock = $_POST['stock'] ?? null;
    
    // Validar datos
    if (empty($product_id)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'ID de producto requerido']);
        exit;
    }
    
    if ($stock === null || $stock === '') {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Cantidad de stock requerida']);
        exit;
    }
    
    $stock = (int)$stock;
    
    if ($stock < 0) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'El stock no puede ser negativo']);
        exit;
    }
    
    // Verificar que el producto existe
    $stmt = $db->prepare("SELECT id, nombre FROM productos WHERE id = :id");
    $stmt->execute([':id' => $product_id]);
    $producto = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$producto) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'Producto no encontrado']);
        exit;
    }
    
    // Actualizar el stock
    $stmt = $db->prepare("UPDATE productos SET stock = :stock, updated_at = NOW() WHERE id = :id");
    $stmt->execute([
        ':stock' => $stock,
        ':id' => $product_id
    ]);
    
    if ($stmt->rowCount() > 0) {
        echo json_encode([
            'success' => true,
            'message' => 'Stock actualizado correctamente',
            'data' => [
                'product_id' => $product_id,
                'stock' => $stock
            ]
        ]);
    } else {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'No se pudo actualizar el stock']);
    }
    
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Error en la base de datos: ' . $e->getMessage()]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
}

