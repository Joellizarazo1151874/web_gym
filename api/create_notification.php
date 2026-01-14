<?php
/**
 * Crear nueva notificación
 * Endpoint API para crear notificaciones (solo admin/entrenador)
 */

session_start();
header('Content-Type: application/json');
require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/auth.php';
require_once __DIR__ . '/../database/helpers/push_notification_helper.php';

// Solo permitir POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Método no permitido'
    ]);
    exit;
}

// Verificar autenticación
$auth = new Auth();
if (!$auth->isAuthenticated()) {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'message' => 'No autenticado'
    ]);
    exit;
}

// Verificar rol (solo admin)
if (!$auth->hasRole(['admin'])) {
    http_response_code(403);
    echo json_encode([
        'success' => false,
        'message' => 'No autorizado. Solo los administradores pueden crear notificaciones.'
    ]);
    exit;
}

try {
    $db = getDB();
    $data = json_decode(file_get_contents('php://input'), true);
    
    // Validar datos requeridos
    $titulo = trim($data['titulo'] ?? '');
    $mensaje = trim($data['mensaje'] ?? '');
    $tipo = $data['tipo'] ?? 'info';
    $usuario_id = isset($data['usuario_id']) && $data['usuario_id'] !== '' ? (int)$data['usuario_id'] : null;
    
    // Validaciones
    if (empty($titulo)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'El título es requerido'
        ]);
        exit;
    }
    
    if (empty($mensaje)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'El mensaje es requerido'
        ]);
        exit;
    }
    
    // Validar tipo
    $tipos_validos = ['info', 'success', 'warning', 'error', 'promocion'];
    if (!in_array($tipo, $tipos_validos)) {
        $tipo = 'info';
    }
    
    // Si se especifica un usuario_id, verificar que existe
    if ($usuario_id !== null) {
        $stmt = $db->prepare("SELECT id FROM usuarios WHERE id = :id");
        $stmt->execute([':id' => $usuario_id]);
        if (!$stmt->fetch()) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'Usuario no encontrado'
            ]);
            exit;
        }
    }
    
    // Insertar notificación
    $stmt = $db->prepare("
        INSERT INTO notificaciones (usuario_id, titulo, mensaje, tipo, leida, fecha)
        VALUES (:usuario_id, :titulo, :mensaje, :tipo, 0, NOW())
    ");
    
    $stmt->execute([
        ':usuario_id' => $usuario_id,
        ':titulo' => $titulo,
        ':mensaje' => $mensaje,
        ':tipo' => $tipo
    ]);
    
    $notificacion_id = $db->lastInsertId();
    
    // Enviar notificación push
    try {
        $tokens = [];
        $fotoUsuario = null;
        
        if ($usuario_id !== null) {
            // Notificación para un usuario específico
            $tokens = getFCMTokensForUser($db, $usuario_id);
            
            // Obtener foto del usuario (si tiene)
            $stmtFoto = $db->prepare("SELECT foto FROM usuarios WHERE id = :id");
            $stmtFoto->execute([':id' => $usuario_id]);
            $fotoData = $stmtFoto->fetch(PDO::FETCH_ASSOC);
            if ($fotoData && !empty($fotoData['foto'])) {
                $siteUrl = getSiteUrl();
                $fotoUsuario = $siteUrl . 'uploads/usuarios/' . $fotoData['foto'];
            }
        } else {
            // Notificación global - enviar a todos los usuarios activos
            $tokens = getAllFCMTokensExceptUser($db, 0); // 0 = no excluir a nadie (obtener todos)
            
            // Para notificaciones globales, usar el logo de la empresa
            $siteUrl = getSiteUrl();
            // Intentar obtener logo de la empresa desde configuración
            $stmtLogo = $db->prepare("SELECT valor FROM configuracion WHERE clave = 'logo_empresa'");
            $stmtLogo->execute();
            $logoData = $stmtLogo->fetch(PDO::FETCH_ASSOC);
            if ($logoData && !empty($logoData['valor'])) {
                $fotoUsuario = $siteUrl . 'uploads/' . $logoData['valor'];
            } else {
                // Si no hay logo configurado, usar un logo por defecto o null
                $fotoUsuario = null;
            }
        }
        
        if (!empty($tokens)) {
            $data = [
                'type' => 'system_notification',
                'notification_type' => $tipo,
                'notification_id' => (string)$notificacion_id,
            ];
            
            // Agregar usuario_id si es específico
            if ($usuario_id !== null) {
                $data['usuario_id'] = (string)$usuario_id;
            }
            
            $pushResult = sendPushNotificationToMultiple($tokens, $titulo, $mensaje, $data, $fotoUsuario);
            
            if ($pushResult['success']) {
                $destinatarios = $usuario_id !== null ? "usuario_id={$usuario_id}" : "todos los usuarios";
                error_log("[create_notification] ✅ Push notification enviada - {$destinatarios} notification_id={$notificacion_id} sent={$pushResult['sent_count']} failed={$pushResult['failed_count']}");
            } else {
                error_log("[create_notification] ❌ Error al enviar push notification: " . $pushResult['message']);
            }
        } else {
            $destinatarios = $usuario_id !== null ? "usuario_id={$usuario_id}" : "todos los usuarios";
            error_log("[create_notification] ⚠️ No hay tokens FCM para enviar push notification - {$destinatarios}");
        }
    } catch (Exception $e) {
        error_log("[create_notification] ❌ Error al enviar push notification: " . $e->getMessage());
        // No fallar la creación de la notificación si hay error en push
    }
    
    echo json_encode([
        'success' => true,
        'message' => 'Notificación creada exitosamente',
        'notificacion_id' => $notificacion_id
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al crear notificación: ' . $e->getMessage()
    ]);
}

