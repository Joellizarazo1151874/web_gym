<?php
/**
 * Política de Privacidad - Functional Training Gym
 * Página pública que describe cómo se manejan los datos personales
 */
require_once __DIR__ . '/database/config.php';
require_once __DIR__ . '/database/config_helpers.php';

$db = getDB();
$configuracion = obtenerConfiguracion($db);

// Valores por defecto
$gimnasio_nombre = $configuracion['gimnasio_nombre'] ?? 'Functional Training Gym';
$gimnasio_email = $configuracion['gimnasio_email'] ?? 'info@ftgym.com';
$gimnasio_direccion = $configuracion['gimnasio_direccion'] ?? '';
$gimnasio_ciudad = $configuracion['gimnasio_ciudad'] ?? '';
$gimnasio_telefono = $configuracion['gimnasio_telefono'] ?? '';
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Política de Privacidad - <?php echo htmlspecialchars($gimnasio_nombre); ?></title>
    <meta name="description" content="Política de privacidad de <?php echo htmlspecialchars($gimnasio_nombre); ?>. Conoce cómo protegemos y manejamos tus datos personales.">
    
    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Catamaran:wght@600;700;800;900&family=Rubik:wght@400;500;800&display=swap" rel="stylesheet">
    
    <!-- Ionicon -->
    <script type="module" src="https://unpkg.com/ionicons@5.5.2/dist/ionicons/ionicons.esm.js"></script>
    <script nomodule src="https://unpkg.com/ionicons@5.5.2/dist/ionicons/ionicons.js"></script>
    
    <!-- CSS -->
    <link rel="stylesheet" href="./assets/css/style.css">
    
    <style>
        :root {
            --coquelicot: hsl(12, 98%, 52%);
            --rich-black-fogra-29-1: hsl(210, 26%, 11%);
            --sonic-silver: hsl(0, 0%, 47%);
            --silver-metallic: hsl(212, 9%, 67%);
            --white: hsl(0, 0%, 100%);
            --gainsboro: hsl(0, 0%, 88%);
            --coquelicot_20: hsla(12, 98%, 52%, 0.2);
            --coquelicot_10: hsla(12, 98%, 52%, 0.1);
            --black_10: hsl(0, 0%, 0%, 0.1);
        }
        
        .legal-page {
            padding-top: 120px;
            padding-bottom: 80px;
            background: linear-gradient(180deg, var(--white) 0%, #f8f9fa 100%);
        }
        
        .legal-header {
            text-align: center;
            margin-bottom: 60px;
            padding-bottom: 30px;
            border-bottom: 3px solid var(--coquelicot);
        }
        
        .legal-header .h1 {
            color: var(--rich-black-fogra-29-1);
            font-size: 4.5rem;
            margin-bottom: 15px;
            font-weight: 900;
        }
        
        .legal-header .section-text {
            font-size: 1.8rem;
            color: var(--sonic-silver);
            max-width: 700px;
            margin: 0 auto;
        }
        
        .legal-content {
            max-width: 1000px;
            margin: 0 auto;
            padding: 0 20px;
        }
        
        .legal-section {
            background: var(--white);
            border-radius: 15px;
            padding: 40px;
            margin-bottom: 30px;
            box-shadow: 0 5px 20px var(--black_10);
            transition: transform 0.3s ease, box-shadow 0.3s ease;
        }
        
        .legal-section:hover {
            transform: translateY(-5px);
            box-shadow: 0 10px 30px var(--coquelicot_20);
        }
        
        .legal-section-title {
            color: var(--coquelicot);
            font-size: 2.5rem;
            font-weight: 800;
            margin-bottom: 20px;
            padding-bottom: 15px;
            border-bottom: 2px solid var(--gainsboro);
            display: flex;
            align-items: center;
            gap: 15px;
        }
        
        .legal-section-title ion-icon {
            font-size: 2.5rem;
            color: var(--coquelicot);
        }
        
        .legal-section h4 {
            color: var(--rich-black-fogra-29-1);
            font-size: 1.8rem;
            font-weight: 700;
            margin-top: 25px;
            margin-bottom: 15px;
        }
        
        .legal-section p {
            color: var(--sonic-silver);
            font-size: 1.6rem;
            line-height: 1.8;
            margin-bottom: 15px;
            text-align: justify;
        }
        
        .legal-section ul,
        .legal-section ol {
            margin: 20px 0;
            padding-left: 30px;
        }
        
        .legal-section li {
            color: var(--sonic-silver);
            font-size: 1.6rem;
            line-height: 1.8;
            margin-bottom: 10px;
            list-style: disc;
        }
        
        .legal-section ol li {
            list-style: decimal;
        }
        
        .highlight-box {
            background: linear-gradient(135deg, var(--coquelicot_10) 0%, var(--coquelicot_20) 100%);
            border-left: 5px solid var(--coquelicot);
            padding: 25px;
            margin: 25px 0;
            border-radius: 10px;
        }
        
        .highlight-box strong {
            color: var(--rich-black-fogra-29-1);
            font-size: 1.7rem;
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 10px;
        }
        
        .highlight-box ion-icon {
            font-size: 2rem;
            color: var(--coquelicot);
        }
        
        .warning-box {
            background: linear-gradient(135deg, #fff3cd 0%, #ffe69c 100%);
            border-left: 5px solid #ffc107;
            padding: 25px;
            margin: 25px 0;
            border-radius: 10px;
        }
        
        .warning-box strong {
            color: var(--rich-black-fogra-29-1);
            font-size: 1.7rem;
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 10px;
        }
        
        .contact-info-box {
            background: linear-gradient(135deg, var(--rich-black-fogra-29-1) 0%, #1a1f2e 100%);
            color: var(--white);
            padding: 40px;
            border-radius: 15px;
            margin-top: 40px;
            box-shadow: 0 10px 40px var(--black_10);
        }
        
        .contact-info-box h4 {
            color: var(--coquelicot);
            font-size: 2.2rem;
            margin-bottom: 25px;
            display: flex;
            align-items: center;
            gap: 15px;
        }
        
        .contact-info-box ul {
            list-style: none;
            padding-left: 0;
        }
        
        .contact-info-box li {
            font-size: 1.6rem;
            margin-bottom: 15px;
            display: flex;
            align-items: center;
            gap: 15px;
        }
        
        .contact-info-box ion-icon {
            font-size: 2rem;
            color: var(--coquelicot);
        }
        
        .contact-info-box a {
            color: var(--coquelicot);
            text-decoration: none;
            transition: color 0.3s ease;
        }
        
        .contact-info-box a:hover {
            color: var(--white);
            text-decoration: underline;
        }
        
        .back-link {
            display: inline-flex;
            align-items: center;
            gap: 10px;
            margin-top: 40px;
            padding: 15px 30px;
            background: var(--coquelicot);
            color: var(--white);
            text-decoration: none;
            border-radius: 10px;
            font-weight: 600;
            font-size: 1.6rem;
            transition: all 0.3s ease;
            text-transform: uppercase;
        }
        
        .back-link:hover {
            background: var(--rich-black-fogra-29-1);
            transform: translateX(-5px);
            box-shadow: 0 5px 20px var(--coquelicot_20);
        }
        
        .last-updated {
            text-align: center;
            color: var(--silver-metallic);
            font-size: 1.4rem;
            font-style: italic;
            margin-top: 20px;
            padding: 15px;
            background: var(--gainsboro);
            border-radius: 10px;
        }
        
        @media (max-width: 768px) {
            .legal-header .h1 {
                font-size: 3rem;
            }
            
            .legal-section {
                padding: 25px;
            }
            
            .legal-section-title {
                font-size: 2rem;
            }
            
            .contact-info-box {
                padding: 25px;
            }
        }
    </style>
</head>
<body>
    <!-- Header -->
    <header class="header" data-header>
        <div class="container">
            <a href="index.php" class="logo">
                <strong><?php echo htmlspecialchars($gimnasio_nombre); ?></strong>
            </a>
            <nav class="navbar" data-navbar>
                <ul class="navbar-list">
                    <li><a href="index.php" class="navbar-link">Inicio</a></li>
                </ul>
            </nav>
        </div>
    </header>
    
    <!-- Main Content -->
    <main>
        <section class="legal-page section">
            <div class="container">
                <div class="legal-header">
                    <h1 class="h1">
                        <ion-icon name="shield-checkmark-outline"></ion-icon>
                        Política de Privacidad
                    </h1>
                    <p class="section-text">
                        En <?php echo htmlspecialchars($gimnasio_nombre); ?>, nos comprometemos a proteger tu privacidad 
                        y garantizar la seguridad de tus datos personales.
                    </p>
                    <p class="last-updated">
                        <strong>Última actualización:</strong> <?php echo date('d/m/Y'); ?>
                    </p>
                </div>
                
                <div class="legal-content">
                    <!-- Sección 1 -->
                    <div class="legal-section">
                        <h2 class="legal-section-title">
                            <ion-icon name="information-circle-outline"></ion-icon>
                            1. Información que Recopilamos
                        </h2>
                        
                        <h4>1.1. Información Personal</h4>
                        <p>Recopilamos la siguiente información personal cuando te registras como miembro o utilizas nuestros servicios:</p>
                        <ul>
                            <li><strong>Datos de identificación:</strong> Nombre completo, número de identificación, fecha de nacimiento, género</li>
                            <li><strong>Información de contacto:</strong> Dirección de correo electrónico, número de teléfono, dirección física</li>
                            <li><strong>Información de salud:</strong> Condiciones médicas relevantes, restricciones físicas, historial médico básico (con tu consentimiento explícito)</li>
                            <li><strong>Información financiera:</strong> Datos de pago, información de membresías, historial de transacciones</li>
                            <li><strong>Información de uso:</strong> Registro de asistencia, uso de instalaciones, participación en clases</li>
                        </ul>
                        
                        <h4>1.2. Información Técnica</h4>
                        <p>Cuando visitas nuestro sitio web o utilizas nuestra aplicación móvil, recopilamos automáticamente:</p>
                        <ul>
                            <li>Dirección IP y tipo de navegador</li>
                            <li>Páginas visitadas y tiempo de permanencia</li>
                            <li>Dispositivo utilizado y sistema operativo</li>
                            <li>Cookies y tecnologías similares</li>
                        </ul>
                    </div>
                    
                    <!-- Sección 2 -->
                    <div class="legal-section">
                        <h2 class="legal-section-title">
                            <ion-icon name="settings-outline"></ion-icon>
                            2. Uso de la Información
                        </h2>
                        <p>Utilizamos tu información personal para los siguientes propósitos:</p>
                        <ul>
                            <li><strong>Gestión de membresías:</strong> Procesar registros, administrar membresías, gestionar pagos y renovaciones</li>
                            <li><strong>Servicios de gimnasio:</strong> Registrar asistencia, programar clases, gestionar reservas de instalaciones</li>
                            <li><strong>Comunicación:</strong> Enviar notificaciones importantes, recordatorios de clases, información sobre servicios y promociones</li>
                            <li><strong>Seguridad y salud:</strong> Asegurar un ambiente seguro, responder a emergencias médicas, cumplir con regulaciones de salud</li>
                            <li><strong>Mejora de servicios:</strong> Analizar el uso de instalaciones, mejorar nuestros servicios y experiencia del usuario</li>
                            <li><strong>Cumplimiento legal:</strong> Cumplir con obligaciones legales y regulatorias</li>
                        </ul>
                    </div>
                    
                    <!-- Sección 3 -->
                    <div class="legal-section">
                        <h2 class="legal-section-title">
                            <ion-icon name="share-social-outline"></ion-icon>
                            3. Compartir Información
                        </h2>
                        <p>No vendemos ni alquilamos tu información personal. Solo compartimos tu información en las siguientes circunstancias:</p>
                        <ul>
                            <li><strong>Proveedores de servicios:</strong> Con empresas que nos ayudan a operar (procesadores de pago, servicios de email, hosting)</li>
                            <li><strong>Requisitos legales:</strong> Cuando sea requerido por ley, orden judicial o autoridad gubernamental</li>
                            <li><strong>Emergencias médicas:</strong> Con personal médico o servicios de emergencia cuando sea necesario para tu seguridad</li>
                            <li><strong>Con tu consentimiento:</strong> Cuando explícitamente nos autorices a compartir tu información</li>
                        </ul>
                        
                        <div class="highlight-box">
                            <strong>
                                <ion-icon name="lock-closed-outline"></ion-icon>
                                Compromiso de Seguridad
                            </strong>
                            <p>Todos nuestros proveedores de servicios están contractualmente obligados a mantener la confidencialidad de tu información 
                            y utilizarla únicamente para los fines acordados.</p>
                        </div>
                    </div>
                    
                    <!-- Sección 4 -->
                    <div class="legal-section">
                        <h2 class="legal-section-title">
                            <ion-icon name="lock-closed-outline"></ion-icon>
                            4. Seguridad de los Datos
                        </h2>
                        <p>Implementamos medidas de seguridad técnicas y organizativas para proteger tu información personal:</p>
                        <ul>
                            <li><strong>Cifrado:</strong> Utilizamos cifrado SSL/TLS para proteger datos en tránsito</li>
                            <li><strong>Almacenamiento seguro:</strong> Los datos se almacenan en servidores seguros con acceso restringido</li>
                            <li><strong>Control de acceso:</strong> Solo personal autorizado tiene acceso a información personal</li>
                            <li><strong>Monitoreo:</strong> Supervisamos continuamente nuestros sistemas para detectar y prevenir accesos no autorizados</li>
                            <li><strong>Copias de seguridad:</strong> Realizamos copias de seguridad regulares de los datos</li>
                        </ul>
                        
                        <p class="text-muted">
                            A pesar de nuestros esfuerzos, ningún método de transmisión por Internet o almacenamiento electrónico es 100% seguro. 
                            No podemos garantizar la seguridad absoluta, pero nos comprometemos a notificarte de cualquier violación de seguridad 
                            que pueda afectar tus datos personales.
                        </p>
                    </div>
                    
                    <!-- Sección 5 -->
                    <div class="legal-section">
                        <h2 class="legal-section-title">
                            <ion-icon name="time-outline"></ion-icon>
                            5. Retención de Datos
                        </h2>
                        <p>Conservamos tu información personal durante el tiempo necesario para:</p>
                        <ul>
                            <li>Cumplir con los propósitos para los que fue recopilada</li>
                            <li>Cumplir con obligaciones legales, contables o de informes</li>
                            <li>Resolver disputas y hacer cumplir nuestros acuerdos</li>
                        </ul>
                        
                        <p>
                            Cuando tu información ya no sea necesaria, la eliminaremos de forma segura. Si cancelas tu membresía, 
                            conservaremos cierta información según lo requiera la ley o para fines legítimos de negocio.
                        </p>
                    </div>
                    
                    <!-- Sección 6 -->
                    <div class="legal-section">
                        <h2 class="legal-section-title">
                            <ion-icon name="person-outline"></ion-icon>
                            6. Tus Derechos
                        </h2>
                        <p>Tienes los siguientes derechos respecto a tu información personal:</p>
                        <ul>
                            <li><strong>Acceso:</strong> Solicitar una copia de la información personal que tenemos sobre ti</li>
                            <li><strong>Rectificación:</strong> Corregir información inexacta o incompleta</li>
                            <li><strong>Eliminación:</strong> Solicitar la eliminación de tu información personal (sujeto a obligaciones legales)</li>
                            <li><strong>Oposición:</strong> Oponerte al procesamiento de tu información para ciertos fines</li>
                            <li><strong>Portabilidad:</strong> Recibir tu información en un formato estructurado y de uso común</li>
                            <li><strong>Retirar consentimiento:</strong> Retirar tu consentimiento en cualquier momento cuando el procesamiento se base en consentimiento</li>
                        </ul>
                        
                        <p>
                            Para ejercer estos derechos, contáctanos usando la información proporcionada al final de esta política.
                        </p>
                    </div>
                    
                    <!-- Sección 7 -->
                    <div class="legal-section">
                        <h2 class="legal-section-title">
                            <ion-icon name="cookie-outline"></ion-icon>
                            7. Cookies y Tecnologías Similares
                        </h2>
                        <p>Utilizamos cookies y tecnologías similares para mejorar tu experiencia en nuestro sitio web:</p>
                        <ul>
                            <li><strong>Cookies esenciales:</strong> Necesarias para el funcionamiento del sitio</li>
                            <li><strong>Cookies de rendimiento:</strong> Nos ayudan a entender cómo los visitantes interactúan con nuestro sitio</li>
                            <li><strong>Cookies de funcionalidad:</strong> Permiten recordar tus preferencias</li>
                        </ul>
                        
                        <p>
                            Puedes controlar las cookies a través de la configuración de tu navegador. Sin embargo, 
                            deshabilitar ciertas cookies puede afectar la funcionalidad del sitio.
                        </p>
                    </div>
                    
                    <!-- Sección 8 -->
                    <div class="legal-section">
                        <h2 class="legal-section-title">
                            <ion-icon name="people-outline"></ion-icon>
                            8. Privacidad de Menores
                        </h2>
                        <p>
                            Nuestros servicios están dirigidos a personas mayores de 18 años. Si eres menor de edad, 
                            necesitas el consentimiento de tus padres o tutores legales para utilizar nuestros servicios.
                        </p>
                        
                        <p>
                            No recopilamos intencionalmente información personal de menores sin el consentimiento de los padres. 
                            Si descubrimos que hemos recopilado información de un menor sin consentimiento, la eliminaremos inmediatamente.
                        </p>
                    </div>
                    
                    <!-- Sección 9 -->
                    <div class="legal-section">
                        <h2 class="legal-section-title">
                            <ion-icon name="globe-outline"></ion-icon>
                            9. Cambios a esta Política
                        </h2>
                        <p>
                            Podemos actualizar esta Política de Privacidad ocasionalmente para reflejar cambios en nuestras prácticas 
                            o por razones legales, operativas o regulatorias. Te notificaremos de cualquier cambio significativo mediante:
                        </p>
                        <ul>
                            <li>Publicación de la nueva política en nuestro sitio web</li>
                            <li>Notificación por correo electrónico (si el cambio es sustancial)</li>
                            <li>Aviso en nuestras instalaciones</li>
                        </ul>
                        
                        <p>
                            Te recomendamos revisar esta política periódicamente para estar informado sobre cómo protegemos tu información.
                        </p>
                    </div>
                    
                    <!-- Contacto -->
                    <div class="contact-info-box">
                        <h4>
                            <ion-icon name="mail-outline"></ion-icon>
                            Contacto
                        </h4>
                        <p style="margin-bottom: 20px;">Si tienes preguntas, inquietudes o deseas ejercer tus derechos respecto a tu información personal, contáctanos:</p>
                        <ul>
                            <li>
                                <ion-icon name="business-outline"></ion-icon>
                                <strong>Empresa:</strong> <?php echo htmlspecialchars($gimnasio_nombre); ?>
                            </li>
                            <?php if (!empty($gimnasio_direccion)): ?>
                            <li>
                                <ion-icon name="location-outline"></ion-icon>
                                <strong>Dirección:</strong> <?php echo htmlspecialchars($gimnasio_direccion); ?>, <?php echo htmlspecialchars($gimnasio_ciudad); ?>
                            </li>
                            <?php endif; ?>
                            <li>
                                <ion-icon name="mail-outline"></ion-icon>
                                <strong>Email:</strong> <a href="mailto:<?php echo htmlspecialchars($gimnasio_email); ?>"><?php echo htmlspecialchars($gimnasio_email); ?></a>
                            </li>
                            <?php if (!empty($gimnasio_telefono)): ?>
                            <li>
                                <ion-icon name="call-outline"></ion-icon>
                                <strong>Teléfono:</strong> <a href="tel:<?php echo htmlspecialchars($gimnasio_telefono); ?>"><?php echo htmlspecialchars($gimnasio_telefono); ?></a>
                            </li>
                            <?php endif; ?>
                        </ul>
                    </div>
                    
                    <div class="text-center">
                        <a href="index.php" class="back-link">
                            <ion-icon name="arrow-back-outline"></ion-icon>
                            Volver al inicio
                        </a>
                    </div>
                </div>
            </div>
        </section>
    </main>
    
    <!-- Footer -->
    <footer class="footer">
        <div class="footer-top section">
            <div class="container">
                <div class="footer-brand">
                    <a href="index.php" class="logo">
                        <strong><?php echo htmlspecialchars($gimnasio_nombre); ?></strong>
                    </a>
                </div>
            </div>
        </div>
        <div class="footer-bottom">
            <div class="container">
                <p class="copyright">
                    &copy; <?php echo date('Y'); ?> <?php echo htmlspecialchars($gimnasio_nombre); ?>. Todos los derechos reservados.
                </p>
                <ul class="footer-bottom-list">
                    <li><a href="privacy-policy.php" class="footer-bottom-link has-before">Política de Privacidad</a></li>
                    <li><a href="terms-of-use.php" class="footer-bottom-link has-before">Términos y Condiciones</a></li>
                </ul>
            </div>
        </div>
    </footer>
    
    <script src="./assets/js/script.js"></script>
</body>
</html>
