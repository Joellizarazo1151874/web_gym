<?php
/**
 * Login para Aplicación Móvil
 * Endpoint específico para apps móviles
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

// Iniciar sesión (necesario para la clase Auth)
session_start();

// Incluir dependencias
require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/../database/rate_limit_helper.php';
require_once __DIR__ . '/auth.php';

try {
    // Verificar rate limiting (5 intentos, 15 minutos)
    $rateLimit = checkRateLimit('mobile_login', 5, 15);
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

    // Obtener datos del POST (puede venir como JSON o form-data)
    $input = file_get_contents('php://input');
    $data = json_decode($input, true);

    // Si no es JSON válido, intentar obtener de $_POST
    if (json_last_error() !== JSON_ERROR_NONE || $data === null) {
        $data = $_POST;
    }

    // Extraer datos
    $email = trim($data['email'] ?? '');
    $password = $data['password'] ?? '';

    // Validar email
    if (empty($email) || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
        recordFailedAttempt('mobile_login');
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Email inválido'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // Validar contraseña
    if (empty($password)) {
        recordFailedAttempt('mobile_login');
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Contraseña requerida'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // Intentar login usando la clase Auth
    $auth = new Auth();
    $resultado = $auth->login($email, $password, false);

    // Si el login falló
    if (!$resultado['success']) {
        recordFailedAttempt('mobile_login');
        $rateLimitInfo = getRateLimitInfo('mobile_login', 5, 15);

        $rateLimitData = [
            'remaining' => $rateLimitInfo['remaining'],
            'lockout_until' => $rateLimitInfo['lockout_until']
        ];

        // Advertir si quedan pocos intentos
        $mensaje = $resultado['message'];
        if ($rateLimitInfo['remaining'] <= 2 && $rateLimitInfo['remaining'] > 0) {
            $mensaje .= " Te quedan {$rateLimitInfo['remaining']} intento(s) antes del bloqueo temporal.";
        }

        http_response_code(401);
        echo json_encode([
            'success' => false,
            'message' => $mensaje,
            'rate_limit' => $rateLimitData
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // Login exitoso - limpiar intentos fallidos
    clearFailedAttempts('mobile_login');

    // Obtener información completa del usuario y membresía
    $db = getDB();
    $usuario_id = $_SESSION['usuario_id'] ?? null;

    if (!$usuario_id) {
        throw new Exception('Error al obtener ID de usuario');
    }

    // Obtener datos completos del usuario
    $stmt = $db->prepare("
        SELECT 
            u.id,
            u.nombre,
            u.apellido,
            u.email,
            u.telefono,
            u.documento,
            u.foto,
            u.estado,
            r.nombre as rol
        FROM usuarios u
        LEFT JOIN roles r ON u.rol_id = r.id
        WHERE u.id = :usuario_id
    ");
    $stmt->execute([':usuario_id' => $usuario_id]);
    $usuario_completo = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$usuario_completo) {
        throw new Exception('Error al obtener datos del usuario');
    }

    // Obtener membresía activa del usuario (la más reciente)
    $stmt = $db->prepare("
        SELECT 
            m.id,
            m.plan_id,
            m.fecha_inicio,
            m.fecha_fin,
            m.estado,
            p.nombre as plan_nombre,
            p.precio as plan_precio,
            DATEDIFF(m.fecha_fin, CURDATE()) as dias_restantes
        FROM membresias m
        LEFT JOIN planes p ON m.plan_id = p.id
        WHERE m.usuario_id = :usuario_id
        ORDER BY 
            CASE WHEN m.estado = 'activa' THEN 1 ELSE 2 END,
            m.fecha_fin DESC
        LIMIT 1
    ");
    $stmt->execute([':usuario_id' => $usuario_id]);
    $membresia = $stmt->fetch(PDO::FETCH_ASSOC);


    // --- ESTADÍSTICAS DE ASISTENCIA ---
    // 1) Asistencias del mes
    $stmt = $db->prepare("SELECT COUNT(DISTINCT DATE(fecha_entrada)) FROM asistencias WHERE usuario_id = :uid AND MONTH(fecha_entrada) = MONTH(CURDATE()) AND YEAR(fecha_entrada) = YEAR(CURDATE())");
    $stmt->execute([':uid' => $usuario_id]);
    $asistenciasMes = (int) $stmt->fetchColumn();

    // 2) Racha actual
    $stmt = $db->prepare("SELECT DISTINCT DATE(fecha_entrada) as fecha FROM asistencias WHERE usuario_id = :uid ORDER BY fecha DESC");
    $stmt->execute([':uid' => $usuario_id]);
    $fechas = $stmt->fetchAll(PDO::FETCH_COLUMN);
    $racha = 0;
    if (!empty($fechas)) {
        $hoy = date('Y-m-d');
        $esRachaActiva = true;

        // 1) Verificar si la racha se rompió por inasistencia en días de semana
        if ($fechas[0] !== $hoy) {
            $checkDate = date('Y-m-d', strtotime('yesterday'));
            while ($checkDate > $fechas[0]) {
                $dayOfWeek = (int) date('N', strtotime($checkDate));
                if ($dayOfWeek >= 1 && $dayOfWeek <= 5) { // Lunes a Viernes
                    $esRachaActiva = false;
                    break;
                }
                $checkDate = date('Y-m-d', strtotime($checkDate . ' -1 day'));
            }
        }

        if ($esRachaActiva) {
            $racha = 1;
            for ($i = 0; $i < count($fechas) - 1; $i++) {
                $actual = $fechas[$i];
                $siguiente = $fechas[$i + 1];

                // Verificar los días en el hueco entre asistencias
                $gapDate = date('Y-m-d', strtotime($actual . ' -1 day'));
                $huecoValido = true;
                while ($gapDate > $siguiente) {
                    $dw = (int) date('N', strtotime($gapDate));
                    if ($dw >= 1 && $dw <= 5) {
                        $huecoValido = false;
                        break;
                    }
                    $gapDate = date('Y-m-d', strtotime($gapDate . ' -1 day'));
                }

                if ($huecoValido) {
                    $racha++;
                } else {
                    break;
                }
            }
        }
    }


    // Log para debugging (solo en desarrollo)
    if (!$membresia) {
        error_log("Mobile Login - Usuario ID $usuario_id: No se encontró membresía activa");

        // Verificar si tiene membresías en otros estados
        $stmt = $db->prepare("
            SELECT m.id, m.estado, m.fecha_fin, p.nombre as plan_nombre
            FROM membresias m
            LEFT JOIN planes p ON m.plan_id = p.id
            WHERE m.usuario_id = :usuario_id
            ORDER BY m.fecha_fin DESC
            LIMIT 5
        ");
        $stmt->execute([':usuario_id' => $usuario_id]);
        $todas_membresias = $stmt->fetchAll(PDO::FETCH_ASSOC);
        if (!empty($todas_membresias)) {
            error_log("Mobile Login - Usuario ID $usuario_id: Membresías encontradas: " . json_encode($todas_membresias));
        }
    }

    // Construir URL de foto si existe
    $foto_url = null;
    if (!empty($usuario_completo['foto'])) {
        $baseUrl = getBaseUrl();
        $foto_url = $baseUrl . 'uploads/usuarios/' . $usuario_completo['foto'];
    }

    // Generar token de sesión
    $session_token = session_id();

    // Respuesta exitosa
    echo json_encode([
        'success' => true,
        'message' => 'Login exitoso',
        'token' => $session_token,
        'user' => [
            'id' => (int) $usuario_completo['id'],
            'nombre' => $usuario_completo['nombre'],
            'apellido' => $usuario_completo['apellido'],
            'email' => $usuario_completo['email'],
            'telefono' => $usuario_completo['telefono'],
            'documento' => $usuario_completo['documento'],
            'foto' => $foto_url,
            'rol' => $usuario_completo['rol'],
            'estado' => $usuario_completo['estado'],
            'asistencias_mes' => $asistenciasMes,
            'racha_actual' => $racha
        ],

        'membership' => $membresia ? [
            'id' => (int) $membresia['id'],
            'plan_nombre' => $membresia['plan_nombre'],
            'fecha_inicio' => $membresia['fecha_inicio'],
            'fecha_fin' => $membresia['fecha_fin'],
            'estado' => $membresia['estado'],
            'dias_restantes' => (int) $membresia['dias_restantes']
        ] : null
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);

} catch (Exception $e) {
    error_log("Error en mobile_login.php: " . $e->getMessage());
    error_log("Stack trace: " . $e->getTraceAsString());

    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al procesar el login. Intenta nuevamente.'
    ], JSON_UNESCAPED_UNICODE);
}
