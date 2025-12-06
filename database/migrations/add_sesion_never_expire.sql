-- =====================================================
-- Agregar configuración: Sesión nunca expira
-- Descripción: Permite configurar que la sesión nunca se cierre automáticamente
-- =====================================================

-- Insertar o actualizar la configuración
INSERT INTO `configuracion` (`clave`, `valor`, `tipo`, `categoria`, `descripcion`) 
VALUES ('sesion_never_expire', '0', 'boolean', 'seguridad', 'Nunca cerrar sesión automáticamente (solo cierre manual)')
ON DUPLICATE KEY UPDATE 
    `valor` = '0',
    `tipo` = 'boolean',
    `categoria` = 'seguridad',
    `descripcion` = 'Nunca cerrar sesión automáticamente (solo cierre manual)',
    `updated_at` = CURRENT_TIMESTAMP;

