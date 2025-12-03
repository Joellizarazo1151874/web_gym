<?php
session_start();
header('Content-Type: application/json');
require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/auth.php';

$auth = new Auth();
if (!$auth->isAuthenticated()) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'No autenticado']);
    exit;
}

if (!$auth->hasRole(['admin', 'entrenador'])) {
    http_response_code(403);
    echo json_encode(['success' => false, 'message' => 'No autorizado']);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $plan_id = filter_input(INPUT_GET, 'id', FILTER_VALIDATE_INT);

    if (!$plan_id) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'ID de plan inválido']);
        exit;
    }

    try {
        $db = getDB();
        $stmt = $db->prepare("SELECT id, nombre, descripcion, duracion_dias, precio, precio_app, tipo, activo FROM planes WHERE id = :id");
        $stmt->execute([':id' => $plan_id]);
        $plan = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($plan) {
            echo json_encode(['success' => true, 'data' => $plan]);
        } else {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'Plan no encontrado']);
        }
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Error de base de datos: ' . $e->getMessage()]);
    }
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Método no permitido']);
}
?>

