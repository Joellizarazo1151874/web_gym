<?php
/**
 * Sistema de Autenticación
 * Maneja el login, logout y verificación de sesiones
 */

// No iniciar sesión aquí, debe iniciarse antes de incluir este archivo
// session_start() debe llamarse en el archivo que incluye este
require_once __DIR__ . '/../database/config.php';

class Auth {
    private $db;
    
    public function __construct() {
        $this->db = getDB();
    }
    
    /**
     * Iniciar sesión
     * @param string $email Email del usuario
     * @param string $password Contraseña sin hashear
     * @param bool $remember Recordar sesión
     * @return array Resultado con éxito y mensaje
     */
    public function login($email, $password, $remember = false) {
        try {
            // Validar campos
            if (empty($email) || empty($password)) {
                return [
                    'success' => false,
                    'message' => 'Por favor completa todos los campos'
                ];
            }
            
            // Buscar usuario por email
            // Permitir login a todos excepto los suspendidos
            $stmt = $this->db->prepare("
                SELECT u.*, r.nombre as rol_nombre 
                FROM usuarios u 
                INNER JOIN roles r ON u.rol_id = r.id 
                WHERE u.email = :email 
                AND u.estado != 'suspendido'
            ");
            $stmt->execute([':email' => $email]);
            $usuario = $stmt->fetch();
            
            if (!$usuario) {
                return [
                    'success' => false,
                    'message' => 'Email o contraseña incorrectos'
                ];
            }
            
            // Verificar contraseña
            if (!password_verify($password, $usuario['password'])) {
                return [
                    'success' => false,
                    'message' => 'Email o contraseña incorrectos'
                ];
            }
            
            // Verificar si está suspendido (por si acaso)
            if ($usuario['estado'] === 'suspendido') {
                return [
                    'success' => false,
                    'message' => 'Tu cuenta está suspendida. Contacta al administrador.'
                ];
            }
            
            // Crear sesión
            $_SESSION['usuario_id'] = $usuario['id'];
            $_SESSION['usuario_nombre'] = $usuario['nombre'];
            $_SESSION['usuario_apellido'] = $usuario['apellido'];
            $_SESSION['usuario_email'] = $usuario['email'];
            $_SESSION['usuario_rol'] = $usuario['rol_nombre'];
            $_SESSION['usuario_rol_id'] = $usuario['rol_id'];
            $_SESSION['usuario_logueado'] = true;
            $_SESSION['login_time'] = time();
            
            // Si marcó "Recordar", extender la sesión
            if ($remember) {
                ini_set('session.cookie_lifetime', 604800); // 7 días
            }
            
            // Actualizar último acceso
            $this->actualizarUltimoAcceso($usuario['id']);
            
            return [
                'success' => true,
                'message' => 'Login exitoso',
                'usuario' => [
                    'id' => $usuario['id'],
                    'nombre' => $usuario['nombre'],
                    'apellido' => $usuario['apellido'],
                    'email' => $usuario['email'],
                    'rol' => $usuario['rol_nombre']
                ]
            ];
            
        } catch (PDOException $e) {
            error_log("Error en login: " . $e->getMessage());
            return [
                'success' => false,
                'message' => 'Error al procesar el login. Intenta nuevamente.'
            ];
        }
    }
    
    /**
     * Cerrar sesión
     */
    public function logout() {
        // Si la sesión está iniciada, destruirla completamente
        if (session_status() === PHP_SESSION_ACTIVE) {
            // Limpiar todas las variables de sesión
            $_SESSION = array();
            
            // Destruir cookie de sesión actual
            if (isset($_COOKIE[session_name()])) {
                setcookie(session_name(), '', time() - 3600, '/');
                setcookie(session_name(), '', time() - 3600, '/', '', false, true);
            }
            
            // Destruir todas las cookies relacionadas con la sesión
            if (ini_get("session.use_cookies")) {
                $params = session_get_cookie_params();
                setcookie(session_name(), '', time() - 42000,
                    $params["path"], $params["domain"],
                    $params["secure"], $params["httponly"]
                );
            }
            
            // Destruir la sesión
            session_destroy();
        }
        
        return [
            'success' => true,
            'message' => 'Sesión cerrada correctamente'
        ];
    }
    
    /**
     * Verificar si el usuario está autenticado
     * @return bool
     */
    public function isAuthenticated() {
        // Verificar que la sesión existe y tiene la clave usuario_logueado
        if (!isset($_SESSION['usuario_logueado']) || $_SESSION['usuario_logueado'] !== true) {
            return false;
        }
        
        // Verificar que existen los datos mínimos necesarios
        if (!isset($_SESSION['usuario_id']) || !isset($_SESSION['usuario_rol'])) {
            return false;
        }
        
        return true;
    }
    
    /**
     * Verificar si el usuario tiene un rol específico
     * @param string|array $roles Rol o array de roles permitidos
     * @return bool
     */
    public function hasRole($roles) {
        if (!$this->isAuthenticated()) {
            return false;
        }
        
        if (is_array($roles)) {
            return in_array($_SESSION['usuario_rol'], $roles);
        }
        
        return $_SESSION['usuario_rol'] === $roles;
    }
    
    /**
     * Obtener información del usuario actual
     * @return array|null
     */
    public function getCurrentUser() {
        if (!$this->isAuthenticated()) {
            return null;
        }
        
        return [
            'id' => $_SESSION['usuario_id'],
            'nombre' => $_SESSION['usuario_nombre'],
            'apellido' => $_SESSION['usuario_apellido'],
            'email' => $_SESSION['usuario_email'],
            'rol' => $_SESSION['usuario_rol'],
            'rol_id' => $_SESSION['usuario_rol_id']
        ];
    }
    
    /**
     * Requerir autenticación - redirige si no está logueado
     * @param string $redirectUrl URL a donde redirigir si no está autenticado
     */
    public function requireAuth($redirectUrl = 'login.php') {
        if (!$this->isAuthenticated()) {
            header('Location: ' . $redirectUrl);
            exit;
        }
    }
    
    /**
     * Requerir rol específico - redirige si no tiene el rol
     * @param string|array $roles Rol o roles permitidos
     * @param string $redirectUrl URL a donde redirigir
     */
    public function requireRole($roles, $redirectUrl = '../../dashboard/dist/dashboard/index.php') {
        if (!$this->hasRole($roles)) {
            header('Location: ' . $redirectUrl);
            exit;
        }
    }
    
    /**
     * Actualizar último acceso del usuario
     * @param int $usuarioId ID del usuario
     */
    private function actualizarUltimoAcceso($usuarioId) {
        try {
            $stmt = $this->db->prepare("
                UPDATE usuarios 
                SET ultimo_acceso = NOW() 
                WHERE id = :id
            ");
            $stmt->execute([':id' => $usuarioId]);
        } catch (PDOException $e) {
            error_log("Error al actualizar último acceso: " . $e->getMessage());
        }
    }
    
    /**
     * Verificar si la sesión ha expirado
     * @return bool
     */
    public function isSessionExpired() {
        if (!isset($_SESSION['login_time'])) {
            return true;
        }
        
        // Verificar si está configurado para nunca cerrar sesión
        try {
            $stmt = $this->db->prepare("SELECT valor FROM configuracion WHERE clave = 'sesion_never_expire'");
            $stmt->execute();
            $result = $stmt->fetch();
            
            if ($result && $result['valor'] == '1') {
                // Si está configurado para nunca cerrar, la sesión nunca expira
                return false;
            }
        } catch (Exception $e) {
            // Si hay error al leer la configuración, usar el comportamiento por defecto
            error_log("Error al verificar configuración de sesión: " . $e->getMessage());
        }
        
        // Obtener timeout de la configuración o usar el por defecto
        $sessionLifetime = SESSION_LIFETIME;
        try {
            $stmt = $this->db->prepare("SELECT valor FROM configuracion WHERE clave = 'sesion_timeout'");
            $stmt->execute();
            $result = $stmt->fetch();
            
            if ($result && is_numeric($result['valor']) && (int)$result['valor'] > 0) {
                // Convertir minutos a segundos
                $sessionLifetime = (int)$result['valor'] * 60;
            }
        } catch (Exception $e) {
            // Si hay error, usar el valor por defecto
            error_log("Error al obtener timeout de sesión: " . $e->getMessage());
        }
        
        return (time() - $_SESSION['login_time']) > $sessionLifetime;
    }
}

/**
 * Función helper para obtener instancia de Auth
 */
function getAuth() {
    return new Auth();
}

