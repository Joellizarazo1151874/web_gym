-- =====================================================
-- CONSULTAS ÚTILES - Sistema de Gestión de Gimnasio
-- Functional Training
-- =====================================================

-- =====================================================
-- CONSULTAS DE USUARIOS
-- =====================================================

-- Listar todos los usuarios activos con su rol
SELECT 
    u.id,
    u.documento,
    u.nombre,
    u.apellido,
    u.email,
    u.telefono,
    u.estado,
    r.nombre as rol,
    u.created_at
FROM usuarios u
INNER JOIN roles r ON u.rol_id = r.id
WHERE u.estado = 'activo'
ORDER BY u.apellido, u.nombre;

-- Usuarios con membresía activa
SELECT 
    u.id,
    u.documento,
    CONCAT(u.nombre, ' ', u.apellido) as nombre_completo,
    u.email,
    u.codigo_qr,
    p.nombre as plan,
    m.fecha_inicio,
    m.fecha_fin,
    DATEDIFF(m.fecha_fin, CURDATE()) as dias_restantes,
    m.estado as estado_membresia
FROM usuarios u
INNER JOIN membresias m ON u.id = m.usuario_id
INNER JOIN planes p ON m.plan_id = p.id
WHERE m.estado = 'activa'
  AND m.fecha_fin >= CURDATE()
ORDER BY m.fecha_fin ASC;

-- Usuarios con membresía vencida
SELECT 
    u.id,
    CONCAT(u.nombre, ' ', u.apellido) as nombre_completo,
    u.email,
    u.telefono,
    p.nombre as ultimo_plan,
    m.fecha_fin,
    DATEDIFF(CURDATE(), m.fecha_fin) as dias_vencido
FROM usuarios u
INNER JOIN membresias m ON u.id = m.usuario_id
INNER JOIN planes p ON m.plan_id = p.id
WHERE m.estado = 'activa'
  AND m.fecha_fin < CURDATE()
ORDER BY m.fecha_fin DESC;

-- Buscar usuario por código QR
SELECT 
    u.*,
    r.nombre as rol,
    m.estado as membresia_estado,
    m.fecha_fin
FROM usuarios u
INNER JOIN roles r ON u.rol_id = r.id
LEFT JOIN membresias m ON u.id = m.usuario_id AND m.estado = 'activa'
WHERE u.codigo_qr = 'QR-ADMIN-001';

-- =====================================================
-- CONSULTAS DE MEMBRESÍAS
-- =====================================================

-- Membresías que vencen en los próximos 7 días
SELECT 
    u.id,
    CONCAT(u.nombre, ' ', u.apellido) as nombre_completo,
    u.email,
    u.telefono,
    p.nombre as plan,
    m.fecha_inicio,
    m.fecha_fin,
    DATEDIFF(m.fecha_fin, CURDATE()) as dias_restantes
FROM membresias m
INNER JOIN usuarios u ON m.usuario_id = u.id
INNER JOIN planes p ON m.plan_id = p.id
WHERE m.estado = 'activa'
  AND m.fecha_fin BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY)
ORDER BY m.fecha_fin ASC;

-- Membresías activas por tipo de plan
SELECT 
    p.nombre as plan,
    COUNT(*) as total_membresias,
    SUM(CASE WHEN m.fecha_fin >= CURDATE() THEN 1 ELSE 0 END) as activas,
    SUM(CASE WHEN m.fecha_fin < CURDATE() THEN 1 ELSE 0 END) as vencidas
FROM membresias m
INNER JOIN planes p ON m.plan_id = p.id
WHERE m.estado = 'activa'
GROUP BY p.id, p.nombre;

-- Historial de membresías de un usuario
SELECT 
    p.nombre as plan,
    m.fecha_inicio,
    m.fecha_fin,
    m.precio_pagado,
    m.descuento_app,
    m.estado,
    m.created_at
FROM membresias m
INNER JOIN planes p ON m.plan_id = p.id
WHERE m.usuario_id = 1
ORDER BY m.created_at DESC;

-- =====================================================
-- CONSULTAS DE ASISTENCIAS
-- =====================================================

-- Asistencias del día actual
SELECT 
    u.id,
    CONCAT(u.nombre, ' ', u.apellido) as nombre_completo,
    a.fecha_entrada,
    a.fecha_salida,
    TIMESTAMPDIFF(MINUTE, a.fecha_entrada, COALESCE(a.fecha_salida, NOW())) as minutos_dentro,
    a.tipo_acceso
FROM asistencias a
INNER JOIN usuarios u ON a.usuario_id = u.id
WHERE DATE(a.fecha_entrada) = CURDATE()
ORDER BY a.fecha_entrada DESC;

