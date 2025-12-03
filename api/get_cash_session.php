<?php
/**
 * Obtener sesión de caja activa
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
            u1.apellido as abierta_por_apellido,
            COALESCE(SUM(v.monto_efectivo), 0) as total_efectivo
        FROM sesiones_caja s
        INNER JOIN usuarios u1 ON s.abierta_por = u1.id
        LEFT JOIN ventas v ON v.sesion_caja_id = s.id
        WHERE s.estado = 'abierta'
        GROUP BY s.id
        ORDER BY s.fecha_apertura DESC
        LIMIT 1
    ");
    
    $sesion = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($sesion) {
        // Calcular monto esperado
        $monto_esperado = $sesion['monto_apertura'] + $sesion['total_efectivo'];
        $sesion['monto_esperado'] = $monto_esperado;
        
        echo json_encode([
            'success' => true,
            'sesion' => $sesion
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'sesion' => null
        ]);
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
}
?>


