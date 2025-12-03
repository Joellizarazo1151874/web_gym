<?php
/**
 * Redirección Admin
 * Acceso rápido al login del dashboard
 * URL: midominio.com/admin/
 * 
 * Este archivo redirige automáticamente al login del sistema.
 * Si ya estás logueado, te redirige al dashboard directamente.
 */

session_start();
require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/../api/auth.php';

$auth = new Auth();

// Verificar si ya está logueado
// Verificar que la sesión realmente existe y tiene los datos necesarios
if ($auth->isAuthenticated()) {
    $usuario = $auth->getCurrentUser();
    
    // Verificar que getCurrentUser() devuelve datos válidos
    if ($usuario && isset($usuario['rol'])) {
        if (in_array($usuario['rol'], ['admin', 'entrenador'])) {
            // Admin o entrenador va al dashboard
            header('Location: ../dashboard/dist/dashboard/index.php');
            exit;
        } else {
            // Cliente va al sitio web principal
            header('Location: ../index.php');
            exit;
        }
    }
}

// Si no está logueado o los datos son inválidos, redirigir al login
header('Location: ../dashboard/dist/dashboard/auth/login.php');
exit;

