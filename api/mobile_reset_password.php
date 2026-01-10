<?php
/**
 * Resetear Contraseña - Aplicación Móvil
 * Permite resetear la contraseña usando el token enviado por email
 */

// Headers para CORS y JSON
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept');

// Manejar preflight OPTIONS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Permitir POST y GET (GET para cuando se abre desde el email)
if (!in_array($_SERVER['REQUEST_METHOD'], ['POST', 'GET'])) {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Método no permitido'
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/../database/rate_limit_helper.php';

try {
    $db = getDB();
    
    // Verificar rate limiting (solo para POST)
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $rateLimit = checkRateLimit('reset_password', 5, 15);
        if (!$rateLimit['allowed']) {
            http_response_code(429);
            echo json_encode([
                'success' => false,
                'message' => $rateLimit['message']
            ], JSON_UNESCAPED_UNICODE);
            exit;
        }
    }

    // Obtener datos (puede venir de POST, GET o JSON)
    $token = '';
    $email = '';
    $password = '';
    $password_confirm = '';
    
    if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        // Si es GET, obtener de query string (cuando se abre desde el email)
        $token = trim($_GET['token'] ?? '');
        $email = trim($_GET['email'] ?? '');
    } else {
        // Si es POST, obtener de JSON o form-data
        $input = file_get_contents('php://input');
        $data = json_decode($input, true);
        
        if (json_last_error() !== JSON_ERROR_NONE || $data === null) {
            $data = $_POST;
        }
        
        $token = trim($data['token'] ?? '');
        $email = trim($data['email'] ?? '');
        $password = trim($data['password'] ?? '');
        $password_confirm = trim($data['password_confirm'] ?? '');
    }

    // Validaciones básicas (token y email siempre requeridos)
    if (empty($token) || empty($email)) {
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            recordFailedAttempt('reset_password');
        }
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Token o email inválido'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    // Si es GET, solo validar token y email, luego devolver éxito para mostrar formulario
    if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        $token_hash = hash('sha256', $token);
        
        $stmt = $db->prepare("
            SELECT id, token_verificacion, updated_at
            FROM usuarios 
            WHERE email = :email
        ");
        $stmt->execute([':email' => $email]);
        $usuario = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$usuario || $usuario['token_verificacion'] !== $token_hash) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'Token inválido o expirado'
            ], JSON_UNESCAPED_UNICODE);
            exit;
        }
        
        // Verificar expiración
        $token_created = strtotime($usuario['updated_at']);
        $now = time();
        if (($now - $token_created) > 3600) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'El token ha expirado. Solicita uno nuevo.'
            ], JSON_UNESCAPED_UNICODE);
            exit;
        }
        
        // Token válido, devolver éxito para que la app muestre el formulario
        echo json_encode([
            'success' => true,
            'message' => 'Token válido',
            'token' => $token,
            'email' => $email
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    // Si es POST, validar contraseñas
    if (empty($password) || empty($password_confirm)) {
        recordFailedAttempt('reset_password');
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Las contraseñas son requeridas'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        recordFailedAttempt('reset_password');
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Email inválido'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    if (strlen($password) < 8) {
        recordFailedAttempt('reset_password');
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'La contraseña debe tener al menos 8 caracteres'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    if ($password !== $password_confirm) {
        recordFailedAttempt('reset_password');
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Las contraseñas no coinciden'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // Buscar usuario y verificar token
    $token_hash = hash('sha256', $token);
    
    $stmt = $db->prepare("
        SELECT id, nombre, apellido, email, estado, token_verificacion, updated_at
        FROM usuarios 
        WHERE email = :email
    ");
    $stmt->execute([':email' => $email]);
    $usuario = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$usuario) {
        recordFailedAttempt('reset_password');
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Token o email inválido'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // Verificar que el token coincida
    if ($usuario['token_verificacion'] !== $token_hash) {
        recordFailedAttempt('reset_password');
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Token inválido o expirado'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // Verificar que el token no haya expirado (1 hora)
    $token_created = strtotime($usuario['updated_at']);
    $now = time();
    $expires_in = 3600; // 1 hora en segundos

    if (($now - $token_created) > $expires_in) {
        recordFailedAttempt('reset_password');
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'El token ha expirado. Solicita uno nuevo.'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // Verificar que el usuario no esté suspendido
    if ($usuario['estado'] === 'suspendido') {
        recordFailedAttempt('reset_password');
        http_response_code(403);
        echo json_encode([
            'success' => false,
            'message' => 'Tu cuenta está suspendida. Contacta al administrador.'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // Hash de la nueva contraseña
    $password_hash = password_hash($password, PASSWORD_DEFAULT);

    // Actualizar contraseña y limpiar token
    $stmt = $db->prepare("
        UPDATE usuarios 
        SET password = :password,
            token_verificacion = NULL,
            updated_at = NOW()
        WHERE id = :usuario_id
    ");
    $result = $stmt->execute([
        ':password' => $password_hash,
        ':usuario_id' => $usuario['id']
    ]);

    if ($result) {
        clearFailedAttempts('reset_password');
        echo json_encode([
            'success' => true,
            'message' => 'Contraseña restablecida exitosamente. Ya puedes iniciar sesión con tu nueva contraseña.'
        ], JSON_UNESCAPED_UNICODE);
    } else {
        throw new Exception('Error al actualizar la contraseña');
    }

} catch (Exception $e) {
    error_log("Error en mobile_reset_password.php: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al procesar la solicitud. Intenta nuevamente.'
    ], JSON_UNESCAPED_UNICODE);
}

