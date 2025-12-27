-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 27-12-2025 a las 10:22:04
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `ftgym`
--

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `asistencias`
--

CREATE TABLE `asistencias` (
  `id` int(11) UNSIGNED NOT NULL,
  `usuario_id` int(11) UNSIGNED NOT NULL COMMENT 'ID del usuario que asistió',
  `membresia_id` int(11) UNSIGNED DEFAULT NULL COMMENT 'ID de la membresía activa al momento de la asistencia',
  `fecha_entrada` datetime NOT NULL COMMENT 'Fecha y hora de entrada',
  `fecha_salida` datetime DEFAULT NULL COMMENT 'Fecha y hora de salida',
  `codigo_qr` varchar(100) DEFAULT NULL COMMENT 'Código QR escaneado',
  `tipo_acceso` enum('entrada','salida') DEFAULT 'entrada' COMMENT 'Tipo de acceso',
  `dispositivo` varchar(100) DEFAULT NULL COMMENT 'Dispositivo o ubicación del escáner',
  `observaciones` text DEFAULT NULL COMMENT 'Observaciones adicionales',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Registro de asistencias al gimnasio';

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `checkin_live_buffer`
--

CREATE TABLE `checkin_live_buffer` (
  `id` tinyint(4) NOT NULL DEFAULT 1,
  `code` varchar(32) DEFAULT NULL,
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `clases`
--

CREATE TABLE `clases` (
  `id` int(11) UNSIGNED NOT NULL,
  `nombre` varchar(150) NOT NULL COMMENT 'Nombre de la clase',
  `descripcion` text DEFAULT NULL COMMENT 'Descripción de la clase',
  `instructor_id` int(11) UNSIGNED DEFAULT NULL COMMENT 'ID del instructor',
  `capacidad_maxima` int(11) DEFAULT NULL COMMENT 'Capacidad máxima de participantes',
  `duracion_minutos` int(11) DEFAULT NULL COMMENT 'Duración en minutos',
  `activo` tinyint(1) DEFAULT 1 COMMENT '1=activo, 0=inactivo',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Clases grupales';

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `clase_horarios`
--

CREATE TABLE `clase_horarios` (
  `id` int(11) UNSIGNED NOT NULL,
  `clase_id` int(11) UNSIGNED NOT NULL COMMENT 'ID de la clase',
  `dia_semana` int(11) NOT NULL COMMENT 'Día de la semana (1=lunes, 7=domingo)',
  `hora_inicio` time NOT NULL COMMENT 'Hora de inicio',
  `hora_fin` time NOT NULL COMMENT 'Hora de finalización',
  `activo` tinyint(1) DEFAULT 1 COMMENT '1=activo, 0=inactivo',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Horarios de clases';

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `clase_reservas`
--

CREATE TABLE `clase_reservas` (
  `id` int(11) UNSIGNED NOT NULL,
  `usuario_id` int(11) UNSIGNED NOT NULL COMMENT 'ID del usuario',
  `clase_horario_id` int(11) UNSIGNED NOT NULL COMMENT 'ID del horario de la clase',
  `fecha_clase` date NOT NULL COMMENT 'Fecha de la clase',
  `estado` enum('reservada','confirmada','cancelada','asistio','no_asistio') DEFAULT 'reservada' COMMENT 'Estado de la reserva',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Reservas de clases';

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `configuracion`
--

CREATE TABLE `configuracion` (
  `id` int(11) UNSIGNED NOT NULL,
  `clave` varchar(100) NOT NULL COMMENT 'Clave única de la configuración',
  `valor` text DEFAULT NULL COMMENT 'Valor de la configuración (puede ser JSON para arrays)',
  `tipo` enum('string','number','boolean','json','time') DEFAULT 'string' COMMENT 'Tipo de dato',
  `categoria` varchar(50) DEFAULT 'general' COMMENT 'Categoría de la configuración',
  `descripcion` text DEFAULT NULL COMMENT 'Descripción de la configuración',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Configuración del sistema';

--
-- Volcado de datos para la tabla `configuracion`
--

INSERT INTO `configuracion` (`id`, `clave`, `valor`, `tipo`, `categoria`, `descripcion`, `created_at`, `updated_at`) VALUES
(1, 'gimnasio_nombre', 'Functional Training Gym', 'string', 'general', 'Nombre del gimnasio', '2025-11-19 23:45:57', '2025-12-11 16:12:46'),
(2, 'gimnasio_direccion', 'Calle Principal 666', 'string', 'general', 'Dirección del gimnasio', '2025-11-19 23:45:57', '2025-12-11 16:12:46'),
(3, 'gimnasio_ciudad', 'Cúcuta', 'string', 'general', 'Ciudad del gimnasio', '2025-11-19 23:45:57', '2025-12-11 16:12:46'),
(4, 'gimnasio_telefono', '+57 1 234 5678', 'string', 'general', 'Teléfono de contacto', '2025-11-19 23:45:57', '2025-12-11 16:12:46'),
(5, 'gimnasio_email', 'info@ftgym.com', 'string', 'general', 'Email de contacto', '2025-11-19 23:45:57', '2025-12-11 16:12:46'),
(6, 'gimnasio_web', 'www.ftgym.com', 'string', 'general', 'Sitio web', '2025-11-19 23:45:57', '2025-12-11 16:12:46'),
(7, 'horario_apertura', '06:00', 'time', 'horarios', 'Hora de apertura', '2025-11-19 23:45:57', '2025-12-11 16:12:46'),
(8, 'horario_cierre', '20:30', 'time', 'horarios', 'Hora de cierre', '2025-11-19 23:45:57', '2025-12-11 16:12:46'),
(9, 'dias_semana', '[\"Lunes\",\"Martes\",\"Mi\\u00e9rcoles\",\"Jueves\",\"Viernes\",\"S\\u00e1bado\"]', 'json', 'horarios', 'Días de la semana que está abierto', '2025-11-19 23:45:57', '2025-12-11 16:12:46'),
(10, 'notificaciones_email', '1', 'boolean', 'notificaciones', 'Habilitar notificaciones por email', '2025-11-19 23:45:57', '2025-12-11 16:12:46'),
(11, 'notificaciones_sms', '0', 'boolean', 'notificaciones', 'Habilitar notificaciones por SMS', '2025-11-19 23:45:57', '2025-12-11 16:12:46'),
(12, 'notificaciones_push', '1', 'boolean', 'notificaciones', 'Habilitar notificaciones push', '2025-11-19 23:45:57', '2025-12-11 16:12:46'),
(13, 'sesion_timeout', '0', 'number', 'seguridad', 'Timeout de sesión en minutos', '2025-11-19 23:45:57', '2025-12-11 16:12:46'),
(14, 'requiere_verificacion_email', '0', 'boolean', 'seguridad', 'Requerir verificación de email', '2025-11-19 23:45:57', '2025-12-11 16:12:46'),
(15, 'metodos_pago', '[\"efectivo\",\"tarjeta\",\"transferencia\",\"app\"]', 'json', 'pagos', 'Métodos de pago habilitados', '2025-11-19 23:45:57', '2025-12-11 16:12:46'),
(16, 'moneda', 'COP', 'string', 'pagos', 'Moneda del sistema', '2025-11-19 23:45:57', '2025-12-11 16:12:46'),
(17, 'iva', '19', 'number', 'pagos', 'Porcentaje de IVA', '2025-11-19 23:45:57', '2025-12-11 16:12:46'),
(18, 'backup_automatico', '1', 'boolean', 'sistema', 'Habilitar backup automático', '2025-11-19 23:45:57', '2025-12-11 16:12:46'),
(19, 'frecuencia_backup', 'diario', 'string', 'sistema', 'Frecuencia de backup', '2025-11-19 23:45:57', '2025-12-11 16:12:46'),
(20, 'mantener_logs', '1', 'boolean', 'sistema', 'Mantener logs del sistema', '2025-11-19 23:45:57', '2025-12-11 16:12:46'),
(21, 'dias_logs', '30', 'number', 'sistema', 'Días de retención de logs', '2025-11-19 23:45:57', '2025-12-11 16:12:46'),
(144, 'app_descuento', '10', 'number', 'general', NULL, '2025-11-28 21:01:17', '2025-12-11 16:12:46'),
(241, 'gimnasio_telefono_2', '3209939817', 'string', 'general', NULL, '2025-12-06 06:26:16', '2025-12-11 16:12:46'),
(243, 'gimnasio_email_2', '', 'string', 'general', NULL, '2025-12-06 06:26:16', '2025-12-11 16:12:46'),
(344, 'horario_sabado_apertura', '07:00', 'time', 'general', NULL, '2025-12-06 06:44:55', '2025-12-11 16:12:46'),
(345, 'horario_sabado_cierre', '12:00', 'time', 'general', NULL, '2025-12-06 06:44:55', '2025-12-11 16:12:46'),
(346, 'horario_domingo_apertura', '08:00', 'time', 'general', NULL, '2025-12-06 06:44:55', '2025-12-11 16:12:46'),
(347, 'horario_domingo_cierre', '12:00', 'time', 'general', NULL, '2025-12-06 06:44:55', '2025-12-11 16:12:46'),
(488, 'red_social_facebook_url', 'https://www.facebook.com/', 'string', 'general', NULL, '2025-12-06 06:52:44', '2025-12-11 16:12:46'),
(489, 'red_social_facebook_activa', '1', 'boolean', 'general', NULL, '2025-12-06 06:52:44', '2025-12-11 16:12:46'),
(490, 'red_social_instagram_url', 'https://www.instagram.com/', 'string', 'general', NULL, '2025-12-06 06:52:44', '2025-12-11 16:12:46'),
(491, 'red_social_instagram_activa', '1', 'boolean', 'general', NULL, '2025-12-06 06:52:44', '2025-12-11 16:12:46'),
(492, 'red_social_tiktok_url', 'https://www.tiktok.com/', 'string', 'general', NULL, '2025-12-06 06:52:44', '2025-12-11 16:12:46'),
(493, 'red_social_tiktok_activa', '0', 'boolean', 'general', NULL, '2025-12-06 06:52:44', '2025-12-11 16:12:46'),
(494, 'red_social_x_url', 'https://www.x.com/', 'string', 'general', NULL, '2025-12-06 06:52:44', '2025-12-11 16:12:46'),
(495, 'red_social_x_activa', '0', 'boolean', 'general', NULL, '2025-12-06 06:52:44', '2025-12-11 16:12:46'),
(977, 'sesion_never_expire', '1', 'boolean', 'seguridad', 'Nunca cerrar sesión automáticamente (solo cierre manual)', '2025-12-06 09:56:46', '2025-12-11 16:12:46'),
(1089, 'checkin_qr_auto_enabled', '0', 'string', 'general', NULL, '2025-12-11 05:19:31', '2025-12-11 16:25:18'),
(1090, 'checkin_manual_enabled', '1', 'string', 'general', NULL, '2025-12-11 05:19:31', '2025-12-11 16:26:14'),
(1091, 'checkin_sound_enabled', '1', 'string', 'general', NULL, '2025-12-11 05:19:31', '2025-12-11 05:19:31'),
(1092, 'checkin_vibration_enabled', '1', 'string', 'general', NULL, '2025-12-11 05:19:31', '2025-12-11 05:19:31'),
(1093, 'checkin_auto_reset_seconds', '5', 'string', 'general', NULL, '2025-12-11 05:19:31', '2025-12-11 05:19:31'),
(1109, 'checkin_qr_position', 'right', 'string', 'general', NULL, '2025-12-11 05:29:40', '2025-12-11 16:23:01'),
(1162, 'checkin_input_clear_seconds', '3', 'string', 'general', NULL, '2025-12-11 06:32:32', '2025-12-11 06:32:32'),
(1176, 'checkin_camera_device_id', '644091e76e8d6c97e7e64217d0fa9e2a5e8dd2ba8228bff638e165ee4cf0fb20', 'string', 'general', NULL, '2025-12-11 06:39:05', '2025-12-11 16:24:59'),
(1228, 'logo_empresa', 'uploads/logo/logo_empresa.svg', 'string', 'general', NULL, '2025-12-11 07:15:40', '2025-12-11 16:04:40'),
(1485, 'checkin_live_input', '{\"code\":\"\",\"ts\":1766824175}', 'json', 'general', NULL, '2025-12-11 08:24:16', '2025-12-27 08:29:35');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `ejercicios`
--

CREATE TABLE `ejercicios` (
  `id` int(11) UNSIGNED NOT NULL,
  `nombre` varchar(150) NOT NULL COMMENT 'Nombre del ejercicio',
  `descripcion` text DEFAULT NULL COMMENT 'Descripción del ejercicio',
  `categoria` varchar(100) DEFAULT NULL COMMENT 'Categoría (fuerza, cardio, flexibilidad, etc.)',
  `grupo_muscular` varchar(100) DEFAULT NULL COMMENT 'Grupo muscular principal',
  `imagen` varchar(255) DEFAULT NULL COMMENT 'Ruta de la imagen del ejercicio',
  `video_url` varchar(255) DEFAULT NULL COMMENT 'URL del video tutorial',
  `nivel` enum('principiante','intermedio','avanzado') DEFAULT 'principiante' COMMENT 'Nivel de dificultad',
  `activo` tinyint(1) DEFAULT 1 COMMENT '1=activo, 0=inactivo',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Catálogo de ejercicios';

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `landing_content`
--

CREATE TABLE `landing_content` (
  `id` int(11) UNSIGNED NOT NULL,
  `section` varchar(100) NOT NULL COMMENT 'Sección del landing (hero, about, classes, etc)',
  `element_id` varchar(100) NOT NULL COMMENT 'ID único del elemento editable',
  `content_type` enum('text','image','html') DEFAULT 'text' COMMENT 'Tipo de contenido',
  `content` text DEFAULT NULL COMMENT 'Contenido del elemento (texto o HTML)',
  `image_path` varchar(255) DEFAULT NULL COMMENT 'Ruta de la imagen si es tipo image',
  `alt_text` varchar(255) DEFAULT NULL COMMENT 'Texto alternativo para imágenes',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `updated_by` int(11) UNSIGNED DEFAULT NULL COMMENT 'ID del usuario que hizo la última actualización'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Contenidos editables del landing page';

--
-- Volcado de datos para la tabla `landing_content`
--

INSERT INTO `landing_content` (`id`, `section`, `element_id`, `content_type`, `content`, `image_path`, `alt_text`, `created_at`, `updated_at`, `updated_by`) VALUES
(1, 'header', 'logo-text', 'text', 'Functional Training', NULL, '', '2025-12-06 06:18:12', '2025-12-06 06:33:15', 1),
(2, 'class', 'class-1-image', 'image', NULL, 'uploads/landing/class_class-1-image_1765002062_6933cb4e26dd6.jpg', '', '2025-12-06 06:20:52', '2025-12-06 06:21:02', 1),
(3, 'footer', 'schedule-title-2', 'text', 'Sábado', NULL, '', '2025-12-06 06:29:44', '2025-12-06 06:29:44', 1),
(4, 'footer', 'schedule-time-1', 'text', '5:00am - 9:30pm', NULL, '', '2025-12-06 06:30:27', '2025-12-06 06:30:27', 1),
(5, 'app', 'title', 'text', 'Tu gimnasio en el bolsillo', NULL, '', '2025-12-06 06:30:58', '2025-12-11 06:49:07', 1),
(6, 'app', 'subtitle', 'text', 'Aplicación Móvil', NULL, '', '2025-12-06 06:34:14', '2025-12-06 08:04:21', 1),
(7, 'blog', 'title', 'text', 'Últimas Publicaciones del Blog', NULL, '', '2025-12-06 06:36:42', '2025-12-06 06:52:05', 1),
(8, 'class', 'class-2-title', 'text', 'Cardio y Fuerza', NULL, '', '2025-12-06 07:10:03', '2025-12-06 07:14:42', 1),
(9, 'class', 'class-2-text', 'text', 'Circuitos funcionales y HIIT para aumentar resistencia, quemar grasa y mejorar tu condición física general en poco tiempo.', NULL, '', '2025-12-06 07:10:32', '2025-12-06 07:14:52', 1),
(10, 'class', 'subtitle', 'text', 'Nuestras Clases', NULL, '', '2025-12-06 07:11:19', '2025-12-06 07:11:38', 1),
(11, 'class', 'class-1-title', 'text', 'Levantamiento de Pesas', NULL, '', '2025-12-06 07:13:04', '2025-12-06 07:14:37', 1),
(12, 'video', 'title', 'text', 'Explora la Vida Fitness', NULL, '', '2025-12-06 07:15:02', '2025-12-06 07:15:10', 1),
(13, 'about', 'cta-button', 'text', 'Explorar más', NULL, '', '2025-12-06 07:15:16', '2025-12-06 07:15:26', 1),
(14, 'blog', 'blog-1-text', 'text', 'Ampliamos la zona de peso libre y sumamos máquinas de última generación para que entrenes con más comodidad y seguridad en tus rutinas de fuerza e hipertrofia. ', NULL, '', '2025-12-06 07:20:26', '2025-12-06 07:20:47', 1),
(15, 'blog', 'blog-1-date', 'text', '15 Sep 2025', NULL, '', '2025-12-06 07:20:31', '2025-12-06 07:20:41', 1),
(16, 'footer', 'brand-text', 'text', 'Entrena con nosotros y alcanza tus objetivos fitness. Instalaciones modernas, entrenadores profesionales y una comunidad activa.', NULL, '', '2025-12-06 08:04:28', '2025-12-06 08:04:28', 1),
(17, 'footer', 'logo-text', 'text', 'Functional Training', NULL, '', '2025-12-06 08:04:37', '2025-12-06 08:04:47', 1),
(18, 'about', 'coach-name', 'text', 'Joel Lizarazo', NULL, '', '2025-12-06 08:05:00', '2025-12-11 16:28:33', 1),
(19, 'footer', 'copyright', 'text', '© 2025 Functional Training. Todos los derechos reservados por Joel Lizarazo', NULL, '', '2025-12-11 07:11:47', '2025-12-11 07:11:47', 1),
(20, 'blog', 'subtitle', 'text', 'Nuestras Noticias', NULL, '', '2025-12-11 16:30:09', '2025-12-11 16:30:30', 1),
(21, 'header', 'cta-button', 'text', 'Únete ahora', NULL, '', '2025-12-11 16:33:05', '2025-12-11 16:33:16', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `membresias`
--

CREATE TABLE `membresias` (
  `id` int(11) UNSIGNED NOT NULL,
  `usuario_id` int(11) UNSIGNED NOT NULL COMMENT 'ID del usuario',
  `plan_id` int(11) UNSIGNED NOT NULL COMMENT 'ID del plan contratado',
  `fecha_inicio` date NOT NULL COMMENT 'Fecha de inicio de la membresía',
  `fecha_fin` date NOT NULL COMMENT 'Fecha de vencimiento de la membresía',
  `precio_pagado` decimal(10,2) NOT NULL COMMENT 'Precio que se pagó por esta membresía',
  `descuento_app` tinyint(1) DEFAULT 0 COMMENT '1=se aplicó descuento de app, 0=sin descuento',
  `estado` enum('activa','vencida','cancelada','suspendida') DEFAULT 'activa' COMMENT 'Estado de la membresía',
  `observaciones` text DEFAULT NULL COMMENT 'Observaciones adicionales',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Membresías de usuarios';

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `notificaciones`
--

CREATE TABLE `notificaciones` (
  `id` int(11) UNSIGNED NOT NULL,
  `usuario_id` int(11) UNSIGNED DEFAULT NULL COMMENT 'ID del usuario (NULL = notificación global)',
  `titulo` varchar(200) NOT NULL COMMENT 'Título de la notificación',
  `mensaje` text NOT NULL COMMENT 'Mensaje de la notificación',
  `tipo` enum('info','success','warning','error','promocion') DEFAULT 'info' COMMENT 'Tipo de notificación',
  `leida` tinyint(1) DEFAULT 0 COMMENT '1=leída, 0=no leída',
  `fecha_leida` datetime DEFAULT NULL COMMENT 'Fecha en que se marcó como leída',
  `fecha` datetime DEFAULT current_timestamp() COMMENT 'Fecha de la notificación',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Notificaciones del sistema';

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `pagos`
--

CREATE TABLE `pagos` (
  `id` int(11) UNSIGNED NOT NULL,
  `membresia_id` int(11) UNSIGNED DEFAULT NULL COMMENT 'ID de la membresía pagada (si aplica)',
  `usuario_id` int(11) UNSIGNED NOT NULL COMMENT 'ID del usuario que realizó el pago',
  `tipo` enum('membresia','producto','clase_especial','otro') NOT NULL COMMENT 'Tipo de pago',
  `monto` decimal(10,2) NOT NULL COMMENT 'Monto del pago',
  `metodo_pago` enum('efectivo','tarjeta','transferencia','app','otro') NOT NULL COMMENT 'Método de pago',
  `referencia` varchar(100) DEFAULT NULL COMMENT 'Número de referencia o transacción',
  `estado` enum('pendiente','completado','cancelado','reembolsado') DEFAULT 'pendiente' COMMENT 'Estado del pago',
  `fecha_pago` datetime DEFAULT NULL COMMENT 'Fecha y hora del pago',
  `observaciones` text DEFAULT NULL COMMENT 'Observaciones del pago',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Historial de pagos';

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `pedidos`
--

CREATE TABLE `pedidos` (
  `id` int(11) UNSIGNED NOT NULL,
  `usuario_id` int(11) UNSIGNED NOT NULL COMMENT 'ID del usuario que realizó el pedido',
  `numero_pedido` varchar(50) NOT NULL COMMENT 'Número único del pedido',
  `total` decimal(10,2) NOT NULL COMMENT 'Total del pedido',
  `metodo_pago` enum('efectivo','tarjeta','transferencia','app') DEFAULT 'efectivo' COMMENT 'Método de pago',
  `estado` enum('pendiente','confirmado','en_preparacion','listo','entregado','cancelado') DEFAULT 'pendiente' COMMENT 'Estado del pedido',
  `fecha_pedido` datetime DEFAULT current_timestamp() COMMENT 'Fecha y hora del pedido',
  `fecha_entrega` datetime DEFAULT NULL COMMENT 'Fecha y hora de entrega',
  `observaciones` text DEFAULT NULL COMMENT 'Observaciones del pedido',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Pedidos de productos';

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `pedido_items`
--

CREATE TABLE `pedido_items` (
  `id` int(11) UNSIGNED NOT NULL,
  `pedido_id` int(11) UNSIGNED NOT NULL COMMENT 'ID del pedido',
  `producto_id` int(11) UNSIGNED NOT NULL COMMENT 'ID del producto',
  `cantidad` int(11) NOT NULL COMMENT 'Cantidad del producto',
  `precio_unitario` decimal(10,2) NOT NULL COMMENT 'Precio unitario al momento del pedido',
  `subtotal` decimal(10,2) NOT NULL COMMENT 'Subtotal (cantidad * precio_unitario)',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Items de pedidos';

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `planes`
--

CREATE TABLE `planes` (
  `id` int(11) UNSIGNED NOT NULL,
  `nombre` varchar(100) NOT NULL COMMENT 'Nombre del plan (Día, Semana, Mes)',
  `descripcion` text DEFAULT NULL COMMENT 'Descripción del plan',
  `duracion_dias` int(11) NOT NULL COMMENT 'Duración del plan en días',
  `precio` decimal(10,2) NOT NULL COMMENT 'Precio del plan',
  `precio_app` decimal(10,2) DEFAULT NULL COMMENT 'Precio con descuento desde la app (10% descuento)',
  `tipo` enum('día','semana','mes','anual') NOT NULL COMMENT 'Tipo de plan',
  `activo` tinyint(1) DEFAULT 1 COMMENT '1=activo, 0=inactivo',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Planes de membresía';

--
-- Volcado de datos para la tabla `planes`
--

INSERT INTO `planes` (`id`, `nombre`, `descripcion`, `duracion_dias`, `precio`, `precio_app`, `tipo`, `activo`, `created_at`, `updated_at`) VALUES
(1, 'Día', 'Acceso por un día', 1, 7000.00, 6300.00, 'día', 1, '2025-11-04 19:34:42', '2025-12-11 16:12:46'),
(2, 'Semana', 'Acceso por una semana', 7, 25000.00, 22500.00, 'semana', 1, '2025-11-04 19:34:42', '2025-12-11 16:12:46'),
(3, 'Mes', 'Acceso por un mes', 30, 70000.00, 63000.00, 'mes', 1, '2025-11-04 19:34:42', '2025-12-11 16:12:46'),
(4, 'Anual', 'Pla del año', 365, 1000000.00, 900000.00, 'anual', 0, '2025-11-28 21:00:10', '2025-12-11 16:12:46');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `preferencias_usuario`
--

CREATE TABLE `preferencias_usuario` (
  `id` int(11) UNSIGNED NOT NULL,
  `usuario_id` int(11) UNSIGNED NOT NULL COMMENT 'ID del usuario',
  `color_mode` varchar(20) DEFAULT 'light' COMMENT 'Modo de color: light, dark, auto',
  `dir_mode` varchar(10) DEFAULT 'ltr' COMMENT 'Dirección: ltr, rtl',
  `sidebar_color` varchar(50) DEFAULT NULL COMMENT 'Color del sidebar',
  `sidebar_type` text DEFAULT NULL COMMENT 'Tipos de sidebar (JSON array)',
  `sidebar_style` varchar(50) DEFAULT NULL COMMENT 'Estilo del sidebar',
  `navbar_type` varchar(50) DEFAULT NULL COMMENT 'Tipo de navbar',
  `color_custom` varchar(50) DEFAULT NULL COMMENT 'Color personalizado del tema',
  `color_custom_info` varchar(50) DEFAULT NULL COMMENT 'Información del color personalizado',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Preferencias de tema y UI de usuarios';

--
-- Volcado de datos para la tabla `preferencias_usuario`
--

INSERT INTO `preferencias_usuario` (`id`, `usuario_id`, `color_mode`, `dir_mode`, `sidebar_color`, `sidebar_type`, `sidebar_style`, `navbar_type`, `color_custom`, `color_custom_info`, `created_at`, `updated_at`) VALUES
(1, 1, 'light', 'ltr', 'sidebar-white', '[]', 'navs-rounded-all', NULL, 'theme-color-red', '#366AF0', '2025-12-06 12:10:38', '2025-12-27 08:12:24');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `productos`
--

CREATE TABLE `productos` (
  `id` int(11) UNSIGNED NOT NULL,
  `nombre` varchar(150) NOT NULL COMMENT 'Nombre del producto',
  `descripcion` text DEFAULT NULL COMMENT 'Descripción del producto',
  `categoria` varchar(100) DEFAULT NULL COMMENT 'Categoría (suplementos, accesorios, ropa)',
  `precio` decimal(10,2) NOT NULL COMMENT 'Precio del producto',
  `stock` int(11) DEFAULT 0 COMMENT 'Cantidad en stock',
  `imagen` varchar(255) DEFAULT NULL COMMENT 'Ruta de la imagen del producto',
  `activo` tinyint(1) DEFAULT 1 COMMENT '1=activo, 0=inactivo',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Productos de la tienda';

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `progreso_usuario`
--

CREATE TABLE `progreso_usuario` (
  `id` int(11) UNSIGNED NOT NULL,
  `usuario_id` int(11) UNSIGNED NOT NULL COMMENT 'ID del usuario',
  `fecha` date NOT NULL COMMENT 'Fecha del registro',
  `peso` decimal(5,2) DEFAULT NULL COMMENT 'Peso en kg',
  `altura` decimal(5,2) DEFAULT NULL COMMENT 'Altura en cm',
  `imc` decimal(5,2) DEFAULT NULL COMMENT 'Índice de masa corporal',
  `grasa_corporal` decimal(5,2) DEFAULT NULL COMMENT 'Porcentaje de grasa corporal',
  `musculo` decimal(5,2) DEFAULT NULL COMMENT 'Porcentaje de masa muscular',
  `medidas_brazo` decimal(5,2) DEFAULT NULL COMMENT 'Medida del brazo en cm',
  `medidas_pecho` decimal(5,2) DEFAULT NULL COMMENT 'Medida del pecho en cm',
  `medidas_cintura` decimal(5,2) DEFAULT NULL COMMENT 'Medida de la cintura en cm',
  `medidas_cadera` decimal(5,2) DEFAULT NULL COMMENT 'Medida de la cadera en cm',
  `medidas_pierna` decimal(5,2) DEFAULT NULL COMMENT 'Medida de la pierna en cm',
  `foto_progreso` varchar(255) DEFAULT NULL COMMENT 'Ruta de la foto de progreso',
  `notas` text DEFAULT NULL COMMENT 'Notas adicionales',
  `registrado_por` int(11) UNSIGNED DEFAULT NULL COMMENT 'ID del entrenador que registró el progreso',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Progreso físico de usuarios';

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `push_notifications_config`
--

CREATE TABLE `push_notifications_config` (
  `id` int(11) UNSIGNED NOT NULL,
  `tipo` varchar(50) NOT NULL COMMENT 'Tipo de notificación (cumpleanos, membresia_vencimiento, inactividad)',
  `activa` tinyint(1) DEFAULT 1 COMMENT '1=activa, 0=inactiva',
  `titulo` varchar(200) NOT NULL COMMENT 'Título de la notificación',
  `mensaje` text NOT NULL COMMENT 'Mensaje de la notificación (puede usar variables como {nombre}, {dias}, etc.)',
  `dias_antes` int(11) DEFAULT 0 COMMENT 'Días antes del evento para enviar (0 = el mismo día)',
  `dias_inactividad` int(11) DEFAULT 7 COMMENT 'Días de inactividad para notificar (solo para tipo inactividad)',
  `hora_envio` time DEFAULT '09:00:00' COMMENT 'Hora del día para enviar la notificación',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Configuración de notificaciones push automáticas';

--
-- Volcado de datos para la tabla `push_notifications_config`
--

INSERT INTO `push_notifications_config` (`id`, `tipo`, `activa`, `titulo`, `mensaje`, `dias_antes`, `dias_inactividad`, `hora_envio`, `created_at`, `updated_at`) VALUES
(1, 'cumpleanos', 1, '¡Feliz Cumpleaños! 🎉', '¡Feliz cumpleaños {nombre}! Esperamos verte hoy en el gimnasio. Te deseamos un día lleno de energía y éxito. ¡Vamos a entrenar! 💪', 0, NULL, '06:00:00', '2025-12-06 09:43:23', '2025-12-11 16:00:36'),
(2, 'membresia_vencimiento', 1, 'Tu membresía está por vencer ⏰', 'Hola {nombre}, tu membresía vence en {dias} día(s). Renueva ahora para no perder tus beneficios. ¡Te esperamos!', 1, NULL, '10:00:00', '2025-12-06 09:43:23', '2025-12-11 16:02:26'),
(3, 'membresia_vencida', 1, 'Tu membresía ha vencido', 'Hola {nombre}, tu membresía ha vencido. Renueva ahora para continuar disfrutando de todos nuestros servicios.', 0, NULL, '10:00:00', '2025-12-06 09:43:23', '2025-12-06 09:43:23'),
(4, 'inactividad', 1, 'Te extrañamos en el gimnasio 💪', 'Hola {nombre}, hace {dias} día(s) que no te vemos en el gimnasio. ¡Vuelve y continúa con tu rutina! Te esperamos.', 0, 7, '11:00:00', '2025-12-06 09:43:23', '2025-12-06 09:43:23');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `roles`
--

CREATE TABLE `roles` (
  `id` int(11) UNSIGNED NOT NULL,
  `nombre` varchar(50) NOT NULL COMMENT 'Nombre del rol (admin, entrenador, cliente)',
  `descripcion` text DEFAULT NULL COMMENT 'Descripción del rol y sus permisos',
  `activo` tinyint(1) DEFAULT 1 COMMENT '1=activo, 0=inactivo',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Roles del sistema';

--
-- Volcado de datos para la tabla `roles`
--

INSERT INTO `roles` (`id`, `nombre`, `descripcion`, `activo`, `created_at`, `updated_at`) VALUES
(1, 'admin', 'Administrador del sistema con acceso completo', 1, '2025-11-04 19:34:42', '2025-11-04 19:34:42'),
(2, 'entrenador', 'Entrenador que puede asignar rutinas y ver progreso de usuarios', 1, '2025-11-04 19:34:42', '2025-11-04 19:34:42'),
(3, 'cliente', 'Cliente del gimnasio con acceso a membresía y rutinas', 1, '2025-11-04 19:34:42', '2025-11-04 19:34:42'),
(4, 'empleado', 'Empleado que puede usar la caja y gestionar ventas', 1, '2025-12-03 04:21:46', '2025-12-03 04:21:46');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `rutinas`
--

CREATE TABLE `rutinas` (
  `id` int(11) UNSIGNED NOT NULL,
  `nombre` varchar(150) NOT NULL COMMENT 'Nombre de la rutina',
  `descripcion` text DEFAULT NULL COMMENT 'Descripción de la rutina',
  `objetivo` varchar(100) DEFAULT NULL COMMENT 'Objetivo (ganar masa, perder peso, fuerza, etc.)',
  `nivel` enum('principiante','intermedio','avanzado') DEFAULT 'principiante' COMMENT 'Nivel de dificultad',
  `duracion_semanas` int(11) DEFAULT NULL COMMENT 'Duración recomendada en semanas',
  `dias_semana` int(11) DEFAULT NULL COMMENT 'Días de entrenamiento por semana',
  `activo` tinyint(1) DEFAULT 1 COMMENT '1=activo, 0=inactivo',
  `created_by` int(11) UNSIGNED DEFAULT NULL COMMENT 'ID del entrenador que creó la rutina',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Rutinas de entrenamiento';

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `rutinas_usuario`
--

CREATE TABLE `rutinas_usuario` (
  `id` int(11) UNSIGNED NOT NULL,
  `usuario_id` int(11) UNSIGNED NOT NULL COMMENT 'ID del usuario',
  `rutina_id` int(11) UNSIGNED NOT NULL COMMENT 'ID de la rutina',
  `entrenador_id` int(11) UNSIGNED DEFAULT NULL COMMENT 'ID del entrenador que asignó la rutina',
  `fecha_inicio` date NOT NULL COMMENT 'Fecha de inicio de la rutina',
  `fecha_fin` date DEFAULT NULL COMMENT 'Fecha de finalización de la rutina',
  `estado` enum('activa','completada','pausada','cancelada') DEFAULT 'activa' COMMENT 'Estado de la rutina',
  `observaciones` text DEFAULT NULL COMMENT 'Observaciones del entrenador',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Rutinas asignadas a usuarios';

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `rutina_ejercicios`
--

CREATE TABLE `rutina_ejercicios` (
  `id` int(11) UNSIGNED NOT NULL,
  `rutina_id` int(11) UNSIGNED NOT NULL COMMENT 'ID de la rutina',
  `ejercicio_id` int(11) UNSIGNED NOT NULL COMMENT 'ID del ejercicio',
  `dia` int(11) NOT NULL COMMENT 'Día de la semana (1=lunes, 2=martes, etc.)',
  `orden` int(11) DEFAULT 1 COMMENT 'Orden del ejercicio en el día',
  `series` int(11) DEFAULT NULL COMMENT 'Número de series',
  `repeticiones` varchar(50) DEFAULT NULL COMMENT 'Repeticiones (ej: "10-12", "15", "hasta fallo")',
  `peso` varchar(50) DEFAULT NULL COMMENT 'Peso recomendado (ej: "20kg", "cuerpo", "progresivo")',
  `descanso` int(11) DEFAULT NULL COMMENT 'Tiempo de descanso en segundos',
  `notas` text DEFAULT NULL COMMENT 'Notas adicionales sobre el ejercicio',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Ejercicios de rutinas';

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `sesiones_caja`
--

CREATE TABLE `sesiones_caja` (
  `id` int(11) UNSIGNED NOT NULL,
  `fecha_apertura` datetime NOT NULL COMMENT 'Fecha y hora de apertura de caja',
  `fecha_cierre` datetime DEFAULT NULL COMMENT 'Fecha y hora de cierre de caja',
  `monto_apertura` decimal(10,2) NOT NULL COMMENT 'Monto con el que se abrió la caja',
  `monto_cierre` decimal(10,2) DEFAULT NULL COMMENT 'Monto con el que se cerró la caja',
  `monto_esperado` decimal(10,2) DEFAULT NULL COMMENT 'Monto esperado según transacciones',
  `diferencia` decimal(10,2) DEFAULT NULL COMMENT 'Diferencia entre monto_cierre y monto_esperado',
  `estado` enum('abierta','cerrada') DEFAULT 'abierta' COMMENT 'Estado de la sesión',
  `abierta_por` int(11) UNSIGNED NOT NULL COMMENT 'ID del usuario que abrió la caja',
  `cerrada_por` int(11) UNSIGNED DEFAULT NULL COMMENT 'ID del usuario que cerró la caja',
  `observaciones_apertura` text DEFAULT NULL COMMENT 'Observaciones al abrir',
  `observaciones_cierre` text DEFAULT NULL COMMENT 'Observaciones al cerrar',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Sesiones de apertura y cierre de caja';

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `transacciones_financieras`
--

CREATE TABLE `transacciones_financieras` (
  `id` int(11) UNSIGNED NOT NULL,
  `tipo` enum('ingreso','egreso') NOT NULL COMMENT 'Tipo de transacción: ingreso o egreso',
  `categoria` varchar(100) NOT NULL COMMENT 'Categoría: membresia, producto, gasto_operativo, gasto_equipamiento, salario, otro',
  `concepto` varchar(255) NOT NULL COMMENT 'Concepto o descripción de la transacción',
  `monto` decimal(10,2) NOT NULL COMMENT 'Monto de la transacción',
  `metodo_pago` enum('efectivo','tarjeta','transferencia','app','otro') DEFAULT 'efectivo' COMMENT 'Método de pago',
  `referencia` varchar(100) DEFAULT NULL COMMENT 'Número de referencia o comprobante',
  `usuario_id` int(11) UNSIGNED DEFAULT NULL COMMENT 'ID del usuario relacionado (si aplica)',
  `membresia_id` int(11) UNSIGNED DEFAULT NULL COMMENT 'ID de la membresía relacionada (si aplica)',
  `producto_id` int(11) UNSIGNED DEFAULT NULL COMMENT 'ID del producto relacionado (si aplica)',
  `fecha` datetime NOT NULL COMMENT 'Fecha y hora de la transacción',
  `observaciones` text DEFAULT NULL COMMENT 'Observaciones adicionales',
  `registrado_por` int(11) UNSIGNED NOT NULL COMMENT 'ID del usuario que registró la transacción',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Transacciones financieras del gimnasio';

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuarios`
--

CREATE TABLE `usuarios` (
  `id` int(11) UNSIGNED NOT NULL,
  `rol_id` int(11) UNSIGNED NOT NULL COMMENT 'ID del rol del usuario',
  `documento` varchar(20) NOT NULL COMMENT 'Documento de identidad (cédula, pasaporte)',
  `tipo_documento` enum('CC','CE','PA','TI') DEFAULT 'CC' COMMENT 'Tipo de documento',
  `nombre` varchar(100) NOT NULL COMMENT 'Nombre del usuario',
  `apellido` varchar(100) NOT NULL COMMENT 'Apellido del usuario',
  `email` varchar(150) NOT NULL COMMENT 'Correo electrónico',
  `telefono` varchar(20) DEFAULT NULL COMMENT 'Teléfono de contacto',
  `fecha_nacimiento` date DEFAULT NULL COMMENT 'Fecha de nacimiento',
  `genero` enum('M','F','O') DEFAULT NULL COMMENT 'Género: M=Masculino, F=Femenino, O=Otro',
  `direccion` text DEFAULT NULL COMMENT 'Dirección de residencia',
  `ciudad` varchar(100) DEFAULT NULL COMMENT 'Ciudad de residencia',
  `foto` varchar(255) DEFAULT NULL COMMENT 'Ruta de la foto de perfil',
  `password` varchar(255) NOT NULL COMMENT 'Contraseña hasheada',
  `codigo_qr` varchar(100) DEFAULT NULL COMMENT 'Código QR único para acceso al gym',
  `estado` enum('activo','inactivo','suspendido') DEFAULT 'activo' COMMENT 'Estado del usuario',
  `email_verificado` tinyint(1) DEFAULT 0 COMMENT '1=email verificado, 0=no verificado',
  `token_verificacion` varchar(100) DEFAULT NULL COMMENT 'Token para verificación de email',
  `ultimo_acceso` datetime DEFAULT NULL COMMENT 'Última vez que el usuario accedió al sistema',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Usuarios del sistema';

--
-- Volcado de datos para la tabla `usuarios`
--

INSERT INTO `usuarios` (`id`, `rol_id`, `documento`, `tipo_documento`, `nombre`, `apellido`, `email`, `telefono`, `fecha_nacimiento`, `genero`, `direccion`, `ciudad`, `foto`, `password`, `codigo_qr`, `estado`, `email_verificado`, `token_verificacion`, `ultimo_acceso`, `created_at`, `updated_at`) VALUES
(1, 1, '123456789', 'CC', 'Admin', 'Sistema', 'admin@gmail.com', '3185312833', NULL, NULL, NULL, 'admin@gmail.com', NULL, '$2y$10$dZh1mFWRRsviZ41WOXAm1uTVKgLgHSn9xIDf3NZkXH61puiZmM3SK', 'QR-ADMIN-001', 'inactivo', 1, NULL, '2025-12-27 04:13:59', '2025-11-04 19:34:42', '2025-12-27 09:19:16');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `ventas`
--

CREATE TABLE `ventas` (
  `id` int(11) UNSIGNED NOT NULL,
  `sesion_caja_id` int(11) UNSIGNED NOT NULL COMMENT 'ID de la sesión de caja',
  `numero_factura` varchar(50) NOT NULL COMMENT 'Número único de factura',
  `usuario_id` int(11) UNSIGNED DEFAULT NULL COMMENT 'ID del usuario/cliente',
  `tipo` enum('productos','membresia','mixto') NOT NULL COMMENT 'Tipo de venta',
  `subtotal` decimal(10,2) NOT NULL COMMENT 'Subtotal de la venta',
  `descuento` decimal(10,2) DEFAULT 0.00 COMMENT 'Descuento aplicado',
  `total` decimal(10,2) NOT NULL COMMENT 'Total de la venta',
  `metodo_pago` enum('efectivo','tarjeta','transferencia','app','mixto') NOT NULL COMMENT 'Método de pago',
  `monto_efectivo` decimal(10,2) DEFAULT NULL COMMENT 'Monto pagado en efectivo (si aplica)',
  `monto_tarjeta` decimal(10,2) DEFAULT NULL COMMENT 'Monto pagado con tarjeta (si aplica)',
  `monto_transferencia` decimal(10,2) DEFAULT NULL COMMENT 'Monto pagado por transferencia (si aplica)',
  `monto_app` decimal(10,2) DEFAULT NULL COMMENT 'Monto pagado por app (si aplica)',
  `membresia_id` int(11) UNSIGNED DEFAULT NULL COMMENT 'ID de la membresía vendida (si aplica)',
  `fecha_venta` datetime NOT NULL COMMENT 'Fecha y hora de la venta',
  `vendedor_id` int(11) UNSIGNED NOT NULL COMMENT 'ID del usuario que realizó la venta',
  `observaciones` text DEFAULT NULL COMMENT 'Observaciones de la venta',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Ventas realizadas desde la caja';

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `venta_items`
--

CREATE TABLE `venta_items` (
  `id` int(11) UNSIGNED NOT NULL,
  `venta_id` int(11) UNSIGNED NOT NULL COMMENT 'ID de la venta',
  `producto_id` int(11) UNSIGNED NOT NULL COMMENT 'ID del producto',
  `cantidad` int(11) NOT NULL COMMENT 'Cantidad vendida',
  `precio_unitario` decimal(10,2) NOT NULL COMMENT 'Precio unitario al momento de la venta',
  `subtotal` decimal(10,2) NOT NULL COMMENT 'Subtotal (cantidad * precio_unitario)',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Items de productos en ventas';

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `asistencias`
--
ALTER TABLE `asistencias`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_asistencias_usuario` (`usuario_id`),
  ADD KEY `idx_asistencias_membresia` (`membresia_id`),
  ADD KEY `idx_asistencias_fecha` (`fecha_entrada`),
  ADD KEY `idx_asistencias_qr` (`codigo_qr`);

--
-- Indices de la tabla `checkin_live_buffer`
--
ALTER TABLE `checkin_live_buffer`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `clases`
--
ALTER TABLE `clases`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_clases_instructor` (`instructor_id`),
  ADD KEY `idx_clases_activo` (`activo`);

--
-- Indices de la tabla `clase_horarios`
--
ALTER TABLE `clase_horarios`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_clase_horarios_clase` (`clase_id`);

--
-- Indices de la tabla `clase_reservas`
--
ALTER TABLE `clase_reservas`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_clase_reservas_usuario` (`usuario_id`),
  ADD KEY `idx_clase_reservas_horario` (`clase_horario_id`),
  ADD KEY `idx_clase_reservas_fecha` (`fecha_clase`);

--
-- Indices de la tabla `configuracion`
--
ALTER TABLE `configuracion`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_configuracion_clave` (`clave`),
  ADD KEY `idx_configuracion_categoria` (`categoria`);

--
-- Indices de la tabla `ejercicios`
--
ALTER TABLE `ejercicios`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_ejercicios_categoria` (`categoria`),
  ADD KEY `idx_ejercicios_activo` (`activo`);

--
-- Indices de la tabla `landing_content`
--
ALTER TABLE `landing_content`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_landing_element` (`section`,`element_id`),
  ADD KEY `idx_section` (`section`),
  ADD KEY `updated_by` (`updated_by`);

--
-- Indices de la tabla `membresias`
--
ALTER TABLE `membresias`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_membresias_usuario` (`usuario_id`),
  ADD KEY `idx_membresias_plan` (`plan_id`),
  ADD KEY `idx_membresias_estado` (`estado`),
  ADD KEY `idx_membresias_fechas` (`fecha_inicio`,`fecha_fin`);

--
-- Indices de la tabla `notificaciones`
--
ALTER TABLE `notificaciones`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_notificaciones_usuario` (`usuario_id`),
  ADD KEY `idx_notificaciones_leida` (`leida`);

--
-- Indices de la tabla `pagos`
--
ALTER TABLE `pagos`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_pagos_membresia` (`membresia_id`),
  ADD KEY `idx_pagos_usuario` (`usuario_id`),
  ADD KEY `idx_pagos_estado` (`estado`),
  ADD KEY `idx_pagos_fecha` (`fecha_pago`);

--
-- Indices de la tabla `pedidos`
--
ALTER TABLE `pedidos`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_pedidos_numero` (`numero_pedido`),
  ADD KEY `idx_pedidos_usuario` (`usuario_id`),
  ADD KEY `idx_pedidos_estado` (`estado`);

--
-- Indices de la tabla `pedido_items`
--
ALTER TABLE `pedido_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_pedido_items_pedido` (`pedido_id`),
  ADD KEY `idx_pedido_items_producto` (`producto_id`);

--
-- Indices de la tabla `planes`
--
ALTER TABLE `planes`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_planes_activo` (`activo`);

--
-- Indices de la tabla `preferencias_usuario`
--
ALTER TABLE `preferencias_usuario`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_preferencias_usuario` (`usuario_id`);

--
-- Indices de la tabla `productos`
--
ALTER TABLE `productos`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_productos_categoria` (`categoria`),
  ADD KEY `idx_productos_activo` (`activo`);

--
-- Indices de la tabla `progreso_usuario`
--
ALTER TABLE `progreso_usuario`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_progreso_usuario` (`usuario_id`),
  ADD KEY `idx_progreso_fecha` (`fecha`),
  ADD KEY `fk_progreso_registrado_por` (`registrado_por`);

--
-- Indices de la tabla `push_notifications_config`
--
ALTER TABLE `push_notifications_config`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_push_notif_tipo` (`tipo`);

--
-- Indices de la tabla `roles`
--
ALTER TABLE `roles`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_roles_nombre` (`nombre`);

--
-- Indices de la tabla `rutinas`
--
ALTER TABLE `rutinas`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_rutinas_objetivo` (`objetivo`),
  ADD KEY `idx_rutinas_activo` (`activo`),
  ADD KEY `fk_rutinas_created_by` (`created_by`);

--
-- Indices de la tabla `rutinas_usuario`
--
ALTER TABLE `rutinas_usuario`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_rutinas_usuario_usuario` (`usuario_id`),
  ADD KEY `idx_rutinas_usuario_rutina` (`rutina_id`),
  ADD KEY `idx_rutinas_usuario_entrenador` (`entrenador_id`),
  ADD KEY `idx_rutinas_usuario_estado` (`estado`);

--
-- Indices de la tabla `rutina_ejercicios`
--
ALTER TABLE `rutina_ejercicios`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_rutina_ejercicios_rutina` (`rutina_id`),
  ADD KEY `idx_rutina_ejercicios_ejercicio` (`ejercicio_id`),
  ADD KEY `idx_rutina_ejercicios_dia` (`dia`);

--
-- Indices de la tabla `sesiones_caja`
--
ALTER TABLE `sesiones_caja`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_sesiones_estado` (`estado`),
  ADD KEY `idx_sesiones_fecha_apertura` (`fecha_apertura`),
  ADD KEY `idx_sesiones_abierta_por` (`abierta_por`),
  ADD KEY `idx_sesiones_cerrada_por` (`cerrada_por`);

--
-- Indices de la tabla `transacciones_financieras`
--
ALTER TABLE `transacciones_financieras`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_transacciones_tipo` (`tipo`),
  ADD KEY `idx_transacciones_categoria` (`categoria`),
  ADD KEY `idx_transacciones_fecha` (`fecha`),
  ADD KEY `idx_transacciones_usuario` (`usuario_id`),
  ADD KEY `idx_transacciones_membresia` (`membresia_id`),
  ADD KEY `idx_transacciones_producto` (`producto_id`),
  ADD KEY `idx_transacciones_registrado_por` (`registrado_por`);

--
-- Indices de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_usuarios_email` (`email`),
  ADD UNIQUE KEY `uk_usuarios_documento` (`documento`),
  ADD UNIQUE KEY `uk_usuarios_codigo_qr` (`codigo_qr`),
  ADD KEY `idx_usuarios_rol` (`rol_id`),
  ADD KEY `idx_usuarios_estado` (`estado`);

--
-- Indices de la tabla `ventas`
--
ALTER TABLE `ventas`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_ventas_numero_factura` (`numero_factura`),
  ADD KEY `idx_ventas_sesion_caja` (`sesion_caja_id`),
  ADD KEY `idx_ventas_usuario` (`usuario_id`),
  ADD KEY `idx_ventas_membresia` (`membresia_id`),
  ADD KEY `idx_ventas_fecha` (`fecha_venta`),
  ADD KEY `idx_ventas_vendedor` (`vendedor_id`);

--
-- Indices de la tabla `venta_items`
--
ALTER TABLE `venta_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_venta_items_venta` (`venta_id`),
  ADD KEY `idx_venta_items_producto` (`producto_id`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `asistencias`
--
ALTER TABLE `asistencias`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT de la tabla `clases`
--
ALTER TABLE `clases`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `clase_horarios`
--
ALTER TABLE `clase_horarios`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `clase_reservas`
--
ALTER TABLE `clase_reservas`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `configuracion`
--
ALTER TABLE `configuracion`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9920;

--
-- AUTO_INCREMENT de la tabla `ejercicios`
--
ALTER TABLE `ejercicios`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `landing_content`
--
ALTER TABLE `landing_content`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=22;

--
-- AUTO_INCREMENT de la tabla `membresias`
--
ALTER TABLE `membresias`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `notificaciones`
--
ALTER TABLE `notificaciones`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT de la tabla `pagos`
--
ALTER TABLE `pagos`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `pedidos`
--
ALTER TABLE `pedidos`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `pedido_items`
--
ALTER TABLE `pedido_items`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `planes`
--
ALTER TABLE `planes`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `preferencias_usuario`
--
ALTER TABLE `preferencias_usuario`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `productos`
--
ALTER TABLE `productos`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT de la tabla `progreso_usuario`
--
ALTER TABLE `progreso_usuario`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `push_notifications_config`
--
ALTER TABLE `push_notifications_config`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `roles`
--
ALTER TABLE `roles`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `rutinas`
--
ALTER TABLE `rutinas`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `rutinas_usuario`
--
ALTER TABLE `rutinas_usuario`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `rutina_ejercicios`
--
ALTER TABLE `rutina_ejercicios`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `sesiones_caja`
--
ALTER TABLE `sesiones_caja`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT de la tabla `transacciones_financieras`
--
ALTER TABLE `transacciones_financieras`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=43;

--
-- AUTO_INCREMENT de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `ventas`
--
ALTER TABLE `ventas`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=43;

--
-- AUTO_INCREMENT de la tabla `venta_items`
--
ALTER TABLE `venta_items`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=43;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `asistencias`
--
ALTER TABLE `asistencias`
  ADD CONSTRAINT `fk_asistencias_membresia` FOREIGN KEY (`membresia_id`) REFERENCES `membresias` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_asistencias_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON UPDATE CASCADE;

--
-- Filtros para la tabla `clases`
--
ALTER TABLE `clases`
  ADD CONSTRAINT `fk_clases_instructor` FOREIGN KEY (`instructor_id`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Filtros para la tabla `clase_horarios`
--
ALTER TABLE `clase_horarios`
  ADD CONSTRAINT `fk_clase_horarios_clase` FOREIGN KEY (`clase_id`) REFERENCES `clases` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `clase_reservas`
--
ALTER TABLE `clase_reservas`
  ADD CONSTRAINT `fk_clase_reservas_horario` FOREIGN KEY (`clase_horario_id`) REFERENCES `clase_horarios` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_clase_reservas_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON UPDATE CASCADE;

--
-- Filtros para la tabla `landing_content`
--
ALTER TABLE `landing_content`
  ADD CONSTRAINT `landing_content_ibfk_1` FOREIGN KEY (`updated_by`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL;

--
-- Filtros para la tabla `membresias`
--
ALTER TABLE `membresias`
  ADD CONSTRAINT `fk_membresias_plan` FOREIGN KEY (`plan_id`) REFERENCES `planes` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_membresias_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON UPDATE CASCADE;

--
-- Filtros para la tabla `notificaciones`
--
ALTER TABLE `notificaciones`
  ADD CONSTRAINT `fk_notificaciones_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `pagos`
--
ALTER TABLE `pagos`
  ADD CONSTRAINT `fk_pagos_membresia` FOREIGN KEY (`membresia_id`) REFERENCES `membresias` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_pagos_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON UPDATE CASCADE;

--
-- Filtros para la tabla `pedidos`
--
ALTER TABLE `pedidos`
  ADD CONSTRAINT `fk_pedidos_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON UPDATE CASCADE;

--
-- Filtros para la tabla `pedido_items`
--
ALTER TABLE `pedido_items`
  ADD CONSTRAINT `fk_pedido_items_pedido` FOREIGN KEY (`pedido_id`) REFERENCES `pedidos` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_pedido_items_producto` FOREIGN KEY (`producto_id`) REFERENCES `productos` (`id`) ON UPDATE CASCADE;

--
-- Filtros para la tabla `preferencias_usuario`
--
ALTER TABLE `preferencias_usuario`
  ADD CONSTRAINT `fk_preferencias_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `progreso_usuario`
--
ALTER TABLE `progreso_usuario`
  ADD CONSTRAINT `fk_progreso_registrado_por` FOREIGN KEY (`registrado_por`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_progreso_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `rutinas`
--
ALTER TABLE `rutinas`
  ADD CONSTRAINT `fk_rutinas_created_by` FOREIGN KEY (`created_by`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Filtros para la tabla `rutinas_usuario`
--
ALTER TABLE `rutinas_usuario`
  ADD CONSTRAINT `fk_rutinas_usuario_entrenador` FOREIGN KEY (`entrenador_id`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_rutinas_usuario_rutina` FOREIGN KEY (`rutina_id`) REFERENCES `rutinas` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_rutinas_usuario_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON UPDATE CASCADE;

--
-- Filtros para la tabla `rutina_ejercicios`
--
ALTER TABLE `rutina_ejercicios`
  ADD CONSTRAINT `fk_rutina_ejercicios_ejercicio` FOREIGN KEY (`ejercicio_id`) REFERENCES `ejercicios` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_rutina_ejercicios_rutina` FOREIGN KEY (`rutina_id`) REFERENCES `rutinas` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `sesiones_caja`
--
ALTER TABLE `sesiones_caja`
  ADD CONSTRAINT `fk_sesiones_abierta_por` FOREIGN KEY (`abierta_por`) REFERENCES `usuarios` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_sesiones_cerrada_por` FOREIGN KEY (`cerrada_por`) REFERENCES `usuarios` (`id`) ON UPDATE CASCADE;

--
-- Filtros para la tabla `transacciones_financieras`
--
ALTER TABLE `transacciones_financieras`
  ADD CONSTRAINT `fk_transacciones_membresia` FOREIGN KEY (`membresia_id`) REFERENCES `membresias` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_transacciones_producto` FOREIGN KEY (`producto_id`) REFERENCES `productos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_transacciones_registrado_por` FOREIGN KEY (`registrado_por`) REFERENCES `usuarios` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_transacciones_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Filtros para la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD CONSTRAINT `fk_usuarios_rol` FOREIGN KEY (`rol_id`) REFERENCES `roles` (`id`) ON UPDATE CASCADE;

--
-- Filtros para la tabla `ventas`
--
ALTER TABLE `ventas`
  ADD CONSTRAINT `fk_ventas_membresia` FOREIGN KEY (`membresia_id`) REFERENCES `membresias` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_ventas_sesion_caja` FOREIGN KEY (`sesion_caja_id`) REFERENCES `sesiones_caja` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_ventas_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_ventas_vendedor` FOREIGN KEY (`vendedor_id`) REFERENCES `usuarios` (`id`) ON UPDATE CASCADE;

--
-- Filtros para la tabla `venta_items`
--
ALTER TABLE `venta_items`
  ADD CONSTRAINT `fk_venta_items_producto` FOREIGN KEY (`producto_id`) REFERENCES `productos` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_venta_items_venta` FOREIGN KEY (`venta_id`) REFERENCES `ventas` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
