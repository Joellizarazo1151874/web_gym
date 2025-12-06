<?php
/**
 * Funciones Helper para Configuración
 * Funciones útiles para obtener valores de configuración del sistema
 */

require_once __DIR__ . '/config.php';

/**
 * Obtiene el porcentaje de descuento de la app móvil
 * @return float Porcentaje de descuento (por defecto 10)
 */
function getAppDescuento() {
    try {
        $db = getDB();
        $stmt = $db->prepare("SELECT valor FROM configuracion WHERE clave = 'app_descuento'");
        $stmt->execute();
        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($result && is_numeric($result['valor'])) {
            return (float)$result['valor'];
        }
    } catch (Exception $e) {
        error_log("Error al obtener descuento de app: " . $e->getMessage());
    }
    
    // Valor por defecto si no existe en la configuración
    return 10.0;
}

/**
 * Calcula el precio con descuento de la app móvil
 * @param float $precio Precio base
 * @param float|null $descuento Porcentaje de descuento (si es null, se obtiene de la configuración)
 * @return float Precio con descuento aplicado
 */
function calcularPrecioApp($precio, $descuento = null) {
    if ($descuento === null) {
        $descuento = getAppDescuento();
    }
    
    if ($precio <= 0) {
        return 0;
    }
    
    $descuento_decimal = $descuento / 100;
    $precio_con_descuento = $precio * (1 - $descuento_decimal);
    
    // Redondear a 2 decimales
    return round($precio_con_descuento, 2);
}

/**
 * Obtiene la configuración del sistema
 * @param PDO $db Conexión a la base de datos
 * @param string|null $clave Clave específica de configuración (opcional)
 * @return mixed Valor de configuración o array completo si no se especifica clave
 */
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

/**
 * Convierte el valor según su tipo
 * @param string $valor Valor almacenado
 * @param string $tipo Tipo de dato (string, number, boolean, json, time)
 * @return mixed Valor convertido
 */
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

/**
 * Guarda una configuración en la base de datos
 * @param PDO $db Conexión a la base de datos
 * @param string $clave Clave de la configuración
 * @param mixed $valor Valor a guardar
 * @param string $tipo Tipo de dato (string, number, boolean, json, time)
 * @return bool True si se guardó correctamente
 */
function guardarConfiguracion($db, $clave, $valor, $tipo = 'string') {
    // Convertir valor según tipo
    if ($tipo === 'json' && is_array($valor)) {
        $valor = json_encode($valor);
    } elseif ($tipo === 'boolean') {
        $valor = $valor ? '1' : '0';
    }
    
    // Usar parámetros diferentes para el UPDATE
    $stmt = $db->prepare("
        INSERT INTO configuracion (clave, valor, tipo) 
        VALUES (:clave, :valor, :tipo)
        ON DUPLICATE KEY UPDATE valor = :valor_update, tipo = :tipo_update, updated_at = CURRENT_TIMESTAMP
    ");
    return $stmt->execute([
        ':clave' => $clave,
        ':valor' => $valor,
        ':tipo' => $tipo,
        ':valor_update' => $valor,
        ':tipo_update' => $tipo
    ]);
}
?>

