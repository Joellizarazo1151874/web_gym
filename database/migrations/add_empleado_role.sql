-- =====================================================
-- MIGRACIÓN: Agregar rol "empleado"
-- Descripción: Agrega el rol de empleado al sistema
-- Fecha: 2025
-- =====================================================

USE `ftgym`;

-- Insertar rol empleado
INSERT INTO `roles` (`nombre`, `descripcion`, `activo`) 
VALUES ('empleado', 'Empleado que puede usar la caja y gestionar ventas', 1)
ON DUPLICATE KEY UPDATE 
    `descripcion` = 'Empleado que puede usar la caja y gestionar ventas',
    `activo` = 1;

-- Verificar que se insertó correctamente
SELECT * FROM `roles` WHERE `nombre` = 'empleado';

