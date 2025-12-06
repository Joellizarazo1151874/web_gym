<?php
/**
 * Obtener ventas/recibos generados en caja
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
    
    // Parámetros de filtro
    $fecha_desde = $_GET['fecha_desde'] ?? '';
    $fecha_hasta = $_GET['fecha_hasta'] ?? '';
    $tipo = $_GET['tipo'] ?? '';
    $metodo_pago = $_GET['metodo_pago'] ?? '';
    $busqueda = $_GET['search'] ?? '';
    $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 20;
    $offset = isset($_GET['offset']) ? (int)$_GET['offset'] : 0;
    
    // Construir consulta base
    $sql = "
        SELECT 
            v.id,
            v.numero_factura,
            v.tipo,
            v.subtotal,
            v.descuento,
            v.total,
            v.metodo_pago,
            v.monto_efectivo,
            v.monto_tarjeta,
            v.monto_transferencia,
            v.monto_app,
            v.fecha_venta,
            v.observaciones,
            v.sesion_caja_id,
            CONCAT(u.nombre, ' ', u.apellido) as usuario_nombre,
            u.email as usuario_email,
            u.documento as usuario_documento,
            CONCAT(vd.nombre, ' ', vd.apellido) as vendedor_nombre,
            pl.nombre as plan_nombre,
            pl.tipo as plan_tipo,
            m.fecha_inicio as membresia_fecha_inicio,
            m.fecha_fin as membresia_fecha_fin
        FROM ventas v
        LEFT JOIN usuarios u ON v.usuario_id = u.id
        LEFT JOIN usuarios vd ON v.vendedor_id = vd.id
        LEFT JOIN membresias m ON v.membresia_id = m.id
        LEFT JOIN planes pl ON m.plan_id = pl.id
        WHERE 1=1
    ";
    
    $params = [];
    
    // Aplicar filtros
    if (!empty($fecha_desde)) {
        $sql .= " AND DATE(v.fecha_venta) >= :fecha_desde";
        $params[':fecha_desde'] = $fecha_desde;
    }
    
    if (!empty($fecha_hasta)) {
        $sql .= " AND DATE(v.fecha_venta) <= :fecha_hasta";
        $params[':fecha_hasta'] = $fecha_hasta;
    }
    
    if (!empty($tipo)) {
        $sql .= " AND v.tipo = :tipo";
        $params[':tipo'] = $tipo;
    }
    
    if (!empty($metodo_pago)) {
        $sql .= " AND v.metodo_pago = :metodo_pago";
        $params[':metodo_pago'] = $metodo_pago;
    }
    
    if (!empty($busqueda)) {
        // Si es un número, buscar también por ID
        if (is_numeric($busqueda)) {
            $sql .= " AND (
                v.id = :search_id OR
                v.numero_factura LIKE :search1 OR
                CONCAT(u.nombre, ' ', u.apellido) LIKE :search2 OR
                u.email LIKE :search3 OR
                u.documento LIKE :search4
            )";
            $params[':search_id'] = (int)$busqueda;
        } else {
            $sql .= " AND (
                v.numero_factura LIKE :search1 OR
                CONCAT(u.nombre, ' ', u.apellido) LIKE :search2 OR
                u.email LIKE :search3 OR
                u.documento LIKE :search4
            )";
        }
        $search_term = '%' . $busqueda . '%';
        $params[':search1'] = $search_term;
        $params[':search2'] = $search_term;
        $params[':search3'] = $search_term;
        $params[':search4'] = $search_term;
    }
    
    // Contar total de registros
    $countSql = "SELECT COUNT(*) as total FROM (" . $sql . ") as count_query";
    $countStmt = $db->prepare($countSql);
    $countStmt->execute($params);
    $total = $countStmt->fetch()['total'];
    
    // Agregar orden y límite
    $sql .= " ORDER BY v.fecha_venta DESC, v.id DESC LIMIT :limit OFFSET :offset";
    
    $stmt = $db->prepare($sql);
    
    // Ejecutar con parámetros
    foreach ($params as $key => $value) {
        $stmt->bindValue($key, $value);
    }
    // Siempre agregar limit y offset
    $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
    $stmt->execute();
    
    $ventas = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Obtener items de cada venta
    foreach ($ventas as &$venta) {
        $itemsSql = "
            SELECT 
                vi.id,
                vi.cantidad,
                vi.precio_unitario,
                vi.subtotal,
                p.nombre as producto_nombre,
                p.categoria as producto_categoria
            FROM venta_items vi
            INNER JOIN productos p ON vi.producto_id = p.id
            WHERE vi.venta_id = :venta_id
        ";
        
        $itemsStmt = $db->prepare($itemsSql);
        $itemsStmt->execute([':venta_id' => $venta['id']]);
        $venta['items'] = $itemsStmt->fetchAll(PDO::FETCH_ASSOC);
    }
    
    echo json_encode([
        'success' => true,
        'ventas' => $ventas,
        'total' => $total,
        'limit' => $limit,
        'offset' => $offset
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
}
?>

