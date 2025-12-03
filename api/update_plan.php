<?php
session_start();
header('Content-Type: application/json');
require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/../database/config_helpers.php';
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

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $db = getDB();

        $plan_id = filter_input(INPUT_POST, 'id', FILTER_VALIDATE_INT);
        $nombre = trim($_POST['nombre'] ?? '');
        $descripcion = trim($_POST['descripcion'] ?? '');
        $duracion_dias = isset($_POST['duracion_dias']) ? (int)$_POST['duracion_dias'] : 0;
        $precio = isset($_POST['precio']) ? (float)$_POST['precio'] : 0;
        // Si no se proporciona precio_app, calcularlo automáticamente
        if (!empty($_POST['precio_app'])) {
            $precio_app = (float)$_POST['precio_app'];
        } else {
            $precio_app = calcularPrecioApp($precio);
        }
        $tipo = $_POST['tipo'] ?? '';
        $activo = isset($_POST['activo']) ? (int)$_POST['activo'] : 0;

        if (!$plan_id || empty($nombre) || $duracion_dias <= 0 || $precio <= 0 || empty($tipo)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Por favor completa todos los campos requeridos.']);
            exit;
        }

        // Validar tipo
        $tipos_validos = ['día', 'semana', 'mes', 'anual'];
        if (!in_array($tipo, $tipos_validos)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Tipo de plan inválido.']);
            exit;
        }

        $sql = "UPDATE planes SET 
                    nombre = :nombre, 
                    descripcion = :descripcion,
                    duracion_dias = :duracion_dias,
                    precio = :precio,
                    precio_app = :precio_app,
                    tipo = :tipo,
                    activo = :activo
                WHERE id = :id";
        
        $params = [
            ':nombre' => $nombre,
            ':descripcion' => $descripcion ?: null,
            ':duracion_dias' => $duracion_dias,
            ':precio' => $precio,
            ':precio_app' => $precio_app,
            ':tipo' => $tipo,
            ':activo' => $activo,
            ':id' => $plan_id
        ];

        $stmt = $db->prepare($sql);
        $result = $stmt->execute($params);

        if ($result) {
            echo json_encode(['success' => true, 'message' => 'Plan actualizado correctamente.']);
        } else {
            throw new Exception('Error al actualizar el plan.');
        }

    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Error al actualizar plan: ' . $e->getMessage()]);
    }
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Método no permitido.']);
}
?>

