<?php
/**
 * Login para Aplicación Móvil
 * Endpoint específico para apps móviles que no requiere CSRF token
 * Usa rate limiting y validaciones adicionales para mantener la seguridad
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

require_once __DIR__ . '/../database/config.php';
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

// Verificar rate limiting (más estricto para móvil: 5 intentos, 15 minutos)
$rateLimit = checkRateLimit('mobile_login', 5, 15);
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

// Obtener datos del POST (puede venir como JSON o form-data)
$input = file_get_contents('php://input');
$data = json_decode($input, true);

// Si no es JSON, intentar obtener de POST
if (json_last_error() !== JSON_ERROR_NONE) {
    $data = $_POST;
}

$email = trim($data['email'] ?? '');
$password = $data['password'] ?? '';
$device_id = trim($data['device_id'] ?? ''); // ID único del dispositivo (opcional)

// Validar email
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    recordFailedAttempt('mobile_login');
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Email inválido'
    ]);
    exit;
}

// Validar que se proporcionó contraseña
if (empty($password)) {
    recordFailedAttempt('mobile_login');
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Contraseña requerida'
    ]);
    exit;
}

// Intentar login (sin remember para móvil)
$resultado = $auth->login($email, $password, false);

// Si el login falló, registrar intento fallido
if (!$resultado['success']) {
    recordFailedAttempt('mobile_login');
    $rateLimitInfo = getRateLimitInfo('mobile_login', 5, 15);
    
    // Agregar información de rate limit a la respuesta
    $resultado['rate_limit'] = [
        'remaining' => $rateLimitInfo['remaining'],
        'lockout_until' => $rateLimitInfo['lockout_until']
    ];
    
    // Si quedan pocos intentos, advertir al usuario
    if ($rateLimitInfo['remaining'] <= 2 && $rateLimitInfo['remaining'] > 0) {
        $resultado['message'] .= " Te quedan {$rateLimitInfo['remaining']} intento(s) antes del bloqueo temporal.";
    }
    
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'message' => $resultado['message'],
        'rate_limit' => $resultado['rate_limit']
    ]);
    exit;
}

// Si el login fue exitoso, limpiar intentos fallidos
clearFailedAttempts('mobile_login');

// Obtener información adicional del usuario para la app
try {
    $db = getDB();
    $usuario_id = $_SESSION['usuario_id'] ?? null;
    
    // Obtener membresía activa del usuario
    $stmt = $db->prepare("
        SELECT 
            m.id,
            m.plan_id,
            m.fecha_inicio,
            m.fecha_fin,
            m.estado,
            p.nombre as plan_nombre,
            p.precio as plan_precio,
            DATEDIFF(m.fecha_fin, CURDATE()) as dias_restantes
        FROM membresias m
        LEFT JOIN planes p ON m.plan_id = p.id
        WHERE m.usuario_id = :usuario_id
        AND m.estado = 'activa'
        ORDER BY m.fecha_fin DESC
        LIMIT 1
    ");
    $stmt->execute([':usuario_id' => $usuario_id]);
    $membresia = $stmt->fetch(PDO::FETCH_ASSOC);
    
    // Obtener datos completos del usuario
    $stmt = $db->prepare("
        SELECT 
            u.id,
            u.nombre,
            u.apellido,
            u.email,
            u.telefono,
            u.documento,
            u.foto,
            r.nombre as rol
        FROM usuarios u
        LEFT JOIN roles r ON u.rol_id = r.id
        WHERE u.id = :usuario_id
    ");
    $stmt->execute([':usuario_id' => $usuario_id]);
    $usuario_completo = $stmt->fetch(PDO::FETCH_ASSOC);
    
    // Construir URL de foto si existe
    $foto_url = null;
    if ($usuario_completo && !empty($usuario_completo['foto'])) {
        $baseUrl = getBaseUrl();
        $foto_url = $baseUrl . 'uploads/usuarios/' . $usuario_completo['foto'];
    }
    
    // Generar token de sesión (puedes usar el session_id o crear un token JWT)
    $session_token = session_id();
    
    // Respuesta exitosa con datos del usuario
    echo json_encode([
        'success' => true,
        'message' => 'Login exitoso',
        'token' => $session_token, // Token de sesión para futuras peticiones
        'user' => [
            'id' => $usuario_completo['id'],
            'nombre' => $usuario_completo['nombre'],
            'apellido' => $usuario_completo['apellido'],
            'email' => $usuario_completo['email'],
            'telefono' => $usuario_completo['telefono'],
            'documento' => $usuario_completo['documento'],
            'foto' => $foto_url,
            'rol' => $usuario_completo['rol']
        ],
        'membership' => $membresia ? [
            'id' => $membresia['id'],
            'plan_nombre' => $membresia['plan_nombre'],
            'fecha_inicio' => $membresia['fecha_inicio'],
            'fecha_fin' => $membresia['fecha_fin'],
            'estado' => $membresia['estado'],
            'dias_restantes' => (int)$membresia['dias_restantes']
        ] : null
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    
} catch (Exception $e) {
    error_log("Error en mobile_login.php: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al obtener datos del usuario'
    ]);
}

