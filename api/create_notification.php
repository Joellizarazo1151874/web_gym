<?php
/**
 * Crear nueva notificación
 * Endpoint API para crear notificaciones (solo admin/entrenador)
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

// Verificar rol (solo admin o entrenador)
if (!$auth->hasRole(['admin', 'entrenador'])) {
    http_response_code(403);
    echo json_encode([
        'success' => false,
        'message' => 'No autorizado. Solo administradores y entrenadores pueden crear notificaciones.'
    ]);
    exit;
}

try {
    $db = getDB();
    $data = json_decode(file_get_contents('php://input'), true);
    
    // Validar datos requeridos
    $titulo = trim($data['titulo'] ?? '');
    $mensaje = trim($data['mensaje'] ?? '');
    $tipo = $data['tipo'] ?? 'info';
    $usuario_id = isset($data['usuario_id']) && $data['usuario_id'] !== '' ? (int)$data['usuario_id'] : null;
    
    // Validaciones
    if (empty($titulo)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'El título es requerido'
        ]);
        exit;
    }
    
    if (empty($mensaje)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'El mensaje es requerido'
        ]);
        exit;
    }
    
    // Validar tipo
    $tipos_validos = ['info', 'success', 'warning', 'error', 'promocion'];
    if (!in_array($tipo, $tipos_validos)) {
        $tipo = 'info';
    }
    
    // Si se especifica un usuario_id, verificar que existe
    if ($usuario_id !== null) {
        $stmt = $db->prepare("SELECT id FROM usuarios WHERE id = :id");
        $stmt->execute([':id' => $usuario_id]);
        if (!$stmt->fetch()) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'Usuario no encontrado'
            ]);
            exit;
        }
    }
    
    // Insertar notificación
    $stmt = $db->prepare("
        INSERT INTO notificaciones (usuario_id, titulo, mensaje, tipo, leida, fecha)
        VALUES (:usuario_id, :titulo, :mensaje, :tipo, 0, NOW())
    ");
    
    $stmt->execute([
        ':usuario_id' => $usuario_id,
        ':titulo' => $titulo,
        ':mensaje' => $mensaje,
        ':tipo' => $tipo
    ]);
    
    $notificacion_id = $db->lastInsertId();
    
    echo json_encode([
        'success' => true,
        'message' => 'Notificación creada exitosamente',
        'notificacion_id' => $notificacion_id
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al crear notificación: ' . $e->getMessage()
    ]);
}

