<?php
/**
 * Logout
 * Cierra la sesión del usuario completamente
 */

// Iniciar sesión solo si no está iniciada
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/auth.php';

$auth = new Auth();

// Destruir completamente la sesión
$auth->logout();

// Asegurarse de que la sesión está completamente destruida
if (session_status() === PHP_SESSION_ACTIVE) {
    $_SESSION = array();
    session_destroy();
}

// Limpiar cookies de sesión
if (isset($_COOKIE[session_name()])) {
    setcookie(session_name(), '', time() - 3600, '/');
    setcookie(session_name(), '', time() - 3600, '/', '', false, true);
}

// Redirigir al login usando BASE_URL dinámico
header('Location: ' . BASE_URL . 'dashboard/dist/dashboard/auth/login.php');
exit;

