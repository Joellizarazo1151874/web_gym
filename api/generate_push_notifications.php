<?php
/**
 * Generar Notificaciones Push Automáticas
 * Este script debe ejecutarse periódicamente (cron job) para generar notificaciones automáticas
 * 
 * Tipos de notificaciones:
 * - cumpleanos: Felicitar usuarios en su cumpleaños
 * - membresia_vencimiento: Recordar vencimiento de membresía
 * - membresia_vencida: Notificar membresía vencida
 * - inactividad: Recordar a usuarios inactivos
 */

// Configurar headers JSON
header('Content-Type: application/json; charset=utf-8');

// Manejar errores para que siempre devuelva JSON
set_error_handler(function($severity, $message, $file, $line) {
    throw new ErrorException($message, 0, $severity, $file, $line);
});

require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/../database/helpers/push_notification_helper.php';

try {
    $db = getDB();
    
    // Obtener configuraciones activas
    $stmt = $db->query("SELECT * FROM push_notifications_config WHERE activa = 1");
    $configs = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    $notificaciones_creadas = 0;
    
    foreach ($configs as $config) {
        // Verificar hora de envío (solo generar si es la hora correcta o si se ejecuta manualmente)
        $hora_actual = date('H:i');
        $hora_config = date('H:i', strtotime($config['hora_envio']));
        
        // Si se ejecuta manualmente (con parámetro force), ignorar la hora
        $data = [];
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            $data = json_decode(file_get_contents('php://input'), true) ?? [];
        }
        $es_manual = isset($_GET['force']) || isset($data['force']) || php_sapi_name() === 'cli';
        
        // Solo verificar hora si no es ejecución manual
        if (!$es_manual && $hora_actual !== $hora_config) {
            continue; // Saltar si no es la hora correcta
        }
        
        switch ($config['tipo']) {
            case 'cumpleanos':
                $notificaciones_creadas += generarNotificacionesCumpleanos($db, $config);
                break;
                
            case 'membresia_vencimiento':
                $notificaciones_creadas += generarNotificacionesVencimiento($db, $config);
                break;
                
            case 'membresia_vencida':
                $notificaciones_creadas += generarNotificacionesVencida($db, $config);
                break;
                
            case 'inactividad':
                $notificaciones_creadas += generarNotificacionesInactividad($db, $config);
                break;
                
            default:
                // Para tipos personalizados, intentar generar usando función genérica
                $notificaciones_creadas += generarNotificacionPersonalizada($db, $config);
                break;
        }
    }
    
    echo json_encode([
        'success' => true,
        'message' => "Se generaron $notificaciones_creadas notificaciones automáticas",
        'notificaciones_creadas' => $notificaciones_creadas
    ], JSON_UNESCAPED_UNICODE);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al generar notificaciones: ' . $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

/**
 * Generar notificaciones de cumpleaños
 */
