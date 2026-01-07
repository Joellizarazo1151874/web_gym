<?php
/**
 * Obtener lista de clases
 * Endpoint API para obtener todas las clases del sistema
 */

session_start();
header('Content-Type: application/json');
require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/auth.php';

$auth = new Auth();
if (!$auth->isAuthenticated()) {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'message' => 'No autenticado'
    ]);
    exit;
}

try {
    $db = getDB();
    
    // Obtener parámetros opcionales
    $activo = isset($_GET['activo']) ? (int)$_GET['activo'] : null;
    $instructor_id = isset($_GET['instructor_id']) ? (int)$_GET['instructor_id'] : null;
    
    // Construir query
    $sql = "
        SELECT 
            c.*,
            u.nombre as instructor_nombre,
            u.apellido as instructor_apellido,
            u.foto as instructor_foto,
            (SELECT COUNT(*) FROM clase_horarios ch WHERE ch.clase_id = c.id) as total_horarios,
            0 as total_reservas
        FROM clases c
        LEFT JOIN usuarios u ON c.instructor_id = u.id
        WHERE 1=1
    ";
    
    $params = [];
    
    if ($activo !== null) {
        $sql .= " AND c.activo = :activo";
        $params[':activo'] = $activo;
    }
    
    if ($instructor_id !== null) {
        $sql .= " AND c.instructor_id = :instructor_id";
        $params[':instructor_id'] = $instructor_id;
    }
    
    $sql .= " ORDER BY c.nombre ASC";
    
    $stmt = $db->prepare($sql);
    $stmt->execute($params);
    $clases = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo json_encode([
        'success' => true,
        'clases' => $clases
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al obtener las clases: ' . $e->getMessage()
    ]);
}
?>

