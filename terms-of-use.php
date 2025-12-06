<?php
/**
 * Términos y Condiciones de Uso - Functional Training Gym
 * Página pública que establece los términos de uso del servicio
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
    <title>Términos y Condiciones - <?php echo htmlspecialchars($gimnasio_nombre); ?></title>
    <meta name="description" content="Términos y condiciones de uso de <?php echo htmlspecialchars($gimnasio_nombre); ?>. Conoce las reglas y condiciones para utilizar nuestros servicios.">
    
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
                        <ion-icon name="document-text-outline"></ion-icon>
                        Términos y Condiciones de Uso
                    </h1>
                    <p class="section-text">
                        Bienvenido a <?php echo htmlspecialchars($gimnasio_nombre); ?>. 
                        Al utilizar nuestros servicios, aceptas estos Términos y Condiciones de Uso.
                    </p>
                    <p class="last-updated">
                        <strong>Última actualización:</strong> <?php echo date('d/m/Y'); ?>
                    </p>
                </div>
                
                <div class="legal-content">
                    <!-- Sección 1 -->
                    <div class="legal-section">
                        <h2 class="legal-section-title">
                            <ion-icon name="hand-left-outline"></ion-icon>
                            1. Aceptación de los Términos
                        </h2>
                        <p>
                            Al acceder y utilizar los servicios de <?php echo htmlspecialchars($gimnasio_nombre); ?>, 
                            aceptas estar legalmente vinculado por estos Términos y Condiciones. Si no estás de acuerdo 
                            con alguna parte de estos términos, no debes utilizar nuestros servicios.
                        </p>
                        <p>
                            Nos reservamos el derecho de modificar estos términos en cualquier momento. Los cambios 
                            entrarán en vigor inmediatamente después de su publicación. Es tu responsabilidad revisar 
                            periódicamente estos términos.
                        </p>
                    </div>
                    
                    <!-- Sección 2 -->
                    <div class="legal-section">
                        <h2 class="legal-section-title">
                            <ion-icon name="person-check-outline"></ion-icon>
                            2. Elegibilidad y Registro
                        </h2>
                        <h4>2.1. Requisitos de Edad</h4>
                        <ul>
                            <li>Debes tener al menos 18 años para registrarte como miembro</li>
                            <li>Los menores de 18 años requieren autorización de un padre o tutor legal</li>
                            <li>Debes proporcionar información precisa y completa durante el registro</li>
                        </ul>
                        
                        <h4>2.2. Información del Miembro</h4>
                        <p>Eres responsable de:</p>
                        <ul>
                            <li>Mantener la confidencialidad de tu cuenta y contraseña</li>
                            <li>Notificarnos inmediatamente de cualquier uso no autorizado de tu cuenta</li>
                            <li>Actualizar tu información personal cuando sea necesario</li>
                            <li>Proporcionar información médica relevante para tu seguridad</li>
                        </ul>
                    </div>
                    
                    <!-- Sección 3 -->
                    <div class="legal-section">
                        <h2 class="legal-section-title">
                            <ion-icon name="card-outline"></ion-icon>
                            3. Membresías y Pagos
                        </h2>
                        <h4>3.1. Tipos de Membresía</h4>
                        <p>Ofrecemos diferentes tipos de membresías con características y precios específicos. 
                        Los detalles de cada membresía están disponibles en nuestras instalaciones o en nuestro sitio web.</p>
                        
                        <h4>3.2. Pagos</h4>
                        <ul>
                            <li><strong>Pago inicial:</strong> Se requiere pago completo al momento del registro</li>
                            <li><strong>Pagos recurrentes:</strong> Las membresías mensuales se renuevan automáticamente</li>
                            <li><strong>Métodos de pago:</strong> Aceptamos efectivo, tarjetas de crédito/débito y transferencias bancarias</li>
                            <li><strong>Pagos atrasados:</strong> Los pagos atrasados pueden resultar en suspensión de servicios</li>
                        </ul>
                        
                        <h4>3.3. Renovación y Cancelación</h4>
                        <ul>
                            <li>Las membresías se renuevan automáticamente a menos que se cancele con al menos 7 días de anticipación</li>
                            <li>Las cancelaciones deben realizarse por escrito o a través de nuestro sistema</li>
                            <li>No se realizan reembolsos por períodos no utilizados, excepto según lo establecido en la política de reembolsos</li>
                            <li>Las membresías congeladas pueden estar sujetas a tarifas adicionales</li>
                        </ul>
                    </div>
                    
                    <!-- Sección 4 -->
                    <div class="legal-section">
                        <h2 class="legal-section-title">
                            <ion-icon name="warning-outline"></ion-icon>
                            4. Uso de las Instalaciones
                        </h2>
                        <h4>4.1. Reglas de Conducta</h4>
                        <p>Al utilizar nuestras instalaciones, aceptas:</p>
                        <ul>
                            <li>Tratar a otros miembros y personal con respeto y cortesía</li>
                            <li>Usar el equipo de manera segura y apropiada</li>
                            <li>Limpiar el equipo después de su uso</li>
                            <li>Respetar el espacio personal de otros miembros</li>
                            <li>No utilizar lenguaje ofensivo o comportamiento inapropiado</li>
                            <li>No fumar, consumir alcohol o drogas en las instalaciones</li>
                        </ul>
                        
                        <h4>4.2. Seguridad y Salud</h4>
                        <ul>
                            <li>Debes completar una evaluación médica si es requerida</li>
                            <li>Informa cualquier condición médica que pueda afectar tu capacidad para ejercitarte</li>
                            <li>Usa el equipo de manera segura y sigue las instrucciones del personal</li>
                            <li>El gimnasio no se hace responsable de lesiones resultantes del uso inadecuado del equipo</li>
                        </ul>
                        
                        <div class="warning-box">
                            <strong>
                                <ion-icon name="alert-circle-outline"></ion-icon>
                                Advertencia Importante
                            </strong>
                            <p>El ejercicio físico conlleva riesgos inherentes. Consulta con un médico antes de comenzar 
                            cualquier programa de ejercicios. Utiliza el equipo bajo tu propio riesgo.</p>
                        </div>
                        
                        <h4>4.3. Equipo y Instalaciones</h4>
                        <ul>
                            <li>El equipo debe usarse solo para su propósito previsto</li>
                            <li>Reporta cualquier equipo dañado o defectuoso al personal inmediatamente</li>
                            <li>No modifiques ni muevas el equipo sin autorización</li>
                            <li>El gimnasio se reserva el derecho de cerrar áreas para mantenimiento o eventos especiales</li>
                        </ul>
                    </div>
                    
                    <!-- Sección 5 -->
                    <div class="legal-section">
                        <h2 class="legal-section-title">
                            <ion-icon name="calendar-outline"></ion-icon>
                            5. Reservas y Cancelaciones
                        </h2>
                        <h4>5.1. Clases y Servicios</h4>
                        <ul>
                            <li>Las reservas para clases pueden requerirse con anticipación</li>
                            <li>Las cancelaciones deben realizarse al menos 2 horas antes de la clase</li>
                            <li>Las ausencias sin cancelar pueden resultar en restricciones de reserva</li>
                            <li>El gimnasio se reserva el derecho de cancelar o modificar clases</li>
                        </ul>
                        
                        <h4>5.2. Política de No-Show</h4>
                        <p>
                            Si no asistes a una clase reservada sin cancelar con anticipación, puedes ser sujeto a 
                            restricciones en futuras reservas o cargos adicionales según el tipo de membresía.
                        </p>
                    </div>
                    
                    <!-- Sección 6 -->
                    <div class="legal-section">
                        <h2 class="legal-section-title">
                            <ion-icon name="ban-outline"></ion-icon>
                            6. Prohibiciones
                        </h2>
                        <p>Está estrictamente prohibido:</p>
                        <ul>
                            <li>Permitir que otras personas usen tu membresía o tarjeta de acceso</li>
                            <li>Grabar videos o tomar fotografías sin autorización</li>
                            <li>Vender o promocionar productos o servicios dentro de las instalaciones</li>
                            <li>Usar el gimnasio para actividades comerciales no autorizadas</li>
                            <li>Traer animales (excepto animales de servicio)</li>
                            <li>Usar ropa inapropiada o que pueda dañar el equipo</li>
                            <li>Comportarse de manera que pueda intimidar o molestar a otros miembros</li>
                        </ul>
                    </div>
                    
                    <!-- Sección 7 -->
                    <div class="legal-section">
                        <h2 class="legal-section-title">
                            <ion-icon name="gavel-outline"></ion-icon>
                            7. Suspensión y Terminación
                        </h2>
                        <h4>7.1. Por Parte del Gimnasio</h4>
                        <p>Nos reservamos el derecho de suspender o terminar tu membresía inmediatamente si:</p>
                        <ul>
                            <li>Violas estos términos y condiciones</li>
                            <li>Realizas actividades ilegales en nuestras instalaciones</li>
                            <li>Pones en peligro la seguridad de otros miembros o personal</li>
                            <li>No cumples con tus obligaciones de pago</li>
                            <li>Proporcionas información falsa durante el registro</li>
                        </ul>
                        
                        <h4>7.2. Por Parte del Miembro</h4>
                        <p>Puedes cancelar tu membresía en cualquier momento siguiendo nuestro proceso de cancelación. 
                        Las cancelaciones están sujetas a los términos de tu contrato de membresía.</p>
                    </div>
                    
                    <!-- Sección 8 -->
                    <div class="legal-section">
                        <h2 class="legal-section-title">
                            <ion-icon name="shield-outline"></ion-icon>
                            8. Limitación de Responsabilidad
                        </h2>
                        <p>
                            <?php echo htmlspecialchars($gimnasio_nombre); ?> no será responsable de:
                        </p>
                        <ul>
                            <li>Lesiones personales que resulten del uso de nuestras instalaciones o equipo</li>
                            <li>Pérdida o daño de propiedad personal</li>
                            <li>Interrupciones en el servicio debido a mantenimiento, emergencias o circunstancias fuera de nuestro control</li>
                            <li>Daños indirectos, incidentales o consecuentes</li>
                        </ul>
                        
                        <div class="highlight-box">
                            <strong>
                                <ion-icon name="information-circle-outline"></ion-icon>
                                Nota Importante
                            </strong>
                            <p>Al utilizar nuestras instalaciones, aceptas que participas en actividades físicas bajo tu propio riesgo. 
                            Se recomienda encarecidamente tener un seguro de salud adecuado.</p>
                        </div>
                    </div>
                    
                    <!-- Sección 9 -->
                    <div class="legal-section">
                        <h2 class="legal-section-title">
                            <ion-icon name="copyright-outline"></ion-icon>
                            9. Propiedad Intelectual
                        </h2>
                        <p>
                            Todo el contenido de nuestro sitio web, incluyendo pero no limitado a textos, gráficos, logos, 
                            imágenes y software, es propiedad de <?php echo htmlspecialchars($gimnasio_nombre); ?> o sus licenciantes 
                            y está protegido por leyes de derechos de autor.
                        </p>
                        
                        <p>
                            No puedes reproducir, distribuir, modificar o crear obras derivadas de nuestro contenido sin 
                            nuestro consentimiento escrito previo.
                        </p>
                    </div>
                    
                    <!-- Sección 10 -->
                    <div class="legal-section">
                        <h2 class="legal-section-title">
                            <ion-icon name="scale-outline"></ion-icon>
                            10. Ley Aplicable y Jurisdicción
                        </h2>
                        <p>
                            Estos términos se rigen por las leyes de Colombia. Cualquier disputa que surja de o esté relacionada 
                            con estos términos será sometida a la jurisdicción exclusiva de los tribunales de 
                            <?php echo !empty($gimnasio_ciudad) ? htmlspecialchars($gimnasio_ciudad) : 'Colombia'; ?>.
                        </p>
                    </div>
                    
                    <!-- Contacto -->
                    <div class="contact-info-box">
                        <h4>
                            <ion-icon name="help-circle-outline"></ion-icon>
                            Información de Contacto
                        </h4>
                        <p style="margin-bottom: 20px;">Si tienes preguntas sobre estos Términos y Condiciones, contáctanos:</p>
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
                    
                    <div class="highlight-box" style="margin-top: 30px;">
                        <strong>
                            <ion-icon name="checkmark-circle-outline"></ion-icon>
                            Aceptación
                        </strong>
                        <p>Al utilizar nuestros servicios, confirmas que has leído, entendido y aceptado estos Términos y Condiciones 
                        de Uso. Si no estás de acuerdo con alguno de estos términos, por favor no utilices nuestros servicios.</p>
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
