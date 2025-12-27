<?php
/**
 * Crear nuevo usuario
 * Endpoint API para crear un nuevo usuario en el sistema
 */

session_start();
header('Content-Type: application/json');
require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/../database/config_helpers.php';
require_once __DIR__ . '/../database/csrf_helper.php';
require_once __DIR__ . '/auth.php';

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

// Verificar rol (solo admin o entrenador)
if (!$auth->hasRole(['admin', 'entrenador'])) {
    http_response_code(403);
    echo json_encode([
        'success' => false,
        'message' => 'No autorizado'
    ]);
    exit;
}

// Validar token CSRF
requireCSRFToken(true);

try {
    $db = getDB();
    
    // Obtener datos del POST
    $nombre = trim($_POST['nombre'] ?? '');
    $apellido = trim($_POST['apellido'] ?? '');
    $email = trim($_POST['email'] ?? '');
    $telefono = trim($_POST['telefono'] ?? '');
    $tipo_documento = $_POST['tipo_documento'] ?? 'CC';
    $documento = trim($_POST['documento'] ?? '');
    $rol_id = isset($_POST['rol_id']) ? (int)$_POST['rol_id'] : 0;
    $password = trim($_POST['password'] ?? '');
    $password_confirm = trim($_POST['password_confirm'] ?? '');
    $fecha_nacimiento = !empty($_POST['fecha_nacimiento']) ? $_POST['fecha_nacimiento'] : null;
    $genero = $_POST['genero'] ?? null;
    $direccion = trim($_POST['direccion'] ?? '');
    $ciudad = trim($_POST['ciudad'] ?? '');
    // El estado siempre será 'inactivo' para nuevos usuarios sin membresía
    $estado = 'inactivo';
    
    // Validaciones básicas con mensajes específicos
    $campos_faltantes = [];
    if (empty($nombre)) $campos_faltantes[] = 'Nombre';
    if (empty($apellido)) $campos_faltantes[] = 'Apellido';
    if (empty($email)) $campos_faltantes[] = 'Email';
    if (empty($documento)) $campos_faltantes[] = 'Número de Documento';
    if ($rol_id <= 0) $campos_faltantes[] = 'Rol';
    if (empty($password)) $campos_faltantes[] = 'Contraseña';
    
    if (!empty($campos_faltantes)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Por favor completa los siguientes campos requeridos: ' . implode(', ', $campos_faltantes)
        ]);
        exit;
    }
    
    // Validar email
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Email inválido'
        ]);
        exit;
    }
    
    // Validar contraseña
    if (strlen($password) < 8) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'La contraseña debe tener al menos 8 caracteres'
        ]);
        exit;
    }
    
    // Verificar que las contraseñas coincidan
    if ($password !== $password_confirm) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Las contraseñas no coinciden'
        ]);
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
        ]);
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
        ]);
        exit;
    }
    
    // Verificar que el rol existe
    $stmt = $db->prepare("SELECT id FROM roles WHERE id = :rol_id AND activo = 1");
    $stmt->execute([':rol_id' => $rol_id]);
    if (!$stmt->fetch()) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Rol inválido'
        ]);
        exit;
    }
    
    // Generar código QR único
    $codigo_qr = 'QR-' . strtoupper(substr($tipo_documento, 0, 2)) . '-' . str_pad($documento, 10, '0', STR_PAD_LEFT);
    
    // Verificar que el código QR sea único (por si acaso)
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
        :fecha_nacimiento, :genero, :direccion, :ciudad, :password, :codigo_qr, :estado
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
        ':estado' => $estado
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
        
        $mensaje = 'Usuario creado correctamente';
        if ($email_enviado) {
            $mensaje .= '. Se ha enviado un correo de bienvenida al usuario.';
        } else {
            $mensaje .= '. Nota: No se pudo enviar el correo de bienvenida' . ($email_error ? ': ' . $email_error : '') . '.';
        }
        
        echo json_encode([
            'success' => true,
            'message' => $mensaje,
            'user_id' => $user_id,
            'email_enviado' => $email_enviado,
            'email_error' => $email_error
        ], JSON_UNESCAPED_UNICODE);
    } else {
        throw new Exception('Error al insertar el usuario');
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al crear usuario: ' . $e->getMessage()
    ]);
}

