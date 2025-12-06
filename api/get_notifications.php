<?php
/**
 * Obtener notificaciones del usuario
 * Endpoint API para obtener las notificaciones de un usuario (dashboard y app móvil)
 */

session_start();
header('Content-Type: application/json');
require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/auth.php';

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

try {
    $db = getDB();
    $usuario_id = $_SESSION['usuario_id'] ?? null;
    
    // Parámetros opcionales
    $solo_no_leidas = isset($_GET['solo_no_leidas']) && $_GET['solo_no_leidas'] === '1';
    $limite = isset($_GET['limite']) ? (int)$_GET['limite'] : 50;
    $offset = isset($_GET['offset']) ? (int)$_GET['offset'] : 0;
    
    // Construir consulta
    $sql = "SELECT 
                id,
                titulo,
                mensaje,
                tipo,
                leida,
                fecha,
                created_at
            FROM notificaciones
            WHERE (usuario_id = :usuario_id OR usuario_id IS NULL)";
    
    if ($solo_no_leidas) {
        $sql .= " AND leida = 0";
    }
    
    $sql .= " ORDER BY fecha DESC, created_at DESC LIMIT :limite OFFSET :offset";
    
    $stmt = $db->prepare($sql);
    $stmt->bindValue(':usuario_id', $usuario_id, PDO::PARAM_INT);
    $stmt->bindValue(':limite', $limite, PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
    $stmt->execute();
    
    $notificaciones = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Formatear fechas
    foreach ($notificaciones as &$notif) {
        $notif['leida'] = (bool)$notif['leida'];
        $notif['fecha_formateada'] = date('d/m/Y H:i', strtotime($notif['fecha']));
        $notif['hace'] = getTimeAgo($notif['fecha']);
    }
    
    // Obtener total de no leídas
    $stmt_count = $db->prepare("
        SELECT COUNT(*) as total 
        FROM notificaciones 
        WHERE (usuario_id = :usuario_id OR usuario_id IS NULL) AND leida = 0
    ");
    $stmt_count->execute([':usuario_id' => $usuario_id]);
    $total_no_leidas = $stmt_count->fetch()['total'];
    
    echo json_encode([
        'success' => true,
        'notificaciones' => $notificaciones,
        'total_no_leidas' => (int)$total_no_leidas,
        'total' => count($notificaciones)
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al obtener notificaciones: ' . $e->getMessage()
    ]);
}

/**
 * Función helper para calcular tiempo relativo
 */
function getTimeAgo($datetime) {
    $timestamp = strtotime($datetime);
    $diff = time() - $timestamp;
    
    if ($diff < 60) {
        return 'Hace un momento';
    } elseif ($diff < 3600) {
        $mins = floor($diff / 60);
        return "Hace $mins minuto" . ($mins > 1 ? 's' : '');
    } elseif ($diff < 86400) {
        $hours = floor($diff / 3600);
        return "Hace $hours hora" . ($hours > 1 ? 's' : '');
    } elseif ($diff < 604800) {
        $days = floor($diff / 86400);
        return "Hace $days día" . ($days > 1 ? 's' : '');
    } else {
        return date('d/m/Y', $timestamp);
    }
}

