<?php
/**
 * Obtener consolidado de cierres de caja
 */
session_start();
header('Content-Type: application/json');
require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/auth.php';

$auth = new Auth();
if (!$auth->isAuthenticated() || !$auth->hasRole(['admin', 'entrenador', 'empleado'])) {
    http_response_code(403);
    echo json_encode(['success' => false, 'message' => 'No autorizado']);
    exit;
}

try {
    $db = getDB();
    
    // Parámetros de filtro
    $fecha_desde = $_GET['fecha_desde'] ?? null;
    $fecha_hasta = $_GET['fecha_hasta'] ?? null;
    
    // Construir consulta base
    $where = ["s.estado = 'cerrada'"];
    $params = [];
    
    if ($fecha_desde) {
        $where[] = "DATE(s.fecha_cierre) >= :fecha_desde";
        $params[':fecha_desde'] = $fecha_desde;
    }
    
    if ($fecha_hasta) {
        $where[] = "DATE(s.fecha_cierre) <= :fecha_hasta";
        $params[':fecha_hasta'] = $fecha_hasta;
    }
    
    $whereClause = !empty($where) ? "WHERE " . implode(" AND ", $where) : "";
    
    // Obtener consolidado de sesiones (sin JOIN para evitar duplicación)
    $stmt = $db->prepare("
        SELECT 
            COUNT(*) as total_sesiones,
            COALESCE(SUM(monto_apertura), 0) as total_apertura,
            COALESCE(SUM(monto_cierre), 0) as total_cierre,
            COALESCE(SUM(monto_esperado), 0) as total_esperado,
            COALESCE(SUM(diferencia), 0) as total_diferencia,
            MIN(fecha_apertura) as primera_apertura,
            MAX(fecha_cierre) as ultimo_cierre
        FROM sesiones_caja s
        $whereClause
    ");
    
    $stmt->execute($params);
    $consolidado = $stmt->fetch(PDO::FETCH_ASSOC);
    
    // Obtener IDs de sesiones para calcular ventas
    $stmtIds = $db->prepare("
        SELECT id FROM sesiones_caja s
        $whereClause
    ");
    $stmtIds->execute($params);
    $sesionesIds = $stmtIds->fetchAll(PDO::FETCH_COLUMN);
    
    // Calcular ventas solo si hay sesiones
    if (!empty($sesionesIds)) {
        $placeholders = implode(',', array_fill(0, count($sesionesIds), '?'));
        $stmtVentas = $db->prepare("
            SELECT 
                COALESCE(SUM(total), 0) as total_ventas,
                COALESCE(SUM(monto_efectivo), 0) as total_ventas_efectivo,
                COALESCE(SUM(monto_tarjeta), 0) as total_ventas_tarjeta,
                COALESCE(SUM(monto_transferencia), 0) as total_ventas_transferencia,
                COALESCE(SUM(monto_app), 0) as total_ventas_app,
                COUNT(*) as total_transacciones
            FROM ventas
            WHERE sesion_caja_id IN ($placeholders)
        ");
        $stmtVentas->execute($sesionesIds);
        $ventas = $stmtVentas->fetch(PDO::FETCH_ASSOC);
        
        $consolidado['total_ventas'] = (float)$ventas['total_ventas'];
        $consolidado['total_ventas_efectivo'] = (float)$ventas['total_ventas_efectivo'];
        $consolidado['total_ventas_tarjeta'] = (float)$ventas['total_ventas_tarjeta'];
        $consolidado['total_ventas_transferencia'] = (float)$ventas['total_ventas_transferencia'];
        $consolidado['total_ventas_app'] = (float)$ventas['total_ventas_app'];
        $consolidado['total_transacciones'] = (int)$ventas['total_transacciones'];
    } else {
        $consolidado['total_ventas'] = 0;
        $consolidado['total_ventas_efectivo'] = 0;
        $consolidado['total_ventas_tarjeta'] = 0;
        $consolidado['total_ventas_transferencia'] = 0;
        $consolidado['total_ventas_app'] = 0;
        $consolidado['total_transacciones'] = 0;
    }
    
    // Obtener desglose por día (sin JOIN para evitar duplicación)
    $stmtDias = $db->prepare("
        SELECT 
            DATE(fecha_cierre) as fecha,
            COUNT(*) as sesiones,
            COALESCE(SUM(monto_cierre), 0) as total_cierre_dia
        FROM sesiones_caja s
        $whereClause
        GROUP BY DATE(fecha_cierre)
        ORDER BY fecha DESC
    ");
    
    $stmtDias->execute($params);
    $desglose_dias = $stmtDias->fetchAll(PDO::FETCH_ASSOC);
    
    // Agregar ventas por día usando los IDs de sesiones ya filtradas
    if (!empty($sesionesIds)) {
        foreach ($desglose_dias as &$dia) {
            $fecha = $dia['fecha'];
            // Obtener IDs de sesiones de este día específico
            $whereDia = array_merge($where, ["DATE(s.fecha_cierre) = :fecha_dia"]);
            $whereClauseDia = "WHERE " . implode(" AND ", $whereDia);
            $paramsDia = array_merge($params, [':fecha_dia' => $fecha]);
            
            $stmtIdsDia = $db->prepare("SELECT id FROM sesiones_caja s $whereClauseDia");
            $stmtIdsDia->execute($paramsDia);
            $sesionesIdsDia = $stmtIdsDia->fetchAll(PDO::FETCH_COLUMN);
            
            if (!empty($sesionesIdsDia)) {
                $placeholdersDia = implode(',', array_fill(0, count($sesionesIdsDia), '?'));
                $stmtVentasDia = $db->prepare("
                    SELECT COALESCE(SUM(total), 0) as ventas_dia
                    FROM ventas
                    WHERE sesion_caja_id IN ($placeholdersDia)
                ");
                $stmtVentasDia->execute($sesionesIdsDia);
                $ventasDia = $stmtVentasDia->fetch(PDO::FETCH_ASSOC);
                $dia['ventas_dia'] = (float)($ventasDia['ventas_dia'] ?? 0);
            } else {
                $dia['ventas_dia'] = 0;
            }
        }
        unset($dia);
    } else {
        foreach ($desglose_dias as &$dia) {
            $dia['ventas_dia'] = 0;
        }
        unset($dia);
    }
    
    echo json_encode([
        'success' => true,
        'consolidado' => $consolidado,
        'desglose_dias' => $desglose_dias
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
}
?>

