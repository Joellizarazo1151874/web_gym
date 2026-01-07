<?php
/**
 * Eliminar horario de clase
 * Endpoint API para eliminar un horario físicamente
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

// Verificar rol (solo admin o entrenador)
if (!$auth->hasRole(['admin', 'entrenador'])) {
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
    
    $horario_id = isset($_POST['id']) ? (int)$_POST['id'] : 0;
    
    if ($horario_id <= 0) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'ID de horario inválido'
        ]);
        exit;
    }
    
    // Verificar que el horario existe
    $stmt = $db->prepare("SELECT id FROM clase_horarios WHERE id = :id");
    $stmt->execute([':id' => $horario_id]);
    if (!$stmt->fetch()) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Horario no encontrado'
        ]);
        exit;
    }
    
    // Eliminar físicamente el horario
    $stmt = $db->prepare("
        DELETE FROM clase_horarios 
        WHERE id = :id
    ");
    
    $stmt->execute([':id' => $horario_id]);
    
    echo json_encode([
        'success' => true,
        'message' => 'Horario eliminado exitosamente'
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al eliminar el horario: ' . $e->getMessage()
    ]);
}
?>

