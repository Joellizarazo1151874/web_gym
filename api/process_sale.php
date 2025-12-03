<?php
/**
 * Procesar venta desde la caja
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
    
    // Verificar sesión de caja abierta
    $stmt = $db->query("SELECT id FROM sesiones_caja WHERE estado = 'abierta' LIMIT 1");
    $sesion = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$sesion) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'No hay una sesión de caja abierta']);
        exit;
    }
    
    $sesion_caja_id = $sesion['id'];
    $data = json_decode(file_get_contents('php://input'), true);
    
    $items = $data['items'] ?? [];
    $tipo = $data['tipo'] ?? 'productos'; // productos, membresia, mixto
    $usuario_id = !empty($data['usuario_id']) ? (int)$data['usuario_id'] : null;
    $plan_id = !empty($data['plan_id']) ? (int)$data['plan_id'] : null;
    $metodo_pago = $data['metodo_pago'] ?? 'efectivo';
    $monto_efectivo = isset($data['monto_efectivo']) ? (float)$data['monto_efectivo'] : null;
    $monto_tarjeta = isset($data['monto_tarjeta']) ? (float)$data['monto_tarjeta'] : null;
    $monto_transferencia = isset($data['monto_transferencia']) ? (float)$data['monto_transferencia'] : null;
    $monto_app = isset($data['monto_app']) ? (float)$data['monto_app'] : null;
    $descuento = isset($data['descuento']) ? (float)$data['descuento'] : 0;
    $observaciones = trim($data['observaciones'] ?? '');
    
    // Validaciones
    if (empty($items) && $tipo !== 'membresia') {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Debe agregar al menos un producto']);
        exit;
    }
    
    if ($tipo === 'membresia' && (!$plan_id || !$usuario_id)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Debe seleccionar un plan y un usuario para la membresía']);
        exit;
    }
    
    // Calcular totales
    $subtotal = 0;
    
    // Calcular subtotal de productos
    foreach ($items as $item) {
        $producto_id = (int)$item['producto_id'];
        $cantidad = (int)$item['cantidad'];
        
        // Verificar producto y stock
        $stmt = $db->prepare("SELECT id, precio, stock FROM productos WHERE id = :id AND activo = 1");
        $stmt->execute([':id' => $producto_id]);
        $producto = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$producto) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Producto no encontrado']);
            exit;
        }
        
        if ($producto['stock'] < $cantidad) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Stock insuficiente para ' . $item['nombre']]);
            exit;
        }
        
        $subtotal += $producto['precio'] * $cantidad;
    }
    
    // Agregar precio de membresía si aplica
    $membresia_id = null;
    if ($tipo === 'membresia' || $tipo === 'mixto') {
        $stmt = $db->prepare("SELECT id, precio, precio_app FROM planes WHERE id = :id AND activo = 1");
        $stmt->execute([':id' => $plan_id]);
        $plan = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$plan) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Plan no encontrado']);
            exit;
        }
        
        // Usar precio_app si el método de pago es app, sino precio normal
        $precio_membresia = ($metodo_pago === 'app') ? $plan['precio_app'] : $plan['precio'];
        $subtotal += $precio_membresia;
    }
    
    $total = $subtotal - $descuento;
    
    if ($total <= 0) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'El total debe ser mayor a 0']);
        exit;
    }
    
    // Validar montos de pago
    if ($metodo_pago === 'mixto') {
        $suma_montos = ($monto_efectivo ?? 0) + ($monto_tarjeta ?? 0) + ($monto_transferencia ?? 0) + ($monto_app ?? 0);
        if (abs($suma_montos - $total) > 0.01) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'La suma de los montos no coincide con el total']);
            exit;
        }
    } else {
        // Para métodos únicos, el monto debe ser igual al total
        $monto_metodo = null;
        switch ($metodo_pago) {
            case 'efectivo':
                $monto_metodo = $monto_efectivo;
                break;
            case 'tarjeta':
                $monto_metodo = $monto_tarjeta;
                break;
            case 'transferencia':
                $monto_metodo = $monto_transferencia;
                break;
            case 'app':
                $monto_metodo = $monto_app;
                break;
        }
        
        if ($monto_metodo === null || abs($monto_metodo - $total) > 0.01) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'El monto del método de pago debe coincidir con el total']);
            exit;
        }
    }
    
    // Generar número de factura
    $numero_factura = 'FAC-' . date('Ymd') . '-' . str_pad(rand(1, 9999), 4, '0', STR_PAD_LEFT);
    
    // Verificar que el número de factura sea único
    $stmt = $db->prepare("SELECT id FROM ventas WHERE numero_factura = :numero");
    $stmt->execute([':numero' => $numero_factura]);
    if ($stmt->fetch()) {
        $numero_factura = 'FAC-' . date('Ymd') . '-' . str_pad(rand(1, 9999), 4, '0', STR_PAD_LEFT);
    }
    
    // Iniciar transacción
    $db->beginTransaction();
    
    try {
        // Crear membresía si aplica
        if ($tipo === 'membresia' || $tipo === 'mixto') {
            // Calcular fechas de membresía
            $fecha_inicio = date('Y-m-d');
            $fecha_fin = date('Y-m-d', strtotime('+1 month')); // Por defecto 1 mes, ajustar según el plan
            
            // Obtener duración del plan
            $stmt = $db->prepare("SELECT tipo FROM planes WHERE id = :id");
            $stmt->execute([':id' => $plan_id]);
            $plan_info = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if ($plan_info) {
                switch ($plan_info['tipo']) {
                    case 'día':
                        $fecha_fin = date('Y-m-d', strtotime('+1 day'));
                        break;
                    case 'semana':
                        $fecha_fin = date('Y-m-d', strtotime('+1 week'));
                        break;
                    case 'mes':
                        $fecha_fin = date('Y-m-d', strtotime('+1 month'));
                        break;
                    case 'anual':
                        $fecha_fin = date('Y-m-d', strtotime('+1 year'));
                        break;
                }
            }
            
            $descuento_app = ($metodo_pago === 'app') ? 1 : 0;
            
            $stmt = $db->prepare("
                INSERT INTO membresias (usuario_id, plan_id, fecha_inicio, fecha_fin, precio_pagado, descuento_app, estado)
                VALUES (:usuario_id, :plan_id, :fecha_inicio, :fecha_fin, :precio_pagado, :descuento_app, 'activa')
            ");
            
            $precio_membresia = ($metodo_pago === 'app') ? $plan['precio_app'] : $plan['precio'];
            
            $stmt->execute([
                ':usuario_id' => $usuario_id,
                ':plan_id' => $plan_id,
                ':fecha_inicio' => $fecha_inicio,
                ':fecha_fin' => $fecha_fin,
                ':precio_pagado' => $precio_membresia,
                ':descuento_app' => $descuento_app
            ]);
            
            $membresia_id = $db->lastInsertId();
            
            // Actualizar estado del usuario a 'activo' cuando se compra una membresía
            $stmt = $db->prepare("UPDATE usuarios SET estado = 'activo' WHERE id = :usuario_id");
            $stmt->execute([':usuario_id' => $usuario_id]);
        }
        
        // Crear venta
        $stmt = $db->prepare("
            INSERT INTO ventas (
                sesion_caja_id, numero_factura, usuario_id, tipo, subtotal, descuento, total,
                metodo_pago, monto_efectivo, monto_tarjeta, monto_transferencia, monto_app,
                membresia_id, fecha_venta, vendedor_id, observaciones
            ) VALUES (
                :sesion_caja_id, :numero_factura, :usuario_id, :tipo, :subtotal, :descuento, :total,
                :metodo_pago, :monto_efectivo, :monto_tarjeta, :monto_transferencia, :monto_app,
                :membresia_id, NOW(), :vendedor_id, :observaciones
            )
        ");
        
        $stmt->execute([
            ':sesion_caja_id' => $sesion_caja_id,
            ':numero_factura' => $numero_factura,
            ':usuario_id' => $usuario_id,
            ':tipo' => $tipo,
            ':subtotal' => $subtotal,
            ':descuento' => $descuento,
            ':total' => $total,
            ':metodo_pago' => $metodo_pago,
            ':monto_efectivo' => $monto_efectivo,
            ':monto_tarjeta' => $monto_tarjeta,
            ':monto_transferencia' => $monto_transferencia,
            ':monto_app' => $monto_app,
            ':membresia_id' => $membresia_id,
            ':vendedor_id' => $_SESSION['usuario_id'],
            ':observaciones' => $observaciones ?: null
        ]);
        
        $venta_id = $db->lastInsertId();
        
        // Crear items de venta y actualizar stock
        foreach ($items as $item) {
            $producto_id = (int)$item['producto_id'];
            $cantidad = (int)$item['cantidad'];
            
            // Obtener precio actual
            $stmt = $db->prepare("SELECT precio FROM productos WHERE id = :id");
            $stmt->execute([':id' => $producto_id]);
            $producto = $stmt->fetch(PDO::FETCH_ASSOC);
            
            $precio_unitario = $producto['precio'];
            $subtotal_item = $precio_unitario * $cantidad;
            
            // Insertar item
            $stmt = $db->prepare("
                INSERT INTO venta_items (venta_id, producto_id, cantidad, precio_unitario, subtotal)
                VALUES (:venta_id, :producto_id, :cantidad, :precio_unitario, :subtotal)
            ");
            
            $stmt->execute([
                ':venta_id' => $venta_id,
                ':producto_id' => $producto_id,
                ':cantidad' => $cantidad,
                ':precio_unitario' => $precio_unitario,
                ':subtotal' => $subtotal_item
            ]);
            
            // Actualizar stock
            $stmt = $db->prepare("UPDATE productos SET stock = stock - :cantidad WHERE id = :id");
            $stmt->execute([':cantidad' => $cantidad, ':id' => $producto_id]);
        }
        
        // Registrar transacción financiera
        $stmt = $db->prepare("
            INSERT INTO transacciones_financieras (
                tipo, categoria, concepto, monto, metodo_pago, referencia,
                usuario_id, membresia_id, fecha, registrado_por
            ) VALUES (
                'ingreso', :categoria, :concepto, :monto, :metodo_pago, :referencia,
                :usuario_id, :membresia_id, NOW(), :registrado_por
            )
        ");
        
        $categoria = ($tipo === 'membresia') ? 'membresia' : (($tipo === 'mixto') ? 'membresia' : 'producto');
        $concepto = ($tipo === 'membresia') ? 'Venta de membresía - ' . $numero_factura : 'Venta de productos - ' . $numero_factura;
        
        $stmt->execute([
            ':categoria' => $categoria,
            ':concepto' => $concepto,
            ':monto' => $total,
            ':metodo_pago' => $metodo_pago,
            ':referencia' => $numero_factura,
            ':usuario_id' => $usuario_id,
            ':membresia_id' => $membresia_id,
            ':registrado_por' => $_SESSION['usuario_id']
        ]);
        
        $db->commit();
        
        // Obtener datos completos de la venta para la factura
        $stmt = $db->prepare("
            SELECT v.*, u.nombre as usuario_nombre, u.apellido as usuario_apellido,
                   pl.nombre as plan_nombre, pl.tipo as plan_tipo
            FROM ventas v
            LEFT JOIN usuarios u ON v.usuario_id = u.id
            LEFT JOIN membresias m ON v.membresia_id = m.id
            LEFT JOIN planes pl ON m.plan_id = pl.id
            WHERE v.id = :venta_id
        ");
        $stmt->execute([':venta_id' => $venta_id]);
        $venta_completa = $stmt->fetch(PDO::FETCH_ASSOC);
        
        // Obtener items de la venta
        $stmt = $db->prepare("
            SELECT vi.*, pr.nombre as producto_nombre
            FROM venta_items vi
            INNER JOIN productos pr ON vi.producto_id = pr.id
            WHERE vi.venta_id = :venta_id
        ");
        $stmt->execute([':venta_id' => $venta_id]);
        $venta_completa['items'] = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode([
            'success' => true,
            'message' => 'Venta procesada correctamente',
            'venta' => $venta_completa
        ]);
        
    } catch (Exception $e) {
        $db->rollBack();
        throw $e;
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
}
?>

