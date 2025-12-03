<?php
/**
 * Actualizar producto existente
 * Endpoint API para actualizar un producto en el sistema
 */

session_start();
header('Content-Type: application/json');
require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/auth.php';

// Solo permitir POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
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
    $producto_id = filter_input(INPUT_POST, 'id', FILTER_VALIDATE_INT);
    
    if (!$producto_id) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'ID de producto inválido'
        ]);
        exit;
    }
    
    // Verificar que el producto existe
    $stmt_check = $db->prepare("SELECT id, imagen FROM productos WHERE id = :id");
    $stmt_check->execute([':id' => $producto_id]);
    $producto_existente = $stmt_check->fetch(PDO::FETCH_ASSOC);
    
    if (!$producto_existente) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Producto no encontrado'
        ]);
        exit;
    }
    
    // Obtener datos del POST
    $nombre = trim($_POST['nombre'] ?? '');
    $descripcion = trim($_POST['descripcion'] ?? '');
    $categoria = trim($_POST['categoria'] ?? '');
    $precio = isset($_POST['precio']) ? (float)$_POST['precio'] : 0;
    $stock = isset($_POST['stock']) ? (int)$_POST['stock'] : 0;
    $activo = isset($_POST['activo']) ? (int)$_POST['activo'] : 1;
    
    // Validaciones básicas
    $campos_faltantes = [];
    if (empty($nombre)) $campos_faltantes[] = 'Nombre';
    if (empty($categoria)) $campos_faltantes[] = 'Categoría';
    if ($precio <= 0) $campos_faltantes[] = 'Precio válido';
    if ($stock < 0) $campos_faltantes[] = 'Stock válido';
    
    if (!empty($campos_faltantes)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Por favor completa los siguientes campos requeridos: ' . implode(', ', $campos_faltantes)
        ]);
        exit;
    }
    
    // Manejo de imagen (solo si se sube una nueva)
    $imagen_nombre = $producto_existente['imagen']; // Mantener la imagen actual por defecto
    
    if (isset($_FILES['imagen']) && $_FILES['imagen']['error'] === UPLOAD_ERR_OK) {
        $file = $_FILES['imagen'];
        
        // Validar que sea una imagen válida
        $file_type = mime_content_type($file['tmp_name']);
        $allowed_types = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp', 'image/bmp'];
        
        if (!in_array($file_type, $allowed_types)) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'Tipo de archivo no permitido. Solo se permiten imágenes (JPG, PNG, GIF, WEBP, BMP)'
            ]);
            exit;
        }
        
        // Verificar que GD esté disponible
        if (!function_exists('imagecreatefromjpeg') || !function_exists('imagewebp')) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => 'La extensión GD de PHP no está disponible. No se puede convertir la imagen a WebP.'
            ]);
            exit;
        }
        
        // Definir ruta del directorio de uploads
        $upload_dir = dirname(__DIR__) . DIRECTORY_SEPARATOR . 'uploads' . DIRECTORY_SEPARATOR . 'productos' . DIRECTORY_SEPARATOR;
        
        // Crear directorio si no existe
        if (!is_dir($upload_dir)) {
            if (!@mkdir($upload_dir, 0755, true)) {
                http_response_code(500);
                echo json_encode([
                    'success' => false,
                    'message' => 'Error al crear el directorio de imágenes. Ruta: ' . $upload_dir
                ]);
                exit;
            }
        }
        
        // Verificar que el directorio es escribible
        if (!is_writable($upload_dir)) {
            @chmod($upload_dir, 0755);
            if (!is_writable($upload_dir)) {
                http_response_code(500);
                echo json_encode([
                    'success' => false,
                    'message' => 'El directorio de imágenes no tiene permisos de escritura. Ruta: ' . $upload_dir
                ]);
                exit;
            }
        }
        
        // Eliminar imagen anterior si existe
        if (!empty($producto_existente['imagen'])) {
            $imagen_anterior = $upload_dir . $producto_existente['imagen'];
            if (file_exists($imagen_anterior)) {
                @unlink($imagen_anterior);
            }
        }
        
        // Cargar la imagen según su tipo
        $image = null;
        switch ($file_type) {
            case 'image/jpeg':
            case 'image/jpg':
                $image = @imagecreatefromjpeg($file['tmp_name']);
                break;
            case 'image/png':
                $image = @imagecreatefrompng($file['tmp_name']);
                break;
            case 'image/gif':
                $image = @imagecreatefromgif($file['tmp_name']);
                break;
            case 'image/webp':
                $image = @imagecreatefromwebp($file['tmp_name']);
                break;
            case 'image/bmp':
                if (function_exists('imagecreatefrombmp')) {
                    $image = @imagecreatefrombmp($file['tmp_name']);
                } else {
                    http_response_code(400);
                    echo json_encode([
                        'success' => false,
                        'message' => 'El formato BMP no está soportado en esta versión de PHP. Use JPG, PNG, GIF o WEBP.'
                    ]);
                    exit;
                }
                break;
            default:
                http_response_code(400);
                echo json_encode([
                    'success' => false,
                    'message' => 'Formato de imagen no soportado'
                ]);
                exit;
        }
        
        if (!$image) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => 'Error al procesar la imagen. Verifique que el archivo sea una imagen válida.'
            ]);
            exit;
        }
        
        // Si es PNG, preservar transparencia
        if ($file_type === 'image/png') {
            imagealphablending($image, false);
            imagesavealpha($image, true);
        }
        
        // Generar nombre único con extensión .webp
        $imagen_nombre = 'producto_' . time() . '_' . uniqid() . '.webp';
        $upload_path = $upload_dir . $imagen_nombre;
        
        // Convertir y guardar como WebP con calidad 85
        $quality = 85;
        if (!imagewebp($image, $upload_path, $quality)) {
            imagedestroy($image);
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => 'Error al convertir y guardar la imagen en formato WebP'
            ]);
            exit;
        }
        
        // Liberar memoria
        imagedestroy($image);
        
        // Verificar que el archivo se guardó correctamente
        if (!file_exists($upload_path)) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => 'Error: El archivo no se guardó correctamente'
            ]);
            exit;
        }
    }
    
    // Actualizar producto
    $sql = "UPDATE productos SET 
        nombre = :nombre,
        descripcion = :descripcion,
        categoria = :categoria,
        precio = :precio,
        stock = :stock,
        imagen = :imagen,
        activo = :activo
    WHERE id = :id";
    
    $stmt = $db->prepare($sql);
    $result = $stmt->execute([
        ':id' => $producto_id,
        ':nombre' => $nombre,
        ':descripcion' => $descripcion ?: null,
        ':categoria' => $categoria ?: null,
        ':precio' => $precio,
        ':stock' => $stock,
        ':imagen' => $imagen_nombre,
        ':activo' => $activo
    ]);
    
    if ($result) {
        echo json_encode([
            'success' => true,
            'message' => 'Producto actualizado correctamente'
        ]);
    } else {
        throw new Exception('Error al actualizar el producto');
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al actualizar producto: ' . $e->getMessage()
    ]);
}
?>

