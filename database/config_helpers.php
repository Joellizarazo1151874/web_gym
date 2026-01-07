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
 * Obtiene la ruta URL del logo de la empresa para usar en HTML
 * @param PDO $db Conexión a la base de datos
 * @return string|null Ruta URL del logo o null si no existe
 */
function getLogoUrl($db = null) {
    if ($db === null) {
        $db = getDB();
    }
    
    $logo_empresa = obtenerConfiguracion($db, 'logo_empresa');
    
    if (empty($logo_empresa)) {
        return null;
    }
    
    // Construir ruta del archivo en el sistema de archivos
    $logo_path_fs = __DIR__ . '/../' . $logo_empresa;
    
    // Verificar que el archivo existe
    if (!file_exists($logo_path_fs)) {
        return null;
    }
    
    // Obtener BASE_URL y asegurar que sea una ruta absoluta
    $base_url = BASE_URL;
    
    // Si BASE_URL es relativo (./ o .), calcularlo desde la raíz del servidor
    if ($base_url === './' || $base_url === '.' || empty($base_url)) {
        // Calcular desde la raíz del servidor web
        $scriptPath = dirname($_SERVER['SCRIPT_NAME']);
        
        // Si estamos en api/, subir un nivel
        if (strpos($scriptPath, '/api') !== false) {
            $scriptPath = dirname($scriptPath);
        }
        
        // Si estamos en dashboard/dist/dashboard/app/ o dashboard/dist/dashboard/, 
        // extraer solo la parte base del proyecto
        if (preg_match('#^(/[^/]+)/dashboard/#', $scriptPath, $matches)) {
            $base_url = $matches[1] . '/';
        } else {
            // Normalizar la ruta
            $scriptPath = '/' . trim($scriptPath, '/');
            if ($scriptPath === '/') {
                $base_url = '/';
            } else {
                $base_url = rtrim($scriptPath, '/') . '/';
            }
        }
    }
    
    // Asegurar que BASE_URL termine con /
    if (substr($base_url, -1) !== '/') {
        $base_url .= '/';
    }
    
    // Asegurar que BASE_URL empiece con /
    if (substr($base_url, 0, 1) !== '/') {
        $base_url = '/' . $base_url;
    }
    
    // Construir la URL completa del logo
    // Eliminar barras duplicadas
    $logo_path = $base_url . $logo_empresa;
    $logo_path = preg_replace('#/+#', '/', $logo_path);
    
    return $logo_path;
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

/**
 * Envía un correo electrónico usando SMTP
 * @param string $to Email del destinatario
 * @param string $subject Asunto del correo
 * @param string $message Mensaje del correo (HTML o texto)
 * @param bool $is_html Si el mensaje es HTML
 * @return bool True si se envió correctamente
 */
function enviarCorreo($to, $subject, $message, $is_html = true) {
    // Obtener configuración de email desde la base de datos si está disponible
    try {
        $db = getDB();
        $from_email = obtenerConfiguracion($db, 'email_empresa') ?: SMTP_FROM_EMAIL;
        $from_name = obtenerConfiguracion($db, 'gimnasio_nombre') ?: obtenerConfiguracion($db, 'nombre_empresa') ?: SMTP_FROM_NAME;
    } catch (Exception $e) {
        $from_email = SMTP_FROM_EMAIL;
        $from_name = SMTP_FROM_NAME;
    }
    
    // Si no hay credenciales SMTP configuradas, usar mail() nativo
    if (empty(SMTP_USER) || empty(SMTP_PASS)) {
        $headers = [];
        $headers[] = "From: {$from_name} <{$from_email}>";
        $headers[] = "Reply-To: {$from_email}";
        $headers[] = "X-Mailer: PHP/" . phpversion();
        
        if ($is_html) {
            $headers[] = "MIME-Version: 1.0";
            $headers[] = "Content-Type: text/html; charset=UTF-8";
        } else {
            $headers[] = "Content-Type: text/plain; charset=UTF-8";
        }
        
        return @mail($to, $subject, $message, implode("\r\n", $headers));
    }
    
    // Usar SMTP con autenticación
    try {
        // Función helper para leer respuesta SMTP (puede tener múltiples líneas)
        $readResponse = function($smtp) {
            $response = '';
            while ($line = fgets($smtp, 515)) {
                $response .= $line;
                if (substr($line, 3, 1) === ' ') {
                    break; // Última línea del comando
                }
            }
            return $response;
        };
        
        // Función helper para enviar comando y verificar respuesta
        $sendCommand = function($smtp, $command, $expected_code, $readResponse) {
            fputs($smtp, $command . "\r\n");
            $response = $readResponse($smtp);
            $code = substr($response, 0, 3);
            if ($code !== $expected_code) {
                throw new Exception("Error SMTP: Comando '{$command}' esperaba código {$expected_code}, recibió {$code}. Respuesta: " . trim($response));
            }
            return $response;
        };
        
        // Conectar al servidor SMTP (Gmail requiere STARTTLS, no TLS directo)
        $smtp = fsockopen(SMTP_HOST, SMTP_PORT, $errno, $errstr, 30);
        if (!$smtp) {
            throw new Exception("Error de conexión SMTP: {$errstr} ({$errno})");
        }
        
        // Leer respuesta inicial
        $response = $readResponse($smtp);
        if (substr($response, 0, 3) !== '220') {
            throw new Exception("Error SMTP inicial: " . trim($response));
        }
        
        // Enviar EHLO
        $hostname = isset($_SERVER['HTTP_HOST']) ? $_SERVER['HTTP_HOST'] : (isset($_SERVER['SERVER_NAME']) ? $_SERVER['SERVER_NAME'] : 'localhost');
        $sendCommand($smtp, "EHLO " . $hostname, '250', $readResponse);
        
        // Iniciar TLS (STARTTLS)
        $sendCommand($smtp, "STARTTLS", '220', $readResponse);
        
        // Habilitar cifrado TLS
        $crypto_method = STREAM_CRYPTO_METHOD_TLS_CLIENT;
        if (defined('STREAM_CRYPTO_METHOD_TLSv1_2_CLIENT')) {
            $crypto_method = STREAM_CRYPTO_METHOD_TLSv1_2_CLIENT;
        }
        
        if (!stream_socket_enable_crypto($smtp, true, $crypto_method)) {
            throw new Exception("Error al habilitar TLS/SSL");
        }
        
        // Enviar EHLO nuevamente después de TLS (requerido por SMTP)
        $sendCommand($smtp, "EHLO " . $hostname, '250', $readResponse);
        
        // Autenticación
        $sendCommand($smtp, "AUTH LOGIN", '334', $readResponse);
        
        fputs($smtp, base64_encode(SMTP_USER) . "\r\n");
        $response = $readResponse($smtp);
        if (substr($response, 0, 3) !== '334') {
            throw new Exception("Error usuario SMTP: " . trim($response));
        }
        
        fputs($smtp, base64_encode(SMTP_PASS) . "\r\n");
        $response = $readResponse($smtp);
        if (substr($response, 0, 3) !== '235') {
            throw new Exception("Error autenticación SMTP: " . trim($response));
        }
        
        // Enviar correo
        $sendCommand($smtp, "MAIL FROM: <{$from_email}>", '250', $readResponse);
        $sendCommand($smtp, "RCPT TO: <{$to}>", '250', $readResponse);
        $sendCommand($smtp, "DATA", '354', $readResponse);
        
        // Construir headers del correo
        $headers = "From: {$from_name} <{$from_email}>\r\n";
        $headers .= "To: {$to}\r\n";
        $headers .= "Subject: =?UTF-8?B?" . base64_encode($subject) . "?=\r\n";
        $headers .= "Reply-To: {$from_email}\r\n";
        $headers .= "X-Mailer: PHP/" . phpversion() . "\r\n";
        $headers .= "Date: " . date('r') . "\r\n";
        
        if ($is_html) {
            $headers .= "MIME-Version: 1.0\r\n";
            $headers .= "Content-Type: text/html; charset=UTF-8\r\n";
        } else {
            $headers .= "Content-Type: text/plain; charset=UTF-8\r\n";
        }
        
        // Enviar mensaje completo
        fputs($smtp, $headers . "\r\n" . $message . "\r\n.\r\n");
        $response = $readResponse($smtp);
        if (substr($response, 0, 3) !== '250') {
            throw new Exception("Error enviando mensaje SMTP: " . trim($response));
        }
        
        // Cerrar conexión
        fputs($smtp, "QUIT\r\n");
        @fgets($smtp, 515); // Leer respuesta de QUIT (no es crítico)
        fclose($smtp);
        
        if (DEBUG_MODE) {
            error_log("Correo enviado exitosamente a: {$to}");
        }
        
        return true;
        
    } catch (Exception $e) {
        $error_msg = "Error al enviar correo SMTP a: {$to}. Error: " . $e->getMessage();
        error_log($error_msg);
        if (DEBUG_MODE) {
            error_log($error_msg);
            error_log("Stack trace: " . $e->getTraceAsString());
        }
        if (isset($smtp) && is_resource($smtp)) {
            @fclose($smtp);
        }
        return false;
    } catch (Error $e) {
        $error_msg = "Error fatal al enviar correo SMTP a: {$to}. Error: " . $e->getMessage();
        error_log($error_msg);
        if (DEBUG_MODE) {
            error_log($error_msg);
            error_log("Stack trace: " . $e->getTraceAsString());
        }
        if (isset($smtp) && is_resource($smtp)) {
            @fclose($smtp);
        }
        return false;
    }
}

/**
 * Envía correo de bienvenida a un nuevo usuario
 * @param string $email Email del usuario
 * @param string $nombre Nombre del usuario
 * @param string $apellido Apellido del usuario
 * @param string $password Contraseña del usuario (en texto plano)
 * @return bool True si se envió correctamente
 */
function enviarCorreoBienvenida($email, $nombre, $apellido, $password) {
    $nombre_completo = trim($nombre . ' ' . $apellido);
    
    // Obtener configuración desde la base de datos
    $nombre_empresa = APP_NAME;
    $color_primary = '#667eea'; // Color por defecto
    $color_primary_dark = '#5568d3'; // Versión oscura para gradientes
    $logo_empresa = null;
    
    try {
        $db = getDB();
        // Obtener nombre de la empresa (usar gimnasio_nombre que es la clave correcta)
        $nombre_empresa = obtenerConfiguracion($db, 'gimnasio_nombre') ?: obtenerConfiguracion($db, 'nombre_empresa') ?: APP_NAME;
        $logo_empresa = obtenerConfiguracion($db, 'logo_empresa');
        
        // Obtener color del tema desde las preferencias del admin (usuario_id = 1)
        // Intentar primero con usuario_id = 1, luego buscar cualquier admin
        $stmt = $db->prepare("
            SELECT pu.color_custom_info 
            FROM preferencias_usuario pu
            INNER JOIN usuarios u ON pu.usuario_id = u.id
            INNER JOIN roles r ON u.rol_id = r.id
            WHERE r.nombre = 'admin'
            ORDER BY pu.usuario_id ASC
            LIMIT 1
        ");
        $stmt->execute();
        $pref = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($pref && !empty($pref['color_custom_info'])) {
            $color_primary = trim($pref['color_custom_info']);
            // Validar que sea un color hexadecimal válido
            if (preg_match('/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/', $color_primary)) {
                // Si es formato corto (#RGB), convertir a largo (#RRGGBB)
                if (strlen($color_primary) === 4) {
                    $color_primary = '#' . $color_primary[1] . $color_primary[1] . $color_primary[2] . $color_primary[2] . $color_primary[3] . $color_primary[3];
                }
                // Crear versión más oscura para gradientes (reducir brillo en 15%)
                $color_primary_dark = ajustarBrilloColor($color_primary, -15);
                // Log para debug (solo en modo debug)
                if (defined('DEBUG_MODE') && DEBUG_MODE) {
                    error_log("Color del tema aplicado: {$color_primary} (oscuro: {$color_primary_dark})");
                }
            } else {
                // Si no es válido, usar el color por defecto
                error_log("Color inválido obtenido de preferencias: {$color_primary}");
                $color_primary = '#667eea';
                $color_primary_dark = '#5568d3';
            }
        } else {
            // Si no hay color configurado, usar el por defecto
            if (defined('DEBUG_MODE') && DEBUG_MODE) {
                error_log("No se encontró color_custom_info en preferencias de admin, usando color por defecto");
            }
        }
    } catch (Exception $e) {
        // Usar valores por defecto
        error_log("Error al obtener configuración para email: " . $e->getMessage());
    }
    
    // Debug: Log del color que se va a usar (solo en modo debug)
    if (defined('DEBUG_MODE') && DEBUG_MODE) {
        error_log("Email bienvenida - Color primario: {$color_primary}, Color oscuro: {$color_primary_dark}");
    }
    
    $subject = "¡Bienvenido a {$nombre_empresa}!";
    
    // Construir URL del logo si existe
    $logo_url = '';
    if ($logo_empresa && !empty($logo_empresa)) {
        try {
            // Verificar que el archivo existe primero
            $logo_path_fs = __DIR__ . '/../' . ltrim($logo_empresa, '/');
            if (file_exists($logo_path_fs)) {
                // Usar la función getSiteUrl() de config.php si está disponible
                if (function_exists('getSiteUrl')) {
                    // Construir la ruta relativa desde la raíz del proyecto
                    $logo_path = ltrim($logo_empresa, '/');
                    $logo_url = getSiteUrl() . $logo_path;
                } else {
                    // Fallback: construir URL manualmente (funciona en desarrollo y producción)
                    $protocol = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' || 
                                 (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https')) 
                                 ? 'https' : 'http';
                    $host = $_SERVER['HTTP_HOST'] ?? 'localhost';
                    
                    // Obtener el directorio base del proyecto de forma más robusta
                    // El logo está almacenado como ruta relativa desde la raíz (ej: uploads/logo.png)
                    $logo_path = ltrim($logo_empresa, '/');
                    
                    // Obtener la ruta base del proyecto
                    $script_name = $_SERVER['SCRIPT_NAME'] ?? '';
                    // Si estamos en api/, subir un nivel
                    if (strpos($script_name, '/api/') !== false) {
                        $base_path = dirname(dirname($script_name));
                    } else {
                        $base_path = dirname($script_name);
                    }
                    $base_path = rtrim($base_path, '/') . '/';
                    
                    // Construir URL completa (funciona en desarrollo y producción)
                    $logo_url = $protocol . '://' . $host . $base_path . $logo_path;
                }
                
                // Log para debug (solo en modo debug)
                if (defined('DEBUG_MODE') && DEBUG_MODE) {
                    error_log("Logo URL construida: {$logo_url}");
                }
            } else {
                if (defined('DEBUG_MODE') && DEBUG_MODE) {
                    error_log("Logo no encontrado en: {$logo_path_fs}");
                }
            }
        } catch (Exception $e) {
            error_log("Error al construir URL del logo: " . $e->getMessage());
            $logo_url = '';
        }
    }
    
    // Crear el mensaje HTML mejorado con diseño responsive
    $message = "
    <!DOCTYPE html>
    <html lang='es'>
    <head>
        <meta charset='UTF-8'>
        <meta name='viewport' content='width=device-width, initial-scale=1.0'>
        <title>Bienvenida - {$nombre_empresa}</title>
        <style type='text/css'>
            /* Estilos responsive para móviles */
            @media only screen and (max-width: 600px) {
                .email-container {
                    width: 100% !important;
                    max-width: 100% !important;
                }
                .email-header {
                    padding: 25px 20px !important;
                }
                .email-header h1 {
                    font-size: 24px !important;
                }
                .email-content {
                    padding: 25px 20px !important;
                }
                .email-content p {
                    font-size: 14px !important;
                }
                .email-content h2 {
                    font-size: 18px !important;
                }
                .email-credentials {
                    padding: 20px 15px !important;
                }
                .email-credentials-label {
                    font-size: 12px !important;
                }
                .email-credentials-value {
                    font-size: 14px !important;
                }
                .email-password-code {
                    font-size: 14px !important;
                    padding: 6px 12px !important;
                }
                .email-alert {
                    padding: 15px !important;
                }
                .email-alert p {
                    font-size: 13px !important;
                }
                .email-alert strong {
                    font-size: 15px !important;
                }
                .email-button {
                    padding: 12px 24px !important;
                    font-size: 14px !important;
                }
                .email-footer {
                    padding: 20px 15px !important;
                }
                .email-footer p {
                    font-size: 11px !important;
                }
            }
        </style>
    </head>
    <body style='margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, \"Helvetica Neue\", Arial, sans-serif; background-color: #f5f5f5;'>
        <table role='presentation' cellspacing='0' cellpadding='0' border='0' width='100%' style='background-color: #f5f5f5; padding: 10px 0;'>
            <tr>
                <td align='center'>
                    <table role='presentation' cellspacing='0' cellpadding='0' border='0' width='600' class='email-container' style='max-width: 600px; width: 100%; background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);'>
                        <!-- Header con gradiente -->
                        <tr>
                            <td class='email-header' style='background: linear-gradient(135deg, {$color_primary} 0%, {$color_primary_dark} 100%); padding: 35px 30px; text-align: center;'>
                                <h1 class='email-header' style='color: #ffffff; margin: 0; font-size: 28px; font-weight: 700; letter-spacing: -0.5px; line-height: 1.3;'>¡Bienvenido a {$nombre_empresa}!</h1>
                            </td>
                        </tr>
                        
                        <!-- Contenido principal -->
                        <tr>
                            <td class='email-content' style='padding: 35px 30px;'>
                                <p style='font-size: 16px; line-height: 1.6; color: #333333; margin: 0 0 18px 0;'>
                                    Hola <strong style='color: {$color_primary};'>{$nombre_completo}</strong>,
                                </p>
                                
                                <p style='font-size: 15px; line-height: 1.7; color: #555555; margin: 0 0 22px 0;'>
                                    ¡Estamos emocionados de darte la bienvenida a nuestra familia de entrenamiento! Tu cuenta ha sido creada exitosamente y estamos listos para acompañarte en tu viaje hacia una vida más saludable y activa.
                                </p>
                                
                                <!-- Tarjeta de credenciales -->
                                <table role='presentation' cellspacing='0' cellpadding='0' border='0' width='100%' style='background: linear-gradient(135deg, #f8f9fa 0%, #ffffff 100%); border-radius: 10px; border-left: 4px solid {$color_primary}; margin: 25px 0; overflow: hidden; box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);'>
                                    <tr>
                                        <td class='email-credentials' style='padding: 22px;'>
                                            <h2 style='color: {$color_primary}; margin: 0 0 18px 0; font-size: 20px; font-weight: 600; line-height: 1.3;'>
                                                🔐 Tus credenciales de acceso
                                            </h2>
                                            <table role='presentation' cellspacing='0' cellpadding='0' border='0' width='100%'>
                                                <tr>
                                                    <td style='padding: 10px 0; border-bottom: 1px solid #e9ecef;'>
                                                        <p class='email-credentials-label' style='margin: 0; font-size: 13px; color: #6c757d; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px;'>Email</p>
                                                        <p class='email-credentials-value' style='margin: 5px 0 0 0; font-size: 15px; color: #212529; font-weight: 500; word-break: break-all;'>{$email}</p>
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <td style='padding: 10px 0;'>
                                                        <p class='email-credentials-label' style='margin: 0; font-size: 13px; color: #6c757d; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px;'>Contraseña</p>
                                                        <p style='margin: 5px 0 0 0;'>
                                                            <code class='email-password-code' style='background: #f8f9fa; color: {$color_primary}; padding: 7px 14px; border-radius: 6px; font-size: 15px; font-weight: 600; letter-spacing: 1px; border: 1px solid #e9ecef; display: inline-block; word-break: break-all;'>{$password}</code>
                                                        </p>
                                                    </td>
                                                </tr>
                                            </table>
                                        </td>
                                    </tr>
                                </table>
                                
                                <p style='font-size: 15px; line-height: 1.7; color: #555555; margin: 0 0 22px 0;'>
                                    Puedes usar estas credenciales para iniciar sesión en nuestra <strong style='color: {$color_primary};'>aplicación móvil</strong> y comenzar a disfrutar de todos los beneficios que tenemos para ti.
                                </p>
                                
                                <!-- Alerta de seguridad -->
                                <table role='presentation' cellspacing='0' cellpadding='0' border='0' width='100%' style='background: linear-gradient(135deg, #fff3cd 0%, #ffeaa7 100%); border-radius: 10px; border: 1px solid #ffc107; margin: 22px 0;'>
                                    <tr>
                                        <td class='email-alert' style='padding: 18px;'>
                                            <p style='margin: 0; font-size: 14px; color: #856404; line-height: 1.6;'>
                                                <strong style='font-size: 16px;'>⚠️ Importante:</strong><br>
                                                Por tu seguridad, te recomendamos <strong>cambiar tu contraseña</strong> después de tu primer inicio de sesión.
                                            </p>
                                        </td>
                                    </tr>
                                </table>
                                
                                <p style='font-size: 15px; line-height: 1.7; color: #555555; margin: 22px 0 0 0;'>
                                    Si tienes alguna pregunta o necesitas ayuda, no dudes en contactarnos. Estamos aquí para apoyarte en cada paso de tu viaje hacia una vida más saludable y activa.
                                </p>
                                
                                <!-- Botón CTA (opcional) -->
                                <table role='presentation' cellspacing='0' cellpadding='0' border='0' width='100%' style='margin: 25px 0;'>
                                    <tr>
                                        <td align='center' style='padding: 18px 0;'>
                                            <a href='#' class='email-button' style='display: inline-block; background: linear-gradient(135deg, {$color_primary} 0%, {$color_primary_dark} 100%); color: #ffffff; text-decoration: none; padding: 12px 28px; border-radius: 8px; font-size: 15px; font-weight: 600; box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15); transition: all 0.3s ease;'>
                                                Descargar App Móvil
                                            </a>
                                        </td>
                                    </tr>
                                </table>
                                
                                <p style='font-size: 15px; line-height: 1.7; color: #555555; margin: 25px 0 0 0; text-align: center;'>
                                    ¡Nos vemos pronto!<br>
                                    <strong style='color: {$color_primary}; font-size: 16px;'>El equipo de {$nombre_empresa}</strong>
                                </p>
                            </td>
                        </tr>
                        
                        <!-- Footer -->
                        <tr>
                            <td class='email-footer' style='background-color: #f8f9fa; padding: 22px 30px; text-align: center; border-top: 1px solid #e9ecef;'>
                                <p style='margin: 0 0 6px 0; font-size: 11px; color: #6c757d; line-height: 1.5;'>
                                    Este es un correo automático, por favor no respondas a este mensaje.
                                </p>
                                <p style='margin: 0; font-size: 11px; color: #adb5bd;'>
                                    &copy; " . date('Y') . " {$nombre_empresa}. Todos los derechos reservados.
                                </p>
                            </td>
                        </tr>
                    </table>
                </td>
            </tr>
        </table>
    </body>
    </html>
    ";
    
    return enviarCorreo($email, $subject, $message, true);
}

/**
 * Envía correo de recordatorio de vencimiento de membresía
 * @param string $email Email del usuario
 * @param string $nombre Nombre del usuario
 * @param string $apellido Apellido del usuario
 * @param string $fecha_vencimiento Fecha de vencimiento de la membresía (formato Y-m-d)
 * @param int $dias_restantes Días restantes hasta el vencimiento (3 o 1)
 * @return bool True si se envió correctamente
 */
function enviarCorreoRecordatorioVencimiento($email, $nombre, $apellido, $fecha_vencimiento, $dias_restantes) {
    $nombre_completo = trim($nombre . ' ' . $apellido);
    
    // Obtener configuración desde la base de datos
    $nombre_empresa = APP_NAME;
    $color_primary = '#667eea'; // Color por defecto
    $color_primary_dark = '#5568d3'; // Versión oscura para gradientes
    
    try {
        $db = getDB();
        // Obtener nombre de la empresa
        $nombre_empresa = obtenerConfiguracion($db, 'gimnasio_nombre') ?: obtenerConfiguracion($db, 'nombre_empresa') ?: APP_NAME;
        
        // Obtener color del tema desde las preferencias del admin
        $stmt = $db->prepare("
            SELECT pu.color_custom_info 
            FROM preferencias_usuario pu
            INNER JOIN usuarios u ON pu.usuario_id = u.id
            INNER JOIN roles r ON u.rol_id = r.id
            WHERE r.nombre = 'admin'
            ORDER BY pu.usuario_id ASC
            LIMIT 1
        ");
        $stmt->execute();
        $pref = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($pref && !empty($pref['color_custom_info'])) {
            $color_primary = trim($pref['color_custom_info']);
            if (preg_match('/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/', $color_primary)) {
                if (strlen($color_primary) === 4) {
                    $color_primary = '#' . $color_primary[1] . $color_primary[1] . $color_primary[2] . $color_primary[2] . $color_primary[3] . $color_primary[3];
                }
                $color_primary_dark = ajustarBrilloColor($color_primary, -15);
            } else {
                $color_primary = '#667eea';
                $color_primary_dark = '#5568d3';
            }
        }
    } catch (Exception $e) {
        error_log("Error al obtener configuración para email: " . $e->getMessage());
    }
    
    // Formatear fecha de vencimiento para mostrar
    $fecha_vencimiento_formateada = date('d/m/Y', strtotime($fecha_vencimiento));
    
    // Determinar el mensaje según los días restantes
    $mensaje_dias = '';
    $titulo = '';
    if ($dias_restantes == 3) {
        $titulo = "Tu membresía vence en 3 días";
        $mensaje_dias = "Tu membresía está por vencer en <strong style='color: {$color_primary};'>3 días</strong>. Te recomendamos renovarla para continuar disfrutando de todos nuestros servicios.";
    } else if ($dias_restantes == 1) {
        $titulo = "Tu membresía vence mañana";
        $mensaje_dias = "Tu membresía <strong style='color: {$color_primary};'>vencerá mañana</strong>. ¡No te quedes sin acceso! Renueva ahora para continuar con tu entrenamiento.";
    }
    
    $subject = "{$titulo} - {$nombre_empresa}";
    
    // Crear el mensaje HTML
    $message = "
    <!DOCTYPE html>
    <html lang='es'>
    <head>
        <meta charset='UTF-8'>
        <meta name='viewport' content='width=device-width, initial-scale=1.0'>
        <title>{$titulo}</title>
        <style type='text/css'>
            @media only screen and (max-width: 600px) {
                .email-container {
                    width: 100% !important;
                    max-width: 100% !important;
                }
                .email-header {
                    padding: 25px 20px !important;
                }
                .email-header h1 {
                    font-size: 24px !important;
                }
                .email-content {
                    padding: 25px 20px !important;
                }
                .email-content p {
                    font-size: 14px !important;
                }
                .email-button {
                    padding: 12px 24px !important;
                    font-size: 14px !important;
                }
                .email-footer {
                    padding: 20px 15px !important;
                }
                .email-footer p {
                    font-size: 11px !important;
                }
            }
        </style>
    </head>
    <body style='margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, \"Helvetica Neue\", Arial, sans-serif; background-color: #f5f5f5;'>
        <table role='presentation' cellspacing='0' cellpadding='0' border='0' width='100%' style='background-color: #f5f5f5; padding: 10px 0;'>
            <tr>
                <td align='center'>
                    <table role='presentation' cellspacing='0' cellpadding='0' border='0' width='600' class='email-container' style='max-width: 600px; width: 100%; background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);'>
                        <!-- Header con gradiente -->
                        <tr>
                            <td class='email-header' style='background: linear-gradient(135deg, {$color_primary} 0%, {$color_primary_dark} 100%); padding: 35px 30px; text-align: center;'>
                                <h1 class='email-header' style='color: #ffffff; margin: 0; font-size: 28px; font-weight: 700; letter-spacing: -0.5px; line-height: 1.3;'>{$titulo}</h1>
                            </td>
                        </tr>
                        
                        <!-- Contenido principal -->
                        <tr>
                            <td class='email-content' style='padding: 35px 30px;'>
                                <p style='font-size: 16px; line-height: 1.6; color: #333333; margin: 0 0 18px 0;'>
                                    Hola <strong style='color: {$color_primary};'>{$nombre_completo}</strong>,
                                </p>
                                
                                <p style='font-size: 15px; line-height: 1.7; color: #555555; margin: 0 0 22px 0;'>
                                    {$mensaje_dias}
                                </p>
                                
                                <!-- Tarjeta de información -->
                                <table role='presentation' cellspacing='0' cellpadding='0' border='0' width='100%' style='background: linear-gradient(135deg, #f8f9fa 0%, #ffffff 100%); border-radius: 10px; border-left: 4px solid {$color_primary}; margin: 25px 0; overflow: hidden; box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);'>
                                    <tr>
                                        <td style='padding: 22px;'>
                                            <h2 style='color: {$color_primary}; margin: 0 0 12px 0; font-size: 20px; font-weight: 600; line-height: 1.3;'>
                                                📅 Información de tu membresía
                                            </h2>
                                            <p style='margin: 0; font-size: 15px; color: #212529;'>
                                                <strong>Fecha de vencimiento:</strong> <span style='color: {$color_primary}; font-weight: 600;'>{$fecha_vencimiento_formateada}</span>
                                            </p>
                                        </td>
                                    </tr>
                                </table>
                                
                                <p style='font-size: 15px; line-height: 1.7; color: #555555; margin: 22px 0;'>
                                    Para renovar tu membresía, puedes acercarte a nuestras instalaciones o contactarnos a través de nuestros canales de atención.
                                </p>
                                
                                <p style='font-size: 15px; line-height: 1.7; color: #555555; margin: 22px 0 0 0;'>
                                    ¡Esperamos verte pronto!
                                </p>
                                
                                <p style='font-size: 15px; line-height: 1.7; color: #555555; margin: 5px 0 0 0;'>
                                    El equipo de <strong style='color: {$color_primary};'>{$nombre_empresa}</strong>
                                </p>
                            </td>
                        </tr>
                        
                        <!-- Footer -->
                        <tr>
                            <td class='email-footer' style='background-color: #f8f9fa; padding: 22px 30px; text-align: center; border-top: 1px solid #e9ecef;'>
                                <p style='margin: 0 0 6px 0; font-size: 11px; color: #6c757d; line-height: 1.5;'>
                                    Este es un correo automático, por favor no respondas a este mensaje.
                                </p>
                                <p style='margin: 0; font-size: 11px; color: #adb5bd;'>
                                    &copy; " . date('Y') . " {$nombre_empresa}. Todos los derechos reservados.
                                </p>
                            </td>
                        </tr>
                    </table>
                </td>
            </tr>
        </table>
    </body>
    </html>
    ";
    
    return enviarCorreo($email, $subject, $message, true);
}

/**
 * Ajusta el brillo de un color hexadecimal
 * @param string $hex Color en formato hexadecimal (#RRGGBB)
 * @param int $percent Porcentaje de ajuste (-100 a 100)
 * @return string Color ajustado en formato hexadecimal
 */
function ajustarBrilloColor($hex, $percent) {
    // Remover # si existe
    $hex = ltrim($hex, '#');
    
    // Convertir a RGB
    $r = hexdec(substr($hex, 0, 2));
    $g = hexdec(substr($hex, 2, 2));
    $b = hexdec(substr($hex, 4, 2));
    
    // Ajustar brillo
    $r = max(0, min(255, $r + ($r * $percent / 100)));
    $g = max(0, min(255, $g + ($g * $percent / 100)));
    $b = max(0, min(255, $b + ($b * $percent / 100)));
    
    // Convertir de vuelta a hexadecimal
    return '#' . str_pad(dechex(round($r)), 2, '0', STR_PAD_LEFT) . 
                 str_pad(dechex(round($g)), 2, '0', STR_PAD_LEFT) . 
                 str_pad(dechex(round($b)), 2, '0', STR_PAD_LEFT);
}
?>

