<?php
/**
 * Configuración de Base de Datos
 * Sistema de Gestión de Gimnasio - Functional Training
 * 
 * Este archivo contiene las credenciales y configuración
 * para la conexión a la base de datos MySQL
 */

// Prevenir acceso directo
if (!defined('DB_CONFIG_LOADED')) {
    define('DB_CONFIG_LOADED', true);
}

// Configuración de la base de datos
define('DB_HOST', 'localhost');
define('DB_NAME', 'ftgym');
define('DB_USER', 'root');
define('DB_PASS', '');
define('DB_CHARSET', 'utf8mb4');

// Configuración de la aplicación
define('APP_NAME', 'Functional Training Gym');
define('APP_VERSION', '1.0.0');
define('APP_TIMEZONE', 'America/Bogota');

// Configuración de seguridad
define('JWT_SECRET', 'Y97v9jGyGKPY9LOWYo2S2wBP39dgL7dL');
define('PASSWORD_MIN_LENGTH', 8);

// Configuración de archivos
define('UPLOAD_DIR', __DIR__ . '/../uploads/');
define('UPLOAD_MAX_SIZE', 5242880); // 5MB en bytes

// Rutas de imágenes
define('UPLOAD_USUARIOS', UPLOAD_DIR . 'usuarios/');
define('UPLOAD_PRODUCTOS', UPLOAD_DIR . 'productos/');
define('UPLOAD_EJERCICIOS', UPLOAD_DIR . 'ejercicios/');

// Configuración de QR
define('QR_PREFIX', 'FTGYM-');
define('QR_LENGTH', 10);

// Configuración de pagos
define('DESCUENTO_APP', 0.10); // 10% de descuento desde la app

// Configuración de sesión
define('SESSION_LIFETIME', 7200); // 2 horas en segundos

/**
 * Obtener la base URL del sitio dinámicamente
 * Funciona tanto en desarrollo como en producción
 * 
 * @return string Base URL del sitio (ej: /ftgym/ o /)
 */
function getBaseUrl()
{
    // Obtener el directorio del script actual desde la raíz del servidor web
    $scriptPath = dirname($_SERVER['SCRIPT_NAME']);

    // Si estamos en api/, subir un nivel
    if (strpos($scriptPath, '/api') !== false) {
        $scriptPath = dirname($scriptPath);
    }

    // Si el script está en dashboard/dist/dashboard/app/ o dashboard/dist/dashboard/, 
    // necesitamos encontrar la raíz del proyecto
    // Patrón 1: /ftgym/dashboard/... -> devolver /ftgym/
    if (preg_match('#^(/[^/]+)/dashboard/#', $scriptPath, $matches)) {
        return $matches[1] . '/';
    }

    // Patrón 2: /dashboard/... (sin prefijo) -> devolver / (raíz del servidor)
    if (preg_match('#^/dashboard/#', $scriptPath)) {
        return '/';
    }

    // Normalizar la ruta (eliminar barras duplicadas)
    $scriptPath = '/' . trim($scriptPath, '/');

    // Si estamos en la raíz, devolver /
    if ($scriptPath === '/') {
        return '/';
    }

    // Devolver la ruta con barra final
    return rtrim($scriptPath, '/') . '/';
}

/**
 * Obtener la URL completa del sitio
 * 
 * @return string URL completa del sitio
 */
function getSiteUrl()
{
    $protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off' || $_SERVER['SERVER_PORT'] == 443) ? "https://" : "http://";
    $domain = $_SERVER['HTTP_HOST'];
    return $protocol . $domain . getBaseUrl();
}

// Constante para usar en todo el sistema
define('BASE_URL', getBaseUrl());

// Configuración de email SMTP
define('SMTP_SECURE', 'tls');
define('SMTP_HOST', 'smtp.gmail.com');
define('SMTP_PORT', 587);
define('SMTP_USER', 'ginussmartpark@gmail.com');
define('SMTP_PASS', 'zdhd jlrj breu iirg');
define('SMTP_FROM_EMAIL', 'ginussmartpark@gmail.com');
define('SMTP_FROM_NAME', 'Functional Training Gym');

// Modo de desarrollo (cambiar a false en producción)
define('DEBUG_MODE', false);

// Mostrar errores solo en desarrollo
if (DEBUG_MODE) {
    error_reporting(E_ALL);
    ini_set('display_errors', 1);
} else {
    error_reporting(0);
    ini_set('display_errors', 0);
}

// Configurar zona horaria
date_default_timezone_set(APP_TIMEZONE);

/**
 * Clase para manejar la conexión a la base de datos
 */
class Database
{
    private static $instance = null;
    private $connection;

    /**
     * Constructor privado para implementar patrón Singleton
     */
    private function __construct()
    {
        try {
            $dsn = "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=" . DB_CHARSET;
            $options = [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false,
            ];

            $this->connection = new PDO($dsn, DB_USER, DB_PASS, $options);

            // Configurar zona horaria de MySQL a Colombia
            $this->connection->exec("SET time_zone = '-05:00'");
        } catch (PDOException $e) {
            if (DEBUG_MODE) {
                die("Error de conexión: " . $e->getMessage());
            } else {
                die("Error de conexión a la base de datos");
            }
        }
    }

    /**
     * Obtener instancia única de la conexión (Singleton)
     */
    public static function getInstance()
    {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    /**
     * Obtener la conexión PDO
     */
    public function getConnection()
    {
        return $this->connection;
    }

    /**
     * Prevenir clonación de la instancia
     */
    private function __clone()
    {
    }

    /**
     * Prevenir deserialización de la instancia
     */
    public function __wakeup()
    {
        throw new Exception("Cannot unserialize singleton");
    }
}

/**
 * Función helper para obtener la conexión
 */
function getDB()
{
    return Database::getInstance()->getConnection();
}

