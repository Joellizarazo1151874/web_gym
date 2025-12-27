<?php
/**
 * Helper para protección CSRF (Cross-Site Request Forgery)
 * Genera y valida tokens CSRF para proteger formularios
 */

// Asegurar que la sesión esté iniciada
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

/**
 * Generar token CSRF y guardarlo en sesión
 * @return string Token CSRF
 */
function generateCSRFToken() {
    if (!isset($_SESSION['csrf_token'])) {
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf_token'];
}

/**
 * Obtener el token CSRF actual (sin regenerarlo)
 * @return string|null Token CSRF o null si no existe
 */
function getCSRFToken() {
    return $_SESSION['csrf_token'] ?? null;
}

/**
 * Validar token CSRF
 * @param string $token Token a validar
 * @return bool True si el token es válido, false en caso contrario
 */
function validateCSRFToken($token) {
    if (empty($token)) {
        return false;
    }
    
    if (!isset($_SESSION['csrf_token'])) {
        return false;
    }
    
    // Comparación segura para prevenir timing attacks
    return hash_equals($_SESSION['csrf_token'], $token);
}

/**
 * Regenerar token CSRF (útil después de operaciones críticas)
 * @return string Nuevo token CSRF
 */
function regenerateCSRFToken() {
    $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    return $_SESSION['csrf_token'];
}

/**
 * Obtener campo hidden HTML para formularios
 * @return string HTML del input hidden con el token
 */
function getCSRFTokenField() {
    $token = generateCSRFToken();
    return '<input type="hidden" name="csrf_token" value="' . htmlspecialchars($token, ENT_QUOTES, 'UTF-8') . '">';
}

/**
 * Validar token CSRF desde POST o JSON
 * @param bool $returnJson Si es true, retorna JSON en caso de error
 * @return bool|void True si es válido, o termina ejecución si no lo es
 */
function requireCSRFToken($returnJson = false) {
    // Asegurar que la sesión esté iniciada
    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }
    
    $token = null;
    
    // Intentar obtener token de POST
    if (isset($_POST['csrf_token'])) {
        $token = $_POST['csrf_token'];
    }
    // Intentar obtener token de JSON (para peticiones AJAX)
    elseif (isset($_SERVER['CONTENT_TYPE']) && strpos($_SERVER['CONTENT_TYPE'], 'application/json') !== false) {
        $json = json_decode(file_get_contents('php://input'), true);
        if (isset($json['csrf_token'])) {
            $token = $json['csrf_token'];
        }
    }
    
    // Debug temporal (solo en desarrollo)
    $debug_info = [];
    if (defined('DEBUG_MODE') && DEBUG_MODE) {
        $debug_info = [
            'token_received' => !empty($token) ? 'Sí' : 'No',
            'token_length' => $token ? strlen($token) : 0,
            'session_has_token' => isset($_SESSION['csrf_token']) ? 'Sí' : 'No',
            'session_token_length' => isset($_SESSION['csrf_token']) ? strlen($_SESSION['csrf_token']) : 0,
            'session_id' => session_id()
        ];
    }
    
    if (!validateCSRFToken($token)) {
        if ($returnJson) {
            http_response_code(403);
            header('Content-Type: application/json');
            $error_message = 'Token CSRF inválido o faltante. Por favor, recarga la página e intenta nuevamente.';
            if (defined('DEBUG_MODE') && DEBUG_MODE && !empty($debug_info)) {
                $error_message .= ' Debug: ' . json_encode($debug_info);
            }
            echo json_encode([
                'success' => false,
                'message' => $error_message
            ]);
            exit;
        } else {
            http_response_code(403);
            $error_message = 'Token CSRF inválido o faltante. Por favor, recarga la página e intenta nuevamente.';
            if (defined('DEBUG_MODE') && DEBUG_MODE && !empty($debug_info)) {
                $error_message .= ' Debug: ' . json_encode($debug_info);
            }
            die($error_message);
        }
    }
    
    return true;
}

