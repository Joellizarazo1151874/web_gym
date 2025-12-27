<?php
/**
 * Devuelve el último código tecleado para check-in si no supera 3 segundos.
 * Limpia automáticamente el valor si expira.
 */
require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/../database/config_helpers.php';

header('Content-Type: application/json; charset=utf-8');

try {
    $db = getDB();
    $data = obtenerConfiguracion($db, 'checkin_live_input');

    $now = time();
    $ttlSeconds = 3;
    $code = null;
    $ts = null;

    if (is_array($data) && isset($data['ts'], $data['code'])) {
        $age = $now - (int)$data['ts'];
        if ($age <= $ttlSeconds && !empty($data['code'])) {
            $code = preg_replace('/\D+/', '', (string)$data['code']);
            $code = substr($code, 0, 20);
            $ts = (int)$data['ts'];
        } else {
            // Expirado: limpiar
            guardarConfiguracion($db, 'checkin_live_input', ['code' => '', 'ts' => $now], 'json');
        }
    }

    echo json_encode([
        'success' => true,
        'code' => $code,
        'ts' => $ts
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Error al obtener']);
}

