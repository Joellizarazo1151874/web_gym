<?php
/**
 * Obtener posts de la comunidad
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept, Cookie, X-Session-ID');
header('Access-Control-Allow-Credentials: true');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/auth.php';

// Restaurar sesión desde header
restoreSessionFromHeader();

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

$auth = new Auth();
if (!$auth->isAuthenticated()) {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'message' => 'No autenticado',
    ]);
    exit;
}

try {
    $db = getDB();
    $usuarioId = $_SESSION['usuario_id'] ?? null;

    $limite = isset($_GET['limite']) ? (int)$_GET['limite'] : 50;
    $offset = isset($_GET['offset']) ? (int)$_GET['offset'] : 0;

    $sql = "
        SELECT 
            p.id,
            p.usuario_id,
            p.contenido,
            p.imagen_url,
            p.creado_en,
            u.nombre,
            u.apellido,
            (SELECT COUNT(*) FROM post_likes pl WHERE pl.post_id = p.id) AS likes_count,
            EXISTS(
                SELECT 1 FROM post_likes pl2 
                WHERE pl2.post_id = p.id AND pl2.usuario_id = :usuario_id
            ) AS liked_by_current
        FROM posts p
        INNER JOIN usuarios u ON u.id = p.usuario_id
        WHERE p.activo = 1
        ORDER BY p.creado_en DESC
        LIMIT :limite OFFSET :offset
    ";

    $stmt = $db->prepare($sql);
    $stmt->bindValue(':usuario_id', $usuarioId, PDO::PARAM_INT);
    $stmt->bindValue(':limite', $limite, PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
    $stmt->execute();

    $posts = $stmt->fetchAll(PDO::FETCH_ASSOC);

    foreach ($posts as &$post) {
        $post['likes_count'] = (int)$post['likes_count'];
        $post['liked_by_current'] = (bool)$post['liked_by_current'];
        $post['usuario_nombre'] = trim(($post['nombre'] ?? '') . ' ' . ($post['apellido'] ?? ''));
        $post['hace'] = getTimeAgo($post['creado_en']);
    }

    echo json_encode([
        'success' => true,
        'posts' => $posts,
        'total' => count($posts),
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al obtener posts: ' . $e->getMessage(),
    ]);
}

function getTimeAgo($datetime)
{
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

