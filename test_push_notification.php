<?php
/**
 * Script de prueba para verificar que las notificaciones push funcionen
 * 
 * Uso desde línea de comandos: php test_push_notification.php [token_fcm]
 * Uso desde navegador: test_push_notification.php?token=[token_fcm]
 */

// Configurar headers para navegador
if (php_sapi_name() !== 'cli') {
    header('Content-Type: text/html; charset=utf-8');
    echo '<!DOCTYPE html><html><head><meta charset="UTF-8"><title>Test Push Notification</title>';
    echo '<style>body{font-family:monospace;padding:20px;background:#1e1e1e;color:#d4d4d4;}';
    echo '.success{color:#4ec9b0;} .error{color:#f48771;} .info{color:#569cd6;}';
    echo 'pre{background:#252526;padding:10px;border-radius:5px;overflow-x:auto;}</style></head><body>';
    echo '<pre>';
}

require_once __DIR__ . '/database/config.php';
require_once __DIR__ . '/database/helpers/push_notification_helper.php';

// Obtener token FCM del argumento (CLI), parámetro GET (navegador) o de la base de datos
if (php_sapi_name() === 'cli') {
    $tokenFCM = $argv[1] ?? null;
} else {
    $tokenFCM = $_GET['token'] ?? null;
}

if (!$tokenFCM) {
    // Obtener todos los tokens activos de la base de datos
    $db = getDB();
    $stmt = $db->query("SELECT token, usuario_id, plataforma, created_at, updated_at FROM fcm_tokens WHERE activo = 1 ORDER BY updated_at DESC");
    $tokens = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (empty($tokens)) {
        echo "❌ No hay tokens FCM registrados en la base de datos.\n";
        echo "   Primero inicia sesión en la app para registrar un token.\n";
        exit(1);
    }
    
    echo "📱 Tokens encontrados en la base de datos:\n";
    foreach ($tokens as $idx => $tokenData) {
        echo "   " . ($idx + 1) . ". Usuario ID: {$tokenData['usuario_id']}, Plataforma: {$tokenData['plataforma']}, Actualizado: {$tokenData['updated_at']}\n";
        echo "      Token: " . substr($tokenData['token'], 0, 30) . "...\n";
    }
    
    // Usar el más reciente
    $tokenFCM = $tokens[0]['token'];
    echo "\n📱 Usando el token más reciente: " . substr($tokenFCM, 0, 20) . "...\n";
} else {
    echo "📱 Usando token proporcionado: " . substr($tokenFCM, 0, 20) . "...\n";
}

// Verificar configuración
echo "\n🔍 Verificando configuración...\n";

$db = getDB();
$stmt = $db->prepare("SELECT valor FROM configuracion WHERE clave = 'fcm_credentials_path'");
$stmt->execute();
$config = $stmt->fetch(PDO::FETCH_ASSOC);
$credentialsPath = $config['valor'] ?? __DIR__ . '/config/firebase-credentials.json';

if (!file_exists($credentialsPath)) {
    echo "❌ Error: Archivo de credenciales no encontrado: $credentialsPath\n";
    exit(1);
}
echo "✅ Archivo de credenciales encontrado: $credentialsPath\n";

$credentials = json_decode(file_get_contents($credentialsPath), true);
if (!$credentials) {
    echo "❌ Error: No se pudo leer el archivo de credenciales\n";
    exit(1);
}
echo "✅ Credenciales leídas correctamente\n";
echo "   Project ID: " . ($credentials['project_id'] ?? 'NO ENCONTRADO') . "\n";

// Probar obtener token OAuth2
echo "\n🔐 Obteniendo token OAuth2...\n";
$accessToken = getFCMAccessToken($credentialsPath);
if (!$accessToken) {
    echo "❌ Error: No se pudo obtener token de acceso OAuth2\n";
    exit(1);
}
echo "✅ Token OAuth2 obtenido: " . substr($accessToken, 0, 20) . "...\n";

// Enviar notificación de prueba
echo "\n📤 Enviando notificación de prueba...\n";
$result = sendPushNotification(
    $tokenFCM,
    "🧪 Prueba de Notificación",
    "Si recibes esto, las notificaciones push están funcionando correctamente!",
    ['type' => 'test', 'timestamp' => time()],
    null // Sin imagen por ahora
);

if ($result['success']) {
    echo "✅ Notificación enviada correctamente!\n";
    echo "   Respuesta: " . json_encode($result['response'] ?? [], JSON_PRETTY_PRINT) . "\n";
} else {
    echo "❌ Error al enviar notificación:\n";
    echo "   Mensaje: " . $result['message'] . "\n";
    if (isset($result['response'])) {
        echo "   Respuesta: " . json_encode($result['response'], JSON_PRETTY_PRINT) . "\n";
    }
    exit(1);
}

echo "\n✅ Prueba completada. Revisa tu dispositivo para ver la notificación.\n";

// Cerrar HTML si se ejecuta desde navegador
if (php_sapi_name() !== 'cli') {
    echo '</pre></body></html>';
}
