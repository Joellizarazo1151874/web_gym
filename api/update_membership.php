<?php
/**
 * Actualizar membresía
 */
session_start();
header('Content-Type: application/json');
require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/auth.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Método no permitido']);
    exit;
}

$auth = new Auth();
if (!$auth->isAuthenticated() || !$auth->hasRole(['admin', 'entrenador', 'empleado'])) {
    http_response_code(403);
    echo json_encode(['success' => false, 'message' => 'No autorizado']);
    exit;
}

try {
    $db = getDB();
    
    $data = json_decode(file_get_contents('php://input'), true);
    
    $membresia_id = !empty($data['id']) ? (int)$data['id'] : null;
    $fecha_inicio = !empty($data['fecha_inicio']) ? trim($data['fecha_inicio']) : null;
    $fecha_fin = !empty($data['fecha_fin']) ? trim($data['fecha_fin']) : null;
    $precio_pagado = isset($data['precio_pagado']) ? (float)$data['precio_pagado'] : null;
    $descuento_app = isset($data['descuento_app']) ? (int)$data['descuento_app'] : 0;
    $estado = !empty($data['estado']) ? trim($data['estado']) : null;
    $observaciones = !empty($data['observaciones']) ? trim($data['observaciones']) : null;
    
    // Validaciones
    if (!$membresia_id) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'ID de membresía requerido']);
        exit;
    }
    
    if (!$fecha_inicio || !$fecha_fin) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Fechas de inicio y fin requeridas']);
        exit;
    }
    
    // Validar formato de fechas
    $fecha_inicio_obj = DateTime::createFromFormat('Y-m-d', $fecha_inicio);
    $fecha_fin_obj = DateTime::createFromFormat('Y-m-d', $fecha_fin);
    
    if (!$fecha_inicio_obj || $fecha_inicio_obj->format('Y-m-d') !== $fecha_inicio) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Formato de fecha de inicio inválido']);
        exit;
    }
    
    if (!$fecha_fin_obj || $fecha_fin_obj->format('Y-m-d') !== $fecha_fin) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Formato de fecha de fin inválido']);
        exit;
    }
    
    // Validar que fecha_fin sea mayor que fecha_inicio
    if ($fecha_fin_obj < $fecha_inicio_obj) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'La fecha de fin debe ser mayor que la fecha de inicio']);
        exit;
    }
    
    if ($precio_pagado === null || $precio_pagado < 0) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Precio pagado inválido']);
        exit;
    }
    
    if (!in_array($estado, ['activa', 'vencida', 'cancelada', 'suspendida'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Estado inválido']);
        exit;
    }
    
    // Verificar que la membresía existe y obtener fechas originales
    $stmt = $db->prepare("SELECT fecha_inicio, fecha_fin FROM membresias WHERE id = :id");
    $stmt->execute([':id' => $membresia_id]);
    $membresia_original = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$membresia_original) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'Membresía no encontrada']);
        exit;
    }
    
    // Verificar si el usuario es admin
    $es_admin = $auth->hasRole('admin');
    
    // Si no es admin, usar las fechas originales (no permitir modificar)
    if (!$es_admin) {
        $fecha_inicio = $membresia_original['fecha_inicio'];
        $fecha_fin = $membresia_original['fecha_fin'];
    }
    
    // Actualizar membresía
    $stmt = $db->prepare("
        UPDATE membresias 
        SET fecha_inicio = :fecha_inicio,
            fecha_fin = :fecha_fin,
            precio_pagado = :precio_pagado,
            descuento_app = :descuento_app,
            estado = :estado,
            observaciones = :observaciones
        WHERE id = :id
    ");
    
    $stmt->execute([
        ':id' => $membresia_id,
        ':fecha_inicio' => $fecha_inicio,
        ':fecha_fin' => $fecha_fin,
        ':precio_pagado' => $precio_pagado,
        ':descuento_app' => $descuento_app,
        ':estado' => $estado,
        ':observaciones' => $observaciones ?: null
    ]);
    
    // Si el estado cambió a 'activa', actualizar estado del usuario a 'activo'
    if ($estado === 'activa') {
        $stmt = $db->prepare("
            UPDATE usuarios 
            SET estado = 'activo' 
            WHERE id = (SELECT usuario_id FROM membresias WHERE id = :id)
            AND estado != 'suspendido'
        ");
        $stmt->execute([':id' => $membresia_id]);
    }
    
    // Si el estado cambió a 'vencida' o 'cancelada', verificar si el usuario tiene otras membresías activas
    if (in_array($estado, ['vencida', 'cancelada'])) {
        $stmt = $db->prepare("
            UPDATE usuarios u
            SET u.estado = 'inactivo'
            WHERE u.id = (SELECT usuario_id FROM membresias WHERE id = :id)
            AND u.estado != 'suspendido'
            AND u.id NOT IN (
                SELECT DISTINCT m.usuario_id 
                FROM membresias m 
                WHERE m.estado = 'activa' 
                AND m.fecha_fin >= CURDATE()
                AND m.id != :id
            )
        ");
        $stmt->execute([':id' => $membresia_id]);
    }
    
    echo json_encode([
        'success' => true,
        'message' => 'Membresía actualizada correctamente'
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
}
?>