-- Usuarios actualmente en el gimnasio (sin salida registrada)
SELECT 
    u.id,
    CONCAT(u.nombre, ' ', u.apellido) as nombre_completo,
    u.codigo_qr,
    a.fecha_entrada,
    TIMESTAMPDIFF(MINUTE, a.fecha_entrada, NOW()) as minutos_dentro
FROM asistencias a
INNER JOIN usuarios u ON a.usuario_id = u.id
WHERE DATE(a.fecha_entrada) = CURDATE()
  AND a.fecha_salida IS NULL
ORDER BY a.fecha_entrada DESC;

-- Estadísticas de asistencia por usuario (últimos 30 días)
SELECT 
    u.id,
    CONCAT(u.nombre, ' ', u.apellido) as nombre_completo,
    COUNT(*) as total_asistencias,
    AVG(TIMESTAMPDIFF(MINUTE, a.fecha_entrada, COALESCE(a.fecha_salida, a.fecha_entrada))) as promedio_minutos
FROM asistencias a
INNER JOIN usuarios u ON a.usuario_id = u.id
WHERE a.fecha_entrada >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY u.id, u.nombre, u.apellido
ORDER BY total_asistencias DESC;

-- =====================================================
-- CONSULTAS DE PAGOS
-- =====================================================

-- Pagos del día actual
SELECT 
    p.id,
    CONCAT(u.nombre, ' ', u.apellido) as usuario,
    p.tipo,
    p.monto,
    p.metodo_pago,
    p.estado,
    p.fecha_pago
FROM pagos p
INNER JOIN usuarios u ON p.usuario_id = u.id
WHERE DATE(p.created_at) = CURDATE()
ORDER BY p.created_at DESC;

-- Resumen de pagos por mes
SELECT 
    DATE_FORMAT(fecha_pago, '%Y-%m') as mes,
    COUNT(*) as total_pagos,
    SUM(CASE WHEN estado = 'completado' THEN monto ELSE 0 END) as total_cobrado,
    SUM(CASE WHEN estado = 'pendiente' THEN monto ELSE 0 END) as total_pendiente
FROM pagos
WHERE fecha_pago IS NOT NULL
GROUP BY DATE_FORMAT(fecha_pago, '%Y-%m')
ORDER BY mes DESC;

-- Pagos por método de pago
SELECT 
    metodo_pago,
    COUNT(*) as cantidad,
    SUM(monto) as total,
    AVG(monto) as promedio
FROM pagos
WHERE estado = 'completado'
GROUP BY metodo_pago;

-- =====================================================
-- CONSULTAS DE RUTINAS
-- =====================================================

-- Rutinas asignadas a usuarios activos
SELECT 
    u.id as usuario_id,
    CONCAT(u.nombre, ' ', u.apellido) as usuario,
    r.nombre as rutina,
    r.objetivo,
    ru.fecha_inicio,
    ru.fecha_fin,
    ru.estado,
    CONCAT(e.nombre, ' ', e.apellido) as entrenador
FROM rutinas_usuario ru
INNER JOIN usuarios u ON ru.usuario_id = u.id
INNER JOIN rutinas r ON ru.rutina_id = r.id
LEFT JOIN usuarios e ON ru.entrenador_id = e.id
WHERE ru.estado = 'activa'
ORDER BY ru.fecha_inicio DESC;

-- Ejercicios de una rutina específica
SELECT 
    re.dia,
    re.orden,
    e.nombre as ejercicio,
    e.categoria,
    e.grupo_muscular,
    re.series,
    re.repeticiones,
    re.peso,
    re.descanso,
    re.notas
FROM rutina_ejercicios re
INNER JOIN ejercicios e ON re.ejercicio_id = e.id
WHERE re.rutina_id = 1
ORDER BY re.dia, re.orden;

-- =====================================================
-- CONSULTAS DE PRODUCTOS
-- =====================================================

-- Productos con stock bajo (menos de 10 unidades)
SELECT 
    id,
    nombre,
    categoria,
    precio,
    stock
FROM productos
WHERE activo = 1
  AND stock < 10
ORDER BY stock ASC;

-- Productos más vendidos
SELECT 
    p.id,
    p.nombre,
    p.categoria,
    SUM(pi.cantidad) as total_vendido,
    SUM(pi.subtotal) as ingresos_totales
FROM productos p
INNER JOIN pedido_items pi ON p.id = pi.producto_id
INNER JOIN pedidos pe ON pi.pedido_id = pe.id
WHERE pe.estado IN ('confirmado', 'entregado')
GROUP BY p.id, p.nombre, p.categoria
ORDER BY total_vendido DESC
LIMIT 10;

