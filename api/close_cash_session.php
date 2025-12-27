<?php
/**
 * Cerrar sesión de caja
 */
session_start();
header('Content-Type: application/json');
require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/../database/csrf_helper.php';
require_once __DIR__ . '/auth.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Método no permitido']);
    exit;
}

$auth = new Auth();
if (!$auth->isAuthenticated() || !$auth->hasRole(['admin', 'entrenador', 'empleado'])) {
    http_response_code(403);
    echo json_encode(['success' => false, 'message' => 'No autorizado']);
    exit;
}

// Validar token CSRF
requireCSRFToken(true);

try {
    $db = getDB();
    
    // Obtener sesión abierta
    $stmt = $db->query("
        SELECT 
            s.*,
            COALESCE(SUM(v.monto_efectivo), 0) as total_efectivo
        FROM sesiones_caja s
        LEFT JOIN ventas v ON v.sesion_caja_id = s.id
        WHERE s.estado = 'abierta'
        GROUP BY s.id
        LIMIT 1
    ");
    
    $sesion = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$sesion) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'No hay una sesión de caja abierta']);
        exit;
    }
    
    $monto_cierre = (float)($_POST['monto_cierre'] ?? 0);
    $observaciones = trim($_POST['observaciones'] ?? '');
    
    if ($monto_cierre < 0) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'El monto de cierre no puede ser negativo']);
        exit;
    }
    
    // Calcular monto esperado
    $monto_esperado = $sesion['monto_apertura'] + $sesion['total_efectivo'];
    $diferencia = $monto_cierre - $monto_esperado;
    
    // Actualizar sesión
    $stmt = $db->prepare("
        UPDATE sesiones_caja 
        SET fecha_cierre = NOW(),
            monto_cierre = :monto_cierre,
            monto_esperado = :monto_esperado,
            diferencia = :diferencia,
            estado = 'cerrada',
            cerrada_por = :usuario_id,
            observaciones_cierre = :observaciones
        WHERE id = :sesion_id
    ");
    
    $stmt->execute([
        ':monto_cierre' => $monto_cierre,
        ':monto_esperado' => $monto_esperado,
        ':diferencia' => $diferencia,
        ':usuario_id' => $_SESSION['usuario_id'],
        ':observaciones' => $observaciones ?: null,
        ':sesion_id' => $sesion['id']
    ]);
    
    echo json_encode([
        'success' => true,
        'message' => 'Caja cerrada correctamente',
        'diferencia' => $diferencia,
        'monto_esperado' => $monto_esperado
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
}
?>


