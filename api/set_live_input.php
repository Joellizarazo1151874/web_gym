<?php
/**
 * Guarda temporalmente el código de cédula tecleado para mostrarlo en gym-checkin.
 * Vida útil: 3 segundos (se gestiona en get_live_input).
 */
require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/../database/config_helpers.php';

header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Método no permitido']);
    exit;
}

try {
    $db = getDB();
    $rawCode = $_POST['code'] ?? '';
    // Solo dígitos; limita longitud
    $code = preg_replace('/\D+/', '', $rawCode);
    $code = substr($code, 0, 20);

    $payload = [
        'code' => $code,
        'ts'   => time()
    ];

    guardarConfiguracion($db, 'checkin_live_input', $payload, 'json');

    echo json_encode([
        'success' => true,
        'code' => $code,
        'ts' => $payload['ts']
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Error al guardar']);
}

