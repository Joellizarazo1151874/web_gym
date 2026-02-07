<?php
/**
 * Obtener lista de instructores (entrenadores y admins) para la App Móvil
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

restoreSessionFromHeader();

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

$auth = new Auth();
if (!$auth->isAuthenticated()) {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'message' => 'No autenticado'
    ]);
    exit;
}

try {
    $db = getDB();

    // Obtener usuarios con rol de entrenador o admin
    $stmt = $db->prepare("
        SELECT 
            u.id,
            u.nombre,
            u.apellido,
            r.nombre as rol
        FROM usuarios u
        JOIN roles r ON u.rol_id = r.id
        WHERE r.nombre IN ('entrenador', 'admin')
        AND u.estado = 'activo'
        ORDER BY u.nombre ASC, u.apellido ASC
    ");
    $stmt->execute();
    $instructores = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Formatear IDs
    foreach ($instructores as &$ins) {
        $ins['id'] = (int) $ins['id'];
        $ins['nombre_completo'] = trim($ins['nombre'] . ' ' . $ins['apellido']);
    }

    echo json_encode([
        'success' => true,
        'instructores' => $instructores
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al obtener instructores: ' . $e->getMessage()
    ]);
}
?>