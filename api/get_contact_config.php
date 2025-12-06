<?php
/**
 * Obtener configuración de contacto del gimnasio
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
    
    // Función helper para obtener configuración
    function obtenerConfiguracion($db, $clave = null) {
        if ($clave) {
            $stmt = $db->prepare("SELECT valor, tipo FROM configuracion WHERE clave = :clave");
            $stmt->execute([':clave' => $clave]);
            $result = $stmt->fetch();
            if (!$result) return null;
            
            return convertirValor($result['valor'], $result['tipo']);
        } else {
            $stmt = $db->query("SELECT clave, valor, tipo FROM configuracion");
            $resultados = $stmt->fetchAll();
            $config = [];
            foreach ($resultados as $row) {
                $config[$row['clave']] = convertirValor($row['valor'], $row['tipo']);
            }
            return $config;
        }
    }
    
    function convertirValor($valor, $tipo) {
        switch ($tipo) {
            case 'boolean':
                return (bool)$valor;
            case 'number':
                return is_numeric($valor) ? (strpos($valor, '.') !== false ? (float)$valor : (int)$valor) : 0;
            case 'json':
                return json_decode($valor, true) ?? [];
            default:
                return $valor;
        }
    }
    
    // Obtener configuración de contacto
    $config = obtenerConfiguracion($db);
    
    // Valores por defecto si no existen
    $contacto = [
        'direccion' => $config['gimnasio_direccion'] ?? 'Calle Principal 123',
        'ciudad' => $config['gimnasio_ciudad'] ?? 'Bogotá',
        'telefono_1' => $config['gimnasio_telefono'] ?? '+57 1 234 5678',
        'telefono_2' => $config['gimnasio_telefono_2'] ?? null,
        'email_1' => $config['gimnasio_email'] ?? 'info@ftgym.com',
        'email_2' => $config['gimnasio_email_2'] ?? null,
        'horario_apertura' => $config['horario_apertura'] ?? '06:00',
        'horario_cierre' => $config['horario_cierre'] ?? '22:00',
        'dias_semana' => $config['dias_semana'] ?? ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado']
    ];
    
    // Construir dirección completa
    $direccion_completa = trim(($contacto['ciudad'] ?? '') . ' ' . ($contacto['direccion'] ?? ''));
    if (empty($direccion_completa)) {
        $direccion_completa = 'Calle Principal 123';
    }
    
    $response = [
        'success' => true,
        'contacto' => [
            'direccion' => $direccion_completa,
            'telefono_1' => $contacto['telefono_1'],
            'telefono_2' => $contacto['telefono_2'],
            'email_1' => $contacto['email_1'],
            'email_2' => $contacto['email_2'],
            'horario_apertura' => $contacto['horario_apertura'],
            'horario_cierre' => $contacto['horario_cierre'],
            'dias_semana' => $contacto['dias_semana']
        ]
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
        'message' => 'Error inesperado: ' . $e->getMessage()
    ];
    echo json_encode($response, JSON_UNESCAPED_UNICODE);
}
?>

