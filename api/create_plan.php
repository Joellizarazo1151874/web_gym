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
        $activo = isset($_POST['activo']) ? (int)$_POST['activo'] : 1;

        // Validaciones
        $missing_fields = [];
        if (empty($nombre)) $missing_fields[] = 'Nombre';
        if (empty($tipo)) $missing_fields[] = 'Tipo';
        if ($duracion_dias <= 0) $missing_fields[] = 'Duración (Días)';
        if ($precio <= 0) $missing_fields[] = 'Precio';

        if (!empty($missing_fields)) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'Por favor completa los siguientes campos requeridos: ' . implode(', ', $missing_fields)
            ]);
            exit;
        }

        // Validar tipo
        $tipos_validos = ['día', 'semana', 'mes', 'anual'];
        if (!in_array($tipo, $tipos_validos)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Tipo de plan inválido.']);
            exit;
        }

        // Verificar si ya existe un plan con el mismo nombre
        $stmt = $db->prepare("SELECT id FROM planes WHERE nombre = :nombre");
        $stmt->execute([':nombre' => $nombre]);
        if ($stmt->fetch()) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Ya existe un plan con ese nombre.']);
            exit;
        }

        // Insertar el nuevo plan
        $sql = "INSERT INTO planes (nombre, descripcion, duracion_dias, precio, precio_app, tipo, activo) 
                VALUES (:nombre, :descripcion, :duracion_dias, :precio, :precio_app, :tipo, :activo)";
        
        $params = [
            ':nombre' => $nombre,
            ':descripcion' => $descripcion ?: null,
            ':duracion_dias' => $duracion_dias,
            ':precio' => $precio,
            ':precio_app' => $precio_app,
            ':tipo' => $tipo,
            ':activo' => $activo
        ];

        $stmt = $db->prepare($sql);
        $result = $stmt->execute($params);

        if ($result) {
            echo json_encode(['success' => true, 'message' => 'Plan creado correctamente.']);
        } else {
            throw new Exception('Error al crear el plan.');
        }

    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Error al crear plan: ' . $e->getMessage()]);
    }
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Método no permitido.']);
}
?>

