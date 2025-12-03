<?php
/**
 * Obtener resumen completo para cierre de caja
 */
session_start();
header('Content-Type: application/json');
header('Cache-Control: no-cache, no-store, must-revalidate');
header('Pragma: no-cache');
header('Expires: 0');
require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/auth.php';

$auth = new Auth();
if (!$auth->isAuthenticated()) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'No autenticado']);
    exit;
}

if (!$auth->hasRole(['admin', 'entrenador', 'empleado'])) {
    http_response_code(403);
    echo json_encode(['success' => false, 'message' => 'No autorizado']);
    exit;
}

try {
    $db = getDB();
    
    // Buscar sesión de caja abierta
    $stmt = $db->query("
        SELECT 
            s.*,
            u1.nombre as abierta_por_nombre,
            u1.apellido as abierta_por_apellido
        FROM sesiones_caja s
        INNER JOIN usuarios u1 ON s.abierta_por = u1.id
        WHERE s.estado = 'abierta'
        ORDER BY s.fecha_apertura DESC
        LIMIT 1
    ");
    
    $sesion = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$sesion) {
        echo json_encode([
            'success' => false,
            'message' => 'No hay una sesión de caja abierta'
        ]);
        exit;
    }
    
    $sesionId = $sesion['id'];
    
    // Calcular ventas totales (todas las ventas de la sesión)
    $stmt = $db->prepare("
        SELECT 
            COALESCE(SUM(total), 0) as ventas_totales,
            COALESCE(SUM(monto_efectivo), 0) as ventas_efectivo,
            COALESCE(SUM(monto_tarjeta), 0) as ventas_tarjeta,
            COALESCE(SUM(monto_transferencia), 0) as ventas_transferencia,
            COALESCE(SUM(monto_app), 0) as ventas_app,
            COALESCE(SUM(CASE WHEN metodo_pago = 'mixto' THEN total ELSE 0 END), 0) as ventas_mixto
        FROM ventas
        WHERE sesion_caja_id = :sesion_id
    ");
    $stmt->execute([':sesion_id' => $sesionId]);
    $ventas = $stmt->fetch(PDO::FETCH_ASSOC);
    
    // Ingresos varios (por ahora 0, se puede agregar una tabla de ingresos/gastos)
    $ingresos_varios = 0;
    
    // Gastos varios (por ahora 0, se puede agregar una tabla de ingresos/gastos)
    $gastos_varios = 0;
    
    // Calcular efectivo en caja
    $fondo_caja = (float)$sesion['monto_apertura'];
    $ventas_efectivo = (float)$ventas['ventas_efectivo'];
    $efectivo_en_caja = $fondo_caja + $ventas_efectivo + $ingresos_varios - $gastos_varios;
    
    // Formatear fechas
    $fecha_apertura = date('d/m/Y H:i:s', strtotime($sesion['fecha_apertura']));
    $fecha_cierre = date('d/m/Y H:i:s');
    
    echo json_encode([
        'success' => true,
        'resumen' => [
            'fecha_apertura' => $fecha_apertura,
            'fecha_cierre' => $fecha_cierre,
            'fondo_caja' => $fondo_caja,
            'ventas_totales' => (float)$ventas['ventas_totales'],
            'ventas_efectivo' => $ventas_efectivo,
            'ventas_tarjeta' => (float)$ventas['ventas_tarjeta'],
            'ventas_transferencia' => (float)$ventas['ventas_transferencia'],
            'ventas_app' => (float)$ventas['ventas_app'],
            'ventas_mixto' => (float)$ventas['ventas_mixto'],
            'ingresos_varios' => $ingresos_varios,
            'gastos_varios' => $gastos_varios,
            'efectivo_en_caja' => $efectivo_en_caja,
            'sesion_id' => $sesionId
        ]
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
}
?>

