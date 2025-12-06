<?php
/**
 * Obtener cierres de caja con filtros y paginación
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
    $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 20;
    $offset = isset($_GET['offset']) ? (int)$_GET['offset'] : 0;
    
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
    
    // Obtener total de registros
    $countStmt = $db->prepare("
        SELECT COUNT(*) as total
        FROM sesiones_caja s
        $whereClause
    ");
    $countStmt->execute($params);
    $total = $countStmt->fetch(PDO::FETCH_ASSOC)['total'];
    
    // Obtener cierres de caja
    $stmt = $db->prepare("
        SELECT 
            s.id,
            s.fecha_apertura,
            s.fecha_cierre,
            s.monto_apertura,
            s.monto_cierre,
            s.monto_esperado,
            s.diferencia,
            s.observaciones_apertura,
            s.observaciones_cierre,
            CONCAT(u1.nombre, ' ', u1.apellido) as abierta_por_nombre,
            CONCAT(u2.nombre, ' ', u2.apellido) as cerrada_por_nombre,
            COALESCE(SUM(v.total), 0) as ventas_totales,
            COALESCE(SUM(v.monto_efectivo), 0) as ventas_efectivo,
            COALESCE(SUM(v.monto_tarjeta), 0) as ventas_tarjeta,
            COALESCE(SUM(v.monto_transferencia), 0) as ventas_transferencia,
            COALESCE(SUM(v.monto_app), 0) as ventas_app,
            COUNT(v.id) as total_ventas
        FROM sesiones_caja s
        INNER JOIN usuarios u1 ON s.abierta_por = u1.id
        LEFT JOIN usuarios u2 ON s.cerrada_por = u2.id
        LEFT JOIN ventas v ON v.sesion_caja_id = s.id
        $whereClause
        GROUP BY s.id, s.fecha_apertura, s.fecha_cierre, s.monto_apertura, 
                 s.monto_cierre, s.monto_esperado, s.diferencia, 
                 s.observaciones_apertura, s.observaciones_cierre,
                 u1.nombre, u1.apellido, u2.nombre, u2.apellido
        ORDER BY s.fecha_cierre DESC
        LIMIT :limit OFFSET :offset
    ");
    
    foreach ($params as $key => $value) {
        $stmt->bindValue($key, $value);
    }
    $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
    $stmt->execute();
    
    $cierres = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo json_encode([
        'success' => true,
        'cierres' => $cierres,
        'total' => (int)$total,
        'limit' => $limit,
        'offset' => $offset
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
}
?>

