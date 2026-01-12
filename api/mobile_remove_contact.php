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

    if (!$usuarioId) {
        http_response_code(401);
        echo json_encode([
            'success' => false,
            'message' => 'Usuario no autenticado',
        ]);
        exit;
    }

    $input = json_decode(file_get_contents('php://input'), true);
    if (!is_array($input)) {
        $input = $_POST;
    }

    $contactoId = isset($input['contacto_id']) ? (int)$input['contacto_id'] : 0;

    if ($contactoId <= 0) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Contacto inválido',
        ]);
        exit;
    }

    // Verificar que existe una relación de amistad aceptada
    $stmtCheck = $db->prepare("
        SELECT id 
        FROM friend_requests 
        WHERE estado = 'aceptada' 
          AND (
              (de_usuario_id = ? AND para_usuario_id = ?)
              OR (de_usuario_id = ? AND para_usuario_id = ?)
          )
        LIMIT 1
    ");
    $stmtCheck->execute([$usuarioId, $contactoId, $contactoId, $usuarioId]);
    $existe = $stmtCheck->fetch(PDO::FETCH_ASSOC);

    if (!$existe) {
        echo json_encode([
            'success' => false,
            'message' => 'No se encontró el contacto en tu lista',
        ]);
        exit;
    }

    // Eliminar la relación de amistad
    $stmt = $db->prepare("
        DELETE FROM friend_requests 
        WHERE estado = 'aceptada' 
          AND (
              (de_usuario_id = ? AND para_usuario_id = ?)
              OR (de_usuario_id = ? AND para_usuario_id = ?)
          )
    ");
    $stmt->execute([$usuarioId, $contactoId, $contactoId, $usuarioId]);

    if ($stmt->rowCount() > 0) {
        error_log("[mobile_remove_contact] OK usuario={$usuarioId} contacto={$contactoId} SID=" . session_id());
        echo json_encode([
            'success' => true,
            'message' => 'Contacto eliminado correctamente',
        ]);
    } else {
        error_log("[mobile_remove_contact] No se eliminó ningún registro usuario={$usuarioId} contacto={$contactoId} SID=" . session_id());
        echo json_encode([
            'success' => false,
            'message' => 'No se pudo eliminar el contacto',
        ]);
    }
} catch (Exception $e) {
    error_log("[mobile_remove_contact] Error: " . $e->getMessage() . " Trace: " . $e->getTraceAsString() . " SID=" . session_id());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al eliminar contacto: ' . $e->getMessage(),
    ]);
}
