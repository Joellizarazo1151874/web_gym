<?php
/**
 * Obtener lista de contactos aceptados (amigos)
 * Similar a la lista de contactos de WhatsApp
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
    error_log("[mobile_get_contacts] 401 No autenticado. SID=" . session_id() . " SESSION=" . json_encode($_SESSION));
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'message' => 'No autenticado',
    ]);
    exit;
}

try {
    $db = getDB();
    $usuarioId = $_SESSION['usuario_id'] ?? null;

    // Obtener contactos donde el usuario actual envió la solicitud y fue aceptada
    // Evitar placeholders nombrados repetidos: usar posicionales
    $sql = "
        SELECT 
            fr.id as solicitud_id,
            para_usuario_id as contacto_id,
            u.nombre,
            u.apellido,
            u.email,
            fr.apodo as apodo_contacto,
            fr.creado_en as amigos_desde
        FROM friend_requests fr
        INNER JOIN usuarios u ON u.id = fr.para_usuario_id
        WHERE fr.de_usuario_id = ? 
          AND fr.estado = 'aceptada'
          AND u.estado != 'suspendido'
        
        UNION
        
        SELECT 
            fr.id as solicitud_id,
            de_usuario_id as contacto_id,
            u.nombre,
            u.apellido,
            u.email,
            fr.apodo_inverso as apodo_contacto,
            fr.creado_en as amigos_desde
        FROM friend_requests fr
        INNER JOIN usuarios u ON u.id = fr.de_usuario_id
        WHERE fr.para_usuario_id = ? 
          AND fr.estado = 'aceptada'
          AND u.estado != 'suspendido'
        
        ORDER BY nombre, apellido
    ";

    $stmt = $db->prepare($sql);
    $stmt->execute([$usuarioId, $usuarioId]);
    $contactos = $stmt->fetchAll(PDO::FETCH_ASSOC);

    foreach ($contactos as &$contacto) {
        // Si tiene apodo, usarlo; si no, usar nombre completo
        $nombreCompleto = trim(($contacto['nombre'] ?? '') . ' ' . ($contacto['apellido'] ?? ''));
        $contacto['nombre_mostrar'] = !empty($contacto['apodo_contacto']) 
            ? $contacto['apodo_contacto'] 
            : $nombreCompleto;
        $contacto['nombre_real'] = $nombreCompleto;
    }

    echo json_encode([
        'success' => true,
        'contactos' => $contactos,
        'total' => count($contactos),
    ]);
} catch (Exception $e) {
    error_log("[mobile_get_contacts] Error: " . $e->getMessage() . " SID=" . session_id() . " SESSION=" . json_encode($_SESSION));
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al obtener contactos',
    ]);
}
