<?php
/**
 * API para guardar preferencias de usuario (tema, colores, sidebar, etc.)
 */
// Desactivar errores de visualización para evitar HTML en la respuesta JSON
error_reporting(E_ALL);
ini_set('display_errors', 0);

session_start();
header('Content-Type: application/json');

require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/auth.php';

// Verificar autenticación
$auth = new Auth();
if (!$auth->isAuthenticated()) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'No autenticado']);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Método no permitido']);
    exit;
}

try {
    $db = getDB();
    $usuario_actual = $auth->getCurrentUser();
    $usuario_id = $usuario_actual['id'];
    
    // Verificar que la tabla existe
    $stmt = $db->query("SHOW TABLES LIKE 'preferencias_usuario'");
    if ($stmt->rowCount() === 0) {
        throw new Exception('La tabla preferencias_usuario no existe. Ejecuta la migración: database/migrations/add_preferencias_usuario.sql');
    }
    
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!$data) {
        throw new Exception('Datos inválidos');
    }
    
    // Preparar datos para insertar/actualizar
    $color_mode = $data['color_mode'] ?? 'light';
    $dir_mode = $data['dir_mode'] ?? 'ltr';
    $sidebar_color = $data['sidebar_color'] ?? null;
    $sidebar_type = isset($data['sidebar_type']) ? json_encode($data['sidebar_type']) : null;
    $sidebar_style = $data['sidebar_style'] ?? null;
    $navbar_type = $data['navbar_type'] ?? null;
    $color_custom = $data['color_custom'] ?? null;
    $color_custom_info = $data['color_custom_info'] ?? null;
    
    // Verificar si ya existe una preferencia para este usuario
    $stmt = $db->prepare("SELECT id FROM preferencias_usuario WHERE usuario_id = :usuario_id");
    $stmt->execute([':usuario_id' => $usuario_id]);
    $existe = $stmt->fetch();
    
    if ($existe) {
        // Actualizar
        $stmt = $db->prepare("
            UPDATE preferencias_usuario 
            SET color_mode = :color_mode,
                dir_mode = :dir_mode,
                sidebar_color = :sidebar_color,
                sidebar_type = :sidebar_type,
                sidebar_style = :sidebar_style,
                navbar_type = :navbar_type,
                color_custom = :color_custom,
                color_custom_info = :color_custom_info,
                updated_at = CURRENT_TIMESTAMP
            WHERE usuario_id = :usuario_id
        ");
    } else {
        // Insertar
        $stmt = $db->prepare("
            INSERT INTO preferencias_usuario 
            (usuario_id, color_mode, dir_mode, sidebar_color, sidebar_type, sidebar_style, navbar_type, color_custom, color_custom_info)
            VALUES 
            (:usuario_id, :color_mode, :dir_mode, :sidebar_color, :sidebar_type, :sidebar_style, :navbar_type, :color_custom, :color_custom_info)
        ");
    }
    
    $stmt->execute([
        ':usuario_id' => $usuario_id,
        ':color_mode' => $color_mode,
        ':dir_mode' => $dir_mode,
        ':sidebar_color' => $sidebar_color,
        ':sidebar_type' => $sidebar_type,
        ':sidebar_style' => $sidebar_style,
        ':navbar_type' => $navbar_type,
        ':color_custom' => $color_custom,
        ':color_custom_info' => $color_custom_info
    ]);
    
    echo json_encode([
        'success' => true,
        'message' => 'Preferencias guardadas correctamente'
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al guardar preferencias: ' . $e->getMessage()
    ]);
}

