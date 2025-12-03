<?php
/**
 * Obtener datos de un usuario
 * Endpoint API para obtener información de un usuario por ID
 */

session_start();
header('Content-Type: application/json');
require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/auth.php';

// Solo permitir GET
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
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

// Obtener ID del usuario
$user_id = isset($_GET['id']) ? (int)$_GET['id'] : 0;

if ($user_id <= 0) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'ID de usuario inválido'
    ]);
    exit;
}

try {
    $db = getDB();
    
    // Obtener datos del usuario
    $stmt = $db->prepare("
        SELECT 
            u.id,
            u.rol_id,
            u.documento,
            u.tipo_documento,
            u.nombre,
            u.apellido,
            u.email,
            u.telefono,
            u.fecha_nacimiento,
            u.genero,
            u.direccion,
            u.ciudad,
            u.foto,
            u.estado,
            u.email_verificado,
            u.created_at,
            r.nombre as rol_nombre
        FROM usuarios u
        INNER JOIN roles r ON u.rol_id = r.id
        WHERE u.id = :id
    ");
    
    $stmt->execute([':id' => $user_id]);
    $usuario = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$usuario) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Usuario no encontrado'
        ]);
        exit;
    }
    
    // No devolver la contraseña
    unset($usuario['password']);
    
    // Formatear fecha de nacimiento para el input date
    if ($usuario['fecha_nacimiento']) {
        $usuario['fecha_nacimiento'] = date('Y-m-d', strtotime($usuario['fecha_nacimiento']));
    }
    
    echo json_encode([
        'success' => true,
        'data' => $usuario
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al obtener usuario: ' . $e->getMessage()
    ]);
}

