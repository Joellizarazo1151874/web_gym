<?php
/**
 * Guardar contenido editable del landing page
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
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Datos inválidos']);
        exit;
    }
    
    $section = $input['section'] ?? '';
    $elementId = $input['element_id'] ?? '';
    $contentType = $input['content_type'] ?? 'text';
    $content = $input['content'] ?? null;
    $imagePath = $input['image_path'] ?? null;
    $altText = $input['alt_text'] ?? null;
    
    if (empty($section) || empty($elementId)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Section y element_id son requeridos']);
        exit;
    }
    
    $usuario = $auth->getCurrentUser();
    $db = getDB();
    
    // Verificar si ya existe
    $stmt = $db->prepare("SELECT id FROM landing_content WHERE section = :section AND element_id = :element_id");
    $stmt->execute([':section' => $section, ':element_id' => $elementId]);
    $existing = $stmt->fetch();
    
    if ($existing) {
        // Actualizar
        $sql = "UPDATE landing_content 
                SET content_type = :content_type, 
                    content = :content, 
                    image_path = :image_path, 
                    alt_text = :alt_text,
                    updated_by = :updated_by,
                    updated_at = NOW()
                WHERE section = :section AND element_id = :element_id";
        $stmt = $db->prepare($sql);
        $stmt->execute([
            ':section' => $section,
            ':element_id' => $elementId,
            ':content_type' => $contentType,
            ':content' => $content,
            ':image_path' => $imagePath,
            ':alt_text' => $altText,
            ':updated_by' => $usuario['id']
        ]);
    } else {
        // Insertar
        $sql = "INSERT INTO landing_content (section, element_id, content_type, content, image_path, alt_text, updated_by) 
                VALUES (:section, :element_id, :content_type, :content, :image_path, :alt_text, :updated_by)";
        $stmt = $db->prepare($sql);
        $stmt->execute([
            ':section' => $section,
            ':element_id' => $elementId,
            ':content_type' => $contentType,
            ':content' => $content,
            ':image_path' => $imagePath,
            ':alt_text' => $altText,
            ':updated_by' => $usuario['id']
        ]);
    }
    
    echo json_encode([
        'success' => true,
        'message' => 'Contenido guardado exitosamente'
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al guardar: ' . $e->getMessage()
    ]);
}
?>

