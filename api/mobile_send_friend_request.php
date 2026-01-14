<?php
/**
 * Enviar solicitud de chat / amistad a otro usuario
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
require_once __DIR__ . '/../database/helpers/push_notification_helper.php';

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
    $deUsuarioId = $_SESSION['usuario_id'] ?? null;

    $input = json_decode(file_get_contents('php://input'), true);
    if (!is_array($input)) {
        $input = $_POST;
    }

    $paraUsuarioId = isset($input['para_usuario_id']) ? (int)$input['para_usuario_id'] : 0;

    if ($paraUsuarioId <= 0 || $paraUsuarioId === (int)$deUsuarioId) {
        echo json_encode([
            'success' => false,
            'message' => 'Usuario destinatario inválido',
        ]);
        exit;
    }

    // Verificar que el usuario destino exista y obtener sus datos
    $stmtUser = $db->prepare("SELECT id, nombre, apellido FROM usuarios WHERE id = :id AND estado != 'suspendido'");
    $stmtUser->execute([':id' => $paraUsuarioId]);
    $user = $stmtUser->fetch(PDO::FETCH_ASSOC);
    if (!$user) {
        echo json_encode([
            'success' => false,
            'message' => 'El usuario no existe o está suspendido',
        ]);
        exit;
    }
    
    // Obtener datos del usuario que envía la solicitud (para la notificación)
    $stmtRemitente = $db->prepare("SELECT nombre, apellido, foto FROM usuarios WHERE id = :id");
    $stmtRemitente->execute([':id' => $deUsuarioId]);
    $remitente = $stmtRemitente->fetch(PDO::FETCH_ASSOC);

    // Verificar si ya existe una solicitud
    $stmtReq = $db->prepare("
        SELECT id, estado 
        FROM friend_requests 
        WHERE de_usuario_id = :de AND para_usuario_id = :para
    ");
    $stmtReq->execute([
        ':de' => $deUsuarioId,
        ':para' => $paraUsuarioId,
    ]);
    $req = $stmtReq->fetch(PDO::FETCH_ASSOC);

    if ($req && $req['estado'] === 'pendiente') {
        echo json_encode([
            'success' => false,
            'message' => 'Ya enviaste una solicitud pendiente a este usuario',
        ]);
        exit;
    }

    if ($req && $req['estado'] === 'aceptada') {
        echo json_encode([
            'success' => false,
            'message' => 'Ya tienes un chat activo con este usuario',
        ]);
        exit;
    }

    if ($req && $req['estado'] === 'rechazada') {
        // Reabrir solicitud
        $stmtUpdate = $db->prepare("
            UPDATE friend_requests 
            SET estado = 'pendiente', creado_en = NOW(), respondido_en = NULL 
            WHERE id = :id
        ");
        $stmtUpdate->execute([':id' => $req['id']]);
        $requestId = (int)$req['id'];
    } else {
        // Crear nueva solicitud
        $stmtIns = $db->prepare("
            INSERT INTO friend_requests (de_usuario_id, para_usuario_id, estado, creado_en)
            VALUES (:de, :para, 'pendiente', NOW())
        ");
        $stmtIns->execute([
            ':de' => $deUsuarioId,
            ':para' => $paraUsuarioId,
        ]);
        $requestId = (int)$db->lastInsertId();
    }

    error_log("[mobile_send_friend_request] OK de={$deUsuarioId} para={$paraUsuarioId} request_id={$requestId} SID=" . session_id());

    // Crear notificación en la tabla de notificaciones
    if ($remitente) {
        $remitenteNombre = trim(($remitente['nombre'] ?? '') . ' ' . ($remitente['apellido'] ?? 'Usuario'));
        $titulo = "$remitenteNombre";
        $mensaje = "Te envió una solicitud de amistad";
        
        // Verificar si ya existe una notificación similar hoy para evitar duplicados
        $stmtCheckNotif = $db->prepare("
            SELECT id FROM notificaciones 
            WHERE usuario_id = :usuario_id 
            AND titulo = :titulo 
            AND mensaje = :mensaje
            AND DATE(fecha) = CURDATE()
        ");
        $stmtCheckNotif->execute([
            ':usuario_id' => $paraUsuarioId,
            ':titulo' => $titulo,
            ':mensaje' => $mensaje
        ]);
        
        if (!$stmtCheckNotif->fetch()) {
            $stmtNotif = $db->prepare("
                INSERT INTO notificaciones (usuario_id, titulo, mensaje, tipo, leida, fecha)
                VALUES (:usuario_id, :titulo, :mensaje, 'info', 0, NOW())
            ");
            $stmtNotif->execute([
                ':usuario_id' => $paraUsuarioId,
                ':titulo' => $titulo,
                ':mensaje' => $mensaje
            ]);
            error_log("[mobile_send_friend_request] ✅ Notificación creada en BD - usuario_id={$paraUsuarioId}");
        }
    }

    // Enviar notificación push al usuario que recibe la solicitud
    try {
        // Solo enviar notificación si es una solicitud nueva o reabierta
        if ($requestId > 0) {
            // Obtener tokens FCM del destinatario
            $tokens = getFCMTokensForUser($db, $paraUsuarioId);
            
            if (!empty($tokens) && $remitente) {
                $remitenteNombre = trim(($remitente['nombre'] ?? '') . ' ' . ($remitente['apellido'] ?? 'Usuario'));
                
                // Obtener foto del remitente
                $fotoRemitente = null;
                if (!empty($remitente['foto'])) {
                    $siteUrl = getSiteUrl();
                    $fotoRemitente = $siteUrl . 'uploads/usuarios/' . $remitente['foto'];
                }
                
                $titulo = "$remitenteNombre";
                $body = "Te envió una solicitud";
                
                // Datos adicionales para la app
                $data = [
                    'type' => 'friend_request',
                    'request_id' => (string)$requestId,
                    'remitente_id' => (string)$deUsuarioId,
                    'remitente_nombre' => $remitenteNombre
                ];
                
                // Agregar foto si existe
                if ($fotoRemitente) {
                    $data['remitente_foto'] = $fotoRemitente;
                }
                
                // Enviar notificaciones push con imagen del remitente
                error_log("[mobile_send_friend_request] Intentando enviar push notification a usuario={$paraUsuarioId} con " . count($tokens) . " tokens");
                $pushResult = sendPushNotificationToMultiple($tokens, $titulo, $body, $data, $fotoRemitente);
                
                if ($pushResult['success']) {
                    error_log("[mobile_send_friend_request] ✅ Push notification enviada: {$pushResult['sent_count']} exitosas, {$pushResult['failed_count']} fallidas - usuario={$paraUsuarioId} request_id={$requestId}");
                } else {
                    error_log("[mobile_send_friend_request] ❌ Error al enviar push notification: " . $pushResult['message']);
                    if (!empty($pushResult['errors'])) {
                        error_log("[mobile_send_friend_request] Errores detallados: " . json_encode($pushResult['errors']));
                    }
                }
            }
        }
    } catch (Exception $e) {
        // No fallar el envío de la solicitud si hay error en las notificaciones
        error_log("[mobile_send_friend_request] Error al enviar notificación push: " . $e->getMessage());
    }

    echo json_encode([
        'success' => true,
        'message' => 'Solicitud enviada correctamente',
        'request_id' => $requestId,
    ]);
} catch (Exception $e) {
    error_log("[mobile_send_friend_request] Error: " . $e->getMessage() . " SID=" . session_id());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al enviar solicitud: ' . $e->getMessage(),
    ]);
}

