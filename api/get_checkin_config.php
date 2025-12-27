<?php
/**
 * API para obtener la configuración de ingreso
 * Esta API es pública (no requiere autenticación) ya que la página de ingreso es pública
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

require_once __DIR__ . '/../database/config.php';

try {
    $db = getDB();
    
    // Configuración por defecto
    $config = [
        'qr_auto_enabled' => false,
        'manual_enabled' => true,
        'sound_enabled' => true,
        'vibration_enabled' => true,
        'auto_reset_seconds' => 10
    ];
    
    // Obtener configuración de la base de datos
    $stmt = $db->prepare("SELECT clave, valor FROM configuracion WHERE clave LIKE 'checkin_%'");
    $stmt->execute();
    $configs = $stmt->fetchAll(PDO::FETCH_KEY_PAIR);
    
    foreach ($configs as $key => $value) {
        $shortKey = str_replace('checkin_', '', $key);
        if (isset($config[$shortKey])) {
            // Convert string to appropriate type
            if (in_array($shortKey, ['qr_auto_enabled', 'manual_enabled', 'sound_enabled', 'vibration_enabled'])) {
                $config[$shortKey] = ($value === '1' || $value === 'true');
            } else {
                $config[$shortKey] = (int)$value;
            }
        }
    }
    
    echo json_encode([
        'success' => true,
        'config' => $config
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al obtener configuración',
        'config' => [
            'qr_auto_enabled' => false,
            'manual_enabled' => true,
            'sound_enabled' => true,
            'vibration_enabled' => true,
            'auto_reset_seconds' => 10
        ]
    ]);
}

