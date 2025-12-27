<?php
/**
 * Helper para Rate Limiting (Limitación de intentos)
 * Previene ataques de fuerza bruta limitando intentos de login
 */

// Asegurar que la sesión esté iniciada
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

/**
 * Verificar si el usuario puede realizar un intento
 * @param string $key Clave única para identificar el tipo de intento (ej: 'login', 'password_reset')
 * @param int $maxAttempts Número máximo de intentos permitidos
 * @param int $lockoutMinutes Minutos de bloqueo después de exceder intentos
 * @return array ['allowed' => bool, 'remaining' => int, 'lockout_until' => int|null, 'message' => string]
 */
function checkRateLimit($key, $maxAttempts = 10, $lockoutMinutes = 10) {
    $sessionKey = 'rate_limit_' . $key;
    $lockoutKey = 'rate_limit_lockout_' . $key;
    
    // Verificar si hay un bloqueo activo
    if (isset($_SESSION[$lockoutKey])) {
        $lockoutUntil = $_SESSION[$lockoutKey];
        $now = time();
        
        if ($now < $lockoutUntil) {
            $remainingSeconds = $lockoutUntil - $now;
            $remainingMinutes = ceil($remainingSeconds / 60);
            
            return [
                'allowed' => false,
                'remaining' => 0,
                'lockout_until' => $lockoutUntil,
                'message' => "Demasiados intentos fallidos. Por favor, espera {$remainingMinutes} minuto(s) antes de intentar nuevamente."
            ];
        } else {
            // El bloqueo expiró, limpiar
            unset($_SESSION[$lockoutKey]);
            unset($_SESSION[$sessionKey]);
        }
    }
    
    // Obtener intentos actuales
    $attempts = $_SESSION[$sessionKey] ?? [];
    
    // Limpiar intentos antiguos (más de 1 hora)
    $oneHourAgo = time() - 3600;
    $attempts = array_filter($attempts, function($timestamp) use ($oneHourAgo) {
        return $timestamp > $oneHourAgo;
    });
    
    // Contar intentos válidos
    $attemptCount = count($attempts);
    
    if ($attemptCount >= $maxAttempts) {
        // Bloquear por el tiempo especificado
        $lockoutUntil = time() + ($lockoutMinutes * 60);
        $_SESSION[$lockoutKey] = $lockoutUntil;
        
        return [
            'allowed' => false,
            'remaining' => 0,
            'lockout_until' => $lockoutUntil,
            'message' => "Has excedido el límite de {$maxAttempts} intentos. Por favor, espera {$lockoutMinutes} minuto(s) antes de intentar nuevamente."
        ];
    }
    
    $remaining = $maxAttempts - $attemptCount;
    
    return [
        'allowed' => true,
        'remaining' => $remaining,
        'lockout_until' => null,
        'message' => ''
    ];
}

/**
 * Registrar un intento fallido
 * @param string $key Clave única para identificar el tipo de intento
 */
function recordFailedAttempt($key) {
    $sessionKey = 'rate_limit_' . $key;
    
    if (!isset($_SESSION[$sessionKey])) {
        $_SESSION[$sessionKey] = [];
    }
    
    // Agregar timestamp del intento actual
    $_SESSION[$sessionKey][] = time();
}

/**
 * Limpiar intentos fallidos (usar después de un login exitoso)
 * @param string $key Clave única para identificar el tipo de intento
 */
function clearFailedAttempts($key) {
    $sessionKey = 'rate_limit_' . $key;
    $lockoutKey = 'rate_limit_lockout_' . $key;
    
    unset($_SESSION[$sessionKey]);
    unset($_SESSION[$lockoutKey]);
}

/**
 * Obtener información del rate limit sin modificar nada
 * @param string $key Clave única para identificar el tipo de intento
 * @param int $maxAttempts Número máximo de intentos permitidos
 * @param int $lockoutMinutes Minutos de bloqueo después de exceder intentos
 * @return array Información del estado actual
 */
function getRateLimitInfo($key, $maxAttempts = 10, $lockoutMinutes = 10) {
    return checkRateLimit($key, $maxAttempts, $lockoutMinutes);
}

