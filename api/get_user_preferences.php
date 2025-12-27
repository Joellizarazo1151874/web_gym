<?php
/**
 * API para obtener preferencias de usuario (tema, colores, sidebar, etc.)
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

try {
    $db = getDB();
    $usuario_actual = $auth->getCurrentUser();
    $usuario_id = $usuario_actual['id'];
    
    // Verificar que la tabla existe
    $stmt = $db->query("SHOW TABLES LIKE 'preferencias_usuario'");
    if ($stmt->rowCount() === 0) {
        // Si la tabla no existe, retornar valores por defecto
        echo json_encode([
            'success' => true,
            'preferencias' => [
                'color_mode' => 'light',
                'dir_mode' => 'ltr',
                'sidebar_color' => null,
                'sidebar_type' => null,
                'sidebar_style' => null,
                'navbar_type' => null,
                'color_custom' => null,
                'color_custom_info' => null
            ]
        ]);
        exit;
    }
    
    $stmt = $db->prepare("
        SELECT 
            color_mode,
            dir_mode,
            sidebar_color,
            sidebar_type,
            sidebar_style,
            navbar_type,
            color_custom,
            color_custom_info
        FROM preferencias_usuario
        WHERE usuario_id = :usuario_id
    ");
    
    $stmt->execute([':usuario_id' => $usuario_id]);
    $preferencias = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($preferencias) {
        // Decodificar sidebar_type si es JSON
        if ($preferencias['sidebar_type']) {
            $preferencias['sidebar_type'] = json_decode($preferencias['sidebar_type'], true);
        }
        
        echo json_encode([
            'success' => true,
            'preferencias' => $preferencias
        ]);
    } else {
        // Retornar valores por defecto
        echo json_encode([
            'success' => true,
            'preferencias' => [
                'color_mode' => 'light',
                'dir_mode' => 'ltr',
                'sidebar_color' => null,
                'sidebar_type' => null,
                'sidebar_style' => null,
                'navbar_type' => null,
                'color_custom' => null,
                'color_custom_info' => null
            ]
        ]);
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al obtener preferencias: ' . $e->getMessage()
    ]);
}

