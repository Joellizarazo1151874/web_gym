-- =====================================================
-- TABLA: sesiones_caja
-- Descripción: Control de apertura y cierre de caja
-- =====================================================
CREATE TABLE IF NOT EXISTS `sesiones_caja` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `fecha_apertura` DATETIME NOT NULL COMMENT 'Fecha y hora de apertura de caja',
  `fecha_cierre` DATETIME DEFAULT NULL COMMENT 'Fecha y hora de cierre de caja',
  `monto_apertura` DECIMAL(10,2) NOT NULL COMMENT 'Monto con el que se abrió la caja',
  `monto_cierre` DECIMAL(10,2) DEFAULT NULL COMMENT 'Monto con el que se cerró la caja',
  `monto_esperado` DECIMAL(10,2) DEFAULT NULL COMMENT 'Monto esperado según transacciones',
  `diferencia` DECIMAL(10,2) DEFAULT NULL COMMENT 'Diferencia entre monto_cierre y monto_esperado',
  `estado` ENUM('abierta', 'cerrada') DEFAULT 'abierta' COMMENT 'Estado de la sesión',
  `abierta_por` INT(11) UNSIGNED NOT NULL COMMENT 'ID del usuario que abrió la caja',
  `cerrada_por` INT(11) UNSIGNED DEFAULT NULL COMMENT 'ID del usuario que cerró la caja',
  `observaciones_apertura` TEXT DEFAULT NULL COMMENT 'Observaciones al abrir',
  `observaciones_cierre` TEXT DEFAULT NULL COMMENT 'Observaciones al cerrar',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_sesiones_estado` (`estado`),
  KEY `idx_sesiones_fecha_apertura` (`fecha_apertura`),
  KEY `idx_sesiones_abierta_por` (`abierta_por`),
  KEY `idx_sesiones_cerrada_por` (`cerrada_por`),
  CONSTRAINT `fk_sesiones_abierta_por` FOREIGN KEY (`abierta_por`) REFERENCES `usuarios` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_sesiones_cerrada_por` FOREIGN KEY (`cerrada_por`) REFERENCES `usuarios` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Sesiones de apertura y cierre de caja';

-- =====================================================
-- TABLA: ventas
-- Descripción: Ventas realizadas desde la caja
-- =====================================================
CREATE TABLE IF NOT EXISTS `ventas` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `sesion_caja_id` INT(11) UNSIGNED NOT NULL COMMENT 'ID de la sesión de caja',
  `numero_factura` VARCHAR(50) NOT NULL COMMENT 'Número único de factura',
  `usuario_id` INT(11) UNSIGNED DEFAULT NULL COMMENT 'ID del usuario/cliente',
  `tipo` ENUM('productos', 'membresia', 'mixto') NOT NULL COMMENT 'Tipo de venta',
  `subtotal` DECIMAL(10,2) NOT NULL COMMENT 'Subtotal de la venta',
  `descuento` DECIMAL(10,2) DEFAULT 0 COMMENT 'Descuento aplicado',
  `total` DECIMAL(10,2) NOT NULL COMMENT 'Total de la venta',
  `metodo_pago` ENUM('efectivo', 'tarjeta', 'transferencia', 'app', 'mixto') NOT NULL COMMENT 'Método de pago',
  `monto_efectivo` DECIMAL(10,2) DEFAULT NULL COMMENT 'Monto pagado en efectivo (si aplica)',
  `monto_tarjeta` DECIMAL(10,2) DEFAULT NULL COMMENT 'Monto pagado con tarjeta (si aplica)',
  `monto_transferencia` DECIMAL(10,2) DEFAULT NULL COMMENT 'Monto pagado por transferencia (si aplica)',
  `monto_app` DECIMAL(10,2) DEFAULT NULL COMMENT 'Monto pagado por app (si aplica)',
  `membresia_id` INT(11) UNSIGNED DEFAULT NULL COMMENT 'ID de la membresía vendida (si aplica)',
  `fecha_venta` DATETIME NOT NULL COMMENT 'Fecha y hora de la venta',
  `vendedor_id` INT(11) UNSIGNED NOT NULL COMMENT 'ID del usuario que realizó la venta',
  `observaciones` TEXT DEFAULT NULL COMMENT 'Observaciones de la venta',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_ventas_numero_factura` (`numero_factura`),
  KEY `idx_ventas_sesion_caja` (`sesion_caja_id`),
  KEY `idx_ventas_usuario` (`usuario_id`),
  KEY `idx_ventas_membresia` (`membresia_id`),
  KEY `idx_ventas_fecha` (`fecha_venta`),
  KEY `idx_ventas_vendedor` (`vendedor_id`),
  CONSTRAINT `fk_ventas_sesion_caja` FOREIGN KEY (`sesion_caja_id`) REFERENCES `sesiones_caja` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_membresia` FOREIGN KEY (`membresia_id`) REFERENCES `membresias` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_vendedor` FOREIGN KEY (`vendedor_id`) REFERENCES `usuarios` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Ventas realizadas desde la caja';

-- =====================================================
-- TABLA: venta_items
-- Descripción: Items de productos en cada venta
-- =====================================================
CREATE TABLE IF NOT EXISTS `venta_items` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `venta_id` INT(11) UNSIGNED NOT NULL COMMENT 'ID de la venta',
  `producto_id` INT(11) UNSIGNED NOT NULL COMMENT 'ID del producto',
  `cantidad` INT(11) NOT NULL COMMENT 'Cantidad vendida',
  `precio_unitario` DECIMAL(10,2) NOT NULL COMMENT 'Precio unitario al momento de la venta',
  `subtotal` DECIMAL(10,2) NOT NULL COMMENT 'Subtotal (cantidad * precio_unitario)',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_venta_items_venta` (`venta_id`),
  KEY `idx_venta_items_producto` (`producto_id`),
  CONSTRAINT `fk_venta_items_venta` FOREIGN KEY (`venta_id`) REFERENCES `ventas` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_venta_items_producto` FOREIGN KEY (`producto_id`) REFERENCES `productos` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Items de productos en ventas';






