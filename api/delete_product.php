<?php
/**
 * Eliminar producto
 * Endpoint API para eliminar un producto del sistema
 */

session_start();
header('Content-Type: application/json');
require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/auth.php';

// Solo permitir POST o DELETE
if ($_SERVER['REQUEST_METHOD'] !== 'POST' && $_SERVER['REQUEST_METHOD'] !== 'DELETE') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Método no permitido'
    ]);
    exit;
}

// Verificar autenticación
$auth = new Auth();
if (!$auth->isAuthenticated()) {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'message' => 'No autenticado'
    ]);
    exit;
}

// Verificar rol (solo admin o entrenador)
if (!$auth->hasRole(['admin', 'entrenador'])) {
    http_response_code(403);
    echo json_encode([
        'success' => false,
        'message' => 'No autorizado'
    ]);
    exit;
}

try {
    $db = getDB();
    
    // Obtener ID del producto
    $producto_id = null;
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $producto_id = filter_input(INPUT_POST, 'id', FILTER_VALIDATE_INT);
    } else {
        $producto_id = filter_input(INPUT_GET, 'id', FILTER_VALIDATE_INT);
    }
    
    if (!$producto_id) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'ID de producto inválido'
        ]);
        exit;
    }
    
    // Obtener información del producto antes de eliminarlo (para eliminar la imagen)
    $stmt_check = $db->prepare("SELECT id, imagen FROM productos WHERE id = :id");
    $stmt_check->execute([':id' => $producto_id]);
    $producto = $stmt_check->fetch(PDO::FETCH_ASSOC);
    
    if (!$producto) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Producto no encontrado'
        ]);
        exit;
    }
    
    // Eliminar la imagen del producto si existe
    if (!empty($producto['imagen'])) {
        $upload_dir = dirname(__DIR__) . DIRECTORY_SEPARATOR . 'uploads' . DIRECTORY_SEPARATOR . 'productos' . DIRECTORY_SEPARATOR;
        $imagen_path = $upload_dir . $producto['imagen'];
        
        // Verificar que el archivo existe antes de intentar eliminarlo
        if (file_exists($imagen_path)) {
            if (!@unlink($imagen_path)) {
                // Si no se puede eliminar la imagen, registrar el error pero continuar con la eliminación del producto
                error_log("Error al eliminar la imagen del producto {$producto_id}: {$imagen_path}");
            }
        }
    }
    
    // Eliminar el producto de la base de datos
    $stmt = $db->prepare("DELETE FROM productos WHERE id = :id");
    $result = $stmt->execute([':id' => $producto_id]);
    
    if ($result) {
        echo json_encode([
            'success' => true,
            'message' => 'Producto eliminado correctamente'
        ]);
    } else {
        throw new Exception('Error al eliminar el producto');
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al eliminar producto: ' . $e->getMessage()
    ]);
}
?>

