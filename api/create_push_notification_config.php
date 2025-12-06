<?php
/**
 * Crear nueva configuración de notificación push
 * Endpoint API para crear nuevos tipos de notificaciones push personalizadas
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
        'message' => 'No autorizado. Solo administradores y entrenadores pueden crear configuraciones.'
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

try {
    $db = getDB();
    $data = json_decode(file_get_contents('php://input'), true);
    
    // Validar datos requeridos
    $tipo = trim($data['tipo'] ?? '');
    $titulo = trim($data['titulo'] ?? '');
    $mensaje = trim($data['mensaje'] ?? '');
    
    if (empty($tipo)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'El tipo es requerido'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    if (empty($titulo)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'El título es requerido'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    if (empty($mensaje)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'El mensaje es requerido'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    // Verificar que el tipo no exista ya
    $stmt_check = $db->prepare("SELECT id FROM push_notifications_config WHERE tipo = :tipo");
    $stmt_check->execute([':tipo' => $tipo]);
    if ($stmt_check->fetch()) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Ya existe una configuración con este tipo'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    // Insertar nueva configuración
    $stmt = $db->prepare("
        INSERT INTO push_notifications_config (
            tipo, activa, titulo, mensaje, dias_antes, dias_inactividad, hora_envio
        ) VALUES (
            :tipo, :activa, :titulo, :mensaje, :dias_antes, :dias_inactividad, :hora_envio
        )
    ");
    
    $stmt->execute([
        ':tipo' => $tipo,
        ':activa' => isset($data['activa']) ? (int)$data['activa'] : 1,
        ':titulo' => $titulo,
        ':mensaje' => $mensaje,
        ':dias_antes' => isset($data['dias_antes']) ? (int)$data['dias_antes'] : 0,
        ':dias_inactividad' => isset($data['dias_inactividad']) ? (int)$data['dias_inactividad'] : null,
        ':hora_envio' => $data['hora_envio'] ?? '09:00:00'
    ]);
    
    $config_id = $db->lastInsertId();
    
    echo json_encode([
        'success' => true,
        'message' => 'Configuración creada exitosamente',
        'config_id' => $config_id
    ], JSON_UNESCAPED_UNICODE);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al crear configuración: ' . $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}

