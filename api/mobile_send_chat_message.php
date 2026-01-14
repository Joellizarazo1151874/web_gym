<?php
/**
 * Enviar mensaje a un chat
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
    $usuarioId = $_SESSION['usuario_id'] ?? null;

    $input = json_decode(file_get_contents('php://input'), true);
    if (!is_array($input)) {
        $input = $_POST;
    }

    $chatId = isset($input['chat_id']) ? (int)$input['chat_id'] : 0;
    $mensaje = trim($input['mensaje'] ?? '');
     $imagenUrl = isset($input['imagen_url']) ? trim($input['imagen_url']) : null;

    if ($chatId <= 0 || ($mensaje === '' && $imagenUrl === null)) {
        echo json_encode([
            'success' => false,
            'message' => 'Datos incompletos',
        ]);
        exit;
    }

    // Verificar participación
    $stmtCheck = $db->prepare("
        SELECT 1 FROM chat_participantes 
        WHERE chat_id = :chat_id AND usuario_id = :usuario_id
    ");
    $stmtCheck->execute([
        ':chat_id' => $chatId,
        ':usuario_id' => $usuarioId,
    ]);
    if (!$stmtCheck->fetch()) {
        http_response_code(403);
        echo json_encode([
            'success' => false,
            'message' => 'No tienes acceso a este chat',
        ]);
        exit;
    }

    $stmt = $db->prepare("
        INSERT INTO chat_mensajes (chat_id, remitente_id, mensaje, imagen_url, creado_en, leido)
        VALUES (:chat_id, :remitente_id, :mensaje, :imagen_url, NOW(), 0)
    ");
    $stmt->execute([
        ':chat_id' => $chatId,
        ':remitente_id' => $usuarioId,
        ':mensaje' => $mensaje,
        ':imagen_url' => $imagenUrl !== '' ? $imagenUrl : null,
    ]);

    $mensajeId = (int)$db->lastInsertId();

    // Verificar si hay más de 200 mensajes en el chat
    $stmtCount = $db->prepare("SELECT COUNT(*) as total FROM chat_mensajes WHERE chat_id = :chat_id");
    $stmtCount->execute([':chat_id' => $chatId]);
    $totalMensajes = $stmtCount->fetch(PDO::FETCH_ASSOC)['total'];

    $maxMensajes = 200; // Límite máximo de mensajes por chat

    if ($totalMensajes > $maxMensajes) {
        // Obtener el mensaje más antiguo
        $stmtOldest = $db->prepare("
            SELECT id, imagen_url 
            FROM chat_mensajes 
            WHERE chat_id = :chat_id 
            ORDER BY creado_en ASC 
            LIMIT 1
        ");
        $stmtOldest->execute([':chat_id' => $chatId]);
        $oldestMsg = $stmtOldest->fetch(PDO::FETCH_ASSOC);

        if ($oldestMsg) {
            // Eliminar el mensaje más antiguo
            $stmtDeleteOldest = $db->prepare("DELETE FROM chat_mensajes WHERE id = :id");
            $stmtDeleteOldest->execute([':id' => $oldestMsg['id']]);

            // Eliminar imagen asociada si existe
            if (!empty($oldestMsg['imagen_url'])) {
                $imagePath = str_replace(getSiteUrl(), __DIR__ . '/../', $oldestMsg['imagen_url']);
                if (file_exists($imagePath)) {
                    unlink($imagePath);
                }
            }
        }
    }

    $stmtMsg = $db->prepare("
        SELECT 
            m.id,
            m.chat_id,
            m.remitente_id,
            m.mensaje,
            m.imagen_url,
            m.creado_en,
            m.leido,
            u.nombre,
            u.apellido,
            u.foto
        FROM chat_mensajes m
        INNER JOIN usuarios u ON u.id = m.remitente_id
        WHERE m.id = :id
    ");
    $stmtMsg->execute([':id' => $mensajeId]);
    $msg = $stmtMsg->fetch(PDO::FETCH_ASSOC);

    if ($msg) {
        $msg['leido'] = (bool)$msg['leido'];
        $msg['remitente_nombre'] = trim(($msg['nombre'] ?? '') . ' ' . ($msg['apellido'] ?? ''));
    }

    // Enviar notificación push al destinatario (solo para chats privados)
    try {
        // Verificar si es un chat privado (2 participantes)
        $stmtChatInfo = $db->prepare("
            SELECT 
                c.es_grupal,
                COUNT(cp.usuario_id) as total_participantes
            FROM chats c
            INNER JOIN chat_participantes cp ON cp.chat_id = c.id
            WHERE c.id = :chat_id
            GROUP BY c.id, c.es_grupal
        ");
        $stmtChatInfo->execute([':chat_id' => $chatId]);
        $chatInfo = $stmtChatInfo->fetch(PDO::FETCH_ASSOC);
        
        // Solo enviar push si es chat privado (no grupal y solo 2 participantes)
        if ($chatInfo && !$chatInfo['es_grupal'] && $chatInfo['total_participantes'] == 2) {
            // Obtener el otro participante (destinatario)
            $stmtDestinatario = $db->prepare("
                SELECT usuario_id 
                FROM chat_participantes 
                WHERE chat_id = :chat_id AND usuario_id != :remitente_id
                LIMIT 1
            ");
            $stmtDestinatario->execute([
                ':chat_id' => $chatId,
                ':remitente_id' => $usuarioId
            ]);
            $destinatario = $stmtDestinatario->fetch(PDO::FETCH_ASSOC);
            
            if ($destinatario) {
                $destinatarioId = $destinatario['usuario_id'];
                
                // Obtener tokens FCM del destinatario
                $tokens = getFCMTokensForUser($db, $destinatarioId);
                
                if (!empty($tokens)) {
                    $remitenteNombre = trim(($msg['nombre'] ?? '') . ' ' . ($msg['apellido'] ?? 'Usuario'));
                    
                    // Obtener foto del remitente
                    $fotoRemitente = null;
                    if (!empty($msg['foto'])) {
                        $siteUrl = getSiteUrl();
                        $fotoRemitente = $siteUrl . 'uploads/usuarios/' . $msg['foto'];
                    }
                    
                    // Preparar contenido de la notificación
                    $mensajePreview = $mensaje;
                    if (mb_strlen($mensajePreview) > 80) {
                        $mensajePreview = mb_substr($mensajePreview, 0, 80) . '...';
                    }
                    
                    $titulo = "$remitenteNombre";
                    $body = $mensajePreview;
                    
                    // Si hay imagen, cambiar el mensaje
                    if ($imagenUrl) {
                        $body = "📸 Envió una imagen";
                    }
                    
                    // Datos adicionales para la app
                    $data = [
                        'type' => 'chat_message',
                        'chat_id' => (string)$chatId,
                        'mensaje_id' => (string)$mensajeId,
                        'remitente_id' => (string)$usuarioId,
                        'remitente_nombre' => $remitenteNombre
                    ];
                    
                    // Agregar foto si existe
                    if ($fotoRemitente) {
                        $data['remitente_foto'] = $fotoRemitente;
                    }
                    
                    // Enviar notificaciones push con imagen del remitente
                    error_log("[mobile_send_chat_message] Intentando enviar push notification a usuario={$destinatarioId} con " . count($tokens) . " tokens");
                    $pushResult = sendPushNotificationToMultiple($tokens, $titulo, $body, $data, $fotoRemitente);
                    
                    if ($pushResult['success']) {
                        error_log("[mobile_send_chat_message] ✅ Push notification enviada: {$pushResult['sent_count']} exitosas, {$pushResult['failed_count']} fallidas - usuario={$destinatarioId} chat={$chatId}");
                    } else {
                        error_log("[mobile_send_chat_message] ❌ Error al enviar push notification: " . $pushResult['message']);
                        if (!empty($pushResult['errors'])) {
                            error_log("[mobile_send_chat_message] Errores detallados: " . json_encode($pushResult['errors']));
                        }
                    }
                }
            }
        }
    } catch (Exception $e) {
        // No fallar el envío del mensaje si hay error en las notificaciones
        error_log("[mobile_send_chat_message] Error al enviar notificación push: " . $e->getMessage());
    }

    echo json_encode([
        'success' => true,
        'message' => 'Mensaje enviado correctamente',
        'data' => $msg, // El mensaje enviado
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al enviar mensaje: ' . $e->getMessage(),
    ]);
}

