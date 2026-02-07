<?php
/**
 * Obtener datos actualizados del usuario actual
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept, Cookie, X-Session-ID');
header('Access-Control-Allow-Credentials: true');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/auth.php';

// LOG 1: Ver headers recibidos
error_log("=== INICIO mobile_get_current_user.php ===");
error_log("HTTP_X_SESSION_ID: " . ($_SERVER['HTTP_X_SESSION_ID'] ?? 'NO PRESENTE'));
error_log("Todos los headers: " . json_encode(getallheaders()));

// Restaurar sesión desde header
$restored = restoreSessionFromHeader();
error_log("restoreSessionFromHeader() retornó: " . ($restored ? 'TRUE' : 'FALSE'));

if (session_status() === PHP_SESSION_NONE) {
    error_log("Iniciando nueva sesión...");
    session_start();
} else {
    error_log("Sesión ya activa: " . session_id());
}

error_log("Session ID actual: " . session_id());
error_log("Contenido de \$_SESSION: " . json_encode($_SESSION));

$auth = new Auth();
$isAuth = $auth->isAuthenticated();
error_log("isAuthenticated() retornó: " . ($isAuth ? 'TRUE' : 'FALSE'));

if (!$isAuth) {
    error_log("❌ Usuario NO autenticado - enviando 401");
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'message' => 'No autenticado'
    ]);
    exit;
}

try {
    $db = getDB();
    $userId = $_SESSION['usuario_id'] ?? null;

    // LOG para debugging
    error_log("mobile_get_current_user.php - Session ID: " . session_id());
    error_log("mobile_get_current_user.php - usuario_id en sesión: " . ($userId ?? 'NULL'));
    error_log("mobile_get_current_user.php - Toda la sesión: " . json_encode($_SESSION));
    error_log("mobile_get_current_user.php - X-Session-ID header: " . ($_SERVER['HTTP_X_SESSION_ID'] ?? 'NO PRESENTE'));

    if (!$userId) {
        http_response_code(401);
        echo json_encode([
            'success' => false,
            'message' => 'No autenticado'
        ]);
        exit;
    }

    // Obtener datos del usuario
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
    $stmt->execute([':usuario_id' => $userId]);
    $usuario = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$usuario) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Usuario no encontrado'
        ]);
        exit;
    }

    // Obtener membresía activa (la más reciente)
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
    $stmt->execute([':usuario_id' => $userId]);
    $membresia = $stmt->fetch(PDO::FETCH_ASSOC);


    // --- ESTADÍSTICAS DE ASISTENCIA ---
    // 1) Asistencias del mes (días distintos)
    $stmt = $db->prepare("
        SELECT COUNT(DISTINCT DATE(fecha_entrada)) 
        FROM asistencias 
        WHERE usuario_id = :uid 
        AND MONTH(fecha_entrada) = MONTH(CURDATE()) 
        AND YEAR(fecha_entrada) = YEAR(CURDATE())
    ");
    $stmt->execute([':uid' => $userId]);
    $asistenciasMes = (int) $stmt->fetchColumn();

    // 2) Racha actual (días consecutivos)
    $stmt = $db->prepare("
        SELECT DISTINCT DATE(fecha_entrada) as fecha 
        FROM asistencias 
        WHERE usuario_id = :uid 
        ORDER BY fecha DESC
    ");
    $stmt->execute([':uid' => $userId]);
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


    // Construir URL de foto si existe
    $foto_url = null;
    if (!empty($usuario['foto'])) {
        if (strpos($usuario['foto'], 'http') === 0) {
            $foto_url = $usuario['foto'];
        } else {
            $baseUrl = getBaseUrl();
            $foto_url = $baseUrl . 'uploads/usuarios/' . $usuario['foto'];
        }
    }


    // Respuesta exitosa (formato idéntico a mobile_login.php)
    $response = [
        'success' => true,
        'user' => [
            'id' => (int) $usuario['id'],
            'nombre' => $usuario['nombre'],
            'apellido' => $usuario['apellido'],
            'email' => $usuario['email'],
            'telefono' => $usuario['telefono'],
            'documento' => $usuario['documento'],
            'foto' => $foto_url,
            'rol' => $usuario['rol'],
            'estado' => $usuario['estado'],
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
    ];

    echo json_encode($response, JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error en el servidor',
        'error' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
?>