<?php
/**
 * Dar/Quitar like a un post
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

    $postId = isset($input['post_id']) ? (int)$input['post_id'] : 0;
    if ($postId <= 0) {
        echo json_encode([
            'success' => false,
            'message' => 'ID de post inválido',
        ]);
        exit;
    }

    // Verificar si ya tiene like
    $stmtCheck = $db->prepare("
        SELECT id FROM post_likes 
        WHERE post_id = :post_id AND usuario_id = :usuario_id
    ");
    $stmtCheck->execute([
        ':post_id' => $postId,
        ':usuario_id' => $usuarioId,
    ]);
    $like = $stmtCheck->fetch(PDO::FETCH_ASSOC);

    $liked = false;
    if ($like) {
        // Quitar like
        $stmtDel = $db->prepare("DELETE FROM post_likes WHERE id = :id");
        $stmtDel->execute([':id' => $like['id']]);
        $liked = false;
    } else {
        // Dar like
        $stmtIns = $db->prepare("
            INSERT INTO post_likes (post_id, usuario_id, creado_en)
            VALUES (:post_id, :usuario_id, NOW())
        ");
        $stmtIns->execute([
            ':post_id' => $postId,
            ':usuario_id' => $usuarioId,
        ]);
        $liked = true;
    }

    // Recalcular cantidad de likes
    $stmtCount = $db->prepare("
        SELECT COUNT(*) AS total FROM post_likes WHERE post_id = :post_id
    ");
    $stmtCount->execute([':post_id' => $postId]);
    $row = $stmtCount->fetch(PDO::FETCH_ASSOC);
    $likesCount = (int)($row['total'] ?? 0);

    echo json_encode([
        'success' => true,
        'liked' => $liked,
        'likes_count' => $likesCount,
        'message' => $liked ? 'Like agregado' : 'Like eliminado',
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al procesar like: ' . $e->getMessage(),
    ]);
}

