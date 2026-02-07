<?php
/**
 * Obtener la lista de chats del usuario autenticado
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

restoreSessionFromHeader();

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

$auth = new Auth();
if (!$auth->isAuthenticated()) {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'message' => 'No autenticado',
    ]);
    exit;
}

try {
    $db = getDB();
    $usuarioId = $_SESSION['usuario_id'] ?? null;

    $sql = "
        SELECT 
            c.id,
            c.nombre,
            c.es_grupal,
            c.creado_en,
            m.mensaje AS ultimo_mensaje,
            m.creado_en AS ultimo_mensaje_en,
            u.nombre AS ultimo_remitente_nombre,
            u.apellido AS ultimo_remitente_apellido,
            (
                SELECT COUNT(1)
                FROM chat_mensajes cmu
                WHERE cmu.chat_id = c.id
                  AND cmu.remitente_id <> ?
                  AND (cmu.leido = 0 OR cmu.leido IS NULL)
            ) AS unread_count,
            (
                SELECT cp2.usuario_id
                FROM chat_participantes cp2
                WHERE cp2.chat_id = c.id AND cp2.usuario_id <> ?
                LIMIT 1
            ) AS otro_usuario_id,
            (
                SELECT CONCAT_WS(' ', u2.nombre, u2.apellido)
                FROM chat_participantes cp2
                INNER JOIN usuarios u2 ON u2.id = cp2.usuario_id
                WHERE cp2.chat_id = c.id AND cp2.usuario_id <> ?
                LIMIT 1
            ) AS nombre_otro,
            (
                SELECT u2.foto
                FROM chat_participantes cp2
                INNER JOIN usuarios u2 ON u2.id = cp2.usuario_id
                WHERE cp2.chat_id = c.id AND cp2.usuario_id <> ?
                LIMIT 1
            ) AS foto_otro
        FROM chats c
        INNER JOIN chat_participantes cp ON cp.chat_id = c.id
        LEFT JOIN chat_mensajes m ON m.id = (
            SELECT cm2.id 
            FROM chat_mensajes cm2 
            WHERE cm2.chat_id = c.id 
            ORDER BY cm2.creado_en DESC 
            LIMIT 1
        )
        LEFT JOIN usuarios u ON u.id = m.remitente_id
        WHERE cp.usuario_id = ?
        ORDER BY m.creado_en DESC, c.creado_en DESC
    ";

    $stmt = $db->prepare($sql);
    $stmt->execute([$usuarioId, $usuarioId, $usuarioId, $usuarioId, $usuarioId]);
    $chats = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $baseUrl = getBaseUrl();

    foreach ($chats as &$chat) {
        $chat['es_grupal'] = (bool) $chat['es_grupal'];
        $chat['unread_count'] = (int) ($chat['unread_count'] ?? 0);

        $fotoRaw = null;

        if ($chat['es_grupal']) {
            if (empty($chat['nombre'])) {
                $chat['nombre'] = 'Chat grupal';
            }
            // Aquí podrías agregar lógica para foto de grupo si tu tabla chats tiene columna 'foto'
            // $fotoRaw = $chat['foto_grupo']; 
        } else {
            // Para chat privado, obtener el apodo si existe
            $otroUsuarioId = isset($chat['otro_usuario_id']) ? (int) $chat['otro_usuario_id'] : null;
            $apodoContacto = null;

            // Usar la foto del otro usuario
            $fotoRaw = $chat['foto_otro'] ?? null;

            if ($otroUsuarioId) {
                // Buscar el apodo en friend_requests
                $stmtApodo = $db->prepare("
                    SELECT 
                        CASE 
                            WHEN de_usuario_id = ? THEN apodo
                            WHEN para_usuario_id = ? THEN apodo_inverso
                            ELSE NULL
                        END AS apodo
                    FROM friend_requests
                    WHERE estado = 'aceptada'
                      AND (
                          (de_usuario_id = ? AND para_usuario_id = ?)
                          OR (de_usuario_id = ? AND para_usuario_id = ?)
                      )
                    LIMIT 1
                ");
                $stmtApodo->execute([$usuarioId, $usuarioId, $usuarioId, $otroUsuarioId, $otroUsuarioId, $usuarioId]);
                $apodoRow = $stmtApodo->fetch(PDO::FETCH_ASSOC);
                if ($apodoRow && !empty($apodoRow['apodo'])) {
                    $apodoContacto = trim($apodoRow['apodo']);
                }
            }

            $nombreOtro = trim($chat['nombre_otro'] ?? '');

            if ($apodoContacto !== null && $apodoContacto !== '') {
                // Si hay apodo, usarlo
                $chat['nombre'] = $apodoContacto;
            } else if ($nombreOtro !== '') {
                // Si no hay apodo, usar el nombre real
                $chat['nombre'] = $nombreOtro;
            } else {
                $chat['nombre'] = 'Chat privado';
            }
        }

        // Procesar URL de foto
        if (!empty($fotoRaw)) {
            if (strpos($fotoRaw, 'http') === 0) {
                $chat['foto'] = $fotoRaw;
            } else {
                $chat['foto'] = $baseUrl . 'uploads/usuarios/' . $fotoRaw;
            }
        } else {
            $chat['foto'] = null;
        }

        if (!empty($chat['ultimo_remitente_nombre']) || !empty($chat['ultimo_remitente_apellido'])) {
            $chat['ultimo_remitente'] = trim(($chat['ultimo_remitente_nombre'] ?? '') . ' ' . ($chat['ultimo_remitente_apellido'] ?? ''));
        } else {
            $chat['ultimo_remitente'] = null;
        }
    }

    error_log("[mobile_get_chats] usuario={$usuarioId} total=" . count($chats));

    echo json_encode([
        'success' => true,
        'chats' => $chats,
        'total' => count($chats),
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al obtener chats: ' . $e->getMessage(),
    ]);
}

