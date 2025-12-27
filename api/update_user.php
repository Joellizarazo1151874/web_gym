<?php
/**
 * Actualizar usuario
 * Endpoint API para actualizar información de un usuario
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

// Verificar rol (admin o empleado)
if (!$auth->hasRole(['admin', 'empleado'])) {
    http_response_code(403);
    echo json_encode([
        'success' => false,
        'message' => 'No autorizado'
    ]);
    exit;
}

// Obtener datos del POST
$user_id = isset($_POST['user_id']) ? (int)$_POST['user_id'] : 0;

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
    
    // Verificar que el usuario existe
    $stmt = $db->prepare("SELECT id FROM usuarios WHERE id = :id");
    $stmt->execute([':id' => $user_id]);
    if (!$stmt->fetch()) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Usuario no encontrado'
        ]);
        exit;
    }
    
    // Obtener rol del usuario actual
    $usuario_actual = $auth->getCurrentUser();
    $es_empleado = $usuario_actual['rol'] === 'empleado';
    
    // Preparar datos para actualizar
    $nombre = trim($_POST['nombre'] ?? '');
    $apellido = trim($_POST['apellido'] ?? '');
    $email = trim($_POST['email'] ?? '');
    $telefono = trim($_POST['telefono'] ?? '');
    $tipo_documento = $_POST['tipo_documento'] ?? 'CC';
    $documento = trim($_POST['documento'] ?? '');
    $estado = $_POST['estado'] ?? 'activo';
    $fecha_nacimiento = !empty($_POST['fecha_nacimiento']) ? $_POST['fecha_nacimiento'] : null;
    $genero = $_POST['genero'] ?? null;
    $direccion = trim($_POST['direccion'] ?? '');
    $ciudad = trim($_POST['ciudad'] ?? '');
    $password = trim($_POST['password'] ?? '');
    
    // Manejar rol_id según el tipo de usuario
    $rol_id = null;
    if ($es_empleado) {
        // Si es empleado, obtener el rol actual del usuario (no permitir cambiarlo)
        $stmt_rol = $db->prepare("SELECT rol_id FROM usuarios WHERE id = :id");
        $stmt_rol->execute([':id' => $user_id]);
        $usuario_actual_data = $stmt_rol->fetch(PDO::FETCH_ASSOC);
        if ($usuario_actual_data) {
            $rol_id = (int)$usuario_actual_data['rol_id'];
        } else {
            http_response_code(404);
            echo json_encode([
                'success' => false,
                'message' => 'Usuario no encontrado'
            ]);
            exit;
        }
    } else {
        // Si es admin, permitir cambiar el rol
        $rol_id = isset($_POST['rol_id']) ? (int)$_POST['rol_id'] : 0;
    }
    
    // Validaciones básicas
    if (empty($nombre) || empty($apellido) || empty($email) || empty($documento)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Por favor completa todos los campos requeridos'
        ]);
        exit;
    }
    
    // Validar rol_id solo si es admin
    if (!$es_empleado && $rol_id <= 0) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Por favor selecciona un rol válido'
        ]);
        exit;
    }
    
    // Validar email
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Email inválido'
        ]);
        exit;
    }
    
    // Verificar que el email no esté en uso por otro usuario
    $stmt = $db->prepare("SELECT id FROM usuarios WHERE email = :email AND id != :id");
    $stmt->execute([':email' => $email, ':id' => $user_id]);
    if ($stmt->fetch()) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'El email ya está en uso por otro usuario'
        ]);
        exit;
    }
    
    // Verificar que el documento no esté en uso por otro usuario
    $stmt = $db->prepare("SELECT id FROM usuarios WHERE documento = :documento AND id != :id");
    $stmt->execute([':documento' => $documento, ':id' => $user_id]);
    if ($stmt->fetch()) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'El documento ya está en uso por otro usuario'
        ]);
        exit;
    }
    
    // Construir consulta de actualización
    $sql = "UPDATE usuarios SET 
            nombre = :nombre,
            apellido = :apellido,
            email = :email,
            telefono = :telefono,
            tipo_documento = :tipo_documento,
            documento = :documento,
            rol_id = :rol_id,
            estado = :estado,
            fecha_nacimiento = :fecha_nacimiento,
            genero = :genero,
            direccion = :direccion,
            ciudad = :ciudad";
    
    $params = [
        ':nombre' => $nombre,
        ':apellido' => $apellido,
        ':email' => $email,
        ':telefono' => $telefono ?: null,
        ':tipo_documento' => $tipo_documento,
        ':documento' => $documento,
        ':rol_id' => $rol_id,
        ':estado' => $estado,
        ':fecha_nacimiento' => $fecha_nacimiento ?: null,
        ':genero' => $genero ?: null,
        ':direccion' => $direccion ?: null,
        ':ciudad' => $ciudad ?: null,
        ':id' => $user_id
    ];
    
    // Si se proporciona una nueva contraseña, actualizarla
    if (!empty($password)) {
        if (strlen($password) < 8) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'La contraseña debe tener al menos 8 caracteres'
            ]);
            exit;
        }
        $sql .= ", password = :password";
        $params[':password'] = password_hash($password, PASSWORD_DEFAULT);
    }
    
    $sql .= " WHERE id = :id";
    
    $stmt = $db->prepare($sql);
    $stmt->execute($params);
    
    echo json_encode([
        'success' => true,
        'message' => 'Usuario actualizado correctamente'
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al actualizar usuario: ' . $e->getMessage()
    ]);
}

