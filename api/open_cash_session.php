<?php
/**
 * Abrir sesión de caja
 */
session_start();
header('Content-Type: application/json');
require_once __DIR__ . '/../database/config.php';
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

try {
    $db = getDB();
    
    // Verificar si ya hay una sesión abierta
    $stmt = $db->query("SELECT id FROM sesiones_caja WHERE estado = 'abierta' LIMIT 1");
    if ($stmt->fetch()) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Ya existe una sesión de caja abierta']);
        exit;
    }
    
    $monto_apertura = (float)($_POST['monto_apertura'] ?? 0);
    $observaciones = trim($_POST['observaciones'] ?? '');
    
    if ($monto_apertura < 0) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'El monto de apertura no puede ser negativo']);
        exit;
    }
    
    $stmt = $db->prepare("
        INSERT INTO sesiones_caja (fecha_apertura, monto_apertura, abierta_por, observaciones_apertura, estado)
        VALUES (NOW(), :monto, :usuario_id, :observaciones, 'abierta')
    ");
    
    $stmt->execute([
        ':monto' => $monto_apertura,
        ':usuario_id' => $_SESSION['usuario_id'],
        ':observaciones' => $observaciones ?: null
    ]);
    
    $sesion_id = $db->lastInsertId();
    
    echo json_encode([
        'success' => true,
        'message' => 'Caja abierta correctamente',
        'sesion_id' => $sesion_id
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
}
?>


