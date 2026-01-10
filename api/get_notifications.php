<?php
/**
 * Obtener notificaciones del usuario
 * Endpoint API para obtener las notificaciones de un usuario (dashboard y app móvil)
 */

// Headers para CORS y JSON
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept, Cookie, X-Session-ID');
header('Access-Control-Allow-Credentials: true');

// Manejar preflight OPTIONS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Incluir dependencias primero
require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/auth.php';

// Intentar restaurar sesión desde header X-Session-ID (para apps móviles)
restoreSessionFromHeader();

// Iniciar sesión (necesario para la clase Auth)
// Si restoreSessionFromHeader() ya inició la sesión, esto no hará nada
if (session_status() === PHP_SESSION_NONE) {
    session_start();
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
                fecha_leida,
                created_at
            FROM notificaciones
            WHERE (usuario_id = :usuario_id OR usuario_id IS NULL)";
    
    if ($solo_no_leidas) {
        $sql .= " AND leida = 0";
    } else {
        // Excluir notificaciones leídas que tengan más de 5 minutos desde fecha_leida
        // Solo para el header (cuando se cargan todas, no solo no leídas)
        $sql .= " AND (leida = 0 OR (leida = 1 AND fecha_leida IS NOT NULL AND fecha_leida >= DATE_SUB(NOW(), INTERVAL 5 MINUTE)))";
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
        // Incluir fecha_leida si existe (formato ISO para JavaScript)
        if (isset($notif['fecha_leida']) && $notif['fecha_leida']) {
            $notif['fecha_leida'] = date('c', strtotime($notif['fecha_leida'])); // Formato ISO 8601
        }
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

