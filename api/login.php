<?php
/**
 * Procesar Login
 * Endpoint para procesar el formulario de login
 */

session_start();
header('Content-Type: application/json');
require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/../database/csrf_helper.php';
require_once __DIR__ . '/../database/rate_limit_helper.php';

// Solo permitir POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Método no permitido'
    ]);
    exit;
}

// Validar token CSRF
requireCSRFToken(true);

// Verificar rate limiting (10 intentos, 10 minutos de bloqueo)
$rateLimit = checkRateLimit('login', 10, 10);
if (!$rateLimit['allowed']) {
    http_response_code(429); // Too Many Requests
    echo json_encode([
        'success' => false,
        'message' => $rateLimit['message'],
        'rate_limit' => [
            'lockout_until' => $rateLimit['lockout_until'],
            'remaining' => 0
        ]
    ]);
    exit;
}

// Incluir clase Auth
require_once __DIR__ . '/auth.php';

$auth = new Auth();

// Obtener datos del POST
$email = trim($_POST['email'] ?? '');
$password = $_POST['password'] ?? '';
$remember = isset($_POST['remember']) && $_POST['remember'] === 'on';

// Validar email
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    echo json_encode([
        'success' => false,
        'message' => 'Email inválido'
    ]);
    exit;
}

// Intentar login
$resultado = $auth->login($email, $password, $remember);

// Si el login falló, registrar intento fallido
if (!$resultado['success']) {
    recordFailedAttempt('login');
    $rateLimitInfo = getRateLimitInfo('login', 10, 10);
    
    // Agregar información de rate limit a la respuesta
    $resultado['rate_limit'] = [
        'remaining' => $rateLimitInfo['remaining'],
        'lockout_until' => $rateLimitInfo['lockout_until']
    ];
    
    // Si quedan pocos intentos, advertir al usuario
    if ($rateLimitInfo['remaining'] <= 3 && $rateLimitInfo['remaining'] > 0) {
        $resultado['message'] .= " Te quedan {$rateLimitInfo['remaining']} intento(s) antes del bloqueo temporal.";
    }
} else {
    // Si el login fue exitoso, limpiar intentos fallidos
    clearFailedAttempts('login');
}

// Responder
if ($resultado['success']) {
    // Redirigir según el rol
    $rol = $resultado['usuario']['rol'];
    
    // Determinar URL de redirección según el rol (usando BASE_URL dinámico)
    switch ($rol) {
        case 'admin':
            $redirectUrl = BASE_URL . 'dashboard/dist/dashboard/index.php';
            break;
        case 'entrenador':
            $redirectUrl = BASE_URL . 'dashboard/dist/dashboard/index.php';
            break;
        case 'cliente':
            $redirectUrl = BASE_URL . 'index.php';
            break;
        default:
            $redirectUrl = BASE_URL . 'dashboard/dist/dashboard/index.php';
    }
    
    echo json_encode([
        'success' => true,
        'message' => $resultado['message'],
        'redirect' => $redirectUrl
    ]);
} else {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'message' => $resultado['message']
    ]);
}
