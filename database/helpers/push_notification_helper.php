<?php
/**
 * Helper para enviar notificaciones push usando Firebase Cloud Messaging (FCM) API V1
 */

require_once __DIR__ . '/../config.php';

/**
 * Obtener token de acceso OAuth2 para FCM API V1
 * 
 * @param string $credentialsPath Ruta al archivo JSON de credenciales
 * @return string|false Token de acceso o false si hay error
 */
function getFCMAccessToken($credentialsPath) {
    if (!file_exists($credentialsPath)) {
        error_log("[FCM] Error: Archivo de credenciales no encontrado: $credentialsPath");
        return false;
    }
    
    $credentials = json_decode(file_get_contents($credentialsPath), true);
    if (!$credentials) {
        error_log("[FCM] Error: No se pudo leer el archivo de credenciales");
        return false;
    }
    
    // Crear JWT para solicitar token de acceso
    $now = time();
    $jwtHeader = base64_encode(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
    
    $jwtPayload = base64_encode(json_encode([
        'iss' => $credentials['client_email'],
        'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
        'aud' => 'https://oauth2.googleapis.com/token',
        'exp' => $now + 3600,
        'iat' => $now
    ]));
    
    // Firmar JWT con la clave privada
    $privateKey = openssl_pkey_get_private($credentials['private_key']);
    if (!$privateKey) {
        error_log("[FCM] Error: No se pudo cargar la clave privada");
        return false;
    }
    
    $signature = '';
    openssl_sign("$jwtHeader.$jwtPayload", $signature, $privateKey, OPENSSL_ALGO_SHA256);
    openssl_free_key($privateKey);
    
    $jwt = "$jwtHeader.$jwtPayload." . base64_encode($signature);
    
    // Solicitar token de acceso
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, 'https://oauth2.googleapis.com/token');
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
        'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion' => $jwt
    ]));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    if ($httpCode !== 200) {
        error_log("[FCM] Error al obtener token OAuth2: HTTP $httpCode - $response");
        return false;
    }
    
    $tokenData = json_decode($response, true);
    return $tokenData['access_token'] ?? false;
}

/**
 * Enviar notificación push a un token FCM específico usando API V1
 * 
 * @param string $token Token FCM del dispositivo
 * @param string $title Título de la notificación
 * @param string $body Cuerpo del mensaje
 * @param array $data Datos adicionales (opcional)
 * @param string|null $imageUrl URL de la imagen para mostrar en la notificación (opcional)
 * @return array Resultado con success y message
 */
function sendPushNotification($token, $title, $body, $data = [], $imageUrl = null) {
    // Obtener ruta del archivo de credenciales desde configuración
    $db = getDB();
    $stmt = $db->prepare("SELECT valor FROM configuracion WHERE clave = 'fcm_credentials_path'");
    $stmt->execute();
    $config = $stmt->fetch(PDO::FETCH_ASSOC);
    
    $credentialsPath = $config['valor'] ?? __DIR__ . '/../../config/firebase-credentials.json';
    
    if (empty($token)) {
        return [
            'success' => false,
            'message' => 'Token FCM vacío'
        ];
    }
    
    // Obtener token de acceso OAuth2
    $accessToken = getFCMAccessToken($credentialsPath);
    if (!$accessToken) {
        return [
            'success' => false,
            'message' => 'Error al obtener token de acceso OAuth2'
        ];
    }
    
    // Obtener project_id del archivo de credenciales
    $credentials = json_decode(file_get_contents($credentialsPath), true);
    $projectId = $credentials['project_id'] ?? '';
    
    if (empty($projectId)) {
        error_log("[FCM] Error: project_id no encontrado en credenciales");
        return [
            'success' => false,
            'message' => 'Error en configuración de credenciales'
        ];
    }
    
    if (empty($token)) {
        return [
            'success' => false,
            'message' => 'Token FCM vacío'
        ];
    }
    
    // Preparar payload para API V1
    $androidNotification = [
        'sound' => 'default',
        'channel_id' => 'default',
        'priority' => 'high',
        'icon' => 'ic_notification' // Ícono personalizado de notificación
    ];
    
    // Agregar imagen si está disponible (Android)
    if ($imageUrl) {
        $androidNotification['image'] = $imageUrl;
    }
    
    $apnsPayload = [
        'aps' => [
            'sound' => 'default',
            'badge' => 1
        ]
    ];
    
    // Agregar imagen si está disponible (iOS)
    if ($imageUrl) {
        $apnsPayload['fcm_options'] = [
            'image' => $imageUrl
        ];
    }
    
    $message = [
        'message' => [
            'token' => $token,
            'notification' => [
                'title' => $title,
                'body' => $body
            ],
            'data' => array_merge([
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK'
            ], array_map('strval', $data)), // Convertir todos los valores a string
            'android' => [
                'priority' => 'high',
                'notification' => $androidNotification
            ],
            'apns' => [
                'headers' => [
                    'apns-priority' => '10'
                ],
                'payload' => $apnsPayload
            ]
        ]
    ];
    
    // Headers para la petición a FCM API V1
    $headers = [
        'Authorization: Bearer ' . $accessToken,
        'Content-Type: application/json'
    ];
    
    // URL de la API V1
    $url = "https://fcm.googleapis.com/v1/projects/$projectId/messages:send";
    
    // Enviar petición a FCM
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($message));
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);
    
    if ($error) {
        error_log("[FCM] Error cURL: " . $error);
        return [
            'success' => false,
            'message' => 'Error al enviar notificación: ' . $error
        ];
    }
    
    $responseData = json_decode($response, true);
    
    if ($httpCode === 200 && isset($responseData['name'])) {
        return [
            'success' => true,
            'message' => 'Notificación enviada correctamente',
            'response' => $responseData
        ];
    } else {
        error_log("[FCM] Error en respuesta: HTTP $httpCode - " . $response);
        return [
            'success' => false,
            'message' => 'Error al enviar notificación',
            'response' => $responseData
        ];
    }
}

