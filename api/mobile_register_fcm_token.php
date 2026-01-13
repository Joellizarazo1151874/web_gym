<?php
/**
 * Registrar o actualizar token FCM de un dispositivo móvil
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

    $token = isset($input['token']) ? trim($input['token']) : '';
    $plataforma = isset($input['plataforma']) ? trim($input['plataforma']) : 'android';

    if (empty($token)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Token FCM requerido',
        ]);
        exit;
    }

    // Validar plataforma
    if (!in_array($plataforma, ['android', 'ios'])) {
        $plataforma = 'android';
    }

    // Verificar si el token ya existe
    $stmtCheck = $db->prepare("SELECT id, usuario_id FROM fcm_tokens WHERE token = :token");
    $stmtCheck->execute([':token' => $token]);
    $existing = $stmtCheck->fetch(PDO::FETCH_ASSOC);

    if ($existing) {
        // Si el token existe pero pertenece a otro usuario, actualizarlo
        if ($existing['usuario_id'] != $usuarioId) {
            $stmtUpdate = $db->prepare("
                UPDATE fcm_tokens 
                SET usuario_id = :usuario_id, plataforma = :plataforma, activo = 1, updated_at = NOW()
                WHERE id = :id
            ");
            $stmtUpdate->execute([
                ':usuario_id' => $usuarioId,
                ':plataforma' => $plataforma,
                ':id' => $existing['id']
            ]);
        } else {
            // Si ya pertenece al usuario, solo actualizar plataforma y activar
            $stmtUpdate = $db->prepare("
                UPDATE fcm_tokens 
                SET plataforma = :plataforma, activo = 1, updated_at = NOW()
                WHERE id = :id
            ");
            $stmtUpdate->execute([
                ':plataforma' => $plataforma,
                ':id' => $existing['id']
            ]);
        }
    } else {
        // Insertar nuevo token
        $stmtInsert = $db->prepare("
            INSERT INTO fcm_tokens (usuario_id, token, plataforma, activo)
            VALUES (:usuario_id, :token, :plataforma, 1)
        ");
        $stmtInsert->execute([
            ':usuario_id' => $usuarioId,
            ':token' => $token,
            ':plataforma' => $plataforma
        ]);
    }

    error_log("[mobile_register_fcm_token] Token registrado para usuario={$usuarioId} plataforma={$plataforma} SID=" . session_id());

    echo json_encode([
        'success' => true,
        'message' => 'Token FCM registrado correctamente',
    ]);
} catch (Exception $e) {
    error_log("[mobile_register_fcm_token] Error: " . $e->getMessage() . " Trace: " . $e->getTraceAsString() . " SID=" . session_id());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al registrar token: ' . $e->getMessage(),
    ]);
}
