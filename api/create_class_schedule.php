<?php
/**
 * Crear horario de clase
 * Endpoint API para crear un nuevo horario para una clase
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
    
    // Obtener datos del POST
    $clase_id = isset($_POST['clase_id']) ? (int)$_POST['clase_id'] : 0;
    $dia_semana = isset($_POST['dia_semana']) ? (int)$_POST['dia_semana'] : 0;
    $hora_inicio = trim($_POST['hora_inicio'] ?? '');
    $hora_fin = trim($_POST['hora_fin'] ?? '');
    $activo = isset($_POST['activo']) ? (int)$_POST['activo'] : 1;
    
    // Validaciones
    if ($clase_id <= 0) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'ID de clase inválido'
        ]);
        exit;
    }
    
    if ($dia_semana < 1 || $dia_semana > 7) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Día de la semana inválido (debe ser entre 1 y 7)'
        ]);
        exit;
    }
    
    if (empty($hora_inicio) || empty($hora_fin)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Las horas de inicio y fin son requeridas'
        ]);
        exit;
    }
    
    // Validar formato de hora (HH:MM)
    if (!preg_match('/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/', $hora_inicio) || 
        !preg_match('/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/', $hora_fin)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Formato de hora inválido (debe ser HH:MM)'
        ]);
        exit;
    }
    
    // Verificar que la hora de fin sea mayor que la de inicio
    if (strtotime($hora_fin) <= strtotime($hora_inicio)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'La hora de fin debe ser mayor que la hora de inicio'
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
    
    // Verificar si ya existe un horario para este día y hora (opcional, puedes comentar si quieres permitir múltiples)
    $stmt = $db->prepare("
        SELECT id FROM clase_horarios 
        WHERE clase_id = :clase_id 
        AND dia_semana = :dia_semana 
        AND (
            (hora_inicio <= :hora_inicio1 AND hora_fin > :hora_inicio2) OR
            (hora_inicio < :hora_fin1 AND hora_fin >= :hora_fin2) OR
            (hora_inicio >= :hora_inicio3 AND hora_fin <= :hora_fin3)
        )
        AND activo = 1
    ");
    $stmt->execute([
        ':clase_id' => $clase_id,
        ':dia_semana' => $dia_semana,
        ':hora_inicio1' => $hora_inicio,
        ':hora_inicio2' => $hora_inicio,
        ':hora_inicio3' => $hora_inicio,
        ':hora_fin1' => $hora_fin,
        ':hora_fin2' => $hora_fin,
        ':hora_fin3' => $hora_fin
    ]);
    
    if ($stmt->fetch()) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Ya existe un horario activo para esta clase en este día y hora'
        ]);
        exit;
    }
    
    // Insertar horario
    $stmt = $db->prepare("
        INSERT INTO clase_horarios (clase_id, dia_semana, hora_inicio, hora_fin, activo)
        VALUES (:clase_id, :dia_semana, :hora_inicio, :hora_fin, :activo)
    ");
    
    $stmt->execute([
        ':clase_id' => $clase_id,
        ':dia_semana' => $dia_semana,
        ':hora_inicio' => $hora_inicio,
        ':hora_fin' => $hora_fin,
        ':activo' => $activo
    ]);
    
    $horario_id = $db->lastInsertId();
    
    echo json_encode([
        'success' => true,
        'message' => 'Horario creado exitosamente',
        'horario_id' => $horario_id
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al crear el horario: ' . $e->getMessage()
    ]);
}
?>

