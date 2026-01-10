<?php
/**
 * Solicitar Recuperación de Contraseña - Aplicación Móvil
 * Envía un email con un token para resetear la contraseña
 */

// Headers para CORS y JSON
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept');

// Manejar preflight OPTIONS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Solo permitir POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Método no permitido'
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/../database/config_helpers.php';
require_once __DIR__ . '/../database/rate_limit_helper.php';

try {
    // Verificar rate limiting (5 intentos, 15 minutos)
    $rateLimit = checkRateLimit('forgot_password', 5, 15);
    if (!$rateLimit['allowed']) {
        http_response_code(429);
        echo json_encode([
            'success' => false,
            'message' => $rateLimit['message'],
            'rate_limit' => [
                'lockout_until' => $rateLimit['lockout_until'],
                'remaining' => 0
            ]
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // Obtener datos del POST
    $input = file_get_contents('php://input');
    $data = json_decode($input, true);
    
    if (json_last_error() !== JSON_ERROR_NONE || $data === null) {
        $data = $_POST;
    }

    $email = trim($data['email'] ?? '');

    // Validar email
    if (empty($email) || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
        recordFailedAttempt('forgot_password');
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Email inválido'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $db = getDB();

    // Buscar usuario por email
    $stmt = $db->prepare("
        SELECT id, nombre, apellido, email, estado 
        FROM usuarios 
        WHERE email = :email
    ");
    $stmt->execute([':email' => $email]);
    $usuario = $stmt->fetch(PDO::FETCH_ASSOC);

    // Por seguridad, siempre devolver éxito aunque el email no exista
    // Esto previene enumeración de usuarios
    if (!$usuario) {
        clearFailedAttempts('forgot_password');
        // Simular delay para prevenir timing attacks
        usleep(500000); // 0.5 segundos
        
        echo json_encode([
            'success' => true,
            'message' => 'Si el email existe, recibirás un correo con instrucciones para recuperar tu contraseña.'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // Verificar que el usuario no esté suspendido
    if ($usuario['estado'] === 'suspendido') {
        recordFailedAttempt('forgot_password');
        http_response_code(403);
        echo json_encode([
            'success' => false,
            'message' => 'Tu cuenta está suspendida. Contacta al administrador.'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // Generar token de recuperación (32 caracteres aleatorios)
    $token = bin2hex(random_bytes(16));
    $token_hash = hash('sha256', $token);
    $expires_at = date('Y-m-d H:i:s', strtotime('+1 hour')); // Token válido por 1 hora

    // Guardar token en la base de datos (usar token_verificacion temporalmente o crear campo password_reset_token)
    // Usaremos token_verificacion para almacenar el token de reset
    $stmt = $db->prepare("
        UPDATE usuarios 
        SET token_verificacion = :token_hash,
            updated_at = NOW()
        WHERE id = :usuario_id
    ");
    $stmt->execute([
        ':token_hash' => $token_hash,
        ':usuario_id' => $usuario['id']
    ]);

    // Obtener configuración del gimnasio
    $nombre_empresa = obtenerConfiguracion($db, 'gimnasio_nombre') ?: APP_NAME;
    $color_primary = '#E63946'; // Color por defecto
    
    try {
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
            if (!preg_match('/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/', $color_primary)) {
                $color_primary = '#E63946';
            }
        }
    } catch (Exception $e) {
        error_log("Error al obtener color del tema: " . $e->getMessage());
    }

    // Construir URL de reset (usar BASE_URL)
    $baseUrl = getSiteUrl();
    $resetUrl = $baseUrl . 'reset-password.php?token=' . urlencode($token) . '&email=' . urlencode($email);

    // Crear mensaje de email
    $nombre_completo = trim($usuario['nombre'] . ' ' . $usuario['apellido']);
    $subject = "Recuperación de Contraseña - {$nombre_empresa}";
    
    $message = "
    <!DOCTYPE html>
    <html lang='es'>
    <head>
        <meta charset='UTF-8'>
        <meta name='viewport' content='width=device-width, initial-scale=1.0'>
        <title>Recuperar Contraseña</title>
    </head>
    <body style='margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, \"Helvetica Neue\", Arial, sans-serif; background-color: #f5f5f5;'>
        <table role='presentation' cellspacing='0' cellpadding='0' border='0' width='100%' style='background-color: #f5f5f5; padding: 20px 0;'>
            <tr>
                <td align='center'>
                    <table role='presentation' cellspacing='0' cellpadding='0' border='0' width='600' style='max-width: 600px; width: 100%; background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);'>
                        <!-- Header -->
                        <tr>
                            <td style='background: linear-gradient(135deg, {$color_primary} 0%, " . ajustarBrilloColor($color_primary, -15) . " 100%); padding: 35px 30px; text-align: center;'>
                                <h1 style='color: #ffffff; margin: 0; font-size: 28px; font-weight: 700;'>Recuperar Contraseña</h1>
                            </td>
                        </tr>
                        
                        <!-- Contenido -->
                        <tr>
                            <td style='padding: 35px 30px;'>
                                <p style='font-size: 16px; line-height: 1.6; color: #333333; margin: 0 0 18px 0;'>
                                    Hola <strong style='color: {$color_primary};'>{$nombre_completo}</strong>,
                                </p>
                                
                                <p style='font-size: 15px; line-height: 1.7; color: #555555; margin: 0 0 22px 0;'>
                                    Recibimos una solicitud para recuperar tu contraseña. Si no fuiste tú, puedes ignorar este correo.
                                </p>
                                
                                <p style='font-size: 15px; line-height: 1.7; color: #555555; margin: 0 0 22px 0;'>
                                    Para restablecer tu contraseña, haz clic en el siguiente botón:
                                </p>
                                
                                <table role='presentation' cellspacing='0' cellpadding='0' border='0' width='100%' style='margin: 25px 0;'>
                                    <tr>
                                        <td align='center' style='padding: 18px 0;'>
                                            <a href='{$resetUrl}' style='display: inline-block; background: linear-gradient(135deg, {$color_primary} 0%, " . ajustarBrilloColor($color_primary, -15) . " 100%); color: #ffffff; text-decoration: none; padding: 14px 32px; border-radius: 8px; font-size: 15px; font-weight: 600; box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);'>
                                                Restablecer Contraseña
                                            </a>
                                        </td>
                                    </tr>
                                </table>
                                
                                <p style='font-size: 13px; line-height: 1.6; color: #888888; margin: 22px 0 0 0;'>
                                    O copia y pega este enlace en tu navegador:<br>
                                    <a href='{$resetUrl}' style='color: {$color_primary}; word-break: break-all;'>{$resetUrl}</a>
                                </p>
                                
                                <div style='background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 25px 0; border-radius: 4px;'>
                                    <p style='margin: 0; font-size: 13px; color: #856404; line-height: 1.6;'>
                                        <strong>⚠️ Importante:</strong> Este enlace expirará en 1 hora por seguridad.
                                    </p>
                                </div>
                                
                                <p style='font-size: 15px; line-height: 1.7; color: #555555; margin: 25px 0 0 0;'>
                                    Si no solicitaste este cambio, puedes ignorar este correo de forma segura.
                                </p>
                            </td>
                        </tr>
                        
                        <!-- Footer -->
                        <tr>
                            <td style='background-color: #f8f9fa; padding: 22px 30px; text-align: center; border-top: 1px solid #e9ecef;'>
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

    // Enviar correo
    $email_enviado = enviarCorreo($email, $subject, $message, true);

    if ($email_enviado) {
        clearFailedAttempts('forgot_password');
        echo json_encode([
            'success' => true,
            'message' => 'Si el email existe, recibirás un correo con instrucciones para recuperar tu contraseña.'
        ], JSON_UNESCAPED_UNICODE);
    } else {
        error_log("Error al enviar correo de recuperación a: {$email}");
        echo json_encode([
            'success' => false,
            'message' => 'Error al enviar el correo. Intenta nuevamente más tarde.'
        ], JSON_UNESCAPED_UNICODE);
    }

} catch (Exception $e) {
    error_log("Error en mobile_forgot_password.php: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al procesar la solicitud. Intenta nuevamente.'
    ], JSON_UNESCAPED_UNICODE);
}