/**
 * Enviar notificación push a múltiples tokens
 * 
 * @param array $tokens Array de tokens FCM
 * @param string $title Título de la notificación
 * @param string $body Cuerpo del mensaje
 * @param array $data Datos adicionales (opcional)
 * @param string|null $imageUrl URL de la imagen para mostrar en la notificación (opcional)
 * @return array Resultado con success, sent_count y failed_count
 */
function sendPushNotificationToMultiple($tokens, $title, $body, $data = [], $imageUrl = null) {
    if (empty($tokens) || !is_array($tokens)) {
        return [
            'success' => false,
            'message' => 'No hay tokens para enviar',
            'sent_count' => 0,
            'failed_count' => 0
        ];
    }
    
    // La API V1 no soporta envío masivo directo, debemos enviar uno por uno
    // Pero agrupamos en lotes para ser más eficientes
    $sentCount = 0;
    $failedCount = 0;
    $errors = [];
    
    foreach ($tokens as $token) {
        $result = sendPushNotification($token, $title, $body, $data, $imageUrl);
        if ($result['success']) {
            $sentCount++;
        } else {
            $failedCount++;
            $errors[] = $result['message'];
        }
    }
    
    return [
        'success' => $sentCount > 0,
        'message' => "Notificaciones enviadas: $sentCount exitosas, $failedCount fallidas",
        'sent_count' => $sentCount,
        'failed_count' => $failedCount,
        'errors' => $errors
    ];
}

/**
 * Obtener tokens FCM activos de un usuario
 * 
 * @param PDO $db Conexión a la base de datos
 * @param int $usuarioId ID del usuario
 * @return array Array de tokens FCM
 */
function getFCMTokensForUser($db, $usuarioId) {
    $stmt = $db->prepare("
        SELECT token 
        FROM fcm_tokens 
        WHERE usuario_id = :usuario_id AND activo = 1
    ");
    $stmt->execute([':usuario_id' => $usuarioId]);
    return $stmt->fetchAll(PDO::FETCH_COLUMN);
}

/**
 * Obtener todos los tokens FCM activos excepto los de un usuario específico
 * 
 * @param PDO $db Conexión a la base de datos
 * @param int $excludeUsuarioId ID del usuario a excluir
 * @return array Array de tokens FCM
 */
function getAllFCMTokensExceptUser($db, $excludeUsuarioId) {
    $stmt = $db->prepare("
        SELECT token 
        FROM fcm_tokens 
        WHERE usuario_id != :exclude_usuario_id AND activo = 1
    ");
    $stmt->execute([':exclude_usuario_id' => $excludeUsuarioId]);
    return $stmt->fetchAll(PDO::FETCH_COLUMN);
}
