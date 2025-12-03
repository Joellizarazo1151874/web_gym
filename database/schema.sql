-- =====================================================
-- SISTEMA DE GESTIÓN DE GIMNASIO - FUNCTIONAL TRAINING
-- Base de datos: ftgym_db
-- Versión: 1.0.0
-- Autor: Joel Lizarazo
-- Fecha: 2025
-- =====================================================

-- Crear base de datos si no existe
CREATE DATABASE IF NOT EXISTS `ftgym` 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE `ftgym`;

-- =====================================================
-- TABLA: roles
-- Descripción: Define los roles del sistema (admin, entrenador, cliente)
-- =====================================================
CREATE TABLE IF NOT EXISTS `roles` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(50) NOT NULL COMMENT 'Nombre del rol (admin, entrenador, cliente)',
  `descripcion` TEXT DEFAULT NULL COMMENT 'Descripción del rol y sus permisos',
  `activo` TINYINT(1) DEFAULT 1 COMMENT '1=activo, 0=inactivo',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_roles_nombre` (`nombre`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Roles del sistema';

-- =====================================================
-- TABLA: usuarios
-- Descripción: Información de usuarios del sistema (clientes, entrenadores, admins)
-- =====================================================
CREATE TABLE IF NOT EXISTS `usuarios` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `rol_id` INT(11) UNSIGNED NOT NULL COMMENT 'ID del rol del usuario',
  `documento` VARCHAR(20) NOT NULL COMMENT 'Documento de identidad (cédula, pasaporte)',
  `tipo_documento` ENUM('CC', 'CE', 'PA', 'TI') DEFAULT 'CC' COMMENT 'Tipo de documento',
  `nombre` VARCHAR(100) NOT NULL COMMENT 'Nombre del usuario',
  `apellido` VARCHAR(100) NOT NULL COMMENT 'Apellido del usuario',
  `email` VARCHAR(150) NOT NULL COMMENT 'Correo electrónico',
  `telefono` VARCHAR(20) DEFAULT NULL COMMENT 'Teléfono de contacto',
  `fecha_nacimiento` DATE DEFAULT NULL COMMENT 'Fecha de nacimiento',
  `genero` ENUM('M', 'F', 'O') DEFAULT NULL COMMENT 'Género: M=Masculino, F=Femenino, O=Otro',
  `direccion` TEXT DEFAULT NULL COMMENT 'Dirección de residencia',
  `ciudad` VARCHAR(100) DEFAULT NULL COMMENT 'Ciudad de residencia',
  `foto` VARCHAR(255) DEFAULT NULL COMMENT 'Ruta de la foto de perfil',
  `password` VARCHAR(255) NOT NULL COMMENT 'Contraseña hasheada',
  `codigo_qr` VARCHAR(100) DEFAULT NULL COMMENT 'Código QR único para acceso al gym',
  `estado` ENUM('activo', 'inactivo', 'suspendido') DEFAULT 'activo' COMMENT 'Estado del usuario',
  `email_verificado` TINYINT(1) DEFAULT 0 COMMENT '1=email verificado, 0=no verificado',
  `token_verificacion` VARCHAR(100) DEFAULT NULL COMMENT 'Token para verificación de email',
  `ultimo_acceso` DATETIME DEFAULT NULL COMMENT 'Última vez que el usuario accedió al sistema',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_usuarios_email` (`email`),
  UNIQUE KEY `uk_usuarios_documento` (`documento`),
  UNIQUE KEY `uk_usuarios_codigo_qr` (`codigo_qr`),
  KEY `idx_usuarios_rol` (`rol_id`),
  KEY `idx_usuarios_estado` (`estado`),
  CONSTRAINT `fk_usuarios_rol` FOREIGN KEY (`rol_id`) REFERENCES `roles` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Usuarios del sistema';

-- =====================================================
-- TABLA: planes
-- Descripción: Tipos de planes de membresía disponibles
-- =====================================================
CREATE TABLE IF NOT EXISTS `planes` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(100) NOT NULL COMMENT 'Nombre del plan (Día, Semana, Mes)',
  `descripcion` TEXT DEFAULT NULL COMMENT 'Descripción del plan',
  `duracion_dias` INT(11) NOT NULL COMMENT 'Duración del plan en días',
  `precio` DECIMAL(10,2) NOT NULL COMMENT 'Precio del plan',
  `precio_app` DECIMAL(10,2) DEFAULT NULL COMMENT 'Precio con descuento desde la app (10% descuento)',
  `tipo` ENUM('día', 'semana', 'mes', 'anual') NOT NULL COMMENT 'Tipo de plan',
  `activo` TINYINT(1) DEFAULT 1 COMMENT '1=activo, 0=inactivo',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_planes_activo` (`activo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Planes de membresía';

