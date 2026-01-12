<?php
/**
 * Obtener datos actualizados del usuario actual
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept, Cookie, X-Session-ID');
header('Access-Control-Allow-Credentials: true');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/auth.php';

// LOG 1: Ver headers recibidos
error_log("=== INICIO mobile_get_current_user.php ===");
error_log("HTTP_X_SESSION_ID: " . ($_SERVER['HTTP_X_SESSION_ID'] ?? 'NO PRESENTE'));
error_log("Todos los headers: " . json_encode(getallheaders()));

// Restaurar sesión desde header
$restored = restoreSessionFromHeader();
error_log("restoreSessionFromHeader() retornó: " . ($restored ? 'TRUE' : 'FALSE'));

if (session_status() === PHP_SESSION_NONE) {
    error_log("Iniciando nueva sesión...");
    session_start();
} else {
    error_log("Sesión ya activa: " . session_id());
}

error_log("Session ID actual: " . session_id());
error_log("Contenido de \$_SESSION: " . json_encode($_SESSION));

$auth = new Auth();
$isAuth = $auth->isAuthenticated();
error_log("isAuthenticated() retornó: " . ($isAuth ? 'TRUE' : 'FALSE'));

if (!$isAuth) {
    error_log("❌ Usuario NO autenticado - enviando 401");
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'message' => 'No autenticado'
    ]);
    exit;
}

try {
    $db = getDB();
    $userId = $_SESSION['usuario_id'] ?? null;
    
    // LOG para debugging
    error_log("mobile_get_current_user.php - Session ID: " . session_id());
    error_log("mobile_get_current_user.php - usuario_id en sesión: " . ($userId ?? 'NULL'));
    error_log("mobile_get_current_user.php - Toda la sesión: " . json_encode($_SESSION));
    error_log("mobile_get_current_user.php - X-Session-ID header: " . ($_SERVER['HTTP_X_SESSION_ID'] ?? 'NO PRESENTE'));
    
    if (!$userId) {
        http_response_code(401);
        echo json_encode([
            'success' => false,
            'message' => 'No autenticado'
        ]);
        exit;
    }
    
    // Obtener datos del usuario
    $stmt = $db->prepare("
        SELECT 
            u.id,
            u.nombre,
            u.apellido,
            u.email,
            u.telefono,
            u.documento,
            u.foto,
            u.estado
        FROM usuarios u
        WHERE u.id = :usuario_id
    ");
    $stmt->execute([':usuario_id' => $userId]);
    $usuario = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$usuario) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Usuario no encontrado'
        ]);
        exit;
    }
    
    // Obtener membresía activa
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
        AND m.fecha_fin >= CURDATE()
        ORDER BY m.fecha_fin DESC
        LIMIT 1
    ");
    $stmt->execute([':usuario_id' => $userId]);
    $membresia = $stmt->fetch(PDO::FETCH_ASSOC);
    
    // Si no se encontró con la condición estricta, buscar cualquier membresía activa
    if (!$membresia) {
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
        $stmt->execute([':usuario_id' => $userId]);
        $membresia = $stmt->fetch(PDO::FETCH_ASSOC);
    }
    
    // Construir URL de foto si existe
    $foto_url = null;
    if (!empty($usuario['foto'])) {
        $baseUrl = getBaseUrl();
        $foto_url = $baseUrl . 'uploads/usuarios/' . $usuario['foto'];
    }
    
    // Respuesta exitosa (formato idéntico a mobile_login.php)
    $response = [
        'success' => true,
        'user' => [
            'id' => (int)$usuario['id'],
            'nombre' => $usuario['nombre'],
            'apellido' => $usuario['apellido'],
            'email' => $usuario['email'],
            'telefono' => $usuario['telefono'],
            'documento' => $usuario['documento'],
            'foto' => $foto_url,
            'estado' => $usuario['estado']
        ],
        'membership' => $membresia ? [
            'id' => (int)$membresia['id'],
            'plan_nombre' => $membresia['plan_nombre'],
            'fecha_inicio' => $membresia['fecha_inicio'],
            'fecha_fin' => $membresia['fecha_fin'],
            'estado' => $membresia['estado'],
            'dias_restantes' => (int)$membresia['dias_restantes']
        ] : null
    ];
    
    echo json_encode($response, JSON_UNESCAPED_UNICODE);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error en el servidor',
        'error' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
?>
