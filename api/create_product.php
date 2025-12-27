<?php
/**
 * Crear nuevo producto
 * Endpoint API para crear un nuevo producto en el sistema
 */

session_start();
header('Content-Type: application/json');
require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/../database/csrf_helper.php';
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

// Verificar rol (admin o empleado)
if (!$auth->hasRole(['admin', 'empleado'])) {
    http_response_code(403);
    echo json_encode([
        'success' => false,
        'message' => 'No autorizado'
    ]);
    exit;
}

// Validar token CSRF
requireCSRFToken(true);

try {
    $db = getDB();
    
    // Obtener datos del POST
    $nombre = trim($_POST['nombre'] ?? '');
    $descripcion = trim($_POST['descripcion'] ?? '');
    $categoria = trim($_POST['categoria'] ?? '');
    $precio = isset($_POST['precio']) ? (float)$_POST['precio'] : 0;
    $stock = isset($_POST['stock']) ? (int)$_POST['stock'] : 0;
    $activo = isset($_POST['activo']) ? (int)$_POST['activo'] : 1;
    
    // Validaciones básicas con mensajes específicos
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
    
    // Manejo de imagen
    $imagen_nombre = null;
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
        
        // Verificar que GD esté disponible para conversión
        if (!function_exists('imagecreatefromjpeg') || !function_exists('imagewebp')) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => 'La extensión GD de PHP no está disponible. No se puede convertir la imagen a WebP.'
            ]);
            exit;
        }
        
        // Definir ruta del directorio de uploads (desde api/ hacia uploads/productos/)
        $upload_dir = dirname(__DIR__) . DIRECTORY_SEPARATOR . 'uploads' . DIRECTORY_SEPARATOR . 'productos' . DIRECTORY_SEPARATOR;
        
        // Crear directorio si no existe con permisos adecuados
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
            // Intentar cambiar permisos
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
        
        // Generar nombre único con extensión .webp
        $imagen_nombre = 'producto_' . time() . '_' . uniqid() . '.webp';
        $upload_path = $upload_dir . $imagen_nombre;
        
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
                // imagecreatefrombmp está disponible desde PHP 7.2
                if (function_exists('imagecreatefrombmp')) {
                    $image = @imagecreatefrombmp($file['tmp_name']);
                } else {
                    // Para versiones anteriores, intentar cargar como PNG o JPEG
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
        
        // Convertir y guardar como WebP con calidad 85 (buena calidad, tamaño reducido)
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
    
    // Insertar producto
    $sql = "INSERT INTO productos (
        nombre, descripcion, categoria, precio, stock, imagen, activo
    ) VALUES (
        :nombre, :descripcion, :categoria, :precio, :stock, :imagen, :activo
    )";
    
    $stmt = $db->prepare($sql);
    $result = $stmt->execute([
        ':nombre' => $nombre,
        ':descripcion' => $descripcion ?: null,
        ':categoria' => $categoria ?: null,
        ':precio' => $precio,
        ':stock' => $stock,
        ':imagen' => $imagen_nombre,
        ':activo' => $activo
    ]);
    
    if ($result) {
        $producto_id = $db->lastInsertId();
        echo json_encode([
            'success' => true,
            'message' => 'Producto creado correctamente',
            'producto_id' => $producto_id
        ]);
    } else {
        // Si falló la inserción, eliminar la imagen subida
        if ($imagen_nombre && file_exists($upload_path)) {
            unlink($upload_path);
        }
        throw new Exception('Error al insertar el producto');
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al crear producto: ' . $e->getMessage()
    ]);
}

