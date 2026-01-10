<?php
/**
 * Actualizar contenido de un post (solo autor)
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
    $contenido = trim($input['contenido'] ?? '');

    if ($postId <= 0 || $contenido === '') {
        echo json_encode([
            'success' => false,
            'message' => 'Datos incompletos',
        ]);
        exit;
    }

    // Verificar que el post pertenece al usuario
    $stmtCheck = $db->prepare("
        SELECT id FROM posts 
        WHERE id = :id AND usuario_id = :usuario_id AND activo = 1
    ");
    $stmtCheck->execute([
        ':id' => $postId,
        ':usuario_id' => $usuarioId,
    ]);
    if (!$stmtCheck->fetch()) {
        http_response_code(403);
        echo json_encode([
            'success' => false,
            'message' => 'No tienes permiso para editar este post',
        ]);
        exit;
    }

    $stmtUpdate = $db->prepare("
        UPDATE posts 
        SET contenido = :contenido, actualizado_en = NOW()
        WHERE id = :id
    ");
    $stmtUpdate->execute([
        ':contenido' => $contenido,
        ':id' => $postId,
    ]);

    echo json_encode([
        'success' => true,
        'message' => 'Post actualizado correctamente',
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al actualizar post: ' . $e->getMessage(),
    ]);
}

