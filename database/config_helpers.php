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
?>

