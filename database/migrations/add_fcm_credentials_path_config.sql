-- Insertar configuración de ruta de credenciales FCM si no existe
INSERT INTO `configuracion` (`clave`, `valor`, `descripcion`, `tipo`, `created_at`, `updated_at`)
SELECT
    'fcm_credentials_path',
    '/var/www/html/config/firebase-credentials.json',
    'Ruta al archivo JSON de credenciales de Firebase para FCM API V1',
    'string',
    NOW(),
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM `configuracion` WHERE `clave` = 'fcm_credentials_path'
);
