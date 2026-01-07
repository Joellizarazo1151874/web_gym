<?php
/**
 * Eliminar clase
 * Endpoint API para eliminar una clase físicamente
 * Los horarios asociados se eliminarán automáticamente por CASCADE
 */

session_start();
header('Content-Type: application/json');
require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/../database/config_helpers.php';
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

// Verificar rol (solo admin)
if (!$auth->hasRole(['admin'])) {
    http_response_code(403);
    echo json_encode([
        'success' => false,
        'message' => 'Solo los administradores pueden eliminar clases'
    ]);
    exit;
}

// Validar token CSRF
requireCSRFToken(true);

try {
    $db = getDB();
    
    $clase_id = isset($_POST['id']) ? (int)$_POST['id'] : 0;
    
    if ($clase_id <= 0) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'ID de clase inválido'
        ]);
        exit;
    }
    
    // Verificar que la clase existe
    $stmt = $db->prepare("SELECT id FROM clases WHERE id = :id");
    $stmt->execute([':id' => $clase_id]);
    if (!$stmt->fetch()) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Clase no encontrada'
        ]);
        exit;
    }
    
    // Eliminar físicamente la clase
    // Los horarios se eliminarán automáticamente por la foreign key con ON DELETE CASCADE
    $stmt = $db->prepare("
        DELETE FROM clases 
        WHERE id = :id
    ");
    
    $stmt->execute([':id' => $clase_id]);
    
    echo json_encode([
        'success' => true,
        'message' => 'Clase eliminada exitosamente'
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al eliminar la clase: ' . $e->getMessage()
    ]);
}
?>

