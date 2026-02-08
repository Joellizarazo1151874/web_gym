<?php
/**
 * Eliminar notificación
 * Endpoint API para eliminar una notificación específica o todas las del usuario
 */

// Headers para CORS y JSON
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept, Cookie, X-Session-ID');
header('Access-Control-Allow-Credentials: true');

// Manejar preflight OPTIONS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Incluir dependencias
require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/auth.php';

// Restaurar sesión
restoreSessionFromHeader();
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

// Verificar autenticación
$auth = new Auth();
if (!$auth->isAuthenticated()) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'No autenticado']);
    exit;
}

try {
    $db = getDB();
    $usuario_id = $_SESSION['usuario_id'];

    // Leer input
    $data = json_decode(file_get_contents('php://input'), true);
    $notification_id = isset($data['id']) ? (int) $data['id'] : null;
    $eliminar_todas = isset($data['eliminar_todas']) && $data['eliminar_todas'] === true;

    if ($eliminar_todas) {
        // 1. Eliminar todas las notificaciones específicas del usuario
        $stmt = $db->prepare("DELETE FROM notificaciones WHERE usuario_id = :usuario_id");
        $stmt->execute([':usuario_id' => $usuario_id]);

        // 2. Para las globales, registrarlas como eliminadas para este usuario
        $stmt_globales = $db->prepare("
            INSERT IGNORE INTO notificaciones_eliminadas (usuario_id, notificacion_id)
            SELECT :usuario_id, id FROM notificaciones WHERE usuario_id IS NULL
        ");
        $stmt_globales->execute([':usuario_id' => $usuario_id]);

        // 3. Limpiar registros de leídas si existen
        $stmt_leidas = $db->prepare("DELETE FROM notificaciones_leidas WHERE usuario_id = :usuario_id");
        $stmt_leidas->execute([':usuario_id' => $usuario_id]);

        echo json_encode([
            'success' => true,
            'message' => 'Todas las notificaciones han sido eliminadas'
        ]);
    } elseif ($notification_id) {
        // Verificar tipo de notificación (si es específica del usuario o global)
        $stmt_type = $db->prepare("SELECT usuario_id FROM notificaciones WHERE id = :id");
        $stmt_type->execute([':id' => $notification_id]);
        $notif = $stmt_type->fetch(PDO::FETCH_ASSOC);

        if ($notif) {
            if ($notif['usuario_id'] !== null) {
                // Es específica -> verificar que le pertenece antes de borrarla
                if ($notif['usuario_id'] == $usuario_id) {
                    $stmt = $db->prepare("DELETE FROM notificaciones WHERE id = :id");
                    $stmt->execute([':id' => $notification_id]);
                }
            } else {
                // Es GLOBAL -> no podemos borrarla para todos, así que la ocultamos para este usuario
                $stmt = $db->prepare("INSERT IGNORE INTO notificaciones_eliminadas (usuario_id, notificacion_id) VALUES (:usuario_id, :notific_id)");
                $stmt->execute([':usuario_id' => $usuario_id, ':notific_id' => $notification_id]);
            }
        }

        // Siempre eliminar el registro de leída si existe
        $stmt_leidas = $db->prepare("DELETE FROM notificaciones_leidas WHERE notificacion_id = :notif_id AND usuario_id = :user_id");
        $stmt_leidas->execute([':notif_id' => $notification_id, ':user_id' => $usuario_id]);

        echo json_encode([
            'success' => true,
            'message' => 'Notificación eliminada'
        ]);
    } else {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'ID de notificación no proporcionado']);
    }

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
}
