<?php
/**
 * Obtener horarios de clases
 * Endpoint API para obtener los horarios de las clases
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
    $clase_id = isset($_GET['clase_id']) ? (int)$_GET['clase_id'] : null;
    $activo = isset($_GET['activo']) ? (int)$_GET['activo'] : null;
    $dia_semana = isset($_GET['dia_semana']) ? (int)$_GET['dia_semana'] : null;
    
    // Construir query
    $sql = "
        SELECT 
            ch.*,
            c.nombre as clase_nombre,
            c.capacidad_maxima,
            c.duracion_minutos,
            u.nombre as instructor_nombre,
            u.apellido as instructor_apellido,
            CASE ch.dia_semana
                WHEN 1 THEN 'Lunes'
                WHEN 2 THEN 'Martes'
                WHEN 3 THEN 'Miércoles'
                WHEN 4 THEN 'Jueves'
                WHEN 5 THEN 'Viernes'
                WHEN 6 THEN 'Sábado'
                WHEN 7 THEN 'Domingo'
            END as dia_nombre,
            0 as reservas_activas
        FROM clase_horarios ch
        INNER JOIN clases c ON ch.clase_id = c.id
        LEFT JOIN usuarios u ON c.instructor_id = u.id
        WHERE 1=1
    ";
    
    $params = [];
    
    if ($clase_id !== null) {
        $sql .= " AND ch.clase_id = :clase_id";
        $params[':clase_id'] = $clase_id;
    }
    
    if ($activo !== null) {
        $sql .= " AND ch.activo = :activo";
        $params[':activo'] = $activo;
    }
    
    if ($dia_semana !== null) {
        $sql .= " AND ch.dia_semana = :dia_semana";
        $params[':dia_semana'] = $dia_semana;
    }
    
    $sql .= " ORDER BY ch.dia_semana ASC, ch.hora_inicio ASC";
    
    $stmt = $db->prepare($sql);
    $stmt->execute($params);
    $horarios = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo json_encode([
        'success' => true,
        'horarios' => $horarios
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al obtener los horarios: ' . $e->getMessage()
    ]);
}
?>

