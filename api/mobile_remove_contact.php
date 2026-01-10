<?php
/**
 * Eliminar un contacto (terminar amistad)
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

    if ($contactoId <= 0) {
        echo json_encode([
            'success' => false,
            'message' => 'Contacto inválido',
        ]);
        exit;
    }

    // Eliminar la relación de amistad
    $stmt = $db->prepare("
        DELETE FROM friend_requests 
        WHERE estado = 'aceptada' 
          AND (
              (de_usuario_id = :usuario_id AND para_usuario_id = :contacto_id)
              OR (de_usuario_id = :contacto_id AND para_usuario_id = :usuario_id)
          )
    ");
    $stmt->execute([
        ':usuario_id' => $usuarioId,
        ':contacto_id' => $contactoId,
    ]);

    if ($stmt->rowCount() > 0) {
        echo json_encode([
            'success' => true,
            'message' => 'Contacto eliminado correctamente',
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'No se encontró el contacto',
        ]);
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al eliminar contacto: ' . $e->getMessage(),
    ]);
}
