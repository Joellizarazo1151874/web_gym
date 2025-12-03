<?php
/**
 * Ejemplo de uso de la configuración de base de datos
 * Sistema de Gestión de Gimnasio - Functional Training
 */

// Incluir configuración
require_once __DIR__ . '/database/config.php';

try {
    // Obtener conexión usando el singleton
    $db = getDB();
    
    // Ejemplo 1: Consultar usuarios
    echo "=== EJEMPLO 1: Listar usuarios ===\n";
    $stmt = $db->query("SELECT id, nombre, apellido, email FROM usuarios LIMIT 5");
    $usuarios = $stmt->fetchAll();
    
    foreach ($usuarios as $usuario) {
        echo "ID: {$usuario['id']} - {$usuario['nombre']} {$usuario['apellido']} ({$usuario['email']})\n";
    }
    
    // Ejemplo 2: Insertar un nuevo usuario (preparado)
    echo "\n=== EJEMPLO 2: Insertar usuario ===\n";
    $stmt = $db->prepare("
        INSERT INTO usuarios (
            rol_id, documento, tipo_documento, nombre, apellido, 
            email, password, codigo_qr, estado
        ) VALUES (
            :rol_id, :documento, :tipo_documento, :nombre, :apellido,
            :email, :password, :codigo_qr, :estado
        )
    ");
    
    $password_hash = password_hash('password123', PASSWORD_DEFAULT);
    $codigo_qr = 'QR-' . strtoupper(uniqid());
    
    $stmt->execute([
        ':rol_id' => 3, // Cliente
        ':documento' => '12345678',
        ':tipo_documento' => 'CC',
        ':nombre' => 'Juan',
        ':apellido' => 'Pérez',
        ':email' => 'juan.perez@example.com',
        ':password' => $password_hash,
        ':codigo_qr' => $codigo_qr,
        ':estado' => 'activo'
    ]);
    
    $nuevo_usuario_id = $db->lastInsertId();
    echo "Usuario creado con ID: {$nuevo_usuario_id}\n";
    
    // Ejemplo 3: Consultar con parámetros
    echo "\n=== EJEMPLO 3: Buscar usuario por email ===\n";
    $stmt = $db->prepare("
        SELECT u.*, r.nombre as rol 
        FROM usuarios u 
        INNER JOIN roles r ON u.rol_id = r.id 
        WHERE u.email = :email
    ");
    $stmt->execute([':email' => 'juan.perez@example.com']);
    $usuario = $stmt->fetch();
    
    if ($usuario) {
        echo "Usuario encontrado: {$usuario['nombre']} {$usuario['apellido']} - Rol: {$usuario['rol']}\n";
    }
    
    // Ejemplo 4: Transacción
    echo "\n=== EJEMPLO 4: Crear membresía con transacción ===\n";
    $db->beginTransaction();
    
    try {
        // Crear membresía
        $stmt = $db->prepare("
            INSERT INTO membresias (
                usuario_id, plan_id, fecha_inicio, fecha_fin, 
                precio_pagado, descuento_app, estado
            ) VALUES (
                :usuario_id, :plan_id, :fecha_inicio, :fecha_fin,
                :precio_pagado, :descuento_app, :estado
            )
        ");
        
        $fecha_inicio = date('Y-m-d');
        $fecha_fin = date('Y-m-d', strtotime('+30 days'));
        
        $stmt->execute([
            ':usuario_id' => $nuevo_usuario_id,
            ':plan_id' => 3, // Plan mensual
            ':fecha_inicio' => $fecha_inicio,
            ':fecha_fin' => $fecha_fin,
            ':precio_pagado' => 54000.00, // Con descuento app
            ':descuento_app' => 1,
            ':estado' => 'activa'
        ]);
        
        $membresia_id = $db->lastInsertId();
        
        // Registrar pago
        $stmt = $db->prepare("
            INSERT INTO pagos (
                membresia_id, usuario_id, tipo, monto, 
                metodo_pago, estado, fecha_pago
            ) VALUES (
                :membresia_id, :usuario_id, :tipo, :monto,
                :metodo_pago, :estado, :fecha_pago
            )
        ");
        
        $stmt->execute([
            ':membresia_id' => $membresia_id,
            ':usuario_id' => $nuevo_usuario_id,
            ':tipo' => 'membresia',
            ':monto' => 54000.00,
            ':metodo_pago' => 'app',
            ':estado' => 'completado',
            ':fecha_pago' => date('Y-m-d H:i:s')
        ]);
        
        $db->commit();
        echo "Membresía y pago creados exitosamente\n";
        
    } catch (Exception $e) {
        $db->rollBack();
        throw $e;
    }
    
    // Ejemplo 5: Consulta compleja con JOIN
    echo "\n=== EJEMPLO 5: Usuarios con membresía activa ===\n";
    $stmt = $db->query("
        SELECT 
            u.id,
            CONCAT(u.nombre, ' ', u.apellido) as nombre_completo,
            u.email,
            u.codigo_qr,
            p.nombre as plan,
            m.fecha_inicio,
            m.fecha_fin,
            DATEDIFF(m.fecha_fin, CURDATE()) as dias_restantes
        FROM usuarios u
        INNER JOIN membresias m ON u.id = m.usuario_id
        INNER JOIN planes p ON m.plan_id = p.id
        WHERE m.estado = 'activa'
          AND m.fecha_fin >= CURDATE()
        ORDER BY m.fecha_fin ASC
        LIMIT 5
    ");
    
    $membresias = $stmt->fetchAll();
    foreach ($membresias as $membresia) {
        echo "{$membresia['nombre_completo']} - Plan: {$membresia['plan']} - Días restantes: {$membresia['dias_restantes']}\n";
    }
    
    echo "\n=== Todos los ejemplos ejecutados correctamente ===\n";
    
} catch (PDOException $e) {
    echo "Error de base de datos: " . $e->getMessage() . "\n";
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}

