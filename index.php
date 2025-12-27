<?php
/**
 * Landing Page - Functional Training Gym
 * Lee contenidos editables desde la base de datos si existen
 */

// Si hay PATH_INFO (algo después de index.php/), redirigir al 404
// Ejemplo: index.php/juan.php -> debe ir al 404
if (isset($_SERVER['PATH_INFO']) && !empty($_SERVER['PATH_INFO'])) {
    // Redirigir al 404 personalizado
    header('Location: /ftgym/dashboard/dist/dashboard/errors/error404.php', true, 404);
    exit;
}

require_once __DIR__ . '/database/config.php';
require_once __DIR__ . '/database/config_helpers.php';

// Cargar contenidos editables desde la base de datos
try {
    $db = getDB();
    $stmt = $db->query("SELECT section, element_id, content_type, content, image_path FROM landing_content");
    $contents = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Convertir a array asociativo para fácil acceso
    $contentMap = [];
    foreach ($contents as $content) {
        if (!isset($contentMap[$content['section']])) {
            $contentMap[$content['section']] = [];
        }
        // Para imágenes, usar image_path; para textos, usar content
        if ($content['content_type'] === 'image' && $content['image_path']) {
            // Normalizar ruta de imagen: agregar ./ si no empieza con / o ./
            $imagePath = $content['image_path'];
            if (!empty($imagePath) && $imagePath[0] !== '/' && substr($imagePath, 0, 2) !== './') {
                $imagePath = './' . $imagePath;
            }
            $contentMap[$content['section']][$content['element_id']] = $imagePath;
        } else {
            $contentMap[$content['section']][$content['element_id']] = $content['content'] ?? '';
        }
    }
} catch (Exception $e) {
    // Si hay error, usar valores por defecto
    error_log("Error al cargar contenidos editables: " . $e->getMessage());
    $contentMap = [];
}

// Función helper para obtener contenido editable
function getEditableContent($section, $element_id, $defaultValue, $contentMap) {
    return $contentMap[$section][$element_id] ?? $defaultValue;
}

// Cargar configuración de contacto
$contactConfig = [
    'direccion' => 'Calle Principal 123',
    'ciudad' => 'Bogotá',
    'telefono_1' => '+57 1 234 5678',
    'telefono_2' => null,
    'email_1' => 'info@ftgym.com',
    'email_2' => null,
    'horario_apertura' => '06:00',
    'horario_cierre' => '22:00',
    'dias_semana' => ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'],
    'horario_sabado_apertura' => '07:00',
    'horario_sabado_cierre' => '14:00',
    'horario_domingo_apertura' => '07:00',
    'horario_domingo_cierre' => '14:00'
];

try {
    $db = getDB();
    $config = obtenerConfiguracion($db);
    // Logo usado en landing (header y footer)
    $logoLanding = './favicon.svg';
    $faviconLanding = './favicon.svg'; // Favicon por defecto
    if (!empty($config['logo_empresa'])) {
        $relativeLogo = $config['logo_empresa'];
        if ($relativeLogo[0] !== '/' && substr($relativeLogo, 0, 2) !== './') {
            $relativeLogo = './' . $relativeLogo;
        }
        $logoPathFs = __DIR__ . '/' . ltrim($relativeLogo, './');
        if (file_exists($logoPathFs)) {
            $logoLanding = $relativeLogo;
            // Usar el mismo logo para el favicon
            $faviconLanding = $relativeLogo;
        }
    }
    
    $contactConfig['direccion'] = $config['gimnasio_direccion'] ?? $contactConfig['direccion'];
    $contactConfig['ciudad'] = $config['gimnasio_ciudad'] ?? $contactConfig['ciudad'];
    $contactConfig['telefono_1'] = $config['gimnasio_telefono'] ?? $contactConfig['telefono_1'];
    $contactConfig['telefono_2'] = $config['gimnasio_telefono_2'] ?? $contactConfig['telefono_2'];
    $contactConfig['email_1'] = $config['gimnasio_email'] ?? $contactConfig['email_1'];
    $contactConfig['email_2'] = $config['gimnasio_email_2'] ?? $contactConfig['email_2'];
    $contactConfig['horario_apertura'] = $config['horario_apertura'] ?? $contactConfig['horario_apertura'];
    $contactConfig['horario_cierre'] = $config['horario_cierre'] ?? $contactConfig['horario_cierre'];
    $contactConfig['dias_semana'] = $config['dias_semana'] ?? $contactConfig['dias_semana'];
    $contactConfig['horario_sabado_apertura'] = $config['horario_sabado_apertura'] ?? '07:00';
    $contactConfig['horario_sabado_cierre'] = $config['horario_sabado_cierre'] ?? '14:00';
    $contactConfig['horario_domingo_apertura'] = $config['horario_domingo_apertura'] ?? '07:00';
    $contactConfig['horario_domingo_cierre'] = $config['horario_domingo_cierre'] ?? '14:00';
    
    // Cargar configuración de redes sociales
    $redesSociales = [
        'facebook' => [
            'url' => $config['red_social_facebook_url'] ?? '',
            'activa' => $config['red_social_facebook_activa'] ?? false
        ],
        'instagram' => [
            'url' => $config['red_social_instagram_url'] ?? '',
            'activa' => $config['red_social_instagram_activa'] ?? false
        ],
        'tiktok' => [
            'url' => $config['red_social_tiktok_url'] ?? '',
            'activa' => $config['red_social_tiktok_activa'] ?? false
        ],
        'x' => [
            'url' => $config['red_social_x_url'] ?? '',
            'activa' => $config['red_social_x_activa'] ?? false
        ]
    ];
    
    // Construir dirección completa
    $contactConfig['direccion_completa'] = trim($contactConfig['ciudad'] . ' ' . $contactConfig['direccion']);
} catch (Exception $e) {
    // Usar valores por defecto si hay error
    $contactConfig['direccion_completa'] = trim($contactConfig['ciudad'] . ' ' . $contactConfig['direccion']);
    $logoLanding = './favicon.svg';
}
?>
<!DOCTYPE html>
<html lang="es">

