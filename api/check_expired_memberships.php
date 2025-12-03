<?php
/**
 * Verificar y actualizar membresías vencidas
 * Este script actualiza el estado de las membresías vencidas y el estado de los usuarios
 * Debe ejecutarse periódicamente (cron job recomendado)
 */
session_start();
header('Content-Type: application/json');
require_once __DIR__ . '/../database/config.php';

try {
    $db = getDB();
    
    // Iniciar transacción
    $db->beginTransaction();
    
    try {
        // 1. Buscar membresías que están 'activa' pero cuya fecha_fin ya pasó
        $stmt = $db->prepare("
            SELECT id, usuario_id, fecha_fin 
            FROM membresias 
            WHERE estado = 'activa' 
            AND fecha_fin < CURDATE()
        ");
        $stmt->execute();
        $membresias_vencidas = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        $usuarios_actualizados = [];
        $membresias_actualizadas = 0;
        
        foreach ($membresias_vencidas as $membresia) {
            // Actualizar estado de la membresía a 'vencida'
            $stmt = $db->prepare("UPDATE membresias SET estado = 'vencida' WHERE id = :id");
            $stmt->execute([':id' => $membresia['id']]);
            $membresias_actualizadas++;
            
            $usuario_id = $membresia['usuario_id'];
            
            // Verificar si el usuario tiene alguna otra membresía activa
            $stmt = $db->prepare("
                SELECT COUNT(*) as total 
                FROM membresias 
                WHERE usuario_id = :usuario_id 
                AND estado = 'activa' 
                AND fecha_fin >= CURDATE()
            ");
            $stmt->execute([':usuario_id' => $usuario_id]);
            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            
            // Si no tiene ninguna membresía activa, actualizar estado del usuario a 'inactivo'
            if ($result['total'] == 0) {
                // Solo actualizar si el usuario no está suspendido (mantener suspendido si lo está)
                $stmt = $db->prepare("
                    UPDATE usuarios 
                    SET estado = 'inactivo' 
                    WHERE id = :usuario_id 
                    AND estado != 'suspendido'
                ");
                $stmt->execute([':usuario_id' => $usuario_id]);
                
                if (!in_array($usuario_id, $usuarios_actualizados)) {
                    $usuarios_actualizados[] = $usuario_id;
                }
            }
        }
        
        $db->commit();
        
        echo json_encode([
            'success' => true,
            'message' => 'Verificación completada',
            'membresias_vencidas' => $membresias_actualizadas,
            'usuarios_actualizados' => count($usuarios_actualizados),
            'usuarios_ids' => $usuarios_actualizados
        ]);
        
    } catch (Exception $e) {
        $db->rollBack();
        throw $e;
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false, 
        'message' => 'Error: ' . $e->getMessage()
    ]);
}
?>

