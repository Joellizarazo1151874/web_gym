<?php
/**
 * Enviar recordatorios de vencimiento de membresías
 * Este script envía correos automáticos a usuarios cuya membresía está por vencer
 * - Recordatorio 3 días antes del vencimiento
 * - Recordatorio 1 día antes del vencimiento
 * 
 * Debe ejecutarse diariamente mediante un cron job:
 * 0 9 * * * /usr/bin/php /ruta/al/proyecto/api/send_membership_reminders.php
 */
header('Content-Type: application/json');
require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/../database/config_helpers.php';

try {
    $db = getDB();
    
    // Iniciar transacción
    $db->beginTransaction();
    
    $correos_enviados_3dias = 0;
    $correos_enviados_1dia = 0;
    $errores = [];
    
    try {
        // Verificar si existen las columnas para registrar recordatorios enviados
        // Si no existen, las creamos (para compatibilidad con instalaciones existentes)
        $check_columns = $db->query("SHOW COLUMNS FROM membresias LIKE 'recordatorio_3dias_enviado'");
        if ($check_columns->rowCount() == 0) {
            $db->exec("ALTER TABLE membresias ADD COLUMN recordatorio_3dias_enviado DATETIME NULL DEFAULT NULL COMMENT 'Fecha y hora en que se envió el recordatorio de 3 días'");
        }
        
        $check_columns = $db->query("SHOW COLUMNS FROM membresias LIKE 'recordatorio_1dia_enviado'");
        if ($check_columns->rowCount() == 0) {
            $db->exec("ALTER TABLE membresias ADD COLUMN recordatorio_1dia_enviado DATETIME NULL DEFAULT NULL COMMENT 'Fecha y hora en que se envió el recordatorio de 1 día'");
        }
        
        // 1. Buscar membresías activas que vencen en 3 días y no se les ha enviado el recordatorio
        $stmt = $db->prepare("
            SELECT 
                m.id,
                m.usuario_id,
                m.fecha_fin,
                u.nombre,
                u.apellido,
                u.email
            FROM membresias m
            INNER JOIN usuarios u ON m.usuario_id = u.id
            WHERE m.estado = 'activa'
            AND m.fecha_fin = DATE_ADD(CURDATE(), INTERVAL 3 DAY)
            AND (m.recordatorio_3dias_enviado IS NULL OR m.recordatorio_3dias_enviado < CURDATE())
            AND u.email IS NOT NULL
            AND u.email != ''
        ");
        $stmt->execute();
        $membresias_3dias = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Enviar recordatorios de 3 días
        foreach ($membresias_3dias as $membresia) {
            try {
                $enviado = enviarCorreoRecordatorioVencimiento(
                    $membresia['email'],
                    $membresia['nombre'],
                    $membresia['apellido'],
                    $membresia['fecha_fin'],
                    3
                );
                
                if ($enviado) {
                    // Registrar que se envió el recordatorio
                    $stmt_update = $db->prepare("
                        UPDATE membresias 
                        SET recordatorio_3dias_enviado = NOW() 
                        WHERE id = :id
                    ");
                    $stmt_update->execute([':id' => $membresia['id']]);
                    $correos_enviados_3dias++;
                } else {
                    $errores[] = "No se pudo enviar correo de 3 días a {$membresia['email']} (membresía ID: {$membresia['id']})";
                }
            } catch (Exception $e) {
                $errores[] = "Error al enviar correo de 3 días a {$membresia['email']}: " . $e->getMessage();
                error_log("Error al enviar recordatorio de 3 días: " . $e->getMessage());
            }
        }
        
        // 2. Buscar membresías activas que vencen en 1 día y no se les ha enviado el recordatorio
        $stmt = $db->prepare("
            SELECT 
                m.id,
                m.usuario_id,
                m.fecha_fin,
                u.nombre,
                u.apellido,
                u.email
            FROM membresias m
            INNER JOIN usuarios u ON m.usuario_id = u.id
            WHERE m.estado = 'activa'
            AND m.fecha_fin = DATE_ADD(CURDATE(), INTERVAL 1 DAY)
            AND (m.recordatorio_1dia_enviado IS NULL OR m.recordatorio_1dia_enviado < CURDATE())
            AND u.email IS NOT NULL
            AND u.email != ''
        ");
        $stmt->execute();
        $membresias_1dia = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Enviar recordatorios de 1 día
        foreach ($membresias_1dia as $membresia) {
            try {
                $enviado = enviarCorreoRecordatorioVencimiento(
                    $membresia['email'],
                    $membresia['nombre'],
                    $membresia['apellido'],
                    $membresia['fecha_fin'],
                    1
                );
                
                if ($enviado) {
                    // Registrar que se envió el recordatorio
                    $stmt_update = $db->prepare("
                        UPDATE membresias 
                        SET recordatorio_1dia_enviado = NOW() 
                        WHERE id = :id
                    ");
                    $stmt_update->execute([':id' => $membresia['id']]);
                    $correos_enviados_1dia++;
                } else {
                    $errores[] = "No se pudo enviar correo de 1 día a {$membresia['email']} (membresía ID: {$membresia['id']})";
                }
            } catch (Exception $e) {
                $errores[] = "Error al enviar correo de 1 día a {$membresia['email']}: " . $e->getMessage();
                error_log("Error al enviar recordatorio de 1 día: " . $e->getMessage());
            }
        }
        
        $db->commit();
        
        $resultado = [
            'success' => true,
            'message' => 'Proceso de recordatorios completado',
            'correos_3dias' => $correos_enviados_3dias,
            'correos_1dia' => $correos_enviados_1dia,
            'total_enviados' => $correos_enviados_3dias + $correos_enviados_1dia
        ];
        
        if (!empty($errores)) {
            $resultado['errores'] = $errores;
            $resultado['total_errores'] = count($errores);
        }
        
        echo json_encode($resultado, JSON_PRETTY_PRINT);
        
    } catch (Exception $e) {
        $db->rollBack();
        throw $e;
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false, 
        'message' => 'Error: ' . $e->getMessage()
    ], JSON_PRETTY_PRINT);
    error_log("Error en send_membership_reminders.php: " . $e->getMessage());
}
?>


