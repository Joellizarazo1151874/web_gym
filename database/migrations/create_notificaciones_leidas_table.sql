-- Tabla para rastrear qué notificaciones ha leído cada usuario
-- Esto permite que cada usuario tenga su propio estado de "leída" para notificaciones globales
CREATE TABLE IF NOT EXISTS notificaciones_leidas (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    notificacion_id INT UNSIGNED NOT NULL,
    usuario_id INT UNSIGNED NOT NULL,
    fecha_leida TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_notificacion_usuario (notificacion_id, usuario_id),
    FOREIGN KEY (notificacion_id) REFERENCES notificaciones(id) ON DELETE CASCADE,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    INDEX idx_usuario_id (usuario_id),
    INDEX idx_notificacion_id (notificacion_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
