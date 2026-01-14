<?php
/**
 * Marcar notificación como leída
 * Endpoint API para marcar una o todas las notificaciones como leídas
 */

// Headers para CORS y JSON
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
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

// Solo permitir POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Método no permitido'
    ]);
    exit;
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
    
    if (!$usuario_id) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Usuario no identificado'
        ]);
        exit;
    }
    
    // Verificar si existe la tabla notificaciones_leidas, si no, crearla
    $table_exists = $db->query("SHOW TABLES LIKE 'notificaciones_leidas'")->rowCount() > 0;
    if (!$table_exists) {
        // Crear la tabla si no existe
        $db->exec("
            CREATE TABLE IF NOT EXISTS notificaciones_leidas (
                id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                notificacion_id INT UNSIGNED NOT NULL,
                usuario_id INT UNSIGNED NOT NULL,
                fecha_leida TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE KEY unique_notificacion_usuario (notificacion_id, usuario_id),
                INDEX idx_usuario_id (usuario_id),
                INDEX idx_notificacion_id (notificacion_id)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ");
    }
    
    $data = json_decode(file_get_contents('php://input'), true);
    
    // Aceptar tanto 'id' como 'notificacion_id' para compatibilidad
    $notificacion_id = null;
    if (isset($data['id'])) {
        $notificacion_id = (int)$data['id'];
    } elseif (isset($data['notificacion_id'])) {
        $notificacion_id = (int)$data['notificacion_id'];
    }
    
    $marcar_todas = isset($data['marcar_todas']) && $data['marcar_todas'] === true;
    
    if ($marcar_todas) {
        // Obtener todas las notificaciones no leídas del usuario (específicas + globales)
        $stmt_get = $db->prepare("
            SELECT id 
            FROM notificaciones 
            WHERE (usuario_id = :usuario_id OR usuario_id IS NULL) 
            AND id NOT IN (
                SELECT notificacion_id 
                FROM notificaciones_leidas 
                WHERE usuario_id = :usuario_id
            )
        ");
        $stmt_get->execute([':usuario_id' => $usuario_id]);
        $notificaciones = $stmt_get->fetchAll(PDO::FETCH_COLUMN);
        
        $affected = 0;
        foreach ($notificaciones as $notif_id) {
            // Para notificaciones específicas del usuario, actualizar el campo leida
            $stmt_check = $db->prepare("SELECT usuario_id FROM notificaciones WHERE id = :id");
            $stmt_check->execute([':id' => $notif_id]);
            $notif_data = $stmt_check->fetch(PDO::FETCH_ASSOC);
            
            if ($notif_data && $notif_data['usuario_id'] == $usuario_id) {
                // Notificación específica: actualizar campo leida
                $stmt_update = $db->prepare("
                    UPDATE notificaciones 
                    SET leida = 1, fecha_leida = NOW()
                    WHERE id = :id AND usuario_id = :usuario_id
                ");
                $stmt_update->execute([':id' => $notif_id, ':usuario_id' => $usuario_id]);
            }
            
            // Para todas las notificaciones (específicas y globales), registrar en notificaciones_leidas
            $stmt_insert = $db->prepare("
                INSERT IGNORE INTO notificaciones_leidas (notificacion_id, usuario_id, fecha_leida)
                VALUES (:notificacion_id, :usuario_id, NOW())
            ");
            $stmt_insert->execute([
                ':notificacion_id' => $notif_id,
                ':usuario_id' => $usuario_id
            ]);
            $affected++;
        }
        
        echo json_encode([
            'success' => true,
            'message' => "Se marcaron $affected notificaciones como leídas"
        ]);
    } elseif ($notificacion_id) {
        // Verificar que la notificación existe y pertenece al usuario o es global
        $stmt_check = $db->prepare("
            SELECT id, usuario_id 
            FROM notificaciones 
            WHERE id = :id AND (usuario_id = :usuario_id OR usuario_id IS NULL)
        ");
        $stmt_check->execute([
            ':id' => $notificacion_id,
            ':usuario_id' => $usuario_id
        ]);
        $notif = $stmt_check->fetch(PDO::FETCH_ASSOC);
        
        if (!$notif) {
            http_response_code(404);
            echo json_encode([
                'success' => false,
                'message' => 'Notificación no encontrada'
            ]);
            exit;
        }
        
        // Si es una notificación específica del usuario, actualizar el campo leida
        if ($notif['usuario_id'] == $usuario_id) {
            $stmt_update = $db->prepare("
                UPDATE notificaciones 
                SET leida = 1, fecha_leida = NOW()
                WHERE id = :id AND usuario_id = :usuario_id
            ");
            $stmt_update->execute([
                ':id' => $notificacion_id,
                ':usuario_id' => $usuario_id
            ]);
        }
        
        // Registrar en notificaciones_leidas (para específicas y globales)
        $stmt_insert = $db->prepare("
            INSERT INTO notificaciones_leidas (notificacion_id, usuario_id, fecha_leida)
            VALUES (:notificacion_id, :usuario_id, NOW())
            ON DUPLICATE KEY UPDATE fecha_leida = NOW()
        ");
        $stmt_insert->execute([
            ':notificacion_id' => $notificacion_id,
            ':usuario_id' => $usuario_id
        ]);
        
        echo json_encode([
            'success' => true,
            'message' => 'Notificación marcada como leída'
        ]);
    } else {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Debe proporcionar un ID de notificación o marcar todas'
        ]);
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al marcar notificación: ' . $e->getMessage()
    ]);
}

