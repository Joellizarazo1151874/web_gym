-- =====================================================
-- TABLA: landing_content
-- Descripción: Almacena contenidos editables del landing page
-- =====================================================
CREATE TABLE IF NOT EXISTS `landing_content` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `section` VARCHAR(100) NOT NULL COMMENT 'Sección del landing (hero, about, classes, etc)',
  `element_id` VARCHAR(100) NOT NULL COMMENT 'ID único del elemento editable',
  `content_type` ENUM('text', 'image', 'html') DEFAULT 'text' COMMENT 'Tipo de contenido',
  `content` TEXT DEFAULT NULL COMMENT 'Contenido del elemento (texto o HTML)',
  `image_path` VARCHAR(255) DEFAULT NULL COMMENT 'Ruta de la imagen si es tipo image',
  `alt_text` VARCHAR(255) DEFAULT NULL COMMENT 'Texto alternativo para imágenes',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `updated_by` INT(11) UNSIGNED DEFAULT NULL COMMENT 'ID del usuario que hizo la última actualización',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_landing_element` (`section`, `element_id`),
  KEY `idx_section` (`section`),
  FOREIGN KEY (`updated_by`) REFERENCES `usuarios`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Contenidos editables del landing page';

