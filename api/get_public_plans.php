<?php
/**
 * Obtener planes públicos para la landing page
 * Este endpoint es público y no requiere autenticación
 */
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');

// Prevenir errores de salida antes del JSON
error_reporting(E_ALL);
ini_set('display_errors', 0);

try {
    require_once __DIR__ . '/../database/config.php';
    require_once __DIR__ . '/../database/config_helpers.php';
    
    $db = getDB();
    
    // Obtener el descuento de la configuración
    $descuentoApp = getAppDescuento();
    
    // Obtener solo planes activos
    $sql = "SELECT id, nombre, descripcion, duracion_dias, precio, precio_app, tipo 
            FROM planes 
            WHERE activo = 1 
            ORDER BY 
                CASE tipo 
                    WHEN 'día' THEN 1
                    WHEN 'semana' THEN 2
                    WHEN 'mes' THEN 3
                    WHEN 'anual' THEN 4
                    ELSE 5
                END,
                duracion_dias ASC";
    
    $stmt = $db->prepare($sql);
    $stmt->execute();
    $planes = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Formatear datos
    foreach ($planes as &$plan) {
        // Formatear precios
        $plan['precio_formateado'] = '$' . number_format($plan['precio'], 0, ',', '.');
        $plan['precio_app_formateado'] = '$' . number_format($plan['precio_app'], 0, ',', '.');
        
        // Usar el descuento de la configuración en lugar de calcularlo
        // Solo mostrar descuento si el plan tiene precio_app configurado y es menor que el precio
        if ($plan['precio'] > 0 && $plan['precio_app'] < $plan['precio']) {
            $plan['descuento_porcentaje'] = round($descuentoApp);
        } else {
            $plan['descuento_porcentaje'] = 0;
        }
        
        // Determinar periodo para mostrar
        $plan['periodo'] = '';
        switch ($plan['tipo']) {
            case 'día':
                $plan['periodo'] = '/ día';
                break;
            case 'semana':
                $plan['periodo'] = '/ semana';
                break;
            case 'mes':
                $plan['periodo'] = '/ mes';
                break;
            case 'anual':
                $plan['periodo'] = '/ año';
                break;
        }
    }
    
    $response = [
        'success' => true,
        'planes' => $planes
    ];
    
    echo json_encode($response, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    
} catch (PDOException $e) {
    http_response_code(500);
    $response = [
        'success' => false,
        'message' => 'Error de base de datos: ' . $e->getMessage()
    ];
    echo json_encode($response, JSON_UNESCAPED_UNICODE);
} catch (Exception $e) {
    http_response_code(500);
    $response = [
        'success' => false,
        'message' => 'Error al obtener planes: ' . $e->getMessage()
    ];
    echo json_encode($response, JSON_UNESCAPED_UNICODE);
}
?>

