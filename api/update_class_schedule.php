<?php
/**
 * Actualizar horario de clase
 * Endpoint API para actualizar un horario existente
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
    $stmt = $db->prepare("SELECT id, clase_id FROM clase_horarios WHERE id = :id");
    $stmt->execute([':id' => $horario_id]);
    $horario_actual = $stmt->fetch();
    
    if (!$horario_actual) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Horario no encontrado'
        ]);
        exit;
    }
    
    // Obtener datos del POST
    $dia_semana = isset($_POST['dia_semana']) ? (int)$_POST['dia_semana'] : null;
    $hora_inicio = trim($_POST['hora_inicio'] ?? '');
    $hora_fin = trim($_POST['hora_fin'] ?? '');
    $activo = isset($_POST['activo']) ? (int)$_POST['activo'] : null;
    
    // Si no se proporcionan valores, mantener los actuales
    $stmt = $db->prepare("SELECT * FROM clase_horarios WHERE id = :id");
    $stmt->execute([':id' => $horario_id]);
    $horario_data = $stmt->fetch(PDO::FETCH_ASSOC);
    
    $dia_semana = $dia_semana !== null ? $dia_semana : $horario_data['dia_semana'];
    $hora_inicio = !empty($hora_inicio) ? $hora_inicio : $horario_data['hora_inicio'];
    $hora_fin = !empty($hora_fin) ? $hora_fin : $horario_data['hora_fin'];
    $activo = $activo !== null ? $activo : $horario_data['activo'];
    
    // Validaciones
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
    
    // Validar formato de hora
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
    
    // Verificar si hay conflictos con otros horarios (excluyendo el actual)
    $stmt = $db->prepare("
        SELECT id FROM clase_horarios 
        WHERE clase_id = :clase_id 
        AND dia_semana = :dia_semana 
        AND id != :horario_id
        AND (
            (hora_inicio <= :hora_inicio1 AND hora_fin > :hora_inicio2) OR
            (hora_inicio < :hora_fin1 AND hora_fin >= :hora_fin2) OR
            (hora_inicio >= :hora_inicio3 AND hora_fin <= :hora_fin3)
        )
        AND activo = 1
    ");
    $stmt->execute([
        ':clase_id' => $horario_actual['clase_id'],
        ':dia_semana' => $dia_semana,
        ':horario_id' => $horario_id,
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
            'message' => 'Ya existe otro horario activo para esta clase en este día y hora'
        ]);
        exit;
    }
    
    // Actualizar horario
    $stmt = $db->prepare("
        UPDATE clase_horarios 
        SET dia_semana = :dia_semana,
            hora_inicio = :hora_inicio,
            hora_fin = :hora_fin,
            activo = :activo
        WHERE id = :id
    ");
    
    $stmt->execute([
        ':id' => $horario_id,
        ':dia_semana' => $dia_semana,
        ':hora_inicio' => $hora_inicio,
        ':hora_fin' => $hora_fin,
        ':activo' => $activo
    ]);
    
    echo json_encode([
        'success' => true,
        'message' => 'Horario actualizado exitosamente'
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al actualizar el horario: ' . $e->getMessage()
    ]);
}
?>