-- =====================================================
-- CONSULTAS DE PEDIDOS
-- =====================================================

-- Pedidos pendientes
SELECT 
    pe.id,
    pe.numero_pedido,
    CONCAT(u.nombre, ' ', u.apellido) as usuario,
    pe.total,
    pe.metodo_pago,
    pe.estado,
    pe.fecha_pedido
FROM pedidos pe
INNER JOIN usuarios u ON pe.usuario_id = u.id
WHERE pe.estado IN ('pendiente', 'confirmado', 'en_preparacion')
ORDER BY pe.fecha_pedido ASC;

-- Detalle de un pedido
SELECT 
    p.nombre as producto,
    pi.cantidad,
    pi.precio_unitario,
    pi.subtotal
FROM pedido_items pi
INNER JOIN productos p ON pi.producto_id = p.id
WHERE pi.pedido_id = 1;

-- =====================================================
-- CONSULTAS DE CLASES
-- =====================================================

-- Horarios de clases para hoy
SELECT 
    c.nombre as clase,
    ch.hora_inicio,
    ch.hora_fin,
    CONCAT(u.nombre, ' ', u.apellido) as instructor,
    c.capacidad_maxima,
    COUNT(cr.id) as reservas_actuales,
    (c.capacidad_maxima - COUNT(cr.id)) as cupos_disponibles
FROM clase_horarios ch
INNER JOIN clases c ON ch.clase_id = c.id
LEFT JOIN usuarios u ON c.instructor_id = u.id
LEFT JOIN clase_reservas cr ON ch.id = cr.clase_horario_id 
    AND cr.fecha_clase = CURDATE() 
    AND cr.estado IN ('reservada', 'confirmada')
WHERE ch.dia_semana = DAYOFWEEK(CURDATE())
  AND ch.activo = 1
  AND c.activo = 1
GROUP BY ch.id, c.nombre, ch.hora_inicio, ch.hora_fin, u.nombre, u.apellido, c.capacidad_maxima
ORDER BY ch.hora_inicio;

-- =====================================================
-- CONSULTAS DE PROGRESO
-- =====================================================

-- Último registro de progreso de un usuario
SELECT 
    fecha,
    peso,
    altura,
    imc,
    grasa_corporal,
    musculo,
    medidas_pecho,
    medidas_cintura,
    medidas_cadera
FROM progreso_usuario
WHERE usuario_id = 1
ORDER BY fecha DESC
LIMIT 1;

-- Evolución de peso de un usuario
SELECT 
    fecha,
    peso,
    LAG(peso) OVER (ORDER BY fecha) as peso_anterior,
    peso - LAG(peso) OVER (ORDER BY fecha) as diferencia
FROM progreso_usuario
WHERE usuario_id = 1
ORDER BY fecha ASC;

-- =====================================================
-- CONSULTAS DE NOTIFICACIONES
-- =====================================================

-- Notificaciones no leídas de un usuario
SELECT 
    id,
    titulo,
    mensaje,
    tipo,
    fecha,
    DATEDIFF(NOW(), fecha) as dias_atras
FROM notificaciones
WHERE usuario_id = 1
  AND leida = 0
ORDER BY fecha DESC;

-- =====================================================
-- CONSULTAS DE REPORTES
-- =====================================================

-- Resumen general del gimnasio (hoy)
SELECT 
    (SELECT COUNT(*) FROM usuarios WHERE estado = 'activo') as usuarios_activos,
    (SELECT COUNT(*) FROM membresias WHERE estado = 'activa' AND fecha_fin >= CURDATE()) as membresias_activas,
    (SELECT COUNT(*) FROM asistencias WHERE DATE(fecha_entrada) = CURDATE()) as asistencias_hoy,
    (SELECT COUNT(*) FROM asistencias WHERE DATE(fecha_entrada) = CURDATE() AND fecha_salida IS NULL) as usuarios_dentro,
    (SELECT SUM(monto) FROM pagos WHERE DATE(fecha_pago) = CURDATE() AND estado = 'completado') as ingresos_hoy;

-- Ingresos por mes del año actual
SELECT 
    DATE_FORMAT(fecha_pago, '%Y-%m') as mes,
    SUM(monto) as total_ingresos,
    COUNT(*) as total_transacciones
FROM pagos
WHERE YEAR(fecha_pago) = YEAR(CURDATE())
  AND estado = 'completado'
GROUP BY DATE_FORMAT(fecha_pago, '%Y-%m')
ORDER BY mes DESC;

