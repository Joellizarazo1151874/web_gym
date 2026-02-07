<?php
/**
 * Actualizar perfil de usuario (mobile)
 * Permite al usuario logueado actualizar su propio perfil (incluyendo foto)
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept, Cookie, X-Session-ID');
header('Access-Control-Allow-Credentials: true');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/../database/config.php';
require_once __DIR__ . '/auth.php';

// Restaurar sesión si viene en headers
restoreSessionFromHeader();

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

// Verificar autenticación
$auth = new Auth();
if (!$auth->isAuthenticated()) {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'message' => 'No autenticado',
    ]);
    exit;
}

try {
    $db = getDB();
    $currentUser = $auth->getCurrentUser();
    $userId = $currentUser['id'];

    // Obtener datos del cuerpo de la solicitud
    $input = json_decode(file_get_contents('php://input'), true);

    if (!$input) {
        throw new Exception('No se recibieron datos para actualizar');
    }

    // Campos permitidos para actualización de perfil
    $fieldsToUpdate = [];
    $params = [':id' => $userId];

    // Manejar actualización de foto con borrado de la anterior
    if (isset($input['foto'])) {
        $newPhotoUrl = trim($input['foto']);

        // Obtener foto actual para borrarla si es diferente
        $stmt = $db->prepare("SELECT foto FROM usuarios WHERE id = :id");
        $stmt->execute([':id' => $userId]);
        $currentPhoto = $stmt->fetchColumn();

        if ($currentPhoto && $currentPhoto !== $newPhotoUrl) {
            // Intentar borrar el archivo físico
            // Asumimos que la URL es relativa o absoluta al servidor
            // Necesitamos convertir la URL a path del sistema de archivos

            // Ejemplo URL: https://dominio.com/uploads/posts/foto.jpg
            // Ejemplo Path: /var/www/html/uploads/posts/foto.jpg

            // Extraer la ruta relativa desde 'uploads/'
            $uploadPos = strpos($currentPhoto, 'uploads/');
            if ($uploadPos !== false) {
                $relativePath = substr($currentPhoto, $uploadPos);
                $fullPath = __DIR__ . '/../' . $relativePath;

                if (file_exists($fullPath)) {
                    @unlink($fullPath); // Silenciar error si falla
                }
            }
        }

        $fieldsToUpdate[] = "foto = :foto";
        $params[':foto'] = $newPhotoUrl;
    }

    // Otros campos que el usuario puede actualizar (puedes agregar más según necesidad)
    if (isset($input['telefono'])) {
        $fieldsToUpdate[] = "telefono = :telefono";
        $params[':telefono'] = trim($input['telefono']);
    }
    if (isset($input['direccion'])) {
        $fieldsToUpdate[] = "direccion = :direccion";
        $params[':direccion'] = trim($input['direccion']);
    }
    if (isset($input['ciudad'])) {
        $fieldsToUpdate[] = "ciudad = :ciudad";
        $params[':ciudad'] = trim($input['ciudad']);
    }
    if (isset($input['fecha_nacimiento'])) {
        $fieldsToUpdate[] = "fecha_nacimiento = :fecha_nacimiento";
        $params[':fecha_nacimiento'] = trim($input['fecha_nacimiento']);
    }
    if (isset($input['nombre'])) {
        $fieldsToUpdate[] = "nombre = :nombre";
        $params[':nombre'] = trim($input['nombre']);
    }
    if (isset($input['apellido'])) {
        $fieldsToUpdate[] = "apellido = :apellido";
        $params[':apellido'] = trim($input['apellido']);
    }
    if (isset($input['email'])) {
        // Validar que el email sea único si está cambiando
        $stmt = $db->prepare("SELECT id FROM usuarios WHERE email = :email AND id != :id");
        $stmt->execute([':email' => trim($input['email']), ':id' => $userId]);
        if ($stmt->fetch()) {
            throw new Exception('El correo electrónico ya está en uso por otro usuario');
        }
        $fieldsToUpdate[] = "email = :email";
        $params[':email'] = trim($input['email']);
    }
    if (isset($input['genero'])) {
        $fieldsToUpdate[] = "genero = :genero";
        $params[':genero'] = trim($input['genero']);
    }


    if (empty($fieldsToUpdate)) {
        echo json_encode([
            'success' => true,
            'message' => 'Nada que actualizar',
        ]);
        exit;
    }

    $sql = "UPDATE usuarios SET " . implode(', ', $fieldsToUpdate) . " WHERE id = :id";
    $stmt = $db->prepare($sql);
    $stmt->execute($params);

    // Actualizar datos en sesión
    $stmt = $db->prepare("SELECT * FROM usuarios WHERE id = :id");
    $stmt->execute([':id' => $userId]);
    $updatedUser = $stmt->fetch(PDO::FETCH_ASSOC);
    unset($updatedUser['password']); // No devolver password

    $_SESSION['user_id'] = $updatedUser['id'];
    $_SESSION['user_name'] = $updatedUser['nombre'];
    $_SESSION['user_email'] = $updatedUser['email'];
    $_SESSION['user_role'] = $updatedUser['rol_id']; // Ajustar según tu estructura de Auth
    $_SESSION['logged_in_user_id'] = $updatedUser['id'];

    echo json_encode([
        'success' => true,
        'message' => 'Perfil actualizado correctamente',
        'user' => $updatedUser
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al actualizar perfil: ' . $e->getMessage(),
    ]);
}
