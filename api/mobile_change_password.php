<?php
/**
 * Cambiar Contraseña - Usuario Logueado
 * Permite cambiar la contraseña conociendo la actual
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

// Restaurar sesión
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
    $currentUser = $auth->getCurrentUser();
    $userId = $currentUser['id'];

    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        throw new Exception('Método no permitido');
    }

    $input = file_get_contents('php://input');
    $data = json_decode($input, true);

    // Fallback para form-data
    if (json_last_error() !== JSON_ERROR_NONE || $data === null) {
        $data = $_POST;
    }

    $currentPassword = $data['current_password'] ?? '';
    $newPassword = $data['new_password'] ?? '';
    $confirmPassword = $data['confirm_password'] ?? '';

    // Validaciones
    if (empty($currentPassword) || empty($newPassword) || empty($confirmPassword)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Todos los campos son obligatorios'
        ]);
        exit;
    }

    // 1. Verificar contraseña actual
    // Obtenemos el hash actual de la base de datos
    $stmt = $db->prepare("SELECT password FROM usuarios WHERE id = :id");
    $stmt->execute([':id' => $userId]);
    $storedHash = $stmt->fetchColumn();

    if (!$storedHash || !password_verify($currentPassword, $storedHash)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'La contraseña actual es incorrecta'
        ]);
        exit;
    }

    // 2. Validar nueva contraseña (misma lógica que reset_password)
    if (strlen($newPassword) < 8) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'La nueva contraseña debe tener al menos 8 caracteres'
        ]);
        exit;
    }

    if ($newPassword !== $confirmPassword) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Las nuevas contraseñas no coinciden'
        ]);
        exit;
    }

    // 3. Actualizar contraseña
    $newHash = password_hash($newPassword, PASSWORD_DEFAULT);

    $stmt = $db->prepare("UPDATE usuarios SET password = :password WHERE id = :id");
    $result = $stmt->execute([
        ':password' => $newHash,
        ':id' => $userId
    ]);

    if ($result) {
        echo json_encode([
            'success' => true,
            'message' => 'Contraseña actualizada correctamente'
        ]);
    } else {
        throw new Exception('Error al actualizar la base de datos');
    }

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al cambiar la contraseña: ' . $e->getMessage()
    ]);
}
