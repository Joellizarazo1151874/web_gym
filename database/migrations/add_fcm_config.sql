-- Insertar configuración de FCM Server Key si no existe
INSERT INTO `configuracion` (`clave`, `valor`, `descripcion`, `tipo`, `created_at`, `updated_at`)
SELECT
    'fcm_server_key',
    '',
    'Clave del servidor de Firebase Cloud Messaging (FCM) para enviar notificaciones push',
    'string',
    NOW(),
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM `configuracion` WHERE `clave` = 'fcm_server_key'
);
