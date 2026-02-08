<?php
/**
 * Obtener notificaciones del usuario
 * Endpoint API para obtener las notificaciones de un usuario (dashboard y app móvil)
 */

// Headers para CORS y JSON
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept, Cookie, X-Session-ID');
header('Access-Control-Allow-Credentials: true');

// Manejar preflight OPTIONS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Incluir dependencias primero
require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/auth.php';

// Intentar restaurar sesión desde header X-Session-ID (para apps móviles)
restoreSessionFromHeader();

// Iniciar sesión (necesario para la clase Auth)
// Si restoreSessionFromHeader() ya inició la sesión, esto no hará nada
if (session_status() === PHP_SESSION_NONE) {
    session_start();
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

try {
    $db = getDB();
    $usuario_id = $_SESSION['usuario_id'] ?? null;

    // Validar que tenemos un usuario_id válido
    if (!$usuario_id || !is_numeric($usuario_id)) {
        error_log("[get_notifications] ERROR: usuario_id inválido o NULL - usuario_id=" . var_export($usuario_id, true) . " SID=" . session_id());
        error_log("[get_notifications] SESSION completa: " . json_encode($_SESSION));
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Usuario no identificado correctamente',
            'debug' => [
                'usuario_id' => $usuario_id,
                'session_id' => session_id(),
                'session_keys' => array_keys($_SESSION ?? [])
            ]
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // Log para debugging
    error_log("[get_notifications] Usuario ID: {$usuario_id} SID: " . session_id());

    // Parámetros opcionales
    $solo_no_leidas = isset($_GET['solo_no_leidas']) && $_GET['solo_no_leidas'] === '1';
    $limite = isset($_GET['limite']) ? (int) $_GET['limite'] : 50;
    $offset = isset($_GET['offset']) ? (int) $_GET['offset'] : 0;

    // Primero verificar si hay notificaciones en la BD para este usuario (específicas + globales)
    $stmt_debug = $db->prepare("SELECT COUNT(*) as total FROM notificaciones WHERE (usuario_id = :usuario_id OR usuario_id IS NULL)");
    $stmt_debug->execute([':usuario_id' => $usuario_id]);
    $total_bd = $stmt_debug->fetch()['total'];
    error_log("[get_notifications] Total de notificaciones en BD para usuario_id={$usuario_id} (incluyendo globales): {$total_bd}");

    // Construir consulta
    // IMPORTANTE: Mostrar notificaciones del usuario específico Y notificaciones globales (usuario_id IS NULL)
    // Las notificaciones globales son para todos los usuarios
    // Usar COALESCE para created_at por si no existe la columna
    $sql = "SELECT 
                id,
                usuario_id,
                titulo,
                mensaje,
                tipo,
                leida,
                fecha,
                fecha_leida,
                COALESCE(created_at, fecha) as created_at
            FROM notificaciones
            WHERE (usuario_id = :usuario_id OR usuario_id IS NULL)
            AND id NOT IN (
                SELECT notificacion_id 
                FROM notificaciones_eliminadas 
                WHERE usuario_id = :usuario_id_excl
            )";

    // El filtro de solo_no_leidas se aplicará después de verificar la tabla notificaciones_leidas
    // No lo aplicamos aquí porque necesitamos verificar la tabla para notificaciones globales
    // Para la app móvil, mostrar todas las notificaciones (leídas y no leídas)
    // No aplicar el filtro de 5 minutos que se usa en el dashboard

    $sql .= " ORDER BY fecha DESC LIMIT :limite OFFSET :offset";

    error_log("[get_notifications] SQL: {$sql}");
    error_log("[get_notifications] Parámetros: usuario_id={$usuario_id}, limite={$limite}, offset={$offset}, solo_no_leidas=" . ($solo_no_leidas ? '1' : '0'));

    $stmt = $db->prepare($sql);

    // Asegurar que usuario_id sea un entero
    $usuario_id_int = (int) $usuario_id;
    $stmt->bindValue(':usuario_id', $usuario_id_int, PDO::PARAM_INT);
    $stmt->bindValue(':usuario_id_excl', $usuario_id_int, PDO::PARAM_INT);
    $stmt->bindValue(':limite', $limite, PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);

    error_log("[get_notifications] Ejecutando consulta con usuario_id={$usuario_id_int} (tipo: " . gettype($usuario_id_int) . ")");

    $stmt->execute();

    $notificaciones = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Verificar si existe la tabla notificaciones_leidas
    $table_exists = $db->query("SHOW TABLES LIKE 'notificaciones_leidas'")->rowCount() > 0;

    // Si existe la tabla, obtener qué notificaciones ha leído este usuario
    $notificaciones_leidas = [];
    if ($table_exists) {
        $stmt_leidas = $db->prepare("SELECT notificacion_id FROM notificaciones_leidas WHERE usuario_id = :usuario_id");
        $stmt_leidas->execute([':usuario_id' => $usuario_id_int]);
        $notificaciones_leidas = $stmt_leidas->fetchAll(PDO::FETCH_COLUMN);
    }

    // Log para verificar qué se obtuvo de la BD
    error_log("[get_notifications] Notificaciones obtenidas de BD (antes de formatear): " . count($notificaciones));
    if (count($notificaciones) > 0) {
        error_log("[get_notifications] Primera notificación (raw): " . json_encode($notificaciones[0], JSON_UNESCAPED_UNICODE));
    }

    // Verificar directamente con una consulta sin parámetros para debug (incluyendo globales)
    $stmt_direct = $db->query("SELECT COUNT(*) as total FROM notificaciones WHERE (usuario_id = {$usuario_id_int} OR usuario_id IS NULL)");
    $total_direct = $stmt_direct->fetch()['total'];
    error_log("[get_notifications] Verificación directa (sin parámetros, incluyendo globales): total={$total_direct} para usuario_id={$usuario_id_int}");

    // Log detallado para debugging
    error_log("[get_notifications] Notificaciones encontradas: " . count($notificaciones));
    if (count($notificaciones) > 0) {
        error_log("[get_notifications] Primera notificación: " . json_encode($notificaciones[0], JSON_UNESCAPED_UNICODE));
    } else {
        error_log("[get_notifications] ⚠️ No se encontraron notificaciones para usuario_id={$usuario_id}");
        error_log("[get_notifications] Filtro solo_no_leidas: " . ($solo_no_leidas ? 'SÍ' : 'NO'));

        // Verificar directamente con consulta SQL sin parámetros para debug (incluyendo globales)
        $sql_debug = "SELECT COUNT(*) as total FROM notificaciones WHERE (usuario_id = {$usuario_id_int} OR usuario_id IS NULL)";
        if ($solo_no_leidas) {
            $sql_debug .= " AND leida = 0";
        }
        $stmt_debug2 = $db->query($sql_debug);
        $total_debug = $stmt_debug2->fetch()['total'];
        error_log("[get_notifications] Consulta directa SQL (incluyendo globales): {$sql_debug} -> total={$total_debug}");

        // Verificar todas las notificaciones sin filtro (específicas + globales)
        $stmt_all = $db->prepare("SELECT COUNT(*) as total FROM notificaciones WHERE (usuario_id = :usuario_id OR usuario_id IS NULL)");
        $stmt_all->execute([':usuario_id' => $usuario_id_int]);
        $total_all = $stmt_all->fetch()['total'];
        error_log("[get_notifications] Total de notificaciones (todas, sin filtro, incluyendo globales): {$total_all}");

        // Verificar no leídas (específicas + globales)
        $stmt_unread = $db->prepare("SELECT COUNT(*) as total FROM notificaciones WHERE (usuario_id = :usuario_id OR usuario_id IS NULL) AND leida = 0");
        $stmt_unread->execute([':usuario_id' => $usuario_id_int]);
        $total_unread = $stmt_unread->fetch()['total'];
        error_log("[get_notifications] Total de notificaciones (no leídas, incluyendo globales): {$total_unread}");
    }

    // Formatear fechas y asegurar que leida sea un entero (0 o 1) para compatibilidad con Flutter
    $notificaciones_procesadas = [];
    foreach ($notificaciones as $notif) {
        // Asegurar que todos los campos requeridos estén presentes
        if (!isset($notif['id']) || !isset($notif['titulo']) || !isset($notif['mensaje'])) {
            error_log("[get_notifications] ⚠️ Notificación con campos faltantes: " . json_encode($notif, JSON_UNESCAPED_UNICODE));
            continue;
        }

        // Para notificaciones globales (usuario_id IS NULL), verificar si el usuario la ha leído
        if ($notif['usuario_id'] === null && $table_exists) {
            // Si está en la tabla notificaciones_leidas, está leída para este usuario
            $notif['leida'] = in_array($notif['id'], $notificaciones_leidas) ? 1 : 0;
        } else {
            // Para notificaciones específicas, usar el campo leida de la tabla
            $notif['leida'] = (int) $notif['leida'];
        }

        // Aplicar filtro solo_no_leidas después de determinar el estado de leída
        if ($solo_no_leidas && $notif['leida'] == 1) {
            continue; // Saltar notificaciones leídas si se solicita solo no leídas
        }

        // Asegurar que tipo tenga un valor por defecto
        if (!isset($notif['tipo']) || empty($notif['tipo'])) {
            $notif['tipo'] = 'info';
        }

        // Formatear fecha - asegurar que sea un string válido
        if (isset($notif['fecha']) && $notif['fecha']) {
            $notif['fecha_formateada'] = date('d/m/Y H:i', strtotime($notif['fecha']));
            $notif['hace'] = getTimeAgo($notif['fecha']);
        } else {
            $notif['fecha'] = date('Y-m-d H:i:s'); // Fecha por defecto si no existe
            $notif['fecha_formateada'] = date('d/m/Y H:i');
            $notif['hace'] = 'Hace un momento';
        }

        // Incluir fecha_leida si existe (formato ISO para JavaScript)
        if (isset($notif['fecha_leida']) && $notif['fecha_leida']) {
            $notif['fecha_leida'] = date('c', strtotime($notif['fecha_leida'])); // Formato ISO 8601
        } else {
            $notif['fecha_leida'] = null; // Asegurar que sea null si no existe
        }

        // Agregar a la lista procesada
        $notificaciones_procesadas[] = $notif;
    }

    // Usar las notificaciones procesadas
    $notificaciones = $notificaciones_procesadas;

    // Obtener total de no leídas (del usuario específico + globales)
    // Para notificaciones específicas: usar campo leida
    // Para notificaciones globales: verificar tabla notificaciones_leidas
    if ($table_exists) {
        $stmt_count = $db->prepare("
            SELECT COUNT(*) as total 
            FROM notificaciones n
            WHERE (n.usuario_id = :usuario_id OR n.usuario_id IS NULL)
            AND n.id NOT IN (
                SELECT notificacion_id 
                FROM notificaciones_eliminadas 
                WHERE usuario_id = :usuario_id_del
            )
            AND (
                (n.usuario_id = :usuario_id2 AND n.leida = 0)
                OR 
                (n.usuario_id IS NULL AND n.id NOT IN (
                    SELECT notificacion_id 
                    FROM notificaciones_leidas 
                    WHERE usuario_id = :usuario_id3
                ))
            )
        ");
        $stmt_count->bindValue(':usuario_id', $usuario_id_int, PDO::PARAM_INT);
        $stmt_count->bindValue(':usuario_id_del', $usuario_id_int, PDO::PARAM_INT);
        $stmt_count->bindValue(':usuario_id2', $usuario_id_int, PDO::PARAM_INT);
        $stmt_count->bindValue(':usuario_id3', $usuario_id_int, PDO::PARAM_INT);
        $stmt_count->execute();
        $total_no_leidas = $stmt_count->fetch()['total'];
    } else {
        // Fallback si la tabla no existe aún
        $stmt_count = $db->prepare("
            SELECT COUNT(*) as total 
            FROM notificaciones 
            WHERE (usuario_id = :usuario_id OR usuario_id IS NULL) AND leida = 0
        ");
        $stmt_count->execute([':usuario_id' => $usuario_id_int]);
        $total_no_leidas = $stmt_count->fetch()['total'];
    }

    // Obtener total de todas (no eliminadas para este usuario)
    $stmt_todas_count = $db->prepare("
        SELECT COUNT(*) as total 
        FROM notificaciones n
        WHERE (n.usuario_id = :usuario_id OR n.usuario_id IS NULL)
        AND n.id NOT IN (
            SELECT notificacion_id 
            FROM notificaciones_eliminadas 
            WHERE usuario_id = :usuario_id_del
        )
    ");
    $stmt_todas_count->execute([
        ':usuario_id' => $usuario_id_int,
        ':usuario_id_del' => $usuario_id_int
    ]);
    $total_todas = $stmt_todas_count->fetch()['total'];

    $response = [
        'success' => true,
        'notificaciones' => $notificaciones,
        'total_no_leidas' => (int) $total_no_leidas,
        'total_todas' => (int) $total_todas,
        'total' => count($notificaciones),
        'total_en_bd' => (int) $total_bd, // Para debug
        'usuario_id' => (int) $usuario_id, // Para debug
        'solo_no_leidas' => $solo_no_leidas // Para debug
    ];

    // Log completo de la respuesta para debugging
    $json_response = json_encode($response, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    error_log("[get_notifications] Respuesta JSON completa (longitud: " . strlen($json_response) . " chars)");
    error_log("[get_notifications] Respuesta JSON (primeros 1000 chars): " . substr($json_response, 0, 1000));
    error_log("[get_notifications] Total de notificaciones en respuesta: " . count($notificaciones));
    if (count($notificaciones) > 0) {
        error_log("[get_notifications] Primera notificación en respuesta: " . json_encode($notificaciones[0], JSON_UNESCAPED_UNICODE));
    }

    echo $json_response;

} catch (Exception $e) {
    error_log("[get_notifications] ❌ EXCEPCIÓN: " . $e->getMessage());
    error_log("[get_notifications] ❌ Stack trace: " . $e->getTraceAsString());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al obtener notificaciones: ' . $e->getMessage(),
        'error_type' => get_class($e),
        'file' => $e->getFile(),
        'line' => $e->getLine()
    ], JSON_UNESCAPED_UNICODE);
}

/**
 * Función helper para calcular tiempo relativo
 */
function getTimeAgo($datetime)
{
    $timestamp = strtotime($datetime);
    $diff = time() - $timestamp;

    if ($diff < 60) {
        return 'Hace un momento';
    } elseif ($diff < 3600) {
        $mins = floor($diff / 60);
        return "Hace $mins minuto" . ($mins > 1 ? 's' : '');
    } elseif ($diff < 86400) {
        $hours = floor($diff / 3600);
        return "Hace $hours hora" . ($hours > 1 ? 's' : '');
    } elseif ($diff < 604800) {
        $days = floor($diff / 86400);
        return "Hace $days día" . ($days > 1 ? 's' : '');
    } else {
        return date('d/m/Y', $timestamp);
    }
}

