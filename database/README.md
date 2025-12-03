# Base de Datos - Sistema de Gestión de Gimnasio

## Descripción

Este archivo contiene el esquema completo de la base de datos para el sistema de gestión del gimnasio Functional Training.

## Instalación

### Requisitos
- XAMPP instalado
- MySQL/MariaDB activo
- phpMyAdmin (opcional, para gestión visual)

### Pasos para instalar

1. **Abrir phpMyAdmin o línea de comandos MySQL**
   - Desde XAMPP: http://localhost/phpmyadmin
   - O desde terminal: `mysql -u root -p`

2. **Importar el esquema**
   - Opción A: Desde phpMyAdmin
     - Seleccionar "Importar"
     - Elegir el archivo `schema.sql`
     - Clic en "Continuar"
   
   - Opción B: Desde línea de comandos
     ```bash
     mysql -u root -p < database/schema.sql
     ```

3. **Verificar la instalación**
   ```sql
   USE ftgym;
   SHOW TABLES;
   ```

## Estructura de Tablas

### Tablas Principales

#### 1. **roles**
Define los roles del sistema (admin, entrenador, cliente)

#### 2. **usuarios**
Información completa de todos los usuarios del sistema

#### 3. **planes**
Tipos de planes de membresía disponibles

#### 4. **membresias**
Registro de membresías activas de usuarios

#### 5. **pagos**
Historial de todos los pagos realizados

#### 6. **asistencias**
Registro de entrada/salida al gimnasio (escaneo QR)

#### 7. **ejercicios**
Catálogo de ejercicios disponibles

#### 8. **rutinas**
Rutinas de entrenamiento predefinidas

#### 9. **rutina_ejercicios**
Ejercicios que componen cada rutina

#### 10. **rutinas_usuario**
Rutinas asignadas a usuarios específicos

#### 11. **progreso_usuario**
Registro de progreso físico (peso, medidas, etc.)

#### 12. **productos**
Productos de la tienda del gimnasio

#### 13. **pedidos**
Pedidos de productos realizados por usuarios

#### 14. **pedido_items**
Items de cada pedido

#### 15. **clases**
Clases grupales disponibles

#### 16. **clase_horarios**
Horarios de las clases

#### 17. **clase_reservas**
Reservas de usuarios para clases

#### 18. **notificaciones**
Notificaciones del sistema para usuarios

## Usuario Administrador por Defecto

- **Email:** admin@ftgym.com
- **Password:** admin123 (¡CAMBIA ESTO INMEDIATAMENTE!)
- **Rol:** Administrador

## Relaciones Entre Tablas

```
usuarios
  ├── roles (rol_id)
  ├── membresias (usuario_id)
  ├── pagos (usuario_id)
  ├── asistencias (usuario_id)
  ├── rutinas_usuario (usuario_id)
  ├── progreso_usuario (usuario_id)
  ├── pedidos (usuario_id)
  └── notificaciones (usuario_id)

planes
  └── membresias (plan_id)

membresias
  ├── usuarios (usuario_id)
  ├── planes (plan_id)
  ├── pagos (membresia_id)
  └── asistencias (membresia_id)

rutinas
  ├── usuarios (created_by)
  ├── rutina_ejercicios (rutina_id)
  └── rutinas_usuario (rutina_id)

ejercicios
  └── rutina_ejercicios (ejercicio_id)

productos
  └── pedido_items (producto_id)

pedidos
  └── pedido_items (pedido_id)

clases
  ├── usuarios (instructor_id)
  ├── clase_horarios (clase_id)
  └── clase_reservas (clase_horario_id)
```

## Convenciones de Nomenclatura

- **Tablas:** Plural, snake_case (ej: `usuarios`, `membresias`)
- **Columnas:** snake_case (ej: `fecha_inicio`, `codigo_qr`)
- **Claves foráneas:** `fk_tabla_origen_tabla_referencia` (ej: `fk_usuarios_rol`)
- **Índices únicos:** `uk_tabla_columna` (ej: `uk_usuarios_email`)
- **Índices:** `idx_tabla_columna` (ej: `idx_usuarios_estado`)

## Notas Importantes

1. **Códigos QR:** Se generan automáticamente al crear un usuario. Deben ser únicos.

2. **Membresías:** Una membresía puede estar activa aunque haya vencido. El sistema debe validar la fecha de vencimiento.

3. **Asistencias:** Se registran tanto entradas como salidas. El código QR se valida contra la membresía activa.

4. **Precios:** Los precios se almacenan en DECIMAL(10,2) para evitar problemas de precisión.

5. **Fechas:** Se usan DATE para fechas simples y DATETIME para fechas con hora.

## Consultas Útiles

### Ver usuarios activos con membresía activa
```sql
SELECT u.*, m.fecha_fin, p.nombre as plan_nombre
FROM usuarios u
INNER JOIN membresias m ON u.id = m.usuario_id
INNER JOIN planes p ON m.plan_id = p.id
WHERE u.estado = 'activo' 
  AND m.estado = 'activa'
  AND m.fecha_fin >= CURDATE();
```

### Ver asistencias del día
```sql
SELECT u.nombre, u.apellido, a.fecha_entrada, a.fecha_salida
FROM asistencias a
INNER JOIN usuarios u ON a.usuario_id = u.id
WHERE DATE(a.fecha_entrada) = CURDATE()
ORDER BY a.fecha_entrada DESC;
```

### Ver membresías próximas a vencer
```sql
SELECT u.nombre, u.apellido, u.email, m.fecha_fin, p.nombre as plan
FROM membresias m
INNER JOIN usuarios u ON m.usuario_id = u.id
INNER JOIN planes p ON m.plan_id = p.id
WHERE m.estado = 'activa'
  AND m.fecha_fin BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY)
ORDER BY m.fecha_fin ASC;
```

## Mantenimiento

### Backup
```bash
mysqldump -u root -p ftgym_db > backup_ftgym_$(date +%Y%m%d).sql
```

### Restaurar
```bash
mysql -u root -p ftgym_db < backup_ftgym_20250101.sql
```

## Versión

- **Versión:** 1.0.0
- **Última actualización:** 2025

