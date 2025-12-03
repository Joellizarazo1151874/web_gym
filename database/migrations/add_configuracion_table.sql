-- =====================================================
-- TABLA: configuracion
-- Descripción: Almacena la configuración del sistema
-- =====================================================
CREATE TABLE IF NOT EXISTS `configuracion` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `clave` VARCHAR(100) NOT NULL COMMENT 'Clave única de la configuración',
  `valor` TEXT DEFAULT NULL COMMENT 'Valor de la configuración (puede ser JSON para arrays)',
  `tipo` ENUM('string', 'number', 'boolean', 'json', 'time') DEFAULT 'string' COMMENT 'Tipo de dato',
  `categoria` VARCHAR(50) DEFAULT 'general' COMMENT 'Categoría de la configuración',
  `descripcion` TEXT DEFAULT NULL COMMENT 'Descripción de la configuración',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_configuracion_clave` (`clave`),
  KEY `idx_configuracion_categoria` (`categoria`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Configuración del sistema';

-- Insertar valores por defecto
INSERT INTO `configuracion` (`clave`, `valor`, `tipo`, `categoria`, `descripcion`) VALUES
('gimnasio_nombre', 'Functional Training Gym', 'string', 'general', 'Nombre del gimnasio'),
('gimnasio_direccion', 'Calle Principal 123', 'string', 'general', 'Dirección del gimnasio'),
('gimnasio_ciudad', 'Bogotá', 'string', 'general', 'Ciudad del gimnasio'),
('gimnasio_telefono', '+57 1 234 5678', 'string', 'general', 'Teléfono de contacto'),
('gimnasio_email', 'info@ftgym.com', 'string', 'general', 'Email de contacto'),
('gimnasio_web', 'www.ftgym.com', 'string', 'general', 'Sitio web'),
('horario_apertura', '06:00', 'time', 'horarios', 'Hora de apertura'),
('horario_cierre', '22:00', 'time', 'horarios', 'Hora de cierre'),
('dias_semana', '["Lunes","Martes","Miércoles","Jueves","Viernes","Sábado"]', 'json', 'horarios', 'Días de la semana que está abierto'),
('notificaciones_email', '1', 'boolean', 'notificaciones', 'Habilitar notificaciones por email'),
('notificaciones_sms', '0', 'boolean', 'notificaciones', 'Habilitar notificaciones por SMS'),
('notificaciones_push', '1', 'boolean', 'notificaciones', 'Habilitar notificaciones push'),
('sesion_timeout', '30', 'number', 'seguridad', 'Timeout de sesión en minutos'),
('requiere_verificacion_email', '1', 'boolean', 'seguridad', 'Requerir verificación de email'),
('metodos_pago', '["efectivo","tarjeta","transferencia"]', 'json', 'pagos', 'Métodos de pago habilitados'),
('moneda', 'COP', 'string', 'pagos', 'Moneda del sistema'),
('iva', '19', 'number', 'pagos', 'Porcentaje de IVA'),
('backup_automatico', '1', 'boolean', 'sistema', 'Habilitar backup automático'),
('frecuencia_backup', 'diario', 'string', 'sistema', 'Frecuencia de backup'),
('mantener_logs', '1', 'boolean', 'sistema', 'Mantener logs del sistema'),
('dias_logs', '30', 'number', 'sistema', 'Días de retención de logs')
ON DUPLICATE KEY UPDATE `valor` = VALUES(`valor`);

