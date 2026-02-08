<?php
/**
 * API de Registro de Ingreso (Check-in)
 * Entrada: POST cedula (documento)
 * Salida: JSON con datos del usuario, membresía y asistencia registrada
 */
require_once __DIR__ . '/../database/config.php';

header('Content-Type: application/json');

function response($data, $status = 200) {
    http_response_code($status);
    echo json_encode($data);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    response(['success' => false, 'message' => 'Método no permitido'], 405);
}

$cedula = trim($_POST['cedula'] ?? '');
$codigo_qr = trim($_POST['codigo_qr'] ?? $cedula);
$dispositivo = trim($_POST['dispositivo'] ?? 'dashboard-checkin');

if ($cedula === '' || !preg_match('/^[0-9]{4,}$/', $cedula)) {
    response(['success' => false, 'message' => 'Cédula inválida'], 400);
}

try {
    $db = getDB();

    // 1) Buscar usuario por documento (incluyendo estado y rol)
    $stmt = $db->prepare("
        SELECT u.id, u.nombre, u.apellido, u.email, u.telefono, u.estado, r.nombre AS rol
        FROM usuarios u
        LEFT JOIN roles r ON u.rol_id = r.id
        WHERE u.documento = :cedula
        LIMIT 1
    ");
    $stmt->execute([':cedula' => $cedula]);
    $usuario = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$usuario) {
        response([
            'success' => false, 
            'code' => 'USER_NOT_FOUND', 
            'message' => 'Usuario no registrado',
            'detail' => 'Este usuario no está registrado en el sistema'
        ]);
    }

    $usuario_id = (int)$usuario['id'];
    $usuario_estado = $usuario['estado'];

    // 2) Verificar si el usuario está suspendido
    if ($usuario_estado === 'suspendido') {
        response([
            'success' => false,
            'code' => 'USER_SUSPENDED',
            'message' => 'Usuario suspendido',
            'detail' => 'Este usuario está suspendido y no puede ingresar al gimnasio',
            'user' => [
                'id' => $usuario_id,
                'nombre' => $usuario['nombre'] . ' ' . $usuario['apellido'],
                'cedula' => $cedula
            ]
        ]);
    }

    // 3) Obtener membresía activa (válida y no vencida)
    $stmt = $db->prepare("
        SELECT m.id, m.plan_id, m.fecha_inicio, m.fecha_fin, m.estado, p.nombre AS plan_nombre,
               DATEDIFF(m.fecha_fin, CURDATE()) AS dias_restantes
        FROM membresias m
        INNER JOIN planes p ON p.id = m.plan_id
        WHERE m.usuario_id = :uid
          AND m.estado = 'activa'
          AND m.fecha_fin >= CURDATE()
        ORDER BY m.fecha_fin DESC
        LIMIT 1
    ");
    $stmt->execute([':uid' => $usuario_id]);
    $membresia = $stmt->fetch(PDO::FETCH_ASSOC);

    // 4) Si no hay membresía activa, verificar si tiene membresía vencida
    if (!$membresia) {
        // Buscar la última membresía (aunque esté vencida)
        $stmt = $db->prepare("
            SELECT m.id, m.plan_id, m.fecha_inicio, m.fecha_fin, m.estado, p.nombre AS plan_nombre,
                   DATEDIFF(CURDATE(), m.fecha_fin) AS dias_vencida
            FROM membresias m
            INNER JOIN planes p ON p.id = m.plan_id
            WHERE m.usuario_id = :uid
            ORDER BY m.fecha_fin DESC
            LIMIT 1
        ");
        $stmt->execute([':uid' => $usuario_id]);
        $membresia_vencida = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($membresia_vencida) {
            // Tiene membresía pero está vencida
            $dias_vencida = (int)$membresia_vencida['dias_vencida'];
            response([
                'success' => false,
                'code' => 'MEMBERSHIP_EXPIRED',
                'message' => 'Membresía vencida',
                'detail' => "La membresía de este usuario venció hace {$dias_vencida} día(s). Debe renovar su membresía para poder ingresar.",
                'user' => [
                    'id' => $usuario_id,
                    'nombre' => $usuario['nombre'] . ' ' . $usuario['apellido'],
                    'cedula' => $cedula
                ],
                'membership' => [
                    'plan' => $membresia_vencida['plan_nombre'],
                    'fecha_fin' => $membresia_vencida['fecha_fin'],
                    'dias_vencida' => $dias_vencida
                ]
            ]);
        } else {
            // No tiene membresía: permitir solo si es admin
            $es_admin = isset($usuario['rol']) && $usuario['rol'] === 'admin';
            if (!$es_admin) {
                response([
                    'success' => false,
                    'code' => 'NO_MEMBERSHIP',
                    'message' => 'Sin membresía',
                    'detail' => 'Este usuario no tiene una membresía registrada. Debe adquirir una membresía para poder ingresar.',
                    'user' => [
                        'id' => $usuario_id,
                        'nombre' => $usuario['nombre'] . ' ' . $usuario['apellido'],
                        'cedula' => $cedula
                    ]
                ]);
            }
            // Admin sin membresía: acceso permitido con membresía virtual
            $membresia = [
                'id' => null,
                'plan_nombre' => 'Acceso Admin',
                'fecha_inicio' => date('Y-m-d'),
                'fecha_fin' => date('Y-m-d', strtotime('+10 years')),
                'estado' => 'activa',
                'dias_restantes' => 3650
            ];
        }
    }

    $membresia_id = $membresia['id'] !== null ? (int)$membresia['id'] : null;

    // 3) Registrar asistencia
    $stmt = $db->prepare("
        INSERT INTO asistencias (usuario_id, membresia_id, fecha_entrada, codigo_qr, tipo_acceso, dispositivo)
        VALUES (:uid, :mid, NOW(), :codigo_qr, 'entrada', :dispositivo)
    ");
    $stmt->execute([
        ':uid' => $usuario_id,
        ':mid' => $membresia_id,
        ':codigo_qr' => $codigo_qr,
        ':dispositivo' => $dispositivo
    ]);

    $asistencia_id = (int)$db->lastInsertId();

    // Calcular días restantes de membresía
    $dias_restantes = (int)$membresia['dias_restantes'];

    response([
        'success' => true,
        'asistencia_id' => $asistencia_id,
        'user' => [
            'id' => $usuario_id,
            'nombre' => $usuario['nombre'] . ' ' . $usuario['apellido'],
            'cedula' => $cedula,
            'email' => $usuario['email'],
            'telefono' => $usuario['telefono']
        ],
        'membership' => [
            'id' => $membresia_id,
            'plan' => $membresia['plan_nombre'],
            'fecha_inicio' => $membresia['fecha_inicio'],
            'fecha_fin' => $membresia['fecha_fin'],
            'estado' => $membresia['estado'],
            'dias_restantes' => $dias_restantes
        ],
        'message' => 'Ingreso registrado correctamente'
    ]);

} catch (Exception $e) {
    response(['success' => false, 'message' => 'Error en el servidor: ' . $e->getMessage()], 500);
}

