-- Tabla para almacenar tokens FCM de dispositivos móviles
CREATE TABLE IF NOT EXISTS `fcm_tokens` (
  `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `usuario_id` int(11) UNSIGNED NOT NULL COMMENT 'ID del usuario propietario del dispositivo',
  `token` varchar(255) NOT NULL COMMENT 'Token FCM del dispositivo',
  `plataforma` enum('android','ios') DEFAULT 'android' COMMENT 'Plataforma del dispositivo',
  `activo` tinyint(1) DEFAULT 1 COMMENT '1=activo, 0=inactivo',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_token` (`token`),
  KEY `idx_usuario_id` (`usuario_id`),
  KEY `idx_activo` (`activo`),
  CONSTRAINT `fk_fcm_tokens_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Tokens FCM para notificaciones push';
