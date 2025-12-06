<?php
/**
 * Subir imagen para el landing page
 * Requiere autenticación de administrador
 */
session_start();
header('Content-Type: application/json');
require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/auth.php';

$auth = new Auth();

// Verificar autenticación
if (!$auth->isAuthenticated()) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'No autenticado']);
    exit;
}

// Verificar que sea admin
if (!$auth->hasRole(['admin'])) {
    http_response_code(403);
    echo json_encode(['success' => false, 'message' => 'No autorizado']);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Método no permitido']);
    exit;
}

try {
    if (!isset($_FILES['image']) || $_FILES['image']['error'] !== UPLOAD_ERR_OK) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'No se recibió la imagen o hubo un error']);
        exit;
    }
    
    $file = $_FILES['image'];
    $section = $_POST['section'] ?? 'landing';
    $elementId = $_POST['element_id'] ?? 'image';
    
    // Validar tipo de archivo
    $allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml'];
    $finfo = finfo_open(FILEINFO_MIME_TYPE);
    $mimeType = finfo_file($finfo, $file['tmp_name']);
    finfo_close($finfo);
    
    if (!in_array($mimeType, $allowedTypes)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Tipo de archivo no permitido. Solo se permiten imágenes.']);
        exit;
    }
    
    // Validar tamaño (máximo 5MB)
    if ($file['size'] > 5242880) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'La imagen es demasiado grande. Máximo 5MB.']);
        exit;
    }
    
    // Crear directorio si no existe
    $uploadDir = __DIR__ . '/../uploads/landing/';
    if (!is_dir($uploadDir)) {
        mkdir($uploadDir, 0755, true);
    }
    
    // Generar nombre único
    $extension = pathinfo($file['name'], PATHINFO_EXTENSION);
    $fileName = $section . '_' . $elementId . '_' . time() . '_' . uniqid() . '.' . $extension;
    $filePath = $uploadDir . $fileName;
    
    // Mover archivo
    if (!move_uploaded_file($file['tmp_name'], $filePath)) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Error al guardar la imagen']);
        exit;
    }
    
    // Ruta relativa desde la raíz del proyecto
    $relativePath = 'uploads/landing/' . $fileName;
    
    echo json_encode([
        'success' => true,
        'image_path' => $relativePath,
        'message' => 'Imagen subida exitosamente'
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al subir imagen: ' . $e->getMessage()
    ]);
}
?>