-- =====================================================
-- TABLA: membresias
-- Descripción: Registro de membresías activas de los usuarios
-- =====================================================
CREATE TABLE IF NOT EXISTS `membresias` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `usuario_id` INT(11) UNSIGNED NOT NULL COMMENT 'ID del usuario',
  `plan_id` INT(11) UNSIGNED NOT NULL COMMENT 'ID del plan contratado',
  `fecha_inicio` DATE NOT NULL COMMENT 'Fecha de inicio de la membresía',
  `fecha_fin` DATE NOT NULL COMMENT 'Fecha de vencimiento de la membresía',
  `precio_pagado` DECIMAL(10,2) NOT NULL COMMENT 'Precio que se pagó por esta membresía',
  `descuento_app` TINYINT(1) DEFAULT 0 COMMENT '1=se aplicó descuento de app, 0=sin descuento',
  `estado` ENUM('activa', 'vencida', 'cancelada', 'suspendida') DEFAULT 'activa' COMMENT 'Estado de la membresía',
  `observaciones` TEXT DEFAULT NULL COMMENT 'Observaciones adicionales',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_membresias_usuario` (`usuario_id`),
  KEY `idx_membresias_plan` (`plan_id`),
  KEY `idx_membresias_estado` (`estado`),
  KEY `idx_membresias_fechas` (`fecha_inicio`, `fecha_fin`),
  CONSTRAINT `fk_membresias_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_membresias_plan` FOREIGN KEY (`plan_id`) REFERENCES `planes` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Membresías de usuarios';

-- =====================================================
-- TABLA: pagos
-- Descripción: Historial de pagos realizados
-- =====================================================
CREATE TABLE IF NOT EXISTS `pagos` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `membresia_id` INT(11) UNSIGNED DEFAULT NULL COMMENT 'ID de la membresía pagada (si aplica)',
  `usuario_id` INT(11) UNSIGNED NOT NULL COMMENT 'ID del usuario que realizó el pago',
  `tipo` ENUM('membresia', 'producto', 'clase_especial', 'otro') NOT NULL COMMENT 'Tipo de pago',
  `monto` DECIMAL(10,2) NOT NULL COMMENT 'Monto del pago',
  `metodo_pago` ENUM('efectivo', 'tarjeta', 'transferencia', 'app', 'otro') NOT NULL COMMENT 'Método de pago',
  `referencia` VARCHAR(100) DEFAULT NULL COMMENT 'Número de referencia o transacción',
  `estado` ENUM('pendiente', 'completado', 'cancelado', 'reembolsado') DEFAULT 'pendiente' COMMENT 'Estado del pago',
  `fecha_pago` DATETIME DEFAULT NULL COMMENT 'Fecha y hora del pago',
  `observaciones` TEXT DEFAULT NULL COMMENT 'Observaciones del pago',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_pagos_membresia` (`membresia_id`),
  KEY `idx_pagos_usuario` (`usuario_id`),
  KEY `idx_pagos_estado` (`estado`),
  KEY `idx_pagos_fecha` (`fecha_pago`),
  CONSTRAINT `fk_pagos_membresia` FOREIGN KEY (`membresia_id`) REFERENCES `membresias` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_pagos_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Historial de pagos';

