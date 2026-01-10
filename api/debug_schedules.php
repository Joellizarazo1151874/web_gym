<?php
/**
 * Script de debug para verificar horarios directamente desde la base de datos
 * Acceder desde: https://functionaltraining.site/api/debug_schedules.php
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

require_once __DIR__ . '/../database/config.php';

try {
    $db = getDB();
    
    // Obtener TODOS los horarios sin filtros
    $stmt = $db->query("
        SELECT 
            ch.id,
            ch.clase_id,
            ch.dia_semana,
            ch.hora_inicio,
            ch.hora_fin,
            ch.activo,
            c.nombre as clase_nombre,
            c.activo as clase_activa,
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
        INNER JOIN clases c ON ch.clase_id = c.id
        ORDER BY ch.dia_semana ASC, ch.hora_inicio ASC
    ");
    $allSchedules = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Obtener solo horarios activos
    $stmt = $db->query("
        SELECT 
            ch.id,
            ch.clase_id,
            ch.dia_semana,
            ch.hora_inicio,
            ch.hora_fin,
            ch.activo,
            c.nombre as clase_nombre,
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
        INNER JOIN clases c ON ch.clase_id = c.id
        WHERE ch.activo = 1
        ORDER BY ch.dia_semana ASC, ch.hora_inicio ASC
    ");
    $activeSchedules = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Obtener todas las clases
    $stmt = $db->query("
        SELECT 
            c.*,
            (SELECT COUNT(*) FROM clase_horarios ch WHERE ch.clase_id = c.id) as total_horarios,
            (SELECT COUNT(*) FROM clase_horarios ch WHERE ch.clase_id = c.id AND ch.activo = 1) as horarios_activos
        FROM clases c
        ORDER BY c.nombre ASC
    ");
    $allClasses = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Información del día actual
    $today = new DateTime();
    $todayWeekday = (int)$today->format('N'); // 1=Lunes, 7=Domingo
    $dayNames = [
        1 => 'Lunes',
        2 => 'Martes',
        3 => 'Miércoles',
        4 => 'Jueves',
        5 => 'Viernes',
        6 => 'Sábado',
        7 => 'Domingo'
    ];
    
    // Calcular próximos 7 días
    $next7Days = [];
    for ($i = 0; $i < 7; $i++) {
        $date = clone $today;
        $date->modify("+$i days");
        $next7Days[] = [
            'fecha' => $date->format('Y-m-d'),
            'dia_semana' => (int)$date->format('N'),
            'dia_nombre' => $dayNames[(int)$date->format('N')],
        ];
    }
    
    // Verificar qué horarios coinciden con los próximos 7 días
    $matchingSchedules = [];
    foreach ($activeSchedules as $schedule) {
        foreach ($next7Days as $day) {
            if ($day['dia_semana'] == $schedule['dia_semana']) {
                $matchingSchedules[] = [
                    'fecha' => $day['fecha'],
                    'dia_nombre' => $day['dia_nombre'],
                    'horario' => $schedule,
                ];
            }
        }
    }
    
    echo json_encode([
        'success' => true,
        'debug_info' => [
            'fecha_actual' => $today->format('Y-m-d H:i:s'),
            'dia_semana_actual' => $todayWeekday,
            'dia_nombre_actual' => $dayNames[$todayWeekday],
        ],
        'estadisticas' => [
            'total_clases' => count($allClasses),
            'total_horarios' => count($allSchedules),
            'horarios_activos' => count($activeSchedules),
            'horarios_coinciden_proximos_7_dias' => count($matchingSchedules),
        ],
        'proximos_7_dias' => $next7Days,
        'horarios_que_coinciden' => $matchingSchedules,
        'clases' => $allClasses,
        'horarios_todos' => $allSchedules,
        'horarios_activos' => $activeSchedules,
    ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage(),
        'trace' => $e->getTraceAsString()
    ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
}
?>

