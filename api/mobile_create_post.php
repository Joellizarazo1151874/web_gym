<?php
/**
 * Crear un nuevo post
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept, Cookie, X-Session-ID');
header('Access-Control-Allow-Credentials: true');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/auth.php';

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

    $input = json_decode(file_get_contents('php://input'), true);
    if (!is_array($input)) {
        $input = $_POST;
    }

    $contenido = trim($input['contenido'] ?? '');
    $imagenUrl = isset($input['imagen_url']) ? trim($input['imagen_url']) : null;

    if ($contenido === '') {
        echo json_encode([
            'success' => false,
            'message' => 'El contenido del post es obligatorio',
        ]);
        exit;
    }

    // Verificar si hay más de 100 posts activos
    $stmtCount = $db->query("SELECT COUNT(*) as total FROM posts WHERE activo = 1");
    $totalPosts = (int)$stmtCount->fetch(PDO::FETCH_ASSOC)['total'];
    
    if ($totalPosts >= 100) {
        // Obtener el post más antiguo
        $stmtOldest = $db->query("
            SELECT id, imagen_url 
            FROM posts 
            WHERE activo = 1 
            ORDER BY creado_en ASC 
            LIMIT 1
        ");
        $oldestPost = $stmtOldest->fetch(PDO::FETCH_ASSOC);
        
        if ($oldestPost) {
            // Eliminar imagen física si existe
            if (!empty($oldestPost['imagen_url'])) {
                $fileName = basename($oldestPost['imagen_url']);
                $filePath = __DIR__ . '/../uploads/posts/' . $fileName;
                if (file_exists($filePath)) {
                    unlink($filePath);
                }
            }
            
            // Desactivar el post más antiguo
            $stmtDel = $db->prepare("UPDATE posts SET activo = 0 WHERE id = :id");
            $stmtDel->execute([':id' => $oldestPost['id']]);
        }
    }

    // Insertar nuevo post
    $stmt = $db->prepare("
        INSERT INTO posts (usuario_id, contenido, imagen_url, creado_en, activo)
        VALUES (:usuario_id, :contenido, :imagen_url, NOW(), 1)
    ");
    $stmt->execute([
        ':usuario_id' => $usuarioId,
        ':contenido' => $contenido,
        ':imagen_url' => $imagenUrl !== '' ? $imagenUrl : null,
    ]);

    $postId = (int)$db->lastInsertId();

    $stmtPost = $db->prepare("
        SELECT 
            p.id,
            p.usuario_id,
            p.contenido,
            p.imagen_url,
            p.creado_en,
            u.nombre,
            u.apellido,
            0 AS likes_count,
            0 AS liked_by_current
        FROM posts p
        INNER JOIN usuarios u ON u.id = p.usuario_id
        WHERE p.id = :id
    ");
    $stmtPost->execute([':id' => $postId]);
    $post = $stmtPost->fetch(PDO::FETCH_ASSOC);

    if ($post) {
        $post['likes_count'] = 0;
        $post['liked_by_current'] = false;
        $post['usuario_nombre'] = trim(($post['nombre'] ?? '') . ' ' . ($post['apellido'] ?? ''));
        $post['hace'] = 'Hace un momento';
    }

    echo json_encode([
        'success' => true,
        'message' => 'Post creado correctamente',
        'post' => $post,
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al crear post: ' . $e->getMessage(),
    ]);
}

