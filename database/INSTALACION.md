# Guía de Instalación - Sistema de Gestión de Gimnasio

## Requisitos Previos

- **XAMPP** instalado y funcionando
- **PHP 7.4** o superior
- **MySQL 5.7** o superior (incluido en XAMPP)
- Editor de código (VS Code, PHPStorm, etc.)

## Paso 1: Preparar XAMPP

1. **Iniciar XAMPP**
   - Abre el Panel de Control de XAMPP
   - Inicia los servicios:
     - ✅ Apache
     - ✅ MySQL

2. **Verificar que MySQL esté funcionando**
   - Abre tu navegador y ve a: `http://localhost/phpmyadmin`
   - Deberías ver la interfaz de phpMyAdmin

## Paso 2: Crear la Base de Datos

### Opción A: Usando phpMyAdmin (Recomendado)

1. Abre phpMyAdmin: `http://localhost/phpmyadmin`

2. En el panel izquierdo, haz clic en "Nueva" para crear una base de datos

3. O directamente importa el archivo SQL:
   - Selecciona la opción "Importar" en el menú superior
   - Haz clic en "Elegir archivo"
   - Selecciona el archivo: `database/schema.sql`
   - Haz clic en "Continuar"
   - Espera a que termine la importación

### Opción B: Usando Línea de Comandos

1. Abre la terminal/consola

2. Navega a la carpeta del proyecto:
   ```bash
   cd C:\xampp\htdocs\ftgym
   ```

3. Ejecuta el comando:
   ```bash
   mysql -u root -p < database/schema.sql
   ```
   (Si no tienes contraseña, solo presiona Enter)

### Opción C: Copiar y Pegar SQL

1. Abre phpMyAdmin
2. Selecciona "SQL" en el menú superior
3. Abre el archivo `database/schema.sql` en un editor de texto
4. Copia todo el contenido
5. Pégalo en el área de SQL de phpMyAdmin
6. Haz clic en "Continuar"

## Paso 3: Verificar la Instalación

1. En phpMyAdmin, verifica que:
   - La base de datos `ftgym` existe
   - Todas las tablas están creadas (deberías ver 18 tablas)

2. Verifica los datos iniciales:
   ```sql
   -- Ver roles
   SELECT * FROM roles;
   
   -- Ver planes
   SELECT * FROM planes;
   
   -- Ver usuario admin
   SELECT * FROM usuarios WHERE email = 'admin@ftgym.com';
   ```

## Paso 4: Configurar la Conexión

1. Abre el archivo `database/config.php`

2. Verifica que las credenciales sean correctas:
   ```php
   define('DB_HOST', 'localhost');
   define('DB_NAME', 'ftgym_db');
   define('DB_USER', 'root');
   define('DB_PASS', ''); // Vacío por defecto en XAMPP
   ```

3. Si tu MySQL tiene contraseña, cámbiala:
   ```php
   define('DB_PASS', 'tu_contraseña');
   ```

## Paso 5: Crear Directorios de Uploads

1. Crea la carpeta `uploads` en la raíz del proyecto:
   ```bash
   mkdir uploads
   ```

2. Crea las subcarpetas necesarias:
   ```bash
   mkdir uploads/usuarios
   mkdir uploads/productos
   mkdir uploads/ejercicios
   ```

3. O desde Windows Explorer:
   - Crea la carpeta `uploads` en `C:\xampp\htdocs\ftgym\`
   - Dentro crea: `usuarios`, `productos`, `ejercicios`

## Paso 6: Probar la Conexión

1. Abre tu navegador

2. Accede al archivo de prueba:
   ```
   http://localhost/ftgym/database/ejemplo_uso.php
   ```

3. Deberías ver los resultados de las consultas de ejemplo

## Paso 7: Cambiar Contraseña del Admin

**IMPORTANTE:** Cambia la contraseña del usuario administrador por defecto.

1. En phpMyAdmin, ejecuta:
   ```sql
   UPDATE usuarios 
   SET password = '$2y$10$NUEVA_CONTRASEÑA_HASHEADA' 
   WHERE email = 'admin@ftgym.com';
   ```

2. O genera un hash con PHP:
   ```php
   <?php
   echo password_hash('tu_nueva_contraseña', PASSWORD_DEFAULT);
   ?>
   ```

3. Copia el hash y actualiza la base de datos

## Estructura de Archivos Creados

```
ftgym/
├── database/
│   ├── schema.sql          # Esquema completo de la base de datos
│   ├── config.php           # Configuración de conexión PHP
│   ├── queries_utiles.sql   # Consultas útiles de referencia
│   ├── ejemplo_uso.php      # Ejemplos de uso de la conexión
│   └── README.md            # Documentación de la base de datos
```

## Solución de Problemas

### Error: "Access denied for user 'root'@'localhost'"

**Solución:** Verifica que la contraseña en `config.php` sea correcta o esté vacía si es la instalación por defecto.

### Error: "Unknown database 'ftgym'"

**Solución:** Asegúrate de haber ejecutado el archivo `schema.sql` correctamente.

### Error: "Table doesn't exist"

**Solución:** Verifica que todas las tablas se hayan creado. Revisa si hubo errores durante la importación.

### Error de permisos en carpetas de uploads

**Solución:** En Windows, asegúrate de que las carpetas tengan permisos de escritura. Puedes hacer clic derecho > Propiedades > Seguridad y dar permisos de escritura.

## Próximos Pasos

1. ✅ Base de datos instalada y funcionando
2. ⏭️ Crear la estructura de carpetas del backend PHP
3. ⏭️ Implementar sistema de autenticación
4. ⏭️ Crear APIs REST para el frontend
5. ⏭️ Integrar con el dashboard existente

## Credenciales por Defecto

- **Base de datos:** `ftgym`
- **Usuario MySQL:** `root`
- **Contraseña MySQL:** (vacía por defecto)
- **Usuario Admin:** `admin@ftgym.com`
- **Contraseña Admin:** `admin123` (⚠️ CAMBIAR INMEDIATAMENTE)

## Contacto

Para dudas o problemas, revisa la documentación en `database/README.md` o consulta las consultas útiles en `database/queries_utiles.sql`.