-- =====================================================
-- TABLA: asistencias
-- Descripción: Registro de asistencia al gimnasio (escaneo QR)
-- =====================================================
CREATE TABLE IF NOT EXISTS `asistencias` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `usuario_id` INT(11) UNSIGNED NOT NULL COMMENT 'ID del usuario que asistió',
  `membresia_id` INT(11) UNSIGNED DEFAULT NULL COMMENT 'ID de la membresía activa al momento de la asistencia',
  `fecha_entrada` DATETIME NOT NULL COMMENT 'Fecha y hora de entrada',
  `fecha_salida` DATETIME DEFAULT NULL COMMENT 'Fecha y hora de salida',
  `codigo_qr` VARCHAR(100) DEFAULT NULL COMMENT 'Código QR escaneado',
  `tipo_acceso` ENUM('entrada', 'salida') DEFAULT 'entrada' COMMENT 'Tipo de acceso',
  `dispositivo` VARCHAR(100) DEFAULT NULL COMMENT 'Dispositivo o ubicación del escáner',
  `observaciones` TEXT DEFAULT NULL COMMENT 'Observaciones adicionales',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_asistencias_usuario` (`usuario_id`),
  KEY `idx_asistencias_membresia` (`membresia_id`),
  KEY `idx_asistencias_fecha` (`fecha_entrada`),
  KEY `idx_asistencias_qr` (`codigo_qr`),
  CONSTRAINT `fk_asistencias_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_asistencias_membresia` FOREIGN KEY (`membresia_id`) REFERENCES `membresias` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Registro de asistencias al gimnasio';

-- =====================================================
-- TABLA: ejercicios
-- Descripción: Catálogo de ejercicios disponibles
-- =====================================================
CREATE TABLE IF NOT EXISTS `ejercicios` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(150) NOT NULL COMMENT 'Nombre del ejercicio',
  `descripcion` TEXT DEFAULT NULL COMMENT 'Descripción del ejercicio',
  `categoria` VARCHAR(100) DEFAULT NULL COMMENT 'Categoría (fuerza, cardio, flexibilidad, etc.)',
  `grupo_muscular` VARCHAR(100) DEFAULT NULL COMMENT 'Grupo muscular principal',
  `imagen` VARCHAR(255) DEFAULT NULL COMMENT 'Ruta de la imagen del ejercicio',
  `video_url` VARCHAR(255) DEFAULT NULL COMMENT 'URL del video tutorial',
  `nivel` ENUM('principiante', 'intermedio', 'avanzado') DEFAULT 'principiante' COMMENT 'Nivel de dificultad',
  `activo` TINYINT(1) DEFAULT 1 COMMENT '1=activo, 0=inactivo',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_ejercicios_categoria` (`categoria`),
  KEY `idx_ejercicios_activo` (`activo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Catálogo de ejercicios';

-- =====================================================
-- TABLA: rutinas
-- Descripción: Rutinas de entrenamiento predefinidas
-- =====================================================
CREATE TABLE IF NOT EXISTS `rutinas` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(150) NOT NULL COMMENT 'Nombre de la rutina',
  `descripcion` TEXT DEFAULT NULL COMMENT 'Descripción de la rutina',
  `objetivo` VARCHAR(100) DEFAULT NULL COMMENT 'Objetivo (ganar masa, perder peso, fuerza, etc.)',
  `nivel` ENUM('principiante', 'intermedio', 'avanzado') DEFAULT 'principiante' COMMENT 'Nivel de dificultad',
  `duracion_semanas` INT(11) DEFAULT NULL COMMENT 'Duración recomendada en semanas',
  `dias_semana` INT(11) DEFAULT NULL COMMENT 'Días de entrenamiento por semana',
  `activo` TINYINT(1) DEFAULT 1 COMMENT '1=activo, 0=inactivo',
  `created_by` INT(11) UNSIGNED DEFAULT NULL COMMENT 'ID del entrenador que creó la rutina',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_rutinas_objetivo` (`objetivo`),
  KEY `idx_rutinas_activo` (`activo`),
  CONSTRAINT `fk_rutinas_created_by` FOREIGN KEY (`created_by`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Rutinas de entrenamiento';

-- =====================================================
-- TABLA: rutina_ejercicios
-- Descripción: Ejercicios que componen una rutina
-- =====================================================
CREATE TABLE IF NOT EXISTS `rutina_ejercicios` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `rutina_id` INT(11) UNSIGNED NOT NULL COMMENT 'ID de la rutina',
  `ejercicio_id` INT(11) UNSIGNED NOT NULL COMMENT 'ID del ejercicio',
  `dia` INT(11) NOT NULL COMMENT 'Día de la semana (1=lunes, 2=martes, etc.)',
  `orden` INT(11) DEFAULT 1 COMMENT 'Orden del ejercicio en el día',
  `series` INT(11) DEFAULT NULL COMMENT 'Número de series',
  `repeticiones` VARCHAR(50) DEFAULT NULL COMMENT 'Repeticiones (ej: "10-12", "15", "hasta fallo")',
  `peso` VARCHAR(50) DEFAULT NULL COMMENT 'Peso recomendado (ej: "20kg", "cuerpo", "progresivo")',
  `descanso` INT(11) DEFAULT NULL COMMENT 'Tiempo de descanso en segundos',
  `notas` TEXT DEFAULT NULL COMMENT 'Notas adicionales sobre el ejercicio',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_rutina_ejercicios_rutina` (`rutina_id`),
  KEY `idx_rutina_ejercicios_ejercicio` (`ejercicio_id`),
  KEY `idx_rutina_ejercicios_dia` (`dia`),
  CONSTRAINT `fk_rutina_ejercicios_rutina` FOREIGN KEY (`rutina_id`) REFERENCES `rutinas` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_rutina_ejercicios_ejercicio` FOREIGN KEY (`ejercicio_id`) REFERENCES `ejercicios` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Ejercicios de rutinas';

-- =====================================================
-- TABLA: rutinas_usuario
-- Descripción: Rutinas asignadas a usuarios
-- =====================================================
CREATE TABLE IF NOT EXISTS `rutinas_usuario` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `usuario_id` INT(11) UNSIGNED NOT NULL COMMENT 'ID del usuario',
  `rutina_id` INT(11) UNSIGNED NOT NULL COMMENT 'ID de la rutina',
  `entrenador_id` INT(11) UNSIGNED DEFAULT NULL COMMENT 'ID del entrenador que asignó la rutina',
  `fecha_inicio` DATE NOT NULL COMMENT 'Fecha de inicio de la rutina',
  `fecha_fin` DATE DEFAULT NULL COMMENT 'Fecha de finalización de la rutina',
  `estado` ENUM('activa', 'completada', 'pausada', 'cancelada') DEFAULT 'activa' COMMENT 'Estado de la rutina',
  `observaciones` TEXT DEFAULT NULL COMMENT 'Observaciones del entrenador',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_rutinas_usuario_usuario` (`usuario_id`),
  KEY `idx_rutinas_usuario_rutina` (`rutina_id`),
  KEY `idx_rutinas_usuario_entrenador` (`entrenador_id`),
  KEY `idx_rutinas_usuario_estado` (`estado`),
  CONSTRAINT `fk_rutinas_usuario_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_rutinas_usuario_rutina` FOREIGN KEY (`rutina_id`) REFERENCES `rutinas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_rutinas_usuario_entrenador` FOREIGN KEY (`entrenador_id`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Rutinas asignadas a usuarios';

-- =====================================================
-- TABLA: progreso_usuario
-- Descripción: Registro de progreso físico de los usuarios
-- =====================================================
CREATE TABLE IF NOT EXISTS `progreso_usuario` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `usuario_id` INT(11) UNSIGNED NOT NULL COMMENT 'ID del usuario',
  `fecha` DATE NOT NULL COMMENT 'Fecha del registro',
  `peso` DECIMAL(5,2) DEFAULT NULL COMMENT 'Peso en kg',
  `altura` DECIMAL(5,2) DEFAULT NULL COMMENT 'Altura en cm',
  `imc` DECIMAL(5,2) DEFAULT NULL COMMENT 'Índice de masa corporal',
  `grasa_corporal` DECIMAL(5,2) DEFAULT NULL COMMENT 'Porcentaje de grasa corporal',
  `musculo` DECIMAL(5,2) DEFAULT NULL COMMENT 'Porcentaje de masa muscular',
  `medidas_brazo` DECIMAL(5,2) DEFAULT NULL COMMENT 'Medida del brazo en cm',
  `medidas_pecho` DECIMAL(5,2) DEFAULT NULL COMMENT 'Medida del pecho en cm',
  `medidas_cintura` DECIMAL(5,2) DEFAULT NULL COMMENT 'Medida de la cintura en cm',
  `medidas_cadera` DECIMAL(5,2) DEFAULT NULL COMMENT 'Medida de la cadera en cm',
  `medidas_pierna` DECIMAL(5,2) DEFAULT NULL COMMENT 'Medida de la pierna en cm',
  `foto_progreso` VARCHAR(255) DEFAULT NULL COMMENT 'Ruta de la foto de progreso',
  `notas` TEXT DEFAULT NULL COMMENT 'Notas adicionales',
  `registrado_por` INT(11) UNSIGNED DEFAULT NULL COMMENT 'ID del entrenador que registró el progreso',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_progreso_usuario` (`usuario_id`),
  KEY `idx_progreso_fecha` (`fecha`),
  CONSTRAINT `fk_progreso_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_progreso_registrado_por` FOREIGN KEY (`registrado_por`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Progreso físico de usuarios';

-- =====================================================
-- TABLA: productos
-- Descripción: Productos de la tienda del gimnasio
-- =====================================================
CREATE TABLE IF NOT EXISTS `productos` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(150) NOT NULL COMMENT 'Nombre del producto',
  `descripcion` TEXT DEFAULT NULL COMMENT 'Descripción del producto',
  `categoria` VARCHAR(100) DEFAULT NULL COMMENT 'Categoría (suplementos, accesorios, ropa)',
  `precio` DECIMAL(10,2) NOT NULL COMMENT 'Precio del producto',
  `stock` INT(11) DEFAULT 0 COMMENT 'Cantidad en stock',
  `imagen` VARCHAR(255) DEFAULT NULL COMMENT 'Ruta de la imagen del producto',
  `activo` TINYINT(1) DEFAULT 1 COMMENT '1=activo, 0=inactivo',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_productos_categoria` (`categoria`),
  KEY `idx_productos_activo` (`activo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Productos de la tienda';

-- =====================================================
-- TABLA: pedidos
-- Descripción: Pedidos de productos realizados por usuarios
-- =====================================================
CREATE TABLE IF NOT EXISTS `pedidos` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `usuario_id` INT(11) UNSIGNED NOT NULL COMMENT 'ID del usuario que realizó el pedido',
  `numero_pedido` VARCHAR(50) NOT NULL COMMENT 'Número único del pedido',
  `total` DECIMAL(10,2) NOT NULL COMMENT 'Total del pedido',
  `metodo_pago` ENUM('efectivo', 'tarjeta', 'transferencia', 'app') DEFAULT 'efectivo' COMMENT 'Método de pago',
  `estado` ENUM('pendiente', 'confirmado', 'en_preparacion', 'listo', 'entregado', 'cancelado') DEFAULT 'pendiente' COMMENT 'Estado del pedido',
  `fecha_pedido` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha y hora del pedido',
  `fecha_entrega` DATETIME DEFAULT NULL COMMENT 'Fecha y hora de entrega',
  `observaciones` TEXT DEFAULT NULL COMMENT 'Observaciones del pedido',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_pedidos_numero` (`numero_pedido`),
  KEY `idx_pedidos_usuario` (`usuario_id`),
  KEY `idx_pedidos_estado` (`estado`),
  CONSTRAINT `fk_pedidos_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Pedidos de productos';

-- =====================================================
-- TABLA: pedido_items
-- Descripción: Items de cada pedido
-- =====================================================
CREATE TABLE IF NOT EXISTS `pedido_items` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `pedido_id` INT(11) UNSIGNED NOT NULL COMMENT 'ID del pedido',
  `producto_id` INT(11) UNSIGNED NOT NULL COMMENT 'ID del producto',
  `cantidad` INT(11) NOT NULL COMMENT 'Cantidad del producto',
  `precio_unitario` DECIMAL(10,2) NOT NULL COMMENT 'Precio unitario al momento del pedido',
  `subtotal` DECIMAL(10,2) NOT NULL COMMENT 'Subtotal (cantidad * precio_unitario)',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_pedido_items_pedido` (`pedido_id`),
  KEY `idx_pedido_items_producto` (`producto_id`),
  CONSTRAINT `fk_pedido_items_pedido` FOREIGN KEY (`pedido_id`) REFERENCES `pedidos` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_pedido_items_producto` FOREIGN KEY (`producto_id`) REFERENCES `productos` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Items de pedidos';

-- =====================================================
-- TABLA: clases
-- Descripción: Clases grupales disponibles
-- =====================================================
CREATE TABLE IF NOT EXISTS `clases` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(150) NOT NULL COMMENT 'Nombre de la clase',
  `descripcion` TEXT DEFAULT NULL COMMENT 'Descripción de la clase',
  `instructor_id` INT(11) UNSIGNED DEFAULT NULL COMMENT 'ID del instructor',
  `capacidad_maxima` INT(11) DEFAULT NULL COMMENT 'Capacidad máxima de participantes',
  `duracion_minutos` INT(11) DEFAULT NULL COMMENT 'Duración en minutos',
  `activo` TINYINT(1) DEFAULT 1 COMMENT '1=activo, 0=inactivo',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_clases_instructor` (`instructor_id`),
  KEY `idx_clases_activo` (`activo`),
  CONSTRAINT `fk_clases_instructor` FOREIGN KEY (`instructor_id`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Clases grupales';

-- =====================================================
-- TABLA: clase_horarios
-- Descripción: Horarios de las clases
-- =====================================================
CREATE TABLE IF NOT EXISTS `clase_horarios` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `clase_id` INT(11) UNSIGNED NOT NULL COMMENT 'ID de la clase',
  `dia_semana` INT(11) NOT NULL COMMENT 'Día de la semana (1=lunes, 7=domingo)',
  `hora_inicio` TIME NOT NULL COMMENT 'Hora de inicio',
  `hora_fin` TIME NOT NULL COMMENT 'Hora de finalización',
  `activo` TINYINT(1) DEFAULT 1 COMMENT '1=activo, 0=inactivo',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_clase_horarios_clase` (`clase_id`),
  CONSTRAINT `fk_clase_horarios_clase` FOREIGN KEY (`clase_id`) REFERENCES `clases` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Horarios de clases';

-- =====================================================
-- TABLA: clase_reservas
-- Descripción: Reservas de usuarios para clases
-- =====================================================
CREATE TABLE IF NOT EXISTS `clase_reservas` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `usuario_id` INT(11) UNSIGNED NOT NULL COMMENT 'ID del usuario',
  `clase_horario_id` INT(11) UNSIGNED NOT NULL COMMENT 'ID del horario de la clase',
  `fecha_clase` DATE NOT NULL COMMENT 'Fecha de la clase',
  `estado` ENUM('reservada', 'confirmada', 'cancelada', 'asistio', 'no_asistio') DEFAULT 'reservada' COMMENT 'Estado de la reserva',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_clase_reservas_usuario` (`usuario_id`),
  KEY `idx_clase_reservas_horario` (`clase_horario_id`),
  KEY `idx_clase_reservas_fecha` (`fecha_clase`),
  CONSTRAINT `fk_clase_reservas_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_clase_reservas_horario` FOREIGN KEY (`clase_horario_id`) REFERENCES `clase_horarios` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Reservas de clases';

-- =====================================================
-- TABLA: notificaciones
-- Descripción: Notificaciones del sistema para usuarios
-- =====================================================
CREATE TABLE IF NOT EXISTS `notificaciones` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `usuario_id` INT(11) UNSIGNED DEFAULT NULL COMMENT 'ID del usuario (NULL = notificación global)',
  `titulo` VARCHAR(200) NOT NULL COMMENT 'Título de la notificación',
  `mensaje` TEXT NOT NULL COMMENT 'Mensaje de la notificación',
  `tipo` ENUM('info', 'success', 'warning', 'error', 'promocion') DEFAULT 'info' COMMENT 'Tipo de notificación',
  `leida` TINYINT(1) DEFAULT 0 COMMENT '1=leída, 0=no leída',
  `fecha` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha de la notificación',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_notificaciones_usuario` (`usuario_id`),
  KEY `idx_notificaciones_leida` (`leida`),
  CONSTRAINT `fk_notificaciones_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Notificaciones del sistema';

-- =====================================================
-- INSERCIÓN DE DATOS INICIALES
-- =====================================================

-- Insertar roles iniciales
INSERT INTO `roles` (`nombre`, `descripcion`, `activo`) VALUES
('admin', 'Administrador del sistema con acceso completo', 1),
('entrenador', 'Entrenador que puede asignar rutinas y ver progreso de usuarios', 1),
('empleado', 'Empleado que puede usar la caja y gestionar ventas', 1),
('cliente', 'Cliente del gimnasio con acceso a membresía y rutinas', 1);

-- Insertar planes iniciales (basados en la información del sitio web)
INSERT INTO `planes` (`nombre`, `descripcion`, `duracion_dias`, `precio`, `precio_app`, `tipo`, `activo`) VALUES
('Día', 'Acceso por un día', 1, 7000.00, 6300.00, 'día', 1),
('Semana', 'Acceso por una semana', 7, 25000.00, 22500.00, 'semana', 1),
('Mes', 'Acceso por un mes', 30, 60000.00, 54000.00, 'mes', 1);

-- Insertar usuario administrador por defecto
-- Password: admin123 (debe cambiarse después)
INSERT INTO `usuarios` (`rol_id`, `documento`, `tipo_documento`, `nombre`, `apellido`, `email`, `telefono`, `password`, `codigo_qr`, `estado`, `email_verificado`) VALUES
(1, '123456789', 'CC', 'Admin', 'Sistema', 'admin@ftgym.com', '3185312833', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'QR-ADMIN-001', 'activo', 1);

-- =====================================================
-- FIN DEL ESQUEMA
-- =====================================================

