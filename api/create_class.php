<?php
/**
 * Crear nueva clase
 * Endpoint API para crear una nueva clase grupal
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
    $nombre = trim($_POST['nombre'] ?? '');
    $descripcion = trim($_POST['descripcion'] ?? '');
    $instructor_id = !empty($_POST['instructor_id']) ? (int)$_POST['instructor_id'] : null;
    $capacidad_maxima = !empty($_POST['capacidad_maxima']) ? (int)$_POST['capacidad_maxima'] : null;
    $duracion_minutos = !empty($_POST['duracion_minutos']) ? (int)$_POST['duracion_minutos'] : null;
    $activo = isset($_POST['activo']) ? (int)$_POST['activo'] : 1;
    
    // Validaciones
    if (empty($nombre)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'El nombre de la clase es requerido'
        ]);
        exit;
    }
    
    if ($capacidad_maxima !== null && $capacidad_maxima < 1) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'La capacidad máxima debe ser mayor a 0'
        ]);
        exit;
    }
    
    if ($duracion_minutos !== null && $duracion_minutos < 15) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'La duración mínima es de 15 minutos'
        ]);
        exit;
    }
    
    // Verificar si el instructor existe (si se proporcionó)
    if ($instructor_id !== null) {
        $stmt = $db->prepare("SELECT id FROM usuarios WHERE id = :id AND rol_id IN (SELECT id FROM roles WHERE nombre IN ('entrenador', 'admin'))");
        $stmt->execute([':id' => $instructor_id]);
        if (!$stmt->fetch()) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'El instructor seleccionado no es válido'
            ]);
            exit;
        }
    }
    
    // Insertar clase
    $stmt = $db->prepare("
        INSERT INTO clases (nombre, descripcion, instructor_id, capacidad_maxima, duracion_minutos, activo)
        VALUES (:nombre, :descripcion, :instructor_id, :capacidad_maxima, :duracion_minutos, :activo)
    ");
    
    $stmt->execute([
        ':nombre' => $nombre,
        ':descripcion' => $descripcion ?: null,
        ':instructor_id' => $instructor_id,
        ':capacidad_maxima' => $capacidad_maxima,
        ':duracion_minutos' => $duracion_minutos,
        ':activo' => $activo
    ]);
    
    $clase_id = $db->lastInsertId();
    
    echo json_encode([
        'success' => true,
        'message' => 'Clase creada exitosamente',
        'clase_id' => $clase_id
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al crear la clase: ' . $e->getMessage()
    ]);
}
?>