function generarNotificacionesCumpleanos($db, $config) {
    $count = 0;
    $hoy = date('Y-m-d');
    
    // Buscar usuarios que cumplen años hoy
    $stmt = $db->prepare("
        SELECT id, nombre, apellido, fecha_nacimiento 
        FROM usuarios 
        WHERE estado = 'activo' 
        AND fecha_nacimiento IS NOT NULL
        AND DATE_FORMAT(fecha_nacimiento, '%m-%d') = DATE_FORMAT(CURDATE(), '%m-%d')
        AND id NOT IN (
            SELECT usuario_id 
            FROM notificaciones 
            WHERE tipo = 'promocion'
            AND DATE(fecha) = CURDATE()
            AND titulo LIKE '%Cumpleaños%'
            AND usuario_id IS NOT NULL
        )
    ");
    $stmt->execute();
    $usuarios = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    foreach ($usuarios as $usuario) {
        $titulo = str_replace('{nombre}', $usuario['nombre'], $config['titulo']);
        $mensaje = str_replace('{nombre}', $usuario['nombre'] . ' ' . $usuario['apellido'], $config['mensaje']);
        
        // Verificar si ya existe una notificación similar hoy
        $stmt_check = $db->prepare("
            SELECT id FROM notificaciones 
            WHERE usuario_id = :usuario_id 
            AND titulo = :titulo 
            AND DATE(fecha) = CURDATE()
        ");
        $stmt_check->execute([
            ':usuario_id' => $usuario['id'],
            ':titulo' => $titulo
        ]);
        
        if (!$stmt_check->fetch()) {
            $stmt_insert = $db->prepare("
                INSERT INTO notificaciones (usuario_id, titulo, mensaje, tipo, leida, fecha)
                VALUES (:usuario_id, :titulo, :mensaje, 'promocion', 0, NOW())
            ");
            $stmt_insert->execute([
                ':usuario_id' => $usuario['id'],
                ':titulo' => $titulo,
                ':mensaje' => $mensaje
            ]);
            
            // Obtener el ID de la notificación insertada
            $notification_id = $db->lastInsertId();
            
            // Enviar notificación push
            try {
                $tokens = getFCMTokensForUser($db, $usuario['id']);
                if (!empty($tokens)) {
                    // Obtener foto del usuario (si tiene)
                    $fotoUsuario = null;
                    $stmtFoto = $db->prepare("SELECT foto FROM usuarios WHERE id = :id");
                    $stmtFoto->execute([':id' => $usuario['id']]);
                    $fotoData = $stmtFoto->fetch(PDO::FETCH_ASSOC);
                    if ($fotoData && !empty($fotoData['foto'])) {
                        $siteUrl = getSiteUrl();
                        $fotoUsuario = $siteUrl . 'uploads/usuarios/' . $fotoData['foto'];
                    }
                    
                    $data = [
                        'type' => 'system_notification',
                        'notification_type' => 'cumpleanos',
                        'notification_id' => (string)$notification_id,
                    ];
                    
                    sendPushNotificationToMultiple($tokens, $titulo, $mensaje, $data, $fotoUsuario);
                    error_log("[generate_push_notifications] ✅ Push notification enviada para cumpleaños - usuario_id={$usuario['id']}, notification_id={$notification_id}");
                }
            } catch (Exception $e) {
                error_log("[generate_push_notifications] ❌ Error al enviar push notification de cumpleaños: " . $e->getMessage());
            }
            
            $count++;
        }
    }
    
    return $count;
}

/**
 * Generar notificaciones de vencimiento de membresía
 */
function generarNotificacionesVencimiento($db, $config) {
    $count = 0;
    $dias_antes = (int)$config['dias_antes'];
    $fecha_limite = date('Y-m-d', strtotime("+$dias_antes days"));
    
    // Buscar membresías que vencen en X días
    $stmt = $db->prepare("
        SELECT m.id, m.usuario_id, m.fecha_fin, u.nombre, u.apellido
        FROM membresias m
        INNER JOIN usuarios u ON m.usuario_id = u.id
        WHERE m.estado = 'activa'
        AND u.estado = 'activo'
        AND DATE(m.fecha_fin) = :fecha_limite
        AND m.usuario_id NOT IN (
            SELECT usuario_id 
            FROM notificaciones 
            WHERE tipo = 'warning'
            AND DATE(fecha) = CURDATE()
            AND titulo LIKE '%membresía%vencer%'
            AND usuario_id IS NOT NULL
        )
    ");
    $stmt->execute([':fecha_limite' => $fecha_limite]);
    $membresias = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    foreach ($membresias as $membresia) {
        $dias_restantes = (strtotime($membresia['fecha_fin']) - time()) / 86400;
        $dias_restantes = max(0, floor($dias_restantes));
        
        $titulo = str_replace(['{nombre}', '{dias}'], [
            $membresia['nombre'],
            $dias_restantes
        ], $config['titulo']);
        
        $mensaje = str_replace(['{nombre}', '{dias}'], [
            $membresia['nombre'] . ' ' . $membresia['apellido'],
            $dias_restantes
        ], $config['mensaje']);
        
        $stmt_insert = $db->prepare("
            INSERT INTO notificaciones (usuario_id, titulo, mensaje, tipo, leida, fecha)
            VALUES (:usuario_id, :titulo, :mensaje, 'warning', 0, NOW())
        ");
        $stmt_insert->execute([
            ':usuario_id' => $membresia['usuario_id'],
            ':titulo' => $titulo,
            ':mensaje' => $mensaje
        ]);
        
        // Obtener el ID de la notificación insertada
        $notification_id = $db->lastInsertId();
        
        // Enviar notificación push
        try {
            $tokens = getFCMTokensForUser($db, $membresia['usuario_id']);
            if (!empty($tokens)) {
                // Obtener foto del usuario (si tiene)
                $fotoUsuario = null;
                $stmtFoto = $db->prepare("SELECT foto FROM usuarios WHERE id = :id");
                $stmtFoto->execute([':id' => $membresia['usuario_id']]);
                $fotoData = $stmtFoto->fetch(PDO::FETCH_ASSOC);
                if ($fotoData && !empty($fotoData['foto'])) {
                    $siteUrl = getSiteUrl();
                    $fotoUsuario = $siteUrl . 'uploads/usuarios/' . $fotoData['foto'];
                }
                
                $data = [
                    'type' => 'system_notification',
                    'notification_type' => 'membresia_vencimiento',
                    'notification_id' => (string)$notification_id,
                    'dias_restantes' => (string)$dias_restantes,
                ];
                
                sendPushNotificationToMultiple($tokens, $titulo, $mensaje, $data, $fotoUsuario);
                error_log("[generate_push_notifications] ✅ Push notification enviada para vencimiento - usuario_id={$membresia['usuario_id']}, notification_id={$notification_id}");
            }
        } catch (Exception $e) {
            error_log("[generate_push_notifications] ❌ Error al enviar push notification de vencimiento: " . $e->getMessage());
        }
        
        $count++;
    }
    
    return $count;
}

/**
 * Generar notificaciones de membresía vencida
 */
function generarNotificacionesVencida($db, $config) {
    $count = 0;
    
    // Buscar membresías vencidas recientemente (últimos 7 días)
    $stmt = $db->prepare("
        SELECT m.id, m.usuario_id, m.fecha_fin, u.nombre, u.apellido
        FROM membresias m
        INNER JOIN usuarios u ON m.usuario_id = u.id
        WHERE m.estado = 'activa'
        AND u.estado = 'activo'
        AND DATE(m.fecha_fin) < CURDATE()
        AND DATE(m.fecha_fin) >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
        AND m.usuario_id NOT IN (
            SELECT usuario_id 
            FROM notificaciones 
            WHERE tipo = 'error'
            AND DATE(fecha) = CURDATE()
            AND titulo LIKE '%membresía%vencido%'
            AND usuario_id IS NOT NULL
        )
    ");
    $stmt->execute();
    $membresias = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    foreach ($membresias as $membresia) {
        $titulo = str_replace('{nombre}', $membresia['nombre'], $config['titulo']);
        $mensaje = str_replace('{nombre}', $membresia['nombre'] . ' ' . $membresia['apellido'], $config['mensaje']);
        
        $stmt_insert = $db->prepare("
            INSERT INTO notificaciones (usuario_id, titulo, mensaje, tipo, leida, fecha)
            VALUES (:usuario_id, :titulo, :mensaje, 'error', 0, NOW())
        ");
        $stmt_insert->execute([
            ':usuario_id' => $membresia['usuario_id'],
            ':titulo' => $titulo,
            ':mensaje' => $mensaje
        ]);
        
        // Obtener el ID de la notificación insertada
        $notification_id = $db->lastInsertId();
        
        // Enviar notificación push
        try {
            $tokens = getFCMTokensForUser($db, $membresia['usuario_id']);
            if (!empty($tokens)) {
                // Obtener foto del usuario (si tiene)
                $fotoUsuario = null;
                $stmtFoto = $db->prepare("SELECT foto FROM usuarios WHERE id = :id");
                $stmtFoto->execute([':id' => $membresia['usuario_id']]);
                $fotoData = $stmtFoto->fetch(PDO::FETCH_ASSOC);
                if ($fotoData && !empty($fotoData['foto'])) {
                    $siteUrl = getSiteUrl();
                    $fotoUsuario = $siteUrl . 'uploads/usuarios/' . $fotoData['foto'];
                }
                
                $data = [
                    'type' => 'system_notification',
                    'notification_type' => 'membresia_vencida',
                    'notification_id' => (string)$notification_id,
                ];
                
                sendPushNotificationToMultiple($tokens, $titulo, $mensaje, $data, $fotoUsuario);
                error_log("[generate_push_notifications] ✅ Push notification enviada para membresía vencida - usuario_id={$membresia['usuario_id']}, notification_id={$notification_id}");
            }
        } catch (Exception $e) {
            error_log("[generate_push_notifications] ❌ Error al enviar push notification de membresía vencida: " . $e->getMessage());
        }
        
        $count++;
    }
    
    return $count;
}

/**
 * Generar notificaciones de inactividad
 */
function generarNotificacionesInactividad($db, $config) {
    $count = 0;
    $dias_inactividad = (int)$config['dias_inactividad'];
    $fecha_limite = date('Y-m-d', strtotime("-$dias_inactividad days"));
    
    // Buscar usuarios inactivos
    $stmt = $db->prepare("
        SELECT u.id, u.nombre, u.apellido,
               MAX(a.fecha_entrada) as ultima_asistencia,
               DATEDIFF(CURDATE(), MAX(a.fecha_entrada)) as dias_sin_venir
        FROM usuarios u
        LEFT JOIN asistencias a ON u.id = a.usuario_id
        INNER JOIN membresias m ON u.id = m.usuario_id
        WHERE u.estado = 'activo'
        AND m.estado = 'activa'
        AND m.fecha_fin >= CURDATE()
        GROUP BY u.id, u.nombre, u.apellido
        HAVING (ultima_asistencia IS NULL OR ultima_asistencia <= :fecha_limite)
        AND u.id NOT IN (
            SELECT usuario_id 
            FROM notificaciones 
            WHERE tipo = 'info'
            AND DATE(fecha) = CURDATE()
            AND titulo LIKE '%extrañamos%'
            AND usuario_id IS NOT NULL
        )
    ");
    $stmt->execute([':fecha_limite' => $fecha_limite]);
    $usuarios = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    foreach ($usuarios as $usuario) {
        $dias = $usuario['dias_sin_venir'] ?? $dias_inactividad;
        
        $titulo = str_replace(['{nombre}', '{dias}'], [
            $usuario['nombre'],
            $dias
        ], $config['titulo']);
        
        $mensaje = str_replace(['{nombre}', '{dias}'], [
            $usuario['nombre'] . ' ' . $usuario['apellido'],
            $dias
        ], $config['mensaje']);
        
        $stmt_insert = $db->prepare("
            INSERT INTO notificaciones (usuario_id, titulo, mensaje, tipo, leida, fecha)
            VALUES (:usuario_id, :titulo, :mensaje, 'info', 0, NOW())
        ");
        $stmt_insert->execute([
            ':usuario_id' => $usuario['id'],
            ':titulo' => $titulo,
            ':mensaje' => $mensaje
        ]);
        
        // Obtener el ID de la notificación insertada
        $notification_id = $db->lastInsertId();
        
        // Enviar notificación push
        try {
            $tokens = getFCMTokensForUser($db, $usuario['id']);
            if (!empty($tokens)) {
                // Obtener foto del usuario (si tiene)
                $fotoUsuario = null;
                $stmtFoto = $db->prepare("SELECT foto FROM usuarios WHERE id = :id");
                $stmtFoto->execute([':id' => $usuario['id']]);
                $fotoData = $stmtFoto->fetch(PDO::FETCH_ASSOC);
                if ($fotoData && !empty($fotoData['foto'])) {
                    $siteUrl = getSiteUrl();
                    $fotoUsuario = $siteUrl . 'uploads/usuarios/' . $fotoData['foto'];
                }
                
                $data = [
                    'type' => 'system_notification',
                    'notification_type' => 'inactividad',
                    'notification_id' => (string)$notification_id,
                    'dias_inactividad' => (string)$dias,
                ];
                
                sendPushNotificationToMultiple($tokens, $titulo, $mensaje, $data, $fotoUsuario);
                error_log("[generate_push_notifications] ✅ Push notification enviada para inactividad - usuario_id={$usuario['id']}, notification_id={$notification_id}");
            }
        } catch (Exception $e) {
            error_log("[generate_push_notifications] ❌ Error al enviar push notification de inactividad: " . $e->getMessage());
        }
        
        $count++;
    }
    
    return $count;
}

/**
 * Generar notificación personalizada (para tipos no predefinidos)
 * Esta función puede ser extendida para agregar lógica específica según el tipo
 */
function generarNotificacionPersonalizada($db, $config) {
    // Por defecto, no genera nada para tipos personalizados
    // El desarrollador debe agregar la lógica específica aquí o crear una función separada
    // Ejemplo de cómo podría funcionar:
    
    // Si el tipo tiene un patrón específico, puedes agregarlo aquí
    // Por ejemplo, si el tipo es "promocion_especial", podrías buscar usuarios elegibles
    
    // Por ahora, retornamos 0 para tipos personalizados sin lógica definida
    // Para agregar lógica personalizada, puedes modificar esta función o agregar casos específicos
    // en el switch principal del script
    
    return 0;
}
