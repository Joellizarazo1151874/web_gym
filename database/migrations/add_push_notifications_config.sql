-- =====================================================
-- TABLA: push_notifications_config
-- Descripción: Configuración de notificaciones push automáticas
-- =====================================================
CREATE TABLE IF NOT EXISTS `push_notifications_config` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `tipo` VARCHAR(50) NOT NULL COMMENT 'Tipo de notificación (cumpleanos, membresia_vencimiento, inactividad)',
  `activa` TINYINT(1) DEFAULT 1 COMMENT '1=activa, 0=inactiva',
  `titulo` VARCHAR(200) NOT NULL COMMENT 'Título de la notificación',
  `mensaje` TEXT NOT NULL COMMENT 'Mensaje de la notificación (puede usar variables como {nombre}, {dias}, etc.)',
  `dias_antes` INT(11) DEFAULT 0 COMMENT 'Días antes del evento para enviar (0 = el mismo día)',
  `dias_inactividad` INT(11) DEFAULT 7 COMMENT 'Días de inactividad para notificar (solo para tipo inactividad)',
  `hora_envio` TIME DEFAULT '09:00:00' COMMENT 'Hora del día para enviar la notificación',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_push_notif_tipo` (`tipo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Configuración de notificaciones push automáticas';

-- Insertar configuraciones por defecto
INSERT INTO `push_notifications_config` (`tipo`, `activa`, `titulo`, `mensaje`, `dias_antes`, `dias_inactividad`, `hora_envio`) VALUES
('cumpleanos', 1, '¡Feliz Cumpleaños! 🎉', '¡Feliz cumpleaños {nombre}! Esperamos verte hoy en el gimnasio. Te deseamos un día lleno de energía y éxito. ¡Vamos a entrenar! 💪', 0, NULL, '09:00:00'),
('membresia_vencimiento', 1, 'Tu membresía está por vencer ⏰', 'Hola {nombre}, tu membresía vence en {dias} día(s). Renueva ahora para no perder tus beneficios. ¡Te esperamos!', 3, NULL, '10:00:00'),
('membresia_vencida', 1, 'Tu membresía ha vencido', 'Hola {nombre}, tu membresía ha vencido. Renueva ahora para continuar disfrutando de todos nuestros servicios.', 0, NULL, '10:00:00'),
('inactividad', 1, 'Te extrañamos en el gimnasio 💪', 'Hola {nombre}, hace {dias} día(s) que no te vemos en el gimnasio. ¡Vuelve y continúa con tu rutina! Te esperamos.', 0, 7, '11:00:00');

