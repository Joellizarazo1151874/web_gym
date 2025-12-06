<?php
/**
 * Obtener productos públicos para la landing page
 * Este endpoint es público y no requiere autenticación
 */
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');

// Prevenir errores de salida antes del JSON
error_reporting(E_ALL);
ini_set('display_errors', 0);

try {
    require_once __DIR__ . '/../database/config.php';
    
    $db = getDB();
    
    // Obtener solo productos activos con stock disponible
    $sql = "SELECT id, nombre, descripcion, categoria, precio, stock, imagen 
            FROM productos 
            WHERE activo = 1 
            AND stock > 0
            ORDER BY nombre ASC";
    
    $stmt = $db->prepare($sql);
    $stmt->execute();
    $productos = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Formatear datos y construir URLs de imágenes
    foreach ($productos as &$producto) {
        // Formatear precio
        $producto['precio_formateado'] = '$' . number_format($producto['precio'], 0, ',', '.');
        
        // Construir URL de imagen (ruta relativa desde la raíz del proyecto)
        if ($producto['imagen']) {
            // Ruta relativa desde la raíz: /ftgym/uploads/productos/imagen.jpg
            $baseUrl = getBaseUrl();
            $producto['imagen_url'] = $baseUrl . 'uploads/productos/' . $producto['imagen'];
        } else {
            // Imagen por defecto si no tiene
            $producto['imagen_url'] = null;
        }
    }
    
    $response = [
        'success' => true,
        'productos' => $productos
    ];
    
    echo json_encode($response, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    
} catch (PDOException $e) {
    http_response_code(500);
    $response = [
        'success' => false,
        'message' => 'Error de base de datos: ' . $e->getMessage()
    ];
    echo json_encode($response, JSON_UNESCAPED_UNICODE);
} catch (Exception $e) {
    http_response_code(500);
    $response = [
        'success' => false,
        'message' => 'Error al obtener productos: ' . $e->getMessage()
    ];
    echo json_encode($response, JSON_UNESCAPED_UNICODE);
}
?>

