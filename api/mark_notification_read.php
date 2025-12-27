<?php
/**
 * Marcar notificación como leída
 * Endpoint API para marcar una o todas las notificaciones como leídas
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

try {
    $db = getDB();
    $usuario_id = $_SESSION['usuario_id'] ?? null;
    $data = json_decode(file_get_contents('php://input'), true);
    
    $notificacion_id = isset($data['id']) ? (int)$data['id'] : null;
    $marcar_todas = isset($data['marcar_todas']) && $data['marcar_todas'] === true;
    
    if ($marcar_todas) {
        // Marcar todas las notificaciones del usuario como leídas
        $stmt = $db->prepare("
            UPDATE notificaciones 
            SET leida = 1, fecha_leida = NOW()
            WHERE (usuario_id = :usuario_id OR usuario_id IS NULL) AND leida = 0
        ");
        $stmt->execute([':usuario_id' => $usuario_id]);
        $affected = $stmt->rowCount();
        
        echo json_encode([
            'success' => true,
            'message' => "Se marcaron $affected notificaciones como leídas"
        ]);
    } elseif ($notificacion_id) {
        // Marcar una notificación específica como leída
        $stmt = $db->prepare("
            UPDATE notificaciones 
            SET leida = 1, fecha_leida = NOW()
            WHERE id = :id AND (usuario_id = :usuario_id OR usuario_id IS NULL)
        ");
        $stmt->execute([
            ':id' => $notificacion_id,
            ':usuario_id' => $usuario_id
        ]);
        
        if ($stmt->rowCount() > 0) {
            echo json_encode([
                'success' => true,
                'message' => 'Notificación marcada como leída'
            ]);
        } else {
            http_response_code(404);
            echo json_encode([
                'success' => false,
                'message' => 'Notificación no encontrada'
            ]);
        }
    } else {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Debe proporcionar un ID de notificación o marcar todas'
        ]);
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al marcar notificación: ' . $e->getMessage()
    ]);
}

