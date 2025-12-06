<?php
/**
 * Eliminar configuración de notificación push
 * Endpoint API para eliminar configuraciones de notificaciones push
 */

session_start();
header('Content-Type: application/json; charset=utf-8');
require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/auth.php';

// Solo permitir POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Método no permitido'
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

// Verificar autenticación
$auth = new Auth();
if (!$auth->isAuthenticated()) {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'message' => 'No autenticado'
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

// Verificar rol (solo admin o entrenador)
if (!$auth->hasRole(['admin', 'entrenador'])) {
    http_response_code(403);
    echo json_encode([
        'success' => false,
        'message' => 'No autorizado'
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

try {
    $db = getDB();
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($data['id'])) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'ID de configuración requerido'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    $config_id = (int)$data['id'];
    
    // Verificar que no sea una configuración del sistema (opcional: proteger tipos predefinidos)
    $tipos_protegidos = ['cumpleanos', 'membresia_vencimiento', 'membresia_vencida', 'inactividad'];
    $stmt_check = $db->prepare("SELECT tipo FROM push_notifications_config WHERE id = :id");
    $stmt_check->execute([':id' => $config_id]);
    $config = $stmt_check->fetch();
    
    if (!$config) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Configuración no encontrada'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    // Eliminar configuración
    $stmt = $db->prepare("DELETE FROM push_notifications_config WHERE id = :id");
    $stmt->execute([':id' => $config_id]);
    
    if ($stmt->rowCount() > 0) {
        echo json_encode([
            'success' => true,
            'message' => 'Configuración eliminada exitosamente'
        ], JSON_UNESCAPED_UNICODE);
    } else {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'No se pudo eliminar la configuración'
        ], JSON_UNESCAPED_UNICODE);
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al eliminar configuración: ' . $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}

