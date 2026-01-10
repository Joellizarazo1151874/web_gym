<?php
/**
 * Subir imagen para chat
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
    if (!isset($_FILES['image'])) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'No se recibió ninguna imagen',
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
            'message' => 'Tipo de archivo no permitido. Solo se permiten imágenes',
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
    $uploadDir = __DIR__ . '/../uploads/chats/';
    if (!is_dir($uploadDir)) {
        mkdir($uploadDir, 0775, true);
    }

    // Generar nombre único
    $extension = pathinfo($file['name'], PATHINFO_EXTENSION);
    $fileName = uniqid('chat_', true) . '.' . $extension;
    $filePath = $uploadDir . $fileName;

    // Mover archivo
    $dirWritable = is_writable($uploadDir);
    $tmpFileExists = file_exists($file['tmp_name']);

    if (!move_uploaded_file($file['tmp_name'], $filePath)) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Error al guardar la imagen',
            'debug' => [
                'upload_dir' => $uploadDir,
                'dir_exists' => is_dir($uploadDir),
                'dir_writable' => $dirWritable,
                'tmp_file' => $file['tmp_name'],
                'tmp_file_exists' => $tmpFileExists,
                'target_path' => $filePath,
                'file_error' => $file['error']
            ]
        ]);
        exit;
    }

    // Retornar URL completa
    $baseUrl = getSiteUrl();
    $imageUrl = $baseUrl . 'uploads/chats/' . $fileName;

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
