<?php
/**
 * Registro para Aplicación Móvil
 * Endpoint específico para registro desde apps móviles (sin CSRF)
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

try {
    $db = getDB();
    
    // Obtener datos del POST (puede venir como JSON o form-data)
    $input = file_get_contents('php://input');
    $data = json_decode($input, true);
    
    // Si no es JSON válido, intentar obtener de $_POST
    if (json_last_error() !== JSON_ERROR_NONE || $data === null) {
        $data = $_POST;
    }
    
    // Extraer datos
    $nombre = trim($data['nombre'] ?? '');
    $apellido = trim($data['apellido'] ?? '');
    $email = trim($data['email'] ?? '');
    $telefono = trim($data['telefono'] ?? '');
    $tipo_documento = $data['tipo_documento'] ?? 'CC';
    $documento = trim($data['documento'] ?? '');
    $password = trim($data['password'] ?? '');
    $password_confirm = trim($data['password_confirm'] ?? '');
    $fecha_nacimiento = !empty($data['fecha_nacimiento']) ? $data['fecha_nacimiento'] : null;
    $genero = $data['genero'] ?? null;
    $direccion = trim($data['direccion'] ?? '');
    $ciudad = trim($data['ciudad'] ?? '');
    
    // Validaciones básicas
    $campos_faltantes = [];
    if (empty($nombre)) $campos_faltantes[] = 'Nombre';
    if (empty($apellido)) $campos_faltantes[] = 'Apellido';
    if (empty($email)) $campos_faltantes[] = 'Email';
    if (empty($documento)) $campos_faltantes[] = 'Número de Documento';
    if (empty($password)) $campos_faltantes[] = 'Contraseña';
    
    if (!empty($campos_faltantes)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Por favor completa los siguientes campos requeridos: ' . implode(', ', $campos_faltantes)
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    // Validar email
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Email inválido'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    // Validar contraseña
    if (strlen($password) < 8) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'La contraseña debe tener al menos 8 caracteres'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    // Verificar que las contraseñas coincidan
    if ($password !== $password_confirm) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Las contraseñas no coinciden'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    // Verificar que el email no esté en uso
    $stmt = $db->prepare("SELECT id FROM usuarios WHERE email = :email");
    $stmt->execute([':email' => $email]);
    if ($stmt->fetch()) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'El email ya está en uso'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    // Verificar que el documento no esté en uso
    $stmt = $db->prepare("SELECT id FROM usuarios WHERE documento = :documento");
    $stmt->execute([':documento' => $documento]);
    if ($stmt->fetch()) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'El documento ya está en uso'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    // Obtener el rol de cliente (normalmente es el rol_id = 3)
    $stmt = $db->prepare("SELECT id FROM roles WHERE nombre = 'cliente' AND activo = 1 LIMIT 1");
    $stmt->execute();
    $rol = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$rol) {
        // Si no existe el rol cliente, usar el primer rol activo disponible
        $stmt = $db->prepare("SELECT id FROM roles WHERE activo = 1 ORDER BY id ASC LIMIT 1");
        $stmt->execute();
        $rol = $stmt->fetch(PDO::FETCH_ASSOC);
    }
    
    if (!$rol) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Error en la configuración del sistema'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    $rol_id = (int)$rol['id'];
    
    // Generar código QR único
    $codigo_qr = 'QR-' . strtoupper(substr($tipo_documento, 0, 2)) . '-' . str_pad($documento, 10, '0', STR_PAD_LEFT);
    
    // Verificar que el código QR sea único
    $stmt = $db->prepare("SELECT id FROM usuarios WHERE codigo_qr = :codigo_qr");
    $stmt->execute([':codigo_qr' => $codigo_qr]);
    $counter = 1;
    while ($stmt->fetch()) {
        $codigo_qr = 'QR-' . strtoupper(substr($tipo_documento, 0, 2)) . '-' . str_pad($documento, 10, '0', STR_PAD_LEFT) . '-' . $counter;
        $counter++;
        $stmt->execute([':codigo_qr' => $codigo_qr]);
    }
    
    // Hash de la contraseña
    $password_hash = password_hash($password, PASSWORD_DEFAULT);
    
    // Insertar usuario
    $sql = "INSERT INTO usuarios (
        rol_id, documento, tipo_documento, nombre, apellido, email, telefono,
        fecha_nacimiento, genero, direccion, ciudad, password, codigo_qr, estado
    ) VALUES (
        :rol_id, :documento, :tipo_documento, :nombre, :apellido, :email, :telefono,
        :fecha_nacimiento, :genero, :direccion, :ciudad, :password, :codigo_qr, 'inactivo'
    )";
    
    $stmt = $db->prepare($sql);
    $result = $stmt->execute([
        ':rol_id' => $rol_id,
        ':documento' => $documento,
        ':tipo_documento' => $tipo_documento,
        ':nombre' => $nombre,
        ':apellido' => $apellido,
        ':email' => $email,
        ':telefono' => $telefono ?: null,
        ':fecha_nacimiento' => $fecha_nacimiento ?: null,
        ':genero' => $genero ?: null,
        ':direccion' => $direccion ?: null,
        ':ciudad' => $ciudad ?: null,
        ':password' => $password_hash,
        ':codigo_qr' => $codigo_qr,
    ]);
    
    if ($result) {
        $user_id = $db->lastInsertId();
        
        // Intentar enviar correo de bienvenida (no fallar si el correo no se envía)
        $email_enviado = false;
        $email_error = null;
        try {
            $email_enviado = enviarCorreoBienvenida($email, $nombre, $apellido, $password);
            if (!$email_enviado) {
                $email_error = "La función de envío retornó false";
            }
        } catch (Exception $e) {
            // Log del error pero no fallar la creación del usuario
            $email_error = $e->getMessage();
            error_log("Error al enviar correo de bienvenida a {$email}: " . $email_error);
        }
        
        $mensaje = 'Usuario registrado exitosamente. Tu cuenta está pendiente de activación.';
        if ($email_enviado) {
            $mensaje .= ' Se ha enviado un correo de bienvenida a tu email con tus credenciales.';
        } else {
            // No mostrar error al usuario, solo loguearlo
            error_log("No se pudo enviar correo de bienvenida a {$email}" . ($email_error ? ': ' . $email_error : ''));
        }
        
        // Respuesta exitosa
        echo json_encode([
            'success' => true,
            'message' => $mensaje,
            'user_id' => (int)$user_id,
            'email_enviado' => $email_enviado
        ], JSON_UNESCAPED_UNICODE);
    } else {
        throw new Exception('Error al insertar usuario');
    }
    
} catch (PDOException $e) {
    error_log("Error en mobile_register.php: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al registrar usuario. Intenta nuevamente.'
    ], JSON_UNESCAPED_UNICODE);
} catch (Exception $e) {
    error_log("Error en mobile_register.php: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al procesar el registro. Intenta nuevamente.'
    ], JSON_UNESCAPED_UNICODE);
}

