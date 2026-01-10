<?php
/**
 * Página de Restablecimiento de Contraseña
 * Recibe token y email por URL y muestra formulario para resetear contraseña
 */

require_once __DIR__ . '/database/config.php';

// Obtener token y email de la URL
$token = trim($_GET['token'] ?? '');
$email = trim($_GET['email'] ?? '');

// Si no hay token o email, mostrar error
if (empty($token) || empty($email)) {
    $error = 'Token o email inválido';
    $token = '';
    $email = '';
}

// Si hay token y email, validarlos
$token_valid = false;
if (!empty($token) && !empty($email)) {
    try {
        $db = getDB();
        $token_hash = hash('sha256', $token);
        
        $stmt = $db->prepare("
            SELECT id, token_verificacion, updated_at
            FROM usuarios 
            WHERE email = :email
        ");
        $stmt->execute([':email' => $email]);
        $usuario = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($usuario && $usuario['token_verificacion'] === $token_hash) {
            // Verificar expiración (1 hora)
            $token_created = strtotime($usuario['updated_at']);
            $now = time();
            if (($now - $token_created) <= 3600) {
                $token_valid = true;
            } else {
                $error = 'El token ha expirado. Solicita uno nuevo.';
            }
        } else {
            $error = 'Token inválido';
        }
    } catch (Exception $e) {
        $error = 'Error al validar el token';
        error_log("Error en reset-password.php: " . $e->getMessage());
    }
}

// Obtener configuración para el logo
$logo_empresa = './favicon.svg';
try {
    $db = getDB();
    require_once __DIR__ . '/database/config_helpers.php';
    $config = obtenerConfiguracion($db);
    if (!empty($config['logo_empresa'])) {
        $relativeLogo = $config['logo_empresa'];
        if ($relativeLogo[0] !== '/' && substr($relativeLogo, 0, 2) !== './') {
            $relativeLogo = './' . $relativeLogo;
        }
        $logoPathFs = __DIR__ . '/' . ltrim($relativeLogo, './');
        if (file_exists($logoPathFs)) {
            $logo_empresa = $relativeLogo;
        }
    }
} catch (Exception $e) {
    // Usar logo por defecto
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Restablecer Contraseña - FTGym</title>
    <link rel="stylesheet" href="./assets/css/style.css">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Catamaran:wght@600;700;800;900&family=Rubik:wght@400;500;800&display=swap" rel="stylesheet">
    <style>
        body {
            margin: 0;
            padding: 0;
            font-family: 'Rubik', sans-serif;
            background: linear-gradient(135deg, #E63946 0%, #B02A35 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .reset-container {
            background: white;
            border-radius: 16px;
            padding: 40px;
            max-width: 450px;
            width: 90%;
            box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2);
        }
        .logo {
            text-align: center;
            margin-bottom: 30px;
        }
        .logo img {
            width: 60px;
            height: 60px;
        }
        h1 {
            font-family: 'Catamaran', sans-serif;
            font-size: 28px;
            font-weight: 900;
            color: #1A1F2E;
            text-align: center;
            margin: 0 0 10px 0;
        }
        .subtitle {
            text-align: center;
            color: #787878;
            font-size: 14px;
            margin-bottom: 30px;
        }
        .form-group {
            margin-bottom: 20px;
        }
        label {
            display: block;
            margin-bottom: 8px;
            color: #1A1F2E;
            font-weight: 500;
            font-size: 14px;
        }
        input[type="password"] {
            width: 100%;
            padding: 14px;
            border: 2px solid #E0E0E0;
            border-radius: 8px;
            font-size: 16px;
            font-family: 'Rubik', sans-serif;
            box-sizing: border-box;
            transition: border-color 0.3s;
        }
        input[type="password"]:focus {
            outline: none;
            border-color: #E63946;
        }
        .password-toggle {
            position: relative;
        }
        .password-toggle-btn {
            position: absolute;
            right: 12px;
            top: 50%;
            transform: translateY(-50%);
            background: none;
            border: none;
            color: #787878;
            cursor: pointer;
            font-size: 20px;
            padding: 5px;
        }
        .btn {
            width: 100%;
            padding: 16px;
            background: linear-gradient(135deg, #E63946 0%, #B02A35 100%);
            color: white;
            border: none;
            border-radius: 8px;
            font-size: 16px;
            font-weight: 600;
            font-family: 'Rubik', sans-serif;
            cursor: pointer;
            transition: transform 0.2s, box-shadow 0.2s;
            margin-top: 10px;
        }
        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(230, 57, 70, 0.4);
        }
        .btn:disabled {
            opacity: 0.6;
            cursor: not-allowed;
            transform: none;
        }
        .error-message {
            background: #fff3cd;
            border: 1px solid #ffc107;
            color: #856404;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
            text-align: center;
        }
        .success-message {
            background: #d4edda;
            border: 1px solid #28a745;
            color: #155724;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
            text-align: center;
        }
        .helper-text {
            font-size: 12px;
            color: #787878;
            margin-top: 5px;
        }
        .loading {
            display: inline-block;
            width: 20px;
            height: 20px;
            border: 3px solid rgba(255,255,255,.3);
            border-radius: 50%;
            border-top-color: #fff;
            animation: spin 1s ease-in-out infinite;
        }
        @keyframes spin {
            to { transform: rotate(360deg); }
        }
        .app-link {
            text-align: center;
            margin-top: 20px;
            padding-top: 20px;
            border-top: 1px solid #E0E0E0;
        }
        .app-link a {
            color: #E63946;
            text-decoration: none;
            font-weight: 600;
        }
    </style>
</head>
<body>
    <div class="reset-container">
        <div class="logo">
            <img src="<?php echo htmlspecialchars($logo_empresa); ?>" alt="FTGym">
        </div>
        
        <h1>Restablecer Contraseña</h1>
        <p class="subtitle">Ingresa tu nueva contraseña</p>
        
        <?php if (isset($error) && !$token_valid): ?>
            <div class="error-message">
                <?php echo htmlspecialchars($error); ?>
            </div>
            <div style="text-align: center;">
                <a href="./index.php" style="color: #E63946; text-decoration: none; font-weight: 600;">Volver al inicio</a>
            </div>
        <?php elseif ($token_valid): ?>
            <form id="resetForm">
                <input type="hidden" id="token" value="<?php echo htmlspecialchars($token); ?>">
                <input type="hidden" id="email" value="<?php echo htmlspecialchars($email); ?>">
                
                <div class="form-group">
                    <label for="password">Nueva Contraseña *</label>
                    <div class="password-toggle">
                        <input type="password" id="password" name="password" required minlength="8">
                        <button type="button" class="password-toggle-btn" onclick="togglePassword('password', this)">
                            👁️
                        </button>
                    </div>
                    <p class="helper-text">Mínimo 8 caracteres</p>
                </div>
                
                <div class="form-group">
                    <label for="password_confirm">Confirmar Contraseña *</label>
                    <div class="password-toggle">
                        <input type="password" id="password_confirm" name="password_confirm" required minlength="8">
                        <button type="button" class="password-toggle-btn" onclick="togglePassword('password_confirm', this)">
                            👁️
                        </button>
                    </div>
                </div>
                
                <div id="errorMessage" class="error-message" style="display: none;"></div>
                <div id="successMessage" class="success-message" style="display: none;"></div>
                
                <button type="submit" class="btn" id="submitBtn">
                    <span id="btnText">Restablecer Contraseña</span>
                    <span id="btnLoading" class="loading" style="display: none;"></span>
                </button>
            </form>
            
            <div class="app-link">
                <p style="font-size: 12px; color: #787878; margin: 0;">
                    ¿Prefieres usar la app móvil? 
                    <a href="#" onclick="openApp()">Abrir en la app</a>
                </p>
            </div>
        <?php endif; ?>
    </div>
    
    <script>
        function togglePassword(inputId, btn) {
            const input = document.getElementById(inputId);
            if (input.type === 'password') {
                input.type = 'text';
                btn.textContent = '🙈';
            } else {
                input.type = 'password';
                btn.textContent = '👁️';
            }
        }
        
        function openApp() {
            // Intentar abrir la app con deep link
            const token = document.getElementById('token').value;
            const email = document.getElementById('email').value;
            const appUrl = `ftgym://reset-password?token=${encodeURIComponent(token)}&email=${encodeURIComponent(email)}`;
            
            // Intentar abrir la app
            window.location.href = appUrl;
            
            // Si no se abre la app en 2 segundos, mostrar mensaje
            setTimeout(() => {
                alert('Si la app no se abrió, descárgala desde la tienda de aplicaciones.');
            }, 2000);
        }
        
        document.getElementById('resetForm').addEventListener('submit', async function(e) {
            e.preventDefault();
            
            const token = document.getElementById('token').value;
            const email = document.getElementById('email').value;
            const password = document.getElementById('password').value;
            const passwordConfirm = document.getElementById('password_confirm').value;
            
            // Validaciones
            if (password.length < 8) {
                showError('La contraseña debe tener al menos 8 caracteres');
                return;
            }
            
            if (password !== passwordConfirm) {
                showError('Las contraseñas no coinciden');
                return;
            }
            
            // Mostrar loading
            const submitBtn = document.getElementById('submitBtn');
            const btnText = document.getElementById('btnText');
            const btnLoading = document.getElementById('btnLoading');
            
            submitBtn.disabled = true;
            btnText.style.display = 'none';
            btnLoading.style.display = 'inline-block';
            hideError();
            hideSuccess();
            
            try {
                const response = await fetch('./api/mobile_reset_password.php', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({
                        token: token,
                        email: email,
                        password: password,
                        password_confirm: passwordConfirm
                    })
                });
                
                const data = await response.json();
                
                if (data.success) {
                    showSuccess(data.message);
                    submitBtn.style.display = 'none';
                    
                    // Redirigir al login después de 2 segundos
                    setTimeout(() => {
                        window.location.href = './index.php';
                    }, 2000);
                } else {
                    showError(data.message || 'Error al restablecer la contraseña');
                    submitBtn.disabled = false;
                    btnText.style.display = 'inline';
                    btnLoading.style.display = 'none';
                }
            } catch (error) {
                showError('Error de conexión. Intenta nuevamente.');
                submitBtn.disabled = false;
                btnText.style.display = 'inline';
                btnLoading.style.display = 'none';
            }
        });
        
        function showError(message) {
            const errorDiv = document.getElementById('errorMessage');
            errorDiv.textContent = message;
            errorDiv.style.display = 'block';
        }
        
        function hideError() {
            document.getElementById('errorMessage').style.display = 'none';
        }
        
        function showSuccess(message) {
            const successDiv = document.getElementById('successMessage');
            successDiv.textContent = message;
            successDiv.style.display = 'block';
        }
        
        function hideSuccess() {
            document.getElementById('successMessage').style.display = 'none';
        }
    </script>
</body>
</html>

