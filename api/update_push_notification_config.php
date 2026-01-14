<?php
/**
 * Actualizar configuración de notificación push
 * Endpoint API para actualizar la configuración de notificaciones push automáticas
 */

// Headers para CORS y JSON
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept, Cookie, X-Session-ID');
header('Access-Control-Allow-Credentials: true');

// Manejar preflight OPTIONS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

session_start();
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
        'message' => 'No autorizado. Solo administradores y entrenadores pueden modificar la configuración.'
    ]);
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
        ]);
        exit;
    }
    
    $config_id = (int)$data['id'];
    
    // Construir query de actualización
    $updates = [];
    $params = [':id' => $config_id];
    
    if (isset($data['activa'])) {
        $updates[] = 'activa = :activa';
        $params[':activa'] = (int)$data['activa'];
    }
    
    if (isset($data['titulo'])) {
        $updates[] = 'titulo = :titulo';
        $params[':titulo'] = trim($data['titulo']);
    }
    
    if (isset($data['mensaje'])) {
        $updates[] = 'mensaje = :mensaje';
        $params[':mensaje'] = trim($data['mensaje']);
    }
    
    if (isset($data['dias_antes'])) {
        $updates[] = 'dias_antes = :dias_antes';
        $params[':dias_antes'] = (int)$data['dias_antes'];
    }
    
    if (isset($data['dias_inactividad'])) {
        $updates[] = 'dias_inactividad = :dias_inactividad';
        $params[':dias_inactividad'] = (int)$data['dias_inactividad'];
    }
    
    if (isset($data['hora_envio'])) {
        $updates[] = 'hora_envio = :hora_envio';
        $params[':hora_envio'] = $data['hora_envio'];
    }
    
    if (empty($updates)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'No hay campos para actualizar'
        ]);
        exit;
    }
    
    $sql = "UPDATE push_notifications_config SET " . implode(', ', $updates) . " WHERE id = :id";
    $stmt = $db->prepare($sql);
    $stmt->execute($params);
    
    if ($stmt->rowCount() > 0) {
        echo json_encode([
            'success' => true,
            'message' => 'Configuración actualizada exitosamente'
        ], JSON_UNESCAPED_UNICODE);
    } else {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Configuración no encontrada o sin cambios'
        ], JSON_UNESCAPED_UNICODE);
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al actualizar configuración: ' . $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}