<head>
  <meta charset="UTF-8">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Functional Training - Trabaja duro para una mejor vida</title>

  <!-- 
    - favicon
  -->
  <link rel="shortcut icon" href="<?php echo htmlspecialchars($faviconLanding ?? './favicon.svg'); ?>" type="<?php echo (pathinfo($faviconLanding ?? './favicon.svg', PATHINFO_EXTENSION) === 'svg' ? 'image/svg+xml' : 'image/x-icon'); ?>">

  <!-- 
    - custom css link
  -->
  <link rel="stylesheet" href="./assets/css/style.css">

  <!-- 
    - google font link
  -->
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link
    href="https://fonts.googleapis.com/css2?family=Catamaran:wght@600;700;800;900&family=Rubik:wght@400;500;800&display=swap"
    rel="stylesheet">

  <!-- 
    - preload images
  -->
  <link rel="preload" as="image" href="./assets/images/hero-banner.png">
  <link rel="preload" as="image" href="./assets/images/hero-circle-one.png">
  <link rel="preload" as="image" href="./assets/images/hero-circle-two.png">
  <link rel="preload" as="image" href="./assets/images/heart-rate.svg">
  <link rel="preload" as="image" href="./assets/images/calories.svg">

</head>

<body id="top">

  <!-- 
    - #HEADER
  -->

  <header class="header" data-header>
    <div class="container">

      <a href="index.php#home" class="logo">
        <img src="<?php echo htmlspecialchars($logoLanding ?? './favicon.svg'); ?>" alt="Functional Training" width="40" height="40" aria-hidden="true">

        <span class="span logo-full"><?php echo htmlspecialchars(getEditableContent('header', 'logo-text', 'Functional Training', $contentMap)); ?></span>
        <span class="span logo-short">FT GYM</span>
      </a>

      <nav class="navbar" data-navbar>

        <button class="nav-close-btn" aria-label="cerrar menú" data-nav-toggler>
          <ion-icon name="close-sharp" aria-hidden="true"></ion-icon>
        </button>

        <ul class="navbar-list">

          <li>
            <a href="#home" class="navbar-link active" data-nav-link>Inicio</a>
          </li>

          <li>
            <a href="#about" class="navbar-link" data-nav-link>Nosotros</a>
          </li>

          <li>
            <a href="#class" class="navbar-link" data-nav-link>Clases</a>
          </li>

          <li>
            <a href="#blog" class="navbar-link" data-nav-link>Blog</a>
          </li>

          <li>
            <a href="#planes" class="navbar-link" data-nav-link>Planes</a>
          </li>

          <li>
            <a href="#app" class="navbar-link" data-nav-link>App</a>
          </li>

          <li>
            <a href="productos.php" class="navbar-link" data-nav-link>Productos</a>
          </li>

        </ul>

      </nav>

      <a href="#planes" class="btn btn-secondary"><?php echo htmlspecialchars(getEditableContent('header', 'cta-button', 'Únete ahora', $contentMap)); ?></a>

      <button class="nav-open-btn" aria-label="abrir menú" data-nav-toggler>
        <span class="line"></span>
        <span class="line"></span>
        <span class="line"></span>
      </button>

    </div>
  </header>





  <main>
    <article>

      <!-- 
        - #HERO
      -->

      <section class="section hero bg-dark has-after has-bg-image" id="home" aria-label="inicio" data-section
        style="background-image: url('./assets/images/hero-bg.png')">
        <div class="container">

          <div class="hero-content">

            <p class="hero-subtitle">
              <strong class="strong"><?php echo htmlspecialchars(getEditableContent('hero', 'subtitle-strong', 'El Mejor', $contentMap)); ?></strong><?php echo htmlspecialchars(getEditableContent('hero', 'subtitle-text', 'Club de Fitness', $contentMap)); ?>
            </p>

            <h1 class="h1 hero-title"><?php echo htmlspecialchars(getEditableContent('hero', 'title', 'Trabaja duro para una mejor vida', $contentMap)); ?></h1>

            <p class="section-text">
              <?php echo htmlspecialchars(getEditableContent('hero', 'description', 'Entrena con planes personalizados, seguimiento de progreso y acceso rápido con código QR. Compra tus entradas con descuento desde nuestra app.', $contentMap)); ?>
            </p>

            <a href="#" class="btn btn-primary"><?php echo htmlspecialchars(getEditableContent('hero', 'cta-button', 'Comenzar', $contentMap)); ?></a>

          </div>

          <div class="hero-banner">

            <img src="<?php echo htmlspecialchars(getEditableContent('hero', 'banner-image', './assets/images/hero-banner.png', $contentMap)); ?>" width="660" height="753" alt="hero banner" class="w-100">

            <img src="./assets/images/hero-circle-one.png" width="666" height="666" aria-hidden="true" alt=""
              class="circle circle-1">
            <img src="./assets/images/hero-circle-two.png" width="666" height="666" aria-hidden="true" alt=""
              class="circle circle-2">

            <img src="./assets/images/heart-rate.svg" width="255" height="270" alt="ritmo cardíaco"
              class="abs-img abs-img-1">
            <img src="./assets/images/calories.svg" width="348" height="224" alt="calorías" class="abs-img abs-img-2">

          </div>

        </div>
      </section>





      <!-- 
        - #ABOUT
      -->

      <section class="section about" id="about" aria-label="nosotros">
        <div class="container">

          <div class="about-banner has-after">
            <img src="<?php echo htmlspecialchars(getEditableContent('about', 'banner-image', './assets/images/about-banner.png', $contentMap)); ?>" width="660" height="648" loading="lazy" alt="banner sobre nosotros"
              class="w-100">

            <img src="./assets/images/about-circle-one.png" width="660" height="534" loading="lazy" aria-hidden="true"
              alt="" class="circle circle-1">
            <img src="./assets/images/about-circle-two.png" width="660" height="534" loading="lazy" aria-hidden="true"
              alt="" class="circle circle-2">

            <img src="./assets/images/fitness.png" width="650" height="154" loading="lazy" alt="fitness"
              class="abs-img w-100">
          </div>

          <div class="about-content">

            <p class="section-subtitle"><?php echo htmlspecialchars(getEditableContent('about', 'subtitle', 'Nosotros', $contentMap)); ?></p>

            <h2 class="h2 section-title"><?php echo htmlspecialchars(getEditableContent('about', 'title', 'Bienvenido a Nuestro Gimnasio', $contentMap)); ?></h2>

            <p class="section-text">
              <?php echo htmlspecialchars(getEditableContent('about', 'text-1', 'Somos un equipo de entrenadores y profesionales del fitness comprometidos con tu bienestar. Diseñamos programas efectivos para todos los niveles, combinando fuerza, cardio y movilidad para que avances de forma segura.', $contentMap)); ?>
            </p>

            <p class="section-text">
              <?php echo htmlspecialchars(getEditableContent('about', 'text-2', 'Contamos con instalaciones modernas, clases guiadas y una app móvil con rutinas personalizadas, estadísticas y acceso con código QR. Nuestro objetivo es ayudarte a construir hábitos sostenibles y resultados reales.', $contentMap)); ?>
            </p>

            <div class="wrapper">

              <div class="about-coach">

                <figure class="coach-avatar">
                  <img src="<?php echo htmlspecialchars(getEditableContent('about', 'coach-image', './assets/images/about-coach.jpg', $contentMap)); ?>" width="65" height="65" loading="lazy" alt="Trainer">
                </figure>

                <div>
                  <h3 class="h3 coach-name"><?php echo htmlspecialchars(getEditableContent('about', 'coach-name', 'Denis Robinson', $contentMap)); ?></h3>

                  <p class="coach-title"><?php echo htmlspecialchars(getEditableContent('about', 'coach-title', 'Nuestro Entrenador', $contentMap)); ?></p>
                </div>

              </div>

              <a href="#" class="btn btn-primary"><?php echo htmlspecialchars(getEditableContent('about', 'cta-button', 'Explorar más', $contentMap)); ?></a>

            </div>

          </div>

        </div>
      </section>





      <!-- 
        - #VIDEO
      -->

      <section class="section video" aria-label="video">
        <div class="container">

          <div class="video-card has-before has-bg-image"
            style="background-image: url('<?php echo htmlspecialchars(getEditableContent('video', 'background-image', './assets/images/video-banner.jpg', $contentMap)); ?>')">

            <h2 class="h2 card-title"><?php echo htmlspecialchars(getEditableContent('video', 'title', 'Explora la Vida Fitness', $contentMap)); ?></h2>

            <button class="play-btn" aria-label="reproducir video">
              <ion-icon name="play-sharp" aria-hidden="true"></ion-icon>
            </button>

            <a href="#" class="btn-link has-before"><?php echo htmlspecialchars(getEditableContent('video', 'link-text', 'Ver más', $contentMap)); ?></a>

          </div>

        </div>
      </section>





      <!-- 
        - #CLASS
      -->

      <section class="section class bg-dark has-bg-image" id="class" aria-label="clases"
        style="background-image: url('./assets/images/classes-bg.png')">
        <div class="container">

          <p class="section-subtitle"><?php echo htmlspecialchars(getEditableContent('class', 'subtitle', 'Nuestras Clases', $contentMap)); ?></p>

          <h2 class="h2 section-title text-center"><?php echo htmlspecialchars(getEditableContent('class', 'title', 'Clases de Fitness para Cada Objetivo', $contentMap)); ?></h2>

          <ul class="class-list has-scrollbar">

            <li class="scrollbar-item">
              <div class="class-card">

                <figure class="card-banner img-holder" style="--width: 416; --height: 240;">
                  <img src="<?php echo htmlspecialchars(getEditableContent('class', 'class-1-image', './assets/images/class-1.jpg', $contentMap)); ?>" width="416" height="240" loading="lazy" alt="Levantamiento de pesas"
                    class="img-cover">
                </figure>

                <div class="card-content">

                  <div class="title-wrapper">
                    <img src="./assets/images/class-icon-1.png" width="52" height="52" aria-hidden="true" alt=""
                      class="title-icon">

                    <h3 class="h3">
                      <a href="#" class="card-title"><?php echo htmlspecialchars(getEditableContent('class', 'class-1-title', 'Levantamiento de Pesas', $contentMap)); ?></a>
                    </h3>
                  </div>

                  <p class="card-text">
                    <?php echo htmlspecialchars(getEditableContent('class', 'class-1-text', 'Mejora tu fuerza y técnica con programas progresivos y acompañamiento de entrenador. Ideal para ganar masa muscular y estabilidad.', $contentMap)); ?>
                  </p>

                  

                </div>

              </div>
            </li>

            <li class="scrollbar-item">
              <div class="class-card">

                <figure class="card-banner img-holder" style="--width: 416; --height: 240;">
                  <img src="<?php echo htmlspecialchars(getEditableContent('class', 'class-2-image', './assets/images/class-2.jpg', $contentMap)); ?>" width="416" height="240" loading="lazy" alt="Cardio y Fuerza"
                    class="img-cover">
                </figure>

                <div class="card-content">

                  <div class="title-wrapper">
                    <img src="./assets/images/class-icon-2.png" width="52" height="52" aria-hidden="true" alt=""
                      class="title-icon">

                    <h3 class="h3">
                      <a href="#" class="card-title"><?php echo htmlspecialchars(getEditableContent('class', 'class-2-title', 'Cardio y Fuerza', $contentMap)); ?></a>
                    </h3>
                  </div>

                  <p class="card-text">
                    <?php echo htmlspecialchars(getEditableContent('class', 'class-2-text', 'Circuitos funcionales y HIIT para aumentar resistencia, quemar grasa y mejorar tu condición física general en poco tiempo.', $contentMap)); ?>
                  </p>

          

                </div>

              </div>
            </li>

            <li class="scrollbar-item">
              <div class="class-card">

                <figure class="card-banner img-holder" style="--width: 416; --height: 240;">
                  <img src="<?php echo htmlspecialchars(getEditableContent('class', 'class-3-image', './assets/images/class-3.jpg', $contentMap)); ?>" width="416" height="240" loading="lazy" alt="Power Yoga"
                    class="img-cover">
                </figure>

                <div class="card-content">

                  <div class="title-wrapper">
                    <img src="./assets/images/class-icon-3.png" width="52" height="52" aria-hidden="true" alt=""
                      class="title-icon">

                    <h3 class="h3">
                      <a href="#" class="card-title"><?php echo htmlspecialchars(getEditableContent('class', 'class-3-title', 'Power Yoga', $contentMap)); ?></a>
                    </h3>
                  </div>

                  <p class="card-text">
                    <?php echo htmlspecialchars(getEditableContent('class', 'class-3-text', 'Combina respiración y movimiento para ganar movilidad, fuerza y control corporal. Perfecto para reducir estrés y prevenir lesiones.', $contentMap)); ?>
                  </p>

                </div>

              </div>
            </li>

            <li class="scrollbar-item">
              <div class="class-card">

                <figure class="card-banner img-holder" style="--width: 416; --height: 240;">
                  <img src="<?php echo htmlspecialchars(getEditableContent('class', 'class-4-image', './assets/images/class-4.jpg', $contentMap)); ?>" width="416" height="240" loading="lazy" alt="El Paquete Fitness"
                    class="img-cover">
                </figure>

                <div class="card-content">

                  <div class="title-wrapper">
                    <img src="./assets/images/class-icon-4.png" width="52" height="52" aria-hidden="true" alt=""
                      class="title-icon">

                    <h3 class="h3">
                      <a href="#" class="card-title"><?php echo htmlspecialchars(getEditableContent('class', 'class-4-title', 'El Paquete Fitness', $contentMap)); ?></a>
                    </h3>
                  </div>

                  <p class="card-text">
                    <?php echo htmlspecialchars(getEditableContent('class', 'class-4-text', 'Un plan integral que equilibra pesas, cardio y core. Optimiza tu tiempo y acelera resultados de forma segura y sostenible.', $contentMap)); ?>
                  </p>

                </div>

              </div>
            </li>

          </ul>

        </div>
      </section>





      <!-- 
        - #BLOG
      -->

      <section class="section blog" id="blog" aria-label="blog">
        <div class="container">

          <p class="section-subtitle"><?php echo htmlspecialchars(getEditableContent('blog', 'subtitle', 'Nuestras Noticias', $contentMap)); ?></p>
          
          <h2 class="h2 section-title text-center"><?php echo htmlspecialchars(getEditableContent('blog', 'title', 'Últimas Publicaciones del Blog', $contentMap)); ?></h2>

          <ul class="blog-list has-scrollbar">

            <li class="scrollbar-item">
              <div class="blog-card">

                <div class="card-banner img-holder" style="--width: 440; --height: 270;">
                  <img src="<?php echo htmlspecialchars(getEditableContent('blog', 'blog-1-image', './assets/images/blog-1.jpg', $contentMap)); ?>" width="440" height="270" loading="lazy"
                    alt="Nueva zona de peso libre y máquinas" class="img-cover">
                  
                  <time class="card-meta" datetime="<?php echo htmlspecialchars(getEditableContent('blog', 'blog-1-date', '2025-09-15', $contentMap)); ?>"><?php echo htmlspecialchars(getEditableContent('blog', 'blog-1-date', '15 Sep 2025', $contentMap)); ?></time>
                </div>
                
                <div class="card-content">
                  
                  <h3 class="h3">
                    <a href="#" class="card-title"><?php echo htmlspecialchars(getEditableContent('blog', 'blog-1-title', 'Renovamos el área de fuerza: más discos, racks y máquinas', $contentMap)); ?></a>
                  </h3>
                  
                  <p class="card-text">
                    <?php echo htmlspecialchars(getEditableContent('blog', 'blog-1-text', 'Ampliamos la zona de peso libre y sumamos máquinas de última generación para que entrenes con más comodidad y seguridad en tus rutinas de fuerza e hipertrofia.', $contentMap)); ?>
                  </p>
                  
                </div>

              </div>
            </li>

            <li class="scrollbar-item">
              <div class="blog-card">

                <div class="card-banner img-holder" style="--width: 440; --height: 270;">
                  <img src="<?php echo htmlspecialchars(getEditableContent('blog', 'blog-2-image', './assets/images/blog-2.jpg', $contentMap)); ?>" width="440" height="270" loading="lazy"
                    alt="Lanzamiento de la app móvil del gimnasio" class="img-cover">
                  
                  <time class="card-meta" datetime="<?php echo htmlspecialchars(getEditableContent('blog', 'blog-2-date', '2025-08-28', $contentMap)); ?>"><?php echo htmlspecialchars(getEditableContent('blog', 'blog-2-date', '28 Ago 2025', $contentMap)); ?></time>
                </div>
                
                <div class="card-content">
                  
                  <h3 class="h3">
                    <a href="#" class="card-title"><?php echo htmlspecialchars(getEditableContent('blog', 'blog-2-title', 'Presentamos nuestra app: rutinas inteligentes y acceso con QR', $contentMap)); ?></a>
                  </h3>
                  
                  <p class="card-text">
                    <?php echo htmlspecialchars(getEditableContent('blog', 'blog-2-text', 'Descarga la app para obtener rutinas personalizadas con IA, registrar tus entrenamientos y entrar al gym con código QR. Además, obtén 10% de descuento en tus compras.', $contentMap)); ?>
                  </p>
                  
                  
                </div>

              </div>
            </li>

            <li class="scrollbar-item">
              <div class="blog-card">

                <div class="card-banner img-holder" style="--width: 440; --height: 270;">
                  <img src="<?php echo htmlspecialchars(getEditableContent('blog', 'blog-3-image', './assets/images/blog-3.jpg', $contentMap)); ?>" width="440" height="270" loading="lazy"
                    alt="Competencia interna y jornada de puertas abiertas" class="img-cover">
                  
                  <time class="card-meta" datetime="<?php echo htmlspecialchars(getEditableContent('blog', 'blog-3-date', '2025-07-12', $contentMap)); ?>"><?php echo htmlspecialchars(getEditableContent('blog', 'blog-3-date', '12 Jul 2025', $contentMap)); ?></time>
                </div>
                
                <div class="card-content">
                  
                  <h3 class="h3">
                    <a href="#" class="card-title"><?php echo htmlspecialchars(getEditableContent('blog', 'blog-3-title', 'Evento especial: competencia interna y puertas abiertas', $contentMap)); ?></a>
                  </h3>
                  
                  <p class="card-text">
                    <?php echo htmlspecialchars(getEditableContent('blog', 'blog-3-text', 'Te invitamos a participar en nuestra competencia de fuerza y clases abiertas. Habrá premios, coaching en vivo y descuentos exclusivos para nuevos miembros.', $contentMap)); ?>
                  </p>
                  
                </div>

              </div>
            </li>

          </ul>

        </div>
      </section>




      <!-- 
        - #PLANES
      -->


      <section class="section bg-dark has-bg-image text-center" id="planes" aria-label="planes"
      style="background-image: url('./assets/images/classes-bg.png')">
          <div class="container">
          <p class="section-subtitle"><?php echo htmlspecialchars(getEditableContent('planes', 'subtitle', 'Nuestros Planes', $contentMap)); ?></p>

          <h2 class="h2 section-title text-center"><?php echo htmlspecialchars(getEditableContent('planes', 'title', 'Elige tu plan', $contentMap)); ?></h2>

          <div id="planes-loading" class="text-center" style="padding: 40px; color: var(--white);">
            <p>Cargando planes...</p>
                </div>

          <ul class="pricing-list has-scrollbar" id="pricing-list" data-carousel-3d style="display: none;">
            <!-- Los planes se cargarán aquí dinámicamente -->
                </ul>

          <div id="planes-empty" class="text-center" style="display: none; padding: 40px; color: var(--white);">
            <p>No hay planes disponibles en este momento.</p>
                </div>

          <!-- Botón flecha para scroll en móvil -->
          <button class="pricing-scroll-btn" aria-label="Siguiente tarjeta" id="pricing-scroll-btn">
            <ion-icon name="chevron-forward-sharp" aria-hidden="true"></ion-icon>
          </button>

          <p class="section-text" style="margin-top: 16px;">
            <?php echo htmlspecialchars(getEditableContent('planes', 'footer-text', 'El descuento aplica al comprar desde la aplicación móvil. Disponible para Android y iPhone.', $contentMap)); ?>
          </p>

        </div>
      </section>




      <!-- 
        - #APP MOVIL
      -->

      <section class="section text-center" id="app" aria-label="aplicación móvil">
        <div class="container">

          <p class="section-subtitle"><?php echo htmlspecialchars(getEditableContent('app', 'subtitle', 'Aplicación Móvil', $contentMap)); ?></p>

          <h2 class="h2 section-title"><?php echo htmlspecialchars(getEditableContent('app', 'title', 'Tu gimnasio en el bolsillo', $contentMap)); ?></h2>

          <?php 
          // Obtener el descuento de la configuración
          $descuentoApp = getAppDescuento();
          $textoDescripcion = getEditableContent('app', 'description', 'Compra tu entrada con 10% de descuento desde la app. Disponible para Android y iPhone.', $contentMap);
          // Reemplazar el placeholder {DESCUENTO} con el valor real de la configuración
          $textoDescripcion = str_replace('{DESCUENTO}', number_format($descuentoApp, 0), $textoDescripcion);
          // Si el texto no tiene placeholder pero tiene un porcentaje hardcodeado, reemplazarlo
          if (strpos($textoDescripcion, '{DESCUENTO}') === false && preg_match('/(\d+)%/', $textoDescripcion, $matches)) {
            $textoDescripcion = preg_replace('/(\d+)%/', number_format($descuentoApp, 0) . '%', $textoDescripcion);
          }
          ?>
          <p class="section-text"><?php echo htmlspecialchars($textoDescripcion); ?></p>

          <ul class="blog-list has-scrollbar">

            <li class="scrollbar-item">
              <div class="blog-card">
                <div class="card-content">
                  <h3 class="h3"><a href="#" class="card-title">Asesor personal de IA</a></h3>
                  <p class="card-text">Resuelve dudas y recibe recomendaciones al instante.</p>
                </div>
              </div>
            </li>

            <li class="scrollbar-item">
              <div class="blog-card">
                <div class="card-content">
                  <h3 class="h3"><a href="#" class="card-title">Rutinas personalizadas</a></h3>
                  <p class="card-text">Planes de entrenamiento adaptados a tus objetivos.</p>
                </div>
              </div>
            </li>

            <li class="scrollbar-item">
              <div class="blog-card">
                <div class="card-content">
                  <h3 class="h3"><a href="#" class="card-title">Ingreso con código QR</a></h3>
                  <p class="card-text">Acceso rápido y seguro a las instalaciones.</p>
                </div>
              </div>
            </li>

            <li class="scrollbar-item">
              <div class="blog-card">
                <div class="card-content">
                  <h3 class="h3"><a href="#" class="card-title">Estadísticas y progreso</a></h3>
                  <p class="card-text">Controla tus ejercicios, tiempos, PRs y evolución.</p>
                </div>
              </div>
            </li>

            <li class="scrollbar-item">
              <div class="blog-card">
                <div class="card-content">
                  <h3 class="h3"><a href="#" class="card-title">Red social interna</a></h3>
                  <p class="card-text">Comparte logros y conéctate con la comunidad.</p>
                </div>
              </div>
            </li>

            <li class="scrollbar-item">
              <div class="blog-card">
                <div class="card-content">
                  <h3 class="h3"><a href="#" class="card-title">Calendario de eventos</a></h3>
                  <p class="card-text">Clases especiales, competencias y talleres del gym.</p>
                </div>
              </div>
            </li>

            <li class="scrollbar-item">
              <div class="blog-card">
                <div class="card-content">
                  <h3 class="h3"><a href="#" class="card-title">Tienda del gym</a></h3>
                  <p class="card-text">Compra productos oficiales y suplementos.</p>
                </div>
              </div>
            </li>

          </ul>

          <div class="wrapper" style="margin-top: 30px; display: flex; gap: 15px; flex-wrap: wrap; justify-content: center;">
            <a href="#" class="btn btn-store btn-android" aria-label="Descargar en Google Play">
              <ion-icon name="logo-android" aria-hidden="true"></ion-icon>
              <span class="store-text">
                <small>Disponible en</small>
                <strong>Google Play</strong>
              </span>
            </a>
            <a href="#" class="btn btn-store btn-ios" aria-label="Descargar en App Store">
              <ion-icon name="logo-apple" aria-hidden="true"></ion-icon>
              <span class="store-text">
                <small>Descargar en</small>
                <strong>App Store</strong>
              </span>
            </a>
          </div>

        </div>
      </section>

    </article>
  </main>





  <!-- 
    - #FOOTER
  -->

  <footer class="footer">

    <div class="section footer-top bg-dark has-bg-image" style="background-image: url('./assets/images/footer-bg.png')">
      <div class="container">

        <div class="footer-brand">

          <a href="index.html#home" class="logo">
            <img src="<?php echo htmlspecialchars($logoLanding ?? './favicon.svg'); ?>" alt="Functional Training" width="40" height="40" aria-hidden="true">

            <span class="span">Functional Training</span>
          </a>

          <p class="footer-brand-text">
            Etiam suscipit fringilla ullamcorper sed malesuada urna nec odio.
          </p>

          <div class="wrapper">

            <img src="./assets/images/footer-clock.png" width="34" height="34" loading="lazy" alt="Reloj">

            <ul class="footer-brand-list">

              <li>
                <p class="footer-brand-title"><?php 
                  // Filtrar días de semana (excluir sábado y domingo si tienen horarios especiales)
                  $diasSemana = $contactConfig['dias_semana'] ?? [];
                  $tieneSabadoEspecial = !empty($contactConfig['horario_sabado_apertura']) && !empty($contactConfig['horario_sabado_cierre']);
                  $tieneDomingoEspecial = !empty($contactConfig['horario_domingo_apertura']) && !empty($contactConfig['horario_domingo_cierre']);
                  
                  $diasFiltrados = array_filter($diasSemana, function($dia) use ($tieneSabadoEspecial, $tieneDomingoEspecial) {
                    if ($tieneSabadoEspecial && $dia === 'Sábado') return false;
                    if ($tieneDomingoEspecial && $dia === 'Domingo') return false;
                    return true;
                  });
                  
                  $diasFiltrados = array_values($diasFiltrados); // Reindexar
                  
                  if (count($diasFiltrados) > 0) {
                    $titulo = $diasFiltrados[0];
                    if (count($diasFiltrados) > 1) {
                      $titulo .= ' - ' . end($diasFiltrados);
                    }
                    echo htmlspecialchars($titulo);
                  } else {
                    echo htmlspecialchars('Lunes - Viernes');
                  }
                ?></p>

                <p><?php 
                  // Siempre usar la configuración del admin para el primer horario
                  // Formatear hora de apertura
                  $horaAperturaRaw = $contactConfig['horario_apertura'] ?? '06:00';
                  $horaAperturaParts = explode(':', $horaAperturaRaw);
                  $horaAperturaH = (int)$horaAperturaParts[0];
                  $horaAperturaM = isset($horaAperturaParts[1]) ? (int)$horaAperturaParts[1] : 0;
                  $horaApertura = date('g:ia', mktime($horaAperturaH, $horaAperturaM, 0));
                  
                  // Formatear hora de cierre
                  $horaCierreRaw = $contactConfig['horario_cierre'] ?? '22:00';
                  $horaCierreParts = explode(':', $horaCierreRaw);
                  $horaCierreH = (int)$horaCierreParts[0];
                  $horaCierreM = isset($horaCierreParts[1]) ? (int)$horaCierreParts[1] : 0;
                  $horaCierre = date('g:ia', mktime($horaCierreH, $horaCierreM, 0));
                  
                  $scheduleTime1 = $horaApertura . ' - ' . $horaCierre;
                  echo htmlspecialchars($scheduleTime1);
                ?></p>
              </li>

              <?php
              // Mostrar horario de sábado solo si está marcado en días de semana y tiene horario configurado
              $diasSemana = $contactConfig['dias_semana'] ?? [];
              $sabadoMarcado = in_array('Sábado', $diasSemana);
              $sabadoApertura = $contactConfig['horario_sabado_apertura'] ?? null;
              $sabadoCierre = $contactConfig['horario_sabado_cierre'] ?? null;
              
              if ($sabadoMarcado && $sabadoApertura && $sabadoCierre) {
                $sabadoAperturaParts = explode(':', $sabadoApertura);
                $sabadoAperturaH = (int)$sabadoAperturaParts[0];
                $sabadoAperturaM = isset($sabadoAperturaParts[1]) ? (int)$sabadoAperturaParts[1] : 0;
                $sabadoAperturaFormatted = date('g:ia', mktime($sabadoAperturaH, $sabadoAperturaM, 0));
                
                $sabadoCierreParts = explode(':', $sabadoCierre);
                $sabadoCierreH = (int)$sabadoCierreParts[0];
                $sabadoCierreM = isset($sabadoCierreParts[1]) ? (int)$sabadoCierreParts[1] : 0;
                $sabadoCierreFormatted = date('g:ia', mktime($sabadoCierreH, $sabadoCierreM, 0));
              ?>
              <li>
                <p class="footer-brand-title">Sábado</p>
                <p><?php echo htmlspecialchars($sabadoAperturaFormatted . ' - ' . $sabadoCierreFormatted); ?></p>
              </li>
              <?php } ?>
              
              <?php
              // Mostrar horario de domingo solo si está marcado en días de semana y tiene horario configurado
              $domingoMarcado = in_array('Domingo', $diasSemana);
              $domingoApertura = $contactConfig['horario_domingo_apertura'] ?? null;
              $domingoCierre = $contactConfig['horario_domingo_cierre'] ?? null;
              
              if ($domingoMarcado && $domingoApertura && $domingoCierre) {
                $domingoAperturaParts = explode(':', $domingoApertura);
                $domingoAperturaH = (int)$domingoAperturaParts[0];
                $domingoAperturaM = isset($domingoAperturaParts[1]) ? (int)$domingoAperturaParts[1] : 0;
                $domingoAperturaFormatted = date('g:ia', mktime($domingoAperturaH, $domingoAperturaM, 0));
                
                $domingoCierreParts = explode(':', $domingoCierre);
                $domingoCierreH = (int)$domingoCierreParts[0];
                $domingoCierreM = isset($domingoCierreParts[1]) ? (int)$domingoCierreParts[1] : 0;
                $domingoCierreFormatted = date('g:ia', mktime($domingoCierreH, $domingoCierreM, 0));
              ?>
              <li>
                <p class="footer-brand-title">Domingo</p>
                <p><?php echo htmlspecialchars($domingoAperturaFormatted . ' - ' . $domingoCierreFormatted); ?></p>
              </li>
              <?php } ?>

            </ul>

          </div>

        </div>

        <ul class="footer-list">

          <li>
            <p class="footer-list-title has-before">Nuestros Enlaces</p>
          </li>

          <li>
            <a href="#home" class="footer-link">Inicio</a>
          </li>

          <li>
            <a href="#about" class="footer-link">Nosotros</a>
          </li>

          <li>
            <a href="#class" class="footer-link">Clases</a>
          </li>

          <li>
            <a href="#blog" class="footer-link">Blog</a>
          </li>

          <li>
            <a href="#planes" class="footer-link">Planes</a>
          </li>

          <li>
            <a href="#app" class="footer-link">App</a>
          </li>

          <li>
            <a href="productos.php" class="footer-link">Productos</a>
          </li>

        </ul>

        <ul class="footer-list">

          <li>
            <p class="footer-list-title has-before">Contáctanos</p>
          </li>

          <li class="footer-list-item">
            <div class="icon">
              <ion-icon name="location" aria-hidden="true"></ion-icon>
            </div>

            <address class="address footer-link">
              <?php echo htmlspecialchars($contactConfig['direccion_completa']); ?>
            </address>
          </li>

          <li class="footer-list-item">
            <div class="icon">
              <ion-icon name="call" aria-hidden="true"></ion-icon>
            </div>

            <div>
              <?php 
              $tel1 = preg_replace('/[^0-9+]/', '', $contactConfig['telefono_1']);
              $tel1Display = $contactConfig['telefono_1'];
              ?>
              <a href="tel:<?php echo htmlspecialchars($tel1); ?>" class="footer-link"><?php echo htmlspecialchars($tel1Display); ?></a>

              <?php if ($contactConfig['telefono_2']): 
                $tel2 = preg_replace('/[^0-9+]/', '', $contactConfig['telefono_2']);
                $tel2Display = $contactConfig['telefono_2'];
              ?>
              <a href="tel:<?php echo htmlspecialchars($tel2); ?>" class="footer-link"><?php echo htmlspecialchars($tel2Display); ?></a>
              <?php endif; ?>
            </div>
          </li>

          <li class="footer-list-item">
            <div class="icon">
              <ion-icon name="mail" aria-hidden="true"></ion-icon>
            </div>

            <div>
              <a href="mailto:<?php echo htmlspecialchars($contactConfig['email_1']); ?>" class="footer-link"><?php echo htmlspecialchars($contactConfig['email_1']); ?></a>

              <?php if ($contactConfig['email_2']): ?>
              <a href="mailto:<?php echo htmlspecialchars($contactConfig['email_2']); ?>" class="footer-link"><?php echo htmlspecialchars($contactConfig['email_2']); ?></a>
              <?php endif; ?>
            </div>
          </li>

        </ul>

        <ul class="footer-list">

          <li>
            <p class="footer-list-title has-before">Nuestro Boletín</p>
          </li>

          <li>
            <form action="" class="footer-form">
              <input type="email" name="email_address" aria-label="correo" placeholder="Correo electrónico" required
                class="input-field">

              <button type="submit" class="btn btn-primary" aria-label="Enviar">
                <ion-icon name="chevron-forward-sharp" aria-hidden="true"></ion-icon>
              </button>
            </form>
          </li>

          <li>
            <ul class="social-list">
              <?php if ($redesSociales['facebook']['activa'] && !empty($redesSociales['facebook']['url'])): ?>
              <li>
                <a href="<?php echo htmlspecialchars($redesSociales['facebook']['url']); ?>" target="_blank" rel="noopener noreferrer" class="social-link" aria-label="Facebook">
                  <ion-icon name="logo-facebook"></ion-icon>
                </a>
              </li>
              <?php endif; ?>

              <?php if ($redesSociales['instagram']['activa'] && !empty($redesSociales['instagram']['url'])): ?>
              <li>
                <a href="<?php echo htmlspecialchars($redesSociales['instagram']['url']); ?>" target="_blank" rel="noopener noreferrer" class="social-link" aria-label="Instagram">
                  <ion-icon name="logo-instagram"></ion-icon>
                </a>
              </li>
              <?php endif; ?>

              <?php if ($redesSociales['tiktok']['activa'] && !empty($redesSociales['tiktok']['url'])): ?>
              <li>
                <a href="<?php echo htmlspecialchars($redesSociales['tiktok']['url']); ?>" target="_blank" rel="noopener noreferrer" class="social-link" aria-label="TikTok">
                  <ion-icon name="logo-tiktok"></ion-icon>
                </a>
              </li>
              <?php endif; ?>

              <?php if ($redesSociales['x']['activa'] && !empty($redesSociales['x']['url'])): ?>
              <li>
                <a href="<?php echo htmlspecialchars($redesSociales['x']['url']); ?>" target="_blank" rel="noopener noreferrer" class="social-link" aria-label="X (Twitter)">
                  <ion-icon name="logo-twitter"></ion-icon>
                </a>
              </li>
              <?php endif; ?>
            </ul>
          </li>

        </ul>

      </div>
    </div>

    <div class="footer-bottom">
      <div class="container">

        <p class="copyright">
          &copy; 2025 Functional Training. Todos los derechos reservados por <a href="https://www.linkedin.com/in/joellizarazo/" class="copyright-link">Joel Lizarazo</a>
        </p>

        <ul class="footer-bottom-list">

          <li>
            <a href="privacy-policy.php" class="footer-bottom-link has-before">Política de Privacidad</a>
          </li>

          <li>
            <a href="terms-of-use.php" class="footer-bottom-link has-before">Términos y Condiciones</a>
          </li>

        </ul>

      </div>
    </div>

  </footer>





  <!-- 
    - #WHATSAPP BUTTON
  -->

  <a href="https://wa.me/573185312833?text=Hola,%20me%20interesa%20saber%20más%20sobre%20Functional%20Training" 
     target="_blank" 
     rel="noopener noreferrer" 
     class="whatsapp-btn" 
     aria-label="Contáctanos por WhatsApp">
    <ion-icon name="logo-whatsapp" aria-hidden="true"></ion-icon>
  </a>


  <!-- 
    - #BACK TO TOP
  -->

  <a href="#top" class="back-top-btn" aria-label="volver arriba" data-back-top-btn>
    <ion-icon name="caret-up-sharp" aria-hidden="true"></ion-icon>
  </a>





  <!-- 
    - custom js link
  -->
  <script src="./assets/js/script.js" defer></script>

  <!-- 
    - Script para cargar planes dinámicamente
  -->
  <script>
    // Función para escapar HTML (prevenir XSS)
    function escapeHtml(text) {
      if (!text) return '';
      const div = document.createElement('div');
      div.textContent = text;
      return div.innerHTML;
    }

    // Función para formatear precio
    function formatPrice(precio) {
      return '$' + precio.toLocaleString('es-CO');
    }

    // Función para cargar planes desde la API
    async function loadPlans() {
      const loadingEl = document.getElementById('planes-loading');
      const listEl = document.getElementById('pricing-list');
      const emptyEl = document.getElementById('planes-empty');

      try {
        const apiUrl = './api/get_public_plans.php';
        console.log('Cargando planes desde:', apiUrl);
        
        const response = await fetch(apiUrl);
        
        if (!response.ok) {
          throw new Error(`Error HTTP: ${response.status} ${response.statusText}`);
        }
        
        const responseText = await response.text();
        console.log('Respuesta de la API:', responseText);
        
        let data;
        try {
          data = JSON.parse(responseText);
        } catch (parseError) {
          console.error('Error al parsear JSON:', parseError);
          throw new Error('La respuesta del servidor no es válida JSON');
        }

        loadingEl.style.display = 'none';

        if (data.success && data.planes && data.planes.length > 0) {
          listEl.innerHTML = '';
          listEl.style.display = '';

          const planesCount = data.planes.length;
          
          // Agregar clase para carrusel cuando hay más de 3 tarjetas
          const container = document.querySelector('#planes .container');
          if (planesCount > 3) {
            listEl.classList.add('has-many-cards');
            if (container) {
              container.classList.add('has-many-cards');
            }
          } else {
            listEl.classList.remove('has-many-cards');
            if (container) {
              container.classList.remove('has-many-cards');
            }
          }

          // Determinar qué plan marcar como "recommended" (la tercera tarjeta si hay 3 o más, o el último disponible si hay menos)
          const recommendedIndex = planesCount >= 3 
            ? 2  // Siempre la tercera tarjeta (índice 2)
            : (planesCount === 2 ? 1 : 0);

          data.planes.forEach((plan, index) => {
            const li = document.createElement('li');
            li.className = 'scrollbar-item';
            
            const isRecommended = index === recommendedIndex;
            const discountText = plan.descuento_porcentaje > 0 
              ? `${plan.descuento_porcentaje}% con la app` 
              : 'Disponible en la app';
            
            li.innerHTML = `
              <div class="pricing-card ${isRecommended ? 'recommended' : ''}">
                ${isRecommended ? '<span class="ribbon">Destacado</span>' : ''}
                <div class="pricing-header">
                  <h3 class="plan-name">${escapeHtml(plan.nombre || 'Plan')}</h3>
                  <p class="price">
                    <span class="currency"></span>
                    ${plan.precio_formateado || formatPrice(plan.precio || 0)} 
                    <span class="period">${plan.periodo || ''}</span>
                  </p>
                  ${plan.descuento_porcentaje > 0 ? `<span class="discount-badge">${discountText}</span>` : ''}
                </div>
                <ul class="features">
                  <li class="feature-item">
                    <ion-icon name="checkmark-circle"></ion-icon> 
                    Acceso ilimitado al gimnasio
                  </li>
                  <li class="feature-item">
                    <ion-icon name="checkmark-circle"></ion-icon> 
                    App con IA, rutinas y estadísticas
                  </li>
                  <li class="feature-item">
                    <ion-icon name="checkmark-circle"></ion-icon> 
                    Ingreso rápido con código QR
                  </li>
                  ${plan.descripcion ? `<li class="feature-item"><ion-icon name="checkmark-circle"></ion-icon> ${escapeHtml(plan.descripcion)}</li>` : ''}
                </ul>
                <a href="#app" class="btn btn-primary" aria-label="Adquirir plan ${escapeHtml(plan.nombre)}">
                  Adquirir
                </a>
              </div>
            `;
            
            listEl.appendChild(li);
          });

          emptyEl.style.display = 'none';
          
          // Reinicializar el carrusel después de cargar los planes
          setTimeout(() => {
            const carouselList = document.querySelector("[data-carousel-3d]");
            if (carouselList) {
              // Disparar eventos para que el script.js actualice el carrusel
              window.dispatchEvent(new Event('resize'));
              
              // Si existe la función updateCarouselPositions, llamarla directamente
              if (typeof updateCarouselPositions === 'function') {
                updateCarouselPositions(carouselList);
              }
              
              // Reconfigurar el scroll del carrusel
              carouselList.addEventListener("scroll", function() {
                if (typeof updateCarouselPositions === 'function') {
                  window.requestAnimationFrame(() => updateCarouselPositions(carouselList));
                }
              });
              
              // Reconfigurar el botón de scroll si existe
              const pricingScrollBtn = document.querySelector(".pricing-scroll-btn");
              const pricingList = document.querySelector("#planes .pricing-list");
              const planesContainer = document.querySelector("#planes .container");
              
              if (pricingScrollBtn && pricingList && planesContainer) {
                // Remover listeners anteriores si existen
                const newCheckScrollEnd = function() {
                  const isAtEnd = pricingList.scrollWidth - pricingList.scrollLeft <= pricingList.clientWidth + 10;
                  if (isAtEnd) {
                    planesContainer.classList.add("scrolled-to-end");
                  } else {
                    planesContainer.classList.remove("scrolled-to-end");
                  }
                };
                
                // Remover listeners antiguos y agregar nuevos
                pricingList.removeEventListener("scroll", newCheckScrollEnd);
                pricingList.addEventListener("scroll", newCheckScrollEnd);
                newCheckScrollEnd();
                
                // Remover listener anterior del botón y agregar uno nuevo
                const newScrollHandler = function(e) {
                  e.preventDefault();
                  // Calcular scroll amount: en desktop con muchas tarjetas, scroll de una tarjeta completa
                  const isDesktop = window.innerWidth >= 992;
                  const hasManyCards = planesCount > 3;
                  const scrollAmount = isDesktop && hasManyCards 
                    ? 380 + 30 // ancho de tarjeta + gap
                    : pricingList.clientWidth * 0.85;
                  pricingList.scrollBy({
                    left: scrollAmount,
                    behavior: 'smooth'
                  });
                  this.blur();
                };
                
                pricingScrollBtn.removeEventListener("click", newScrollHandler);
                pricingScrollBtn.addEventListener("click", newScrollHandler);
              }
            }
          }, 300);
        } else {
          listEl.style.display = 'none';
          if (data.message) {
            emptyEl.innerHTML = `<p>${escapeHtml(data.message)}</p>`;
          } else {
            emptyEl.innerHTML = '<p>No hay planes disponibles en este momento.</p>';
          }
          emptyEl.style.display = 'block';
        }
      } catch (error) {
        console.error('Error al cargar planes:', error);
        loadingEl.style.display = 'none';
        listEl.style.display = 'none';
        emptyEl.innerHTML = `<p>Error al cargar los planes: ${escapeHtml(error.message)}. Por favor, intenta más tarde.</p>`;
        emptyEl.style.display = 'block';
      }
    }

    // Cargar planes cuando el DOM esté listo
    document.addEventListener('DOMContentLoaded', function() {
      loadPlans();
    });
  </script>

  <!-- 
    - ionicon link
  -->
  <script type="module" src="https://unpkg.com/ionicons@5.5.2/dist/ionicons/ionicons.esm.js"></script>
  <script nomodule src="https://unpkg.com/ionicons@5.5.2/dist/ionicons/ionicons.js"></script>

</body>

</html>