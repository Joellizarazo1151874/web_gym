<?php
/**
 * Buscar usuarios para la caja
 */
session_start();
header('Content-Type: application/json');
require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/auth.php';

try {
    $auth = new Auth();
    if (!$auth->isAuthenticated() || !$auth->hasRole(['admin', 'entrenador', 'empleado'])) {
        http_response_code(403);
        echo json_encode(['success' => false, 'message' => 'No autorizado']);
        exit;
    }
    
    $search = trim($_GET['search'] ?? '');
    
    $db = getDB();
    
    // Para la caja: buscar usuarios activos e inactivos (pueden comprar membresías)
    // Excluir suspendidos (no pueden comprar membresías)
    // Verificar si tienen membresía activa
    $sql = "SELECT 
                u.id, 
                u.nombre, 
                u.apellido, 
                u.email, 
                u.documento, 
                u.telefono, 
                u.estado,
                m.id as membresia_id,
                m.estado as membresia_estado,
                m.fecha_fin as membresia_fecha_fin,
                p.nombre as plan_nombre,
                CASE 
                    WHEN m.id IS NOT NULL 
                         AND m.estado = 'activa' 
                         AND m.fecha_fin >= CURDATE() 
                    THEN 1 
                    ELSE 0 
                END as tiene_membresia_activa
            FROM usuarios u
            LEFT JOIN membresias m ON u.id = m.usuario_id 
                AND m.estado = 'activa' 
                AND m.fecha_fin >= CURDATE()
            LEFT JOIN planes p ON m.plan_id = p.id
            WHERE u.estado != 'suspendido'";
    
    $params = [];
    
    if (!empty($search)) {
        $searchTerm = '%' . $search . '%';
        // Búsqueda más flexible: nombre completo, documento exacto o parcial, email, teléfono
        // La tabla ya tiene COLLATE utf8mb4_unicode_ci, así que las búsquedas son case-insensitive
        $sql .= " AND (
            CONCAT(u.nombre, ' ', u.apellido) LIKE :search1 
            OR u.nombre LIKE :search2 
            OR u.apellido LIKE :search3 
            OR u.email LIKE :search4 
            OR u.documento LIKE :search5 
            OR u.telefono LIKE :search6
        )";
        $params[':search1'] = $searchTerm;
        $params[':search2'] = $searchTerm;
        $params[':search3'] = $searchTerm;
        $params[':search4'] = $searchTerm;
        $params[':search5'] = $searchTerm;
        $params[':search6'] = $searchTerm;
    }
    
    // Ordenar: primero los que tienen membresía activa, luego por estado (activo > inactivo), luego por nombre
    $sql .= " ORDER BY 
        tiene_membresia_activa DESC,
        CASE u.estado 
            WHEN 'activo' THEN 1 
            WHEN 'inactivo' THEN 2 
        END,
        u.nombre, u.apellido ASC 
        LIMIT 20";
    
    $stmt = $db->prepare($sql);
    $stmt->execute($params);
    $usuarios = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Log para debugging (solo en desarrollo)
    if (!empty($search)) {
        error_log("Búsqueda de usuarios - Término: '$search', Encontrados: " . count($usuarios));
        if (count($usuarios) > 0) {
            $estados = array_column($usuarios, 'estado');
            error_log("Estados encontrados: " . implode(', ', array_unique($estados)));
        } else {
            // Si no encuentra nada, verificar si existe el usuario sin el filtro de búsqueda
            $checkSql = "SELECT id, nombre, apellido, documento, estado FROM usuarios WHERE documento = :doc LIMIT 1";
            $checkStmt = $db->prepare($checkSql);
            $checkStmt->execute([':doc' => $search]);
            $checkUser = $checkStmt->fetch(PDO::FETCH_ASSOC);
            if ($checkUser) {
                error_log("Usuario encontrado por documento exacto pero no por LIKE - Estado: " . $checkUser['estado']);
            }
        }
    }
    
    // Formatear datos
    $usuarios_formateados = [];
    foreach ($usuarios as $usuario) {
        $nombreCompleto = trim(($usuario['nombre'] ?? '') . ' ' . ($usuario['apellido'] ?? ''));
        $estado = $usuario['estado'] ?? 'activo';
        $tieneMembresiaActiva = (bool)($usuario['tiene_membresia_activa'] ?? false);
        $membresiaFechaFin = $usuario['membresia_fecha_fin'] ?? null;
        $planNombre = $usuario['plan_nombre'] ?? null;
        
        $usuarios_formateados[] = [
            'id' => (int)$usuario['id'],
            'nombre' => $usuario['nombre'] ?? '',
            'apellido' => $usuario['apellido'] ?? '',
            'email' => $usuario['email'] ?? '',
            'documento' => $usuario['documento'] ?? '',
            'telefono' => $usuario['telefono'] ?? '',
            'estado' => $estado,
            'nombre_completo' => $nombreCompleto,
            'tiene_membresia_activa' => $tieneMembresiaActiva,
            'membresia_fecha_fin' => $membresiaFechaFin,
            'plan_nombre' => $planNombre
        ];
    }
    
    echo json_encode([
        'success' => true,
        'usuarios' => $usuarios_formateados,
        'count' => count($usuarios_formateados)
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    
} catch (PDOException $e) {
    http_response_code(500);
    error_log("Error PDO en search_users_cash.php: " . $e->getMessage());
    echo json_encode([
        'success' => false, 
        'message' => 'Error de base de datos: ' . $e->getMessage()
    ]);
} catch (Exception $e) {
    http_response_code(500);
    error_log("Error en search_users_cash.php: " . $e->getMessage());
    echo json_encode([
        'success' => false, 
        'message' => 'Error al buscar usuarios: ' . $e->getMessage()
    ]);
}
?>

