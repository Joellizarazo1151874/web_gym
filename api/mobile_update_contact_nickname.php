<?php
/**
 * Actualizar apodo de un contacto
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
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
        'message' => 'No autenticado',
    ]);
    exit;
}

try {
    $db = getDB();
    $usuarioId = $_SESSION['usuario_id'] ?? null;

    $input = json_decode(file_get_contents('php://input'), true);
    if (!is_array($input)) {
        $input = $_POST;
    }

    $contactoId = isset($input['contacto_id']) ? (int)$input['contacto_id'] : 0;
    $apodo = isset($input['apodo']) ? trim($input['apodo']) : null;

    if ($contactoId <= 0) {
        echo json_encode([
            'success' => false,
            'message' => 'Contacto inválido',
        ]);
        exit;
    }

    // Verificar que existe una amistad aceptada
    $stmtCheck = $db->prepare("
        SELECT id, de_usuario_id, para_usuario_id 
        FROM friend_requests 
        WHERE estado = 'aceptada' 
          AND (
              (de_usuario_id = :usuario_id AND para_usuario_id = :contacto_id)
              OR (de_usuario_id = :contacto_id AND para_usuario_id = :usuario_id)
          )
    ");
    $stmtCheck->execute([
        ':usuario_id' => $usuarioId,
        ':contacto_id' => $contactoId,
    ]);
    $amistad = $stmtCheck->fetch(PDO::FETCH_ASSOC);

    if (!$amistad) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'No existe una amistad con este usuario',
        ]);
        exit;
    }

    // Determinar qué campo actualizar
    if ($amistad['de_usuario_id'] == $usuarioId) {
        // Usuario actual envió la solicitud, actualizar 'apodo'
        $campo = 'apodo';
    } else {
        // Usuario actual recibió la solicitud, actualizar 'apodo_inverso'
        $campo = 'apodo_inverso';
    }

    // Actualizar apodo
    $stmt = $db->prepare("
        UPDATE friend_requests 
        SET $campo = :apodo 
        WHERE id = :id
    ");
    $stmt->execute([
        ':apodo' => $apodo !== '' ? $apodo : null,
        ':id' => $amistad['id'],
    ]);

    echo json_encode([
        'success' => true,
        'message' => $apodo 
            ? 'Apodo actualizado correctamente' 
            : 'Apodo eliminado correctamente',
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al actualizar apodo: ' . $e->getMessage(),
    ]);
}
