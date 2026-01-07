<?php
/**
 * Obtener una clase específica
 * Endpoint API para obtener los detalles de una clase
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
    
    $clase_id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
    
    if ($clase_id <= 0) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'ID de clase inválido'
        ]);
        exit;
    }
    
    // Obtener clase con información del instructor
    $stmt = $db->prepare("
        SELECT 
            c.*,
            u.nombre as instructor_nombre,
            u.apellido as instructor_apellido,
            u.foto as instructor_foto,
            u.email as instructor_email
        FROM clases c
        LEFT JOIN usuarios u ON c.instructor_id = u.id
        WHERE c.id = :id
    ");
    
    $stmt->execute([':id' => $clase_id]);
    $clase = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$clase) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Clase no encontrada'
        ]);
        exit;
    }
    
    // Obtener horarios de la clase
    $stmt = $db->prepare("
        SELECT 
            ch.*,
            CASE ch.dia_semana
                WHEN 1 THEN 'Lunes'
                WHEN 2 THEN 'Martes'
                WHEN 3 THEN 'Miércoles'
                WHEN 4 THEN 'Jueves'
                WHEN 5 THEN 'Viernes'
                WHEN 6 THEN 'Sábado'
                WHEN 7 THEN 'Domingo'
            END as dia_nombre
        FROM clase_horarios ch
        WHERE ch.clase_id = :clase_id
        ORDER BY ch.dia_semana ASC, ch.hora_inicio ASC
    ");
    
    $stmt->execute([':clase_id' => $clase_id]);
    $horarios = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    $clase['horarios'] = $horarios;
    
    echo json_encode([
        'success' => true,
        'clase' => $clase
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al obtener la clase: ' . $e->getMessage()
    ]);
}
?>

