# Sistema de Autenticación - Guía de Uso

## Archivos Creados

### Backend PHP

1. **`api/auth.php`** - Clase principal de autenticación
   - Métodos: `login()`, `logout()`, `isAuthenticated()`, `hasRole()`, etc.
   - Maneja sesiones y verificación de roles

2. **`api/login.php`** - Endpoint para procesar login
   - Recibe POST con email y password
   - Retorna JSON con resultado
   - Redirige según el rol del usuario

3. **`api/logout.php`** - Endpoint para cerrar sesión
   - Destruye la sesión
   - Redirige al login

### Frontend

4. **`dashboard/dist/dashboard/auth/login.php`** - Página de login funcional
   - Mantiene el diseño del dashboard
   - Formulario con validación AJAX
   - Mensajes de error/success

5. **`dashboard/dist/dashboard/auth/check_session.php`** - Verificador de sesión
   - Incluir en páginas protegidas
   - Verifica autenticación y roles

## Cómo Usar

### 1. Acceder al Login

Abre en tu navegador:
```
http://localhost/ftgym/dashboard/dist/dashboard/auth/login.php
```

### 2. Credenciales por Defecto

- **Email:** `admin@ftgym.com`
- **Password:** `admin123`

### 3. Proteger Páginas PHP

Para proteger una página PHP, incluye al inicio:

```php
<?php
require_once __DIR__ . '/auth/check_session.php';

// Si necesitas verificar un rol específico:
requireRole('admin'); // Solo admin
// o
requireRole(['admin', 'entrenador']); // Admin o entrenador

// Ya tienes acceso a $usuario_actual
echo "Bienvenido: " . $usuario_actual['nombre'];
?>
```

### 4. Proteger Páginas HTML

Para páginas HTML del dashboard, puedes crear un archivo PHP que verifique la sesión antes de incluir el HTML, o usar JavaScript para verificar con una API.

### 5. Cerrar Sesión

Crea un enlace o botón que apunte a:
```php
<a href="../../api/logout.php">Cerrar Sesión</a>
```

## Redirecciones Según Rol

- **Admin:** `../../dashboard/dist/dashboard/index.html`
- **Entrenador:** `../../dashboard/dist/dashboard/index.html`
- **Cliente:** `../../index.html`

## Variables de Sesión Disponibles

Después del login, estas variables están disponibles en `$_SESSION`:

- `usuario_id` - ID del usuario
- `usuario_nombre` - Nombre del usuario
- `usuario_apellido` - Apellido del usuario
- `usuario_email` - Email del usuario
- `usuario_rol` - Nombre del rol (admin, entrenador, cliente)
- `usuario_rol_id` - ID del rol
- `usuario_logueado` - true si está logueado
- `login_time` - Timestamp del login

## Características de Seguridad

✅ Contraseñas hasheadas con `password_hash()`
✅ Validación de email
✅ Protección contra SQL Injection (Prepared Statements)
✅ Verificación de sesión expirada
✅ Verificación de roles
✅ Sanitización de datos de entrada

## Ejemplo de Uso en Página Protegida

```php
<?php
// Verificar autenticación
require_once __DIR__ . '/auth/check_session.php';

// Solo permitir admin
requireRole('admin');

// Tu código aquí
?>
<!DOCTYPE html>
<html>
<head>
    <title>Panel Admin</title>
</head>
<body>
    <h1>Bienvenido <?php echo htmlspecialchars($usuario_actual['nombre']); ?></h1>
    <p>Rol: <?php echo htmlspecialchars($usuario_actual['rol']); ?></p>
    <a href="../../api/logout.php">Cerrar Sesión</a>
</body>
</html>
```

## Solución de Problemas

### Error: "No se pudo conectar con el servidor"
- Verifica que XAMPP esté corriendo
- Verifica la configuración en `database/config.php`
- Asegúrate de que la base de datos `ftgym` existe

### Error: "Email o contraseña incorrectos"
- Verifica que el usuario exista en la base de datos
- Verifica que el password hash sea correcto
- Asegúrate de que el usuario esté activo (`estado = 'activo'`)

### Error: "Método no permitido"
- Asegúrate de que el formulario use POST
- Verifica que el endpoint sea correcto (`../api/login.php`)

### La sesión no persiste
- Verifica que `session_start()` esté al inicio de cada archivo PHP
- Verifica permisos de escritura en la carpeta de sesiones de PHP

## Próximos Pasos

1. ✅ Login funcional
2. ⏭️ Crear página de registro (sign-up)
3. ⏭️ Crear recuperación de contraseña
4. ⏭️ Proteger páginas del dashboard
5. ⏭️ Crear middleware para verificación de permisos

