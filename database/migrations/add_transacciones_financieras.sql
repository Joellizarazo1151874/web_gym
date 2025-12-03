-- =====================================================
-- TABLA: transacciones_financieras
-- Descripción: Registro de todas las entradas y salidas de dinero del gimnasio
-- =====================================================
CREATE TABLE IF NOT EXISTS `transacciones_financieras` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `tipo` ENUM('ingreso', 'egreso') NOT NULL COMMENT 'Tipo de transacción: ingreso o egreso',
  `categoria` VARCHAR(100) NOT NULL COMMENT 'Categoría: membresia, producto, gasto_operativo, gasto_equipamiento, salario, otro',
  `concepto` VARCHAR(255) NOT NULL COMMENT 'Concepto o descripción de la transacción',
  `monto` DECIMAL(10,2) NOT NULL COMMENT 'Monto de la transacción',
  `metodo_pago` ENUM('efectivo', 'tarjeta', 'transferencia', 'app', 'otro') DEFAULT 'efectivo' COMMENT 'Método de pago',
  `referencia` VARCHAR(100) DEFAULT NULL COMMENT 'Número de referencia o comprobante',
  `usuario_id` INT(11) UNSIGNED DEFAULT NULL COMMENT 'ID del usuario relacionado (si aplica)',
  `membresia_id` INT(11) UNSIGNED DEFAULT NULL COMMENT 'ID de la membresía relacionada (si aplica)',
  `producto_id` INT(11) UNSIGNED DEFAULT NULL COMMENT 'ID del producto relacionado (si aplica)',
  `fecha` DATETIME NOT NULL COMMENT 'Fecha y hora de la transacción',
  `observaciones` TEXT DEFAULT NULL COMMENT 'Observaciones adicionales',
  `registrado_por` INT(11) UNSIGNED NOT NULL COMMENT 'ID del usuario que registró la transacción',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_transacciones_tipo` (`tipo`),
  KEY `idx_transacciones_categoria` (`categoria`),
  KEY `idx_transacciones_fecha` (`fecha`),
  KEY `idx_transacciones_usuario` (`usuario_id`),
  KEY `idx_transacciones_membresia` (`membresia_id`),
  KEY `idx_transacciones_producto` (`producto_id`),
  KEY `idx_transacciones_registrado_por` (`registrado_por`),
  CONSTRAINT `fk_transacciones_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_transacciones_membresia` FOREIGN KEY (`membresia_id`) REFERENCES `membresias` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_transacciones_producto` FOREIGN KEY (`producto_id`) REFERENCES `productos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_transacciones_registrado_por` FOREIGN KEY (`registrado_por`) REFERENCES `usuarios` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Transacciones financieras del gimnasio';


