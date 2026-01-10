<?php
/**
 * Reportar un post. Si llega a 5 reportes, se desactiva automáticamente.
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
            'message' => 'Post inválido',
        ]);
        exit;
    }

    // Verificar que el post existe y está activo
    $stmtPost = $db->prepare("SELECT usuario_id FROM posts WHERE id = :id AND activo = 1");
    $stmtPost->execute([':id' => $postId]);
    $post = $stmtPost->fetch(PDO::FETCH_ASSOC);
    if (!$post) {
        echo json_encode([
            'success' => false,
            'message' => 'El post no existe o ya fue eliminado',
        ]);
        exit;
    }

    // Evitar que el mismo autor se auto-reporta (opcional)
    if ((int)$post['usuario_id'] === (int)$usuarioId) {
        echo json_encode([
            'success' => false,
            'message' => 'No puedes reportar tu propio post',
        ]);
        exit;
    }

    // Registrar reporte si no existe
    $stmtExists = $db->prepare("
        SELECT 1 FROM post_reports 
        WHERE post_id = :post_id AND usuario_id = :usuario_id
    ");
    $stmtExists->execute([
        ':post_id' => $postId,
        ':usuario_id' => $usuarioId,
    ]);

    if (!$stmtExists->fetch()) {
        $stmtIns = $db->prepare("
            INSERT INTO post_reports (post_id, usuario_id, creado_en)
            VALUES (:post_id, :usuario_id, NOW())
        ");
        $stmtIns->execute([
            ':post_id' => $postId,
            ':usuario_id' => $usuarioId,
        ]);
    }

    // Contar reportes
    $stmtCount = $db->prepare("
        SELECT COUNT(*) AS total 
        FROM post_reports 
        WHERE post_id = :post_id
    ");
    $stmtCount->execute([':post_id' => $postId]);
    $row = $stmtCount->fetch(PDO::FETCH_ASSOC);
    $totalReportes = (int)($row['total'] ?? 0);

    $deleted = false;
    if ($totalReportes >= 5) {
        // Desactivar post automáticamente
        $stmtDel = $db->prepare("
            UPDATE posts 
            SET activo = 0 
            WHERE id = :id
        ");
        $stmtDel->execute([':id' => $postId]);
        $deleted = true;
    }

    echo json_encode([
        'success' => true,
        'message' => $deleted
            ? 'El post ha sido eliminado automáticamente por múltiples reportes.'
            : 'Reporte enviado. Gracias por ayudarnos a moderar el contenido.',
        'deleted' => $deleted,
        'total_reportes' => $totalReportes,
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al reportar post: ' . $e->getMessage(),
    ]);
}

