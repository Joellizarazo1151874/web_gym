<?php
/**
 * Crear nueva transacción financiera
 * Endpoint API para registrar una nueva transacción (ingreso o egreso)
 */

session_start();
header('Content-Type: application/json');
require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/auth.php';

// Solo permitir POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Método no permitido'
    ]);
    exit;
}

// Verificar autenticación
$auth = new Auth();
if (!$auth->isAuthenticated()) {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'message' => 'No autenticado'
    ]);
    exit;
}

// Verificar rol (solo admin o entrenador)
if (!$auth->hasRole(['admin', 'entrenador'])) {
    http_response_code(403);
    echo json_encode([
        'success' => false,
        'message' => 'No autorizado'
    ]);
    exit;
}

try {
    $db = getDB();
    
    // Obtener datos del POST
    $tipo = trim($_POST['tipo'] ?? '');
    $categoria = trim($_POST['categoria'] ?? '');
    $concepto = trim($_POST['concepto'] ?? '');
    $monto = isset($_POST['monto']) ? (float)$_POST['monto'] : 0;
    $metodo_pago = trim($_POST['metodo_pago'] ?? 'efectivo');
    $referencia = trim($_POST['referencia'] ?? null);
    $usuario_id = !empty($_POST['usuario_id']) ? (int)$_POST['usuario_id'] : null;
    $membresia_id = !empty($_POST['membresia_id']) ? (int)$_POST['membresia_id'] : null;
    $producto_id = !empty($_POST['producto_id']) ? (int)$_POST['producto_id'] : null;
    $fecha = trim($_POST['fecha'] ?? '');
    $observaciones = trim($_POST['observaciones'] ?? null);
    $registrado_por = $_SESSION['usuario_id'];
    
    // Validaciones básicas
    $campos_faltantes = [];
    if (empty($tipo) || !in_array($tipo, ['ingreso', 'egreso'])) {
        $campos_faltantes[] = 'Tipo de transacción válido';
    }
    if (empty($categoria)) {
        $campos_faltantes[] = 'Categoría';
    }
    if (empty($concepto)) {
        $campos_faltantes[] = 'Concepto';
    }
    if ($monto <= 0) {
        $campos_faltantes[] = 'Monto válido';
    }
    if (empty($fecha)) {
        $campos_faltantes[] = 'Fecha';
    }
    
    if (!empty($campos_faltantes)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Por favor completa los siguientes campos requeridos: ' . implode(', ', $campos_faltantes)
        ]);
        exit;
    }
    
    // Validar que el usuario existe si se proporciona
    if ($usuario_id) {
        $stmt = $db->prepare("SELECT id FROM usuarios WHERE id = :id");
        $stmt->execute([':id' => $usuario_id]);
        if (!$stmt->fetch()) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'Usuario no encontrado'
            ]);
            exit;
        }
    }
    
    // Validar que la membresía existe si se proporciona
    if ($membresia_id) {
        $stmt = $db->prepare("SELECT id FROM membresias WHERE id = :id");
        $stmt->execute([':id' => $membresia_id]);
        if (!$stmt->fetch()) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'Membresía no encontrada'
            ]);
            exit;
        }
    }
    
    // Validar que el producto existe si se proporciona
    if ($producto_id) {
        $stmt = $db->prepare("SELECT id FROM productos WHERE id = :id");
        $stmt->execute([':id' => $producto_id]);
        if (!$stmt->fetch()) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'Producto no encontrado'
            ]);
            exit;
        }
    }
    
    // Convertir fecha a formato MySQL
    $fecha_mysql = date('Y-m-d H:i:s', strtotime($fecha));
    
    // Insertar transacción
    $sql = "INSERT INTO transacciones_financieras (
        tipo, categoria, concepto, monto, metodo_pago, referencia,
        usuario_id, membresia_id, producto_id, fecha, observaciones, registrado_por
    ) VALUES (
        :tipo, :categoria, :concepto, :monto, :metodo_pago, :referencia,
        :usuario_id, :membresia_id, :producto_id, :fecha, :observaciones, :registrado_por
    )";
    
    $stmt = $db->prepare($sql);
    $result = $stmt->execute([
        ':tipo' => $tipo,
        ':categoria' => $categoria,
        ':concepto' => $concepto,
        ':monto' => $monto,
        ':metodo_pago' => $metodo_pago,
        ':referencia' => $referencia ?: null,
        ':usuario_id' => $usuario_id,
        ':membresia_id' => $membresia_id,
        ':producto_id' => $producto_id,
        ':fecha' => $fecha_mysql,
        ':observaciones' => $observaciones ?: null,
        ':registrado_por' => $registrado_por
    ]);
    
    if ($result) {
        $transaction_id = $db->lastInsertId();
        echo json_encode([
            'success' => true,
            'message' => 'Transacción registrada correctamente',
            'data' => [
                'id' => $transaction_id
            ]
        ]);
    } else {
        throw new Exception('Error al registrar la transacción');
    }
    
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error en la base de datos: ' . $e->getMessage()
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al registrar transacción: ' . $e->getMessage()
    ]);
}
?>


