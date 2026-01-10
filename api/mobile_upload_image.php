<?php
/**
 * Subir imagen para posts
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept, Cookie, X-Session-ID');
header('Access-Control-Allow-Credentials: true');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/auth.php';

restoreSessionFromHeader();

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

$auth = new Auth();
if (!$auth->isAuthenticated()) {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'message' => 'No autenticado',
    ]);
    exit;
}

try {
    if (!isset($_FILES['image']) || $_FILES['image']['error'] !== UPLOAD_ERR_OK) {
        echo json_encode([
            'success' => false,
            'message' => 'No se recibió ninguna imagen o hubo un error en la carga',
        ]);
        exit;
    }

    $file = $_FILES['image'];
    $allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];
    $maxFileSize = 10 * 1024 * 1024; // 10 MB

    // Validar tipo de archivo
    $finfo = finfo_open(FILEINFO_MIME_TYPE);
    $mimeType = finfo_file($finfo, $file['tmp_name']);
    finfo_close($finfo);

    if (!in_array($mimeType, $allowedTypes)) {
        echo json_encode([
            'success' => false,
            'message' => 'Tipo de archivo no permitido. Solo se permiten imágenes (JPG, PNG, GIF, WEBP)',
        ]);
        exit;
    }

    // Validar tamaño
    if ($file['size'] > $maxFileSize) {
        echo json_encode([
            'success' => false,
            'message' => 'La imagen es demasiado grande. Máximo 10 MB',
        ]);
        exit;
    }

    // Crear directorio si no existe
    $uploadDir = __DIR__ . '/../uploads/posts/';
    if (!is_dir($uploadDir)) {
        mkdir($uploadDir, 0755, true);
    }

    // Generar nombre único
    $extension = pathinfo($file['name'], PATHINFO_EXTENSION);
    $fileName = uniqid('post_', true) . '.' . $extension;
    $filePath = $uploadDir . $fileName;

    // Mover archivo
    if (!move_uploaded_file($file['tmp_name'], $filePath)) {
        echo json_encode([
            'success' => false,
            'message' => 'Error al guardar la imagen',
        ]);
        exit;
    }

    // Retornar URL relativa
    $imageUrl = '/uploads/posts/' . $fileName;

    echo json_encode([
        'success' => true,
        'message' => 'Imagen subida correctamente',
        'url' => $imageUrl,
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al subir imagen: ' . $e->getMessage(),
    ]);
}
