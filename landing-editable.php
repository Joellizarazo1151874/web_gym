<?php
/**
 * Landing Page Editable - Functional Training Gym
 * Requiere autenticación de administrador
 */
session_start();
require_once __DIR__ . '/database/config.php';
require_once __DIR__ . '/api/auth.php';

$auth = new Auth();

// Verificar autenticación
if (!$auth->isAuthenticated()) {
    header('Location: dashboard/dist/dashboard/auth/login.php');
    exit;
}

// Verificar que sea admin
if (!$auth->hasRole(['admin'])) {
    header('Location: dashboard/dist/dashboard/index.php');
    exit;
}

// Obtener usuario actual
$usuario_actual = $auth->getCurrentUser();

// Cargar contenidos editables desde la base de datos
require_once __DIR__ . '/database/config_helpers.php';

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
    $config = obtenerConfiguracion($db);
    
    // Logo usado en landing (header y footer)
    $logoLanding = './favicon.svg';
    if (!empty($config['logo_empresa'])) {
        $relativeLogo = $config['logo_empresa'];
        if ($relativeLogo[0] !== '/' && substr($relativeLogo, 0, 2) !== './') {
            $relativeLogo = './' . $relativeLogo;
        }
        $logoPathFs = __DIR__ . '/' . ltrim($relativeLogo, './');
        if (file_exists($logoPathFs)) {
            $logoLanding = $relativeLogo;
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
  <title>Editar Landing Page - Functional Training</title>

  <link rel="shortcut icon" href="./favicon.svg" type="image/svg+xml">
  <link rel="stylesheet" href="./assets/css/style.css">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Catamaran:wght@600;700;800;900&family=Rubik:wght@400;500;800&display=swap" rel="stylesheet">

  <style>
    /* Estilos para modo edición */
    .editable-mode {
      position: relative;
    }
    
    .editable-mode:hover {
      outline: 2px dashed #0d6efd;
      outline-offset: 2px;
    }
    
    .edit-btn {
      position: absolute;
      top: -8px;
      right: -8px;
      background: #0d6efd;
      color: white;
      border: none;
      border-radius: 50%;
      width: 32px;
      height: 32px;
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      z-index: 1000;
      box-shadow: 0 2px 8px rgba(0,0,0,0.2);
      opacity: 0;
      transition: opacity 0.2s;
    }
    
    .editable-mode:hover .edit-btn {
      opacity: 1;
    }
    
    .edit-btn:hover {
      background: #0a58ca;
      transform: scale(1.1);
    }
    
    .edit-btn svg {
      width: 18px;
      height: 18px;
    }
    
    .editor-toolbar {
      position: fixed;
      top: 110px;
      right: 20px;
      background: white;
      padding: 15px;
      border-radius: 8px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.2);
      z-index: 10000;
      display: flex;
      gap: 10px;
      align-items: center;
    }
    
    .editor-toolbar .btn {
      padding: 8px 16px;
      border: none;
      border-radius: 4px;
      cursor: pointer;
      font-size: 14px;
    }
    
    .editor-toolbar .btn-primary {
      background: #0d6efd;
      color: white;
    }
    
    .editor-toolbar .btn-secondary {
      background: #6c757d;
      color: white;
    }
    
    .editor-toolbar .btn:hover {
      opacity: 0.9;
    }
    
    /* Modal de edición */
    .edit-modal {
      display: none;
      position: fixed;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      background: rgba(0,0,0,0.5);
      z-index: 20000;
      align-items: center;
      justify-content: center;
    }
    
    .edit-modal.active {
      display: flex;
    }
    
    .edit-modal-content {
      background: white;
      padding: 30px;
      border-radius: 8px;
      max-width: 600px;
      width: 90%;
      max-height: 90vh;
      overflow-y: auto;
    }
    
    .edit-modal-content h3 {
      margin-top: 0;
      margin-bottom: 20px;
    }
    
    .edit-modal-content textarea {
      width: 100%;
      min-height: 150px;
      padding: 10px;
      border: 1px solid #ddd;
      border-radius: 4px;
      font-family: inherit;
      font-size: 14px;
    }
    
    .edit-modal-content input[type="text"],
    .edit-modal-content input[type="file"] {
      width: 100%;
      padding: 10px;
      border: 1px solid #ddd;
      border-radius: 4px;
      margin-bottom: 15px;
    }
    
    .edit-modal-actions {
      display: flex;
      gap: 10px;
      justify-content: flex-end;
      margin-top: 20px;
    }
    
    .preview-image {
      max-width: 100%;
      max-height: 200px;
      margin: 15px 0;
      border-radius: 4px;
    }
  </style>
</head>

<body id="top">

  <!-- Toolbar de edición -->
  <div class="editor-toolbar">
    <span><strong>Modo Edición</strong></span>
    <button class="btn btn-secondary" onclick="window.location.href='index.php'">Ver Landing</button>
    <button class="btn btn-secondary" onclick="window.location.href='dashboard/dist/dashboard/index.php'">Dashboard</button>
  </div>

  <!-- Modal de edición -->
  <div class="edit-modal" id="editModal">
    <div class="edit-modal-content">
      <h3 id="editModalTitle">Editar Contenido</h3>
      <div id="editModalBody"></div>
      <div class="edit-modal-actions">
        <button class="btn btn-secondary" onclick="closeEditModal()">Cancelar</button>
        <button class="btn btn-primary" onclick="saveEdit()">Guardar</button>
      </div>
    </div>
  </div>

  <!-- 
    - #HEADER
  -->
  <header class="header" data-header>
    <div class="container">
      <a href="landing-editable.php#home" class="logo editable-mode" data-section="header" data-element="logo-text">
        <img src="<?php echo htmlspecialchars($logoLanding ?? './favicon.svg'); ?>" alt="Functional Training" width="40" height="40" aria-hidden="true">
        <span class="span logo-full" data-editable="text"><?php echo htmlspecialchars(getEditableContent('header', 'logo-text', 'Functional Training', $contentMap)); ?></span>
        <span class="span logo-short">FT GYM</span>
        <button class="edit-btn" onclick="openEditModal('header', 'logo-text', 'text', '<?php echo htmlspecialchars(getEditableContent('header', 'logo-text', 'Functional Training', $contentMap)); ?>')">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
            <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
          </svg>
        </button>
      </a>

      <nav class="navbar" data-navbar>
        <button class="nav-close-btn" aria-label="cerrar menú" data-nav-toggler>
          <ion-icon name="close-sharp" aria-hidden="true"></ion-icon>
        </button>
        <ul class="navbar-list">
          <li><a href="#home" class="navbar-link active" data-nav-link>Inicio</a></li>
          <li><a href="#about" class="navbar-link" data-nav-link>Nosotros</a></li>
          <li><a href="#class" class="navbar-link" data-nav-link>Clases</a></li>
          <li><a href="#blog" class="navbar-link" data-nav-link>Blog</a></li>
          <li><a href="#planes" class="navbar-link" data-nav-link>Planes</a></li>
          <li><a href="#app" class="navbar-link" data-nav-link>App</a></li>
          <li><a href="#" class="navbar-link" data-nav-link>Productos</a></li>
        </ul>
      </nav>

      <a href="#planes" class="btn btn-secondary editable-mode" data-section="header" data-element="cta-button">
        <span data-editable="text"><?php echo htmlspecialchars(getEditableContent('header', 'cta-button', 'Únete ahora', $contentMap)); ?></span>
        <button class="edit-btn" onclick="openEditModal('header', 'cta-button', 'text', '<?php echo htmlspecialchars(getEditableContent('header', 'cta-button', 'Únete ahora', $contentMap)); ?>')">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
            <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
          </svg>
        </button>
      </a>

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
            <p class="hero-subtitle editable-mode" data-section="hero" data-element="subtitle">
              <strong class="strong" data-editable="text"><?php echo htmlspecialchars(getEditableContent('hero', 'subtitle-strong', 'El Mejor', $contentMap)); ?></strong>
              <span data-editable="text"><?php echo htmlspecialchars(getEditableContent('hero', 'subtitle-text', 'Club de Fitness', $contentMap)); ?></span>
              <button class="edit-btn" onclick="openEditModal('hero', 'subtitle', 'text', '<?php echo htmlspecialchars(getEditableContent('hero', 'subtitle-strong', 'El Mejor', $contentMap) . ' ' . getEditableContent('hero', 'subtitle-text', 'Club de Fitness', $contentMap)); ?>')">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                  <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                </svg>
              </button>
            </p>

            <h1 class="h1 hero-title editable-mode" data-section="hero" data-element="title">
              <span data-editable="text"><?php echo htmlspecialchars(getEditableContent('hero', 'title', 'Trabaja duro para una mejor vida', $contentMap)); ?></span>
              <button class="edit-btn" onclick="openEditModal('hero', 'title', 'text', '<?php echo htmlspecialchars(getEditableContent('hero', 'title', 'Trabaja duro para una mejor vida', $contentMap)); ?>')">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                  <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                </svg>
              </button>
            </h1>

            <p class="section-text editable-mode" data-section="hero" data-element="description">
              <span data-editable="text"><?php echo htmlspecialchars(getEditableContent('hero', 'description', 'Entrena con planes personalizados, seguimiento de progreso y acceso rápido con código QR. Compra tus entradas con descuento desde nuestra app.', $contentMap)); ?></span>
              <button class="edit-btn" onclick="openEditModal('hero', 'description', 'text', '<?php echo htmlspecialchars(getEditableContent('hero', 'description', 'Entrena con planes personalizados, seguimiento de progreso y acceso rápido con código QR. Compra tus entradas con descuento desde nuestra app.', $contentMap)); ?>')">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                  <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                </svg>
              </button>
            </p>

            <a href="#" class="btn btn-primary editable-mode" data-section="hero" data-element="cta-button">
              <span data-editable="text"><?php echo htmlspecialchars(getEditableContent('hero', 'cta-button', 'Comenzar', $contentMap)); ?></span>
              <button class="edit-btn" onclick="openEditModal('hero', 'cta-button', 'text', '<?php echo htmlspecialchars(getEditableContent('hero', 'cta-button', 'Comenzar', $contentMap)); ?>')">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                  <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                </svg>
              </button>
            </a>
          </div>

          <div class="hero-banner editable-mode" data-section="hero" data-element="banner-image">
            <img src="<?php echo htmlspecialchars(getEditableContent('hero', 'banner-image', './assets/images/hero-banner.png', $contentMap)); ?>" 
                 width="660" height="753" alt="hero banner" class="w-100" id="hero-banner-img">
            <button class="edit-btn" onclick="openEditModal('hero', 'banner-image', 'image', '<?php echo htmlspecialchars(getEditableContent('hero', 'banner-image', './assets/images/hero-banner.png', $contentMap)); ?>')">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
              </svg>
            </button>
            <img src="./assets/images/hero-circle-one.png" width="666" height="666" aria-hidden="true" alt="" class="circle circle-1">
            <img src="./assets/images/hero-circle-two.png" width="666" height="666" aria-hidden="true" alt="" class="circle circle-2">
            <img src="./assets/images/heart-rate.svg" width="255" height="270" alt="ritmo cardíaco" class="abs-img abs-img-1">
            <img src="./assets/images/calories.svg" width="348" height="224" alt="calorías" class="abs-img abs-img-2">
          </div>
        </div>
      </section>

      <!-- 
        - #ABOUT
      -->
      <section class="section about" id="about" aria-label="nosotros">
        <div class="container">
          <div class="about-banner has-after editable-mode" data-section="about" data-element="banner-image">
            <img src="<?php echo htmlspecialchars(getEditableContent('about', 'banner-image', './assets/images/about-banner.png', $contentMap)); ?>" 
                 width="660" height="648" loading="lazy" alt="banner sobre nosotros" class="w-100">
            <button class="edit-btn" onclick="openEditModal('about', 'banner-image', 'image', '<?php echo htmlspecialchars(getEditableContent('about', 'banner-image', './assets/images/about-banner.png', $contentMap)); ?>')">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
              </svg>
            </button>
            <img src="./assets/images/about-circle-one.png" width="660" height="534" loading="lazy" aria-hidden="true" alt="" class="circle circle-1">
            <img src="./assets/images/about-circle-two.png" width="660" height="534" loading="lazy" aria-hidden="true" alt="" class="circle circle-2">
            <img src="./assets/images/fitness.png" width="650" height="154" loading="lazy" alt="fitness" class="abs-img w-100">
          </div>

          <div class="about-content">
            <p class="section-subtitle editable-mode" data-section="about" data-element="subtitle">
              <span data-editable="text"><?php echo htmlspecialchars(getEditableContent('about', 'subtitle', 'Nosotros', $contentMap)); ?></span>
              <button class="edit-btn" onclick="openEditModal('about', 'subtitle', 'text', '<?php echo htmlspecialchars(getEditableContent('about', 'subtitle', 'Nosotros', $contentMap)); ?>')">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                  <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                </svg>
              </button>
            </p>

            <h2 class="h2 section-title editable-mode" data-section="about" data-element="title">
              <span data-editable="text"><?php echo htmlspecialchars(getEditableContent('about', 'title', 'Bienvenido a Nuestro Gimnasio', $contentMap)); ?></span>
              <button class="edit-btn" onclick="openEditModal('about', 'title', 'text', '<?php echo htmlspecialchars(getEditableContent('about', 'title', 'Bienvenido a Nuestro Gimnasio', $contentMap)); ?>')">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                  <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                </svg>
              </button>
            </h2>

            <p class="section-text editable-mode" data-section="about" data-element="text-1">
              <span data-editable="text"><?php echo htmlspecialchars(getEditableContent('about', 'text-1', 'Somos un equipo de entrenadores y profesionales del fitness comprometidos con tu bienestar. Diseñamos programas efectivos para todos los niveles, combinando fuerza, cardio y movilidad para que avances de forma segura.', $contentMap)); ?></span>
              <button class="edit-btn" onclick="openEditModal('about', 'text-1', 'text', '<?php echo htmlspecialchars(getEditableContent('about', 'text-1', 'Somos un equipo de entrenadores y profesionales del fitness comprometidos con tu bienestar. Diseñamos programas efectivos para todos los niveles, combinando fuerza, cardio y movilidad para que avances de forma segura.', $contentMap)); ?>')">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                  <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                </svg>
              </button>
            </p>

            <p class="section-text editable-mode" data-section="about" data-element="text-2">
              <span data-editable="text"><?php echo htmlspecialchars(getEditableContent('about', 'text-2', 'Contamos con instalaciones modernas, clases guiadas y una app móvil con rutinas personalizadas, estadísticas y acceso con código QR. Nuestro objetivo es ayudarte a construir hábitos sostenibles y resultados reales.', $contentMap)); ?></span>
              <button class="edit-btn" onclick="openEditModal('about', 'text-2', 'text', '<?php echo htmlspecialchars(getEditableContent('about', 'text-2', 'Contamos con instalaciones modernas, clases guiadas y una app móvil con rutinas personalizadas, estadísticas y acceso con código QR. Nuestro objetivo es ayudarte a construir hábitos sostenibles y resultados reales.', $contentMap)); ?>')">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                  <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                </svg>
              </button>
            </p>

            <div class="wrapper">
              <div class="about-coach editable-mode" data-section="about" data-element="coach">
                <figure class="coach-avatar">
                  <img src="<?php echo htmlspecialchars(getEditableContent('about', 'coach-image', './assets/images/about-coach.jpg', $contentMap)); ?>" 
                       width="65" height="65" loading="lazy" alt="Trainer">
                </figure>
                <div>
                  <h3 class="h3 coach-name editable-mode" data-section="about" data-element="coach-name">
                    <span data-editable="text"><?php echo htmlspecialchars(getEditableContent('about', 'coach-name', 'Denis Robinson', $contentMap)); ?></span>
                    <button class="edit-btn" onclick="openEditModal('about', 'coach-name', 'text', '<?php echo htmlspecialchars(getEditableContent('about', 'coach-name', 'Denis Robinson', $contentMap)); ?>')">
                      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                        <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                      </svg>
                    </button>
                  </h3>
                  <p class="coach-title editable-mode" data-section="about" data-element="coach-title">
                    <span data-editable="text"><?php echo htmlspecialchars(getEditableContent('about', 'coach-title', 'Nuestro Entrenador', $contentMap)); ?></span>
                    <button class="edit-btn" onclick="openEditModal('about', 'coach-title', 'text', '<?php echo htmlspecialchars(getEditableContent('about', 'coach-title', 'Nuestro Entrenador', $contentMap)); ?>')">
                      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                        <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                      </svg>
                    </button>
                  </p>
                </div>
              </div>
              <a href="#" class="btn btn-primary editable-mode" data-section="about" data-element="cta-button">
                <span data-editable="text"><?php echo htmlspecialchars(getEditableContent('about', 'cta-button', 'Explorar más', $contentMap)); ?></span>
                <button class="edit-btn" onclick="openEditModal('about', 'cta-button', 'text', '<?php echo htmlspecialchars(getEditableContent('about', 'cta-button', 'Explorar más', $contentMap)); ?>')">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                    <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                  </svg>
                </button>
              </a>
            </div>
          </div>
        </div>
      </section>

      <!-- 
        - #VIDEO
      -->
      <section class="section video" aria-label="video">
        <div class="container">
          <div class="video-card has-before has-bg-image editable-mode" 
               data-section="video" 
               data-element="background-image"
               style="background-image: url('<?php echo htmlspecialchars(getEditableContent('video', 'background-image', './assets/images/video-banner.jpg', $contentMap)); ?>')">
            <h2 class="h2 card-title editable-mode" data-section="video" data-element="title">
              <span data-editable="text"><?php echo htmlspecialchars(getEditableContent('video', 'title', 'Explora la Vida Fitness', $contentMap)); ?></span>
              <button class="edit-btn" onclick="openEditModal('video', 'title', 'text', '<?php echo htmlspecialchars(getEditableContent('video', 'title', 'Explora la Vida Fitness', $contentMap)); ?>')">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                  <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                </svg>
              </button>
            </h2>
            <button class="play-btn" aria-label="reproducir video">
              <ion-icon name="play-sharp" aria-hidden="true"></ion-icon>
            </button>
            <a href="#" class="btn-link has-before editable-mode" data-section="video" data-element="link-text">
              <span data-editable="text"><?php echo htmlspecialchars(getEditableContent('video', 'link-text', 'Ver más', $contentMap)); ?></span>
              <button class="edit-btn" onclick="openEditModal('video', 'link-text', 'text', '<?php echo htmlspecialchars(getEditableContent('video', 'link-text', 'Ver más', $contentMap)); ?>')">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                  <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                </svg>
              </button>
            </a>
            <button class="edit-btn" style="position: absolute; top: 10px; right: 10px;" onclick="openEditModal('video', 'background-image', 'image', '<?php echo htmlspecialchars(getEditableContent('video', 'background-image', './assets/images/video-banner.jpg', $contentMap)); ?>')">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
              </svg>
            </button>
          </div>
        </div>
      </section>

      <!-- 
        - #CLASS
      -->
      <section class="section class bg-dark has-bg-image" id="class" aria-label="clases"
        style="background-image: url('./assets/images/classes-bg.png')">
        <div class="container">
          <p class="section-subtitle editable-mode" data-section="class" data-element="subtitle">
            <span data-editable="text"><?php echo htmlspecialchars(getEditableContent('class', 'subtitle', 'Nuestras Clases', $contentMap)); ?></span>
            <button class="edit-btn" onclick="openEditModal('class', 'subtitle', 'text', '<?php echo htmlspecialchars(getEditableContent('class', 'subtitle', 'Nuestras Clases', $contentMap)); ?>')">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
              </svg>
            </button>
          </p>

          <h2 class="h2 section-title text-center editable-mode" data-section="class" data-element="title">
            <span data-editable="text"><?php echo htmlspecialchars(getEditableContent('class', 'title', 'Clases de Fitness para Cada Objetivo', $contentMap)); ?></span>
            <button class="edit-btn" onclick="openEditModal('class', 'title', 'text', '<?php echo htmlspecialchars(getEditableContent('class', 'title', 'Clases de Fitness para Cada Objetivo', $contentMap)); ?>')">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
              </svg>
            </button>
          </h2>

          <!-- Las clases se pueden hacer editables también, pero por ahora las dejamos estáticas -->
          <ul class="class-list has-scrollbar">
            <li class="scrollbar-item">
              <div class="class-card">
                <figure class="card-banner img-holder editable-mode" style="--width: 416; --height: 240;" data-section="class" data-element="class-1-image">
                  <img src="<?php echo htmlspecialchars(getEditableContent('class', 'class-1-image', './assets/images/class-1.jpg', $contentMap)); ?>" 
                       width="416" height="240" loading="lazy" alt="Levantamiento de pesas" class="img-cover">
                  <button class="edit-btn" onclick="openEditModal('class', 'class-1-image', 'image', '<?php echo htmlspecialchars(getEditableContent('class', 'class-1-image', './assets/images/class-1.jpg', $contentMap)); ?>')">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                      <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                    </svg>
                  </button>
                </figure>
                <div class="card-content">
                  <div class="title-wrapper">
                    <img src="./assets/images/class-icon-1.png" width="52" height="52" aria-hidden="true" alt="" class="title-icon">
                    <h3 class="h3 editable-mode" data-section="class" data-element="class-1-title">
                      <a href="#" class="card-title">
                        <span data-editable="text"><?php echo htmlspecialchars(getEditableContent('class', 'class-1-title', 'Levantamiento de Pesas', $contentMap)); ?></span>
                      </a>
                      <button class="edit-btn" onclick="openEditModal('class', 'class-1-title', 'text', '<?php echo htmlspecialchars(getEditableContent('class', 'class-1-title', 'Levantamiento de Pesas', $contentMap)); ?>')">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                          <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                          <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                        </svg>
                      </button>
                    </h3>
                  </div>
                  <p class="card-text editable-mode" data-section="class" data-element="class-1-text">
                    <span data-editable="text"><?php echo htmlspecialchars(getEditableContent('class', 'class-1-text', 'Mejora tu fuerza y técnica con programas progresivos y acompañamiento de entrenador. Ideal para ganar masa muscular y estabilidad.', $contentMap)); ?></span>
                    <button class="edit-btn" onclick="openEditModal('class', 'class-1-text', 'text', '<?php echo htmlspecialchars(getEditableContent('class', 'class-1-text', 'Mejora tu fuerza y técnica con programas progresivos y acompañamiento de entrenador. Ideal para ganar masa muscular y estabilidad.', $contentMap)); ?>')">
                      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                        <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                      </svg>
                    </button>
                  </p>
                </div>
              </div>
            </li>

            <li class="scrollbar-item">
              <div class="class-card">
                <figure class="card-banner img-holder editable-mode" style="--width: 416; --height: 240;" data-section="class" data-element="class-2-image">
                  <img src="<?php echo htmlspecialchars(getEditableContent('class', 'class-2-image', './assets/images/class-2.jpg', $contentMap)); ?>" 
                       width="416" height="240" loading="lazy" alt="Cardio y Fuerza" class="img-cover">
                  <button class="edit-btn" onclick="openEditModal('class', 'class-2-image', 'image', '<?php echo htmlspecialchars(getEditableContent('class', 'class-2-image', './assets/images/class-2.jpg', $contentMap)); ?>')">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                      <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                    </svg>
                  </button>
                </figure>
                <div class="card-content">
                  <div class="title-wrapper">
                    <img src="./assets/images/class-icon-2.png" width="52" height="52" aria-hidden="true" alt="" class="title-icon">
                    <h3 class="h3 editable-mode" data-section="class" data-element="class-2-title">
                      <a href="#" class="card-title">
                        <span data-editable="text"><?php echo htmlspecialchars(getEditableContent('class', 'class-2-title', 'Cardio y Fuerza', $contentMap)); ?></span>
                      </a>
                      <button class="edit-btn" onclick="openEditModal('class', 'class-2-title', 'text', '<?php echo htmlspecialchars(getEditableContent('class', 'class-2-title', 'Cardio y Fuerza', $contentMap)); ?>')">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                          <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                          <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                        </svg>
                      </button>
                    </h3>
                  </div>
                  <p class="card-text editable-mode" data-section="class" data-element="class-2-text">
                    <span data-editable="text"><?php echo htmlspecialchars(getEditableContent('class', 'class-2-text', 'Circuitos funcionales y HIIT para aumentar resistencia, quemar grasa y mejorar tu condición física general en poco tiempo.', $contentMap)); ?></span>
                    <button class="edit-btn" onclick="openEditModal('class', 'class-2-text', 'text', '<?php echo htmlspecialchars(getEditableContent('class', 'class-2-text', 'Circuitos funcionales y HIIT para aumentar resistencia, quemar grasa y mejorar tu condición física general en poco tiempo.', $contentMap)); ?>')">
                      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                        <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                      </svg>
                    </button>
                  </p>
                </div>
              </div>
            </li>

            <li class="scrollbar-item">
              <div class="class-card">
                <figure class="card-banner img-holder editable-mode" style="--width: 416; --height: 240;" data-section="class" data-element="class-3-image">
                  <img src="<?php echo htmlspecialchars(getEditableContent('class', 'class-3-image', './assets/images/class-3.jpg', $contentMap)); ?>" 
                       width="416" height="240" loading="lazy" alt="Power Yoga" class="img-cover">
                  <button class="edit-btn" onclick="openEditModal('class', 'class-3-image', 'image', '<?php echo htmlspecialchars(getEditableContent('class', 'class-3-image', './assets/images/class-3.jpg', $contentMap)); ?>')">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                      <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                    </svg>
                  </button>
                </figure>
                <div class="card-content">
                  <div class="title-wrapper">
                    <img src="./assets/images/class-icon-3.png" width="52" height="52" aria-hidden="true" alt="" class="title-icon">
                    <h3 class="h3 editable-mode" data-section="class" data-element="class-3-title">
                      <a href="#" class="card-title">
                        <span data-editable="text"><?php echo htmlspecialchars(getEditableContent('class', 'class-3-title', 'Power Yoga', $contentMap)); ?></span>
                      </a>
                      <button class="edit-btn" onclick="openEditModal('class', 'class-3-title', 'text', '<?php echo htmlspecialchars(getEditableContent('class', 'class-3-title', 'Power Yoga', $contentMap)); ?>')">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                          <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                          <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                        </svg>
                      </button>
                    </h3>
                  </div>
                  <p class="card-text editable-mode" data-section="class" data-element="class-3-text">
                    <span data-editable="text"><?php echo htmlspecialchars(getEditableContent('class', 'class-3-text', 'Combina respiración y movimiento para ganar movilidad, fuerza y control corporal. Perfecto para reducir estrés y prevenir lesiones.', $contentMap)); ?></span>
                    <button class="edit-btn" onclick="openEditModal('class', 'class-3-text', 'text', '<?php echo htmlspecialchars(getEditableContent('class', 'class-3-text', 'Combina respiración y movimiento para ganar movilidad, fuerza y control corporal. Perfecto para reducir estrés y prevenir lesiones.', $contentMap)); ?>')">
                      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                        <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                      </svg>
                    </button>
                  </p>
                </div>
              </div>
            </li>

            <li class="scrollbar-item">
              <div class="class-card">
                <figure class="card-banner img-holder editable-mode" style="--width: 416; --height: 240;" data-section="class" data-element="class-4-image">
                  <img src="<?php echo htmlspecialchars(getEditableContent('class', 'class-4-image', './assets/images/class-4.jpg', $contentMap)); ?>" 
                       width="416" height="240" loading="lazy" alt="El Paquete Fitness" class="img-cover">
                  <button class="edit-btn" onclick="openEditModal('class', 'class-4-image', 'image', '<?php echo htmlspecialchars(getEditableContent('class', 'class-4-image', './assets/images/class-4.jpg', $contentMap)); ?>')">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                      <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                    </svg>
                  </button>
                </figure>
                <div class="card-content">
                  <div class="title-wrapper">
                    <img src="./assets/images/class-icon-4.png" width="52" height="52" aria-hidden="true" alt="" class="title-icon">
                    <h3 class="h3 editable-mode" data-section="class" data-element="class-4-title">
                      <a href="#" class="card-title">
                        <span data-editable="text"><?php echo htmlspecialchars(getEditableContent('class', 'class-4-title', 'El Paquete Fitness', $contentMap)); ?></span>
                      </a>
                      <button class="edit-btn" onclick="openEditModal('class', 'class-4-title', 'text', '<?php echo htmlspecialchars(getEditableContent('class', 'class-4-title', 'El Paquete Fitness', $contentMap)); ?>')">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                          <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                          <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                        </svg>
                      </button>
                    </h3>
                  </div>
                  <p class="card-text editable-mode" data-section="class" data-element="class-4-text">
                    <span data-editable="text"><?php echo htmlspecialchars(getEditableContent('class', 'class-4-text', 'Un plan integral que equilibra pesas, cardio y core. Optimiza tu tiempo y acelera resultados de forma segura y sostenible.', $contentMap)); ?></span>
                    <button class="edit-btn" onclick="openEditModal('class', 'class-4-text', 'text', '<?php echo htmlspecialchars(getEditableContent('class', 'class-4-text', 'Un plan integral que equilibra pesas, cardio y core. Optimiza tu tiempo y acelera resultados de forma segura y sostenible.', $contentMap)); ?>')">
                      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                        <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                      </svg>
                    </button>
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
          <p class="section-subtitle editable-mode" data-section="blog" data-element="subtitle">
            <span data-editable="text"><?php echo htmlspecialchars(getEditableContent('blog', 'subtitle', 'Nuestras Noticias', $contentMap)); ?></span>
            <button class="edit-btn" onclick="openEditModal('blog', 'subtitle', 'text', '<?php echo htmlspecialchars(getEditableContent('blog', 'subtitle', 'Nuestras Noticias', $contentMap)); ?>')">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
              </svg>
            </button>
          </p>
          
          <h2 class="h2 section-title text-center editable-mode" data-section="blog" data-element="title">
            <span data-editable="text"><?php echo htmlspecialchars(getEditableContent('blog', 'title', 'Últimas Publicaciones del Blog', $contentMap)); ?></span>
            <button class="edit-btn" onclick="openEditModal('blog', 'title', 'text', '<?php echo htmlspecialchars(getEditableContent('blog', 'title', 'Últimas Publicaciones del Blog', $contentMap)); ?>')">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
              </svg>
            </button>
          </h2>

          <ul class="blog-list has-scrollbar">
            <li class="scrollbar-item">
              <div class="blog-card">
                <div class="card-banner img-holder editable-mode" style="--width: 440; --height: 270;" data-section="blog" data-element="blog-1-image">
                  <img src="<?php echo htmlspecialchars(getEditableContent('blog', 'blog-1-image', './assets/images/blog-1.jpg', $contentMap)); ?>" width="440" height="270" loading="lazy" alt="Nueva zona de peso libre y máquinas" class="img-cover">
                  <time class="card-meta editable-mode" data-section="blog" data-element="blog-1-date" datetime="<?php echo htmlspecialchars(getEditableContent('blog', 'blog-1-date', '2025-09-15', $contentMap)); ?>">
                    <span data-editable="text"><?php echo htmlspecialchars(getEditableContent('blog', 'blog-1-date', '15 Sep 2025', $contentMap)); ?></span>
                    <button class="edit-btn" onclick="openEditModal('blog', 'blog-1-date', 'text', '<?php echo htmlspecialchars(getEditableContent('blog', 'blog-1-date', '15 Sep 2025', $contentMap)); ?>')">
                      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                        <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                      </svg>
                    </button>
                  </time>
                  <button class="edit-btn" onclick="openEditModal('blog', 'blog-1-image', 'image', '<?php echo htmlspecialchars(getEditableContent('blog', 'blog-1-image', './assets/images/blog-1.jpg', $contentMap)); ?>')">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                      <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                    </svg>
                  </button>
                </div>
                <div class="card-content">
                  <h3 class="h3 editable-mode" data-section="blog" data-element="blog-1-title">
                    <a href="#" class="card-title">
                      <span data-editable="text"><?php echo htmlspecialchars(getEditableContent('blog', 'blog-1-title', 'Renovamos el área de fuerza: más discos, racks y máquinas', $contentMap)); ?></span>
                    </a>
                    <button class="edit-btn" onclick="openEditModal('blog', 'blog-1-title', 'text', '<?php echo htmlspecialchars(getEditableContent('blog', 'blog-1-title', 'Renovamos el área de fuerza: más discos, racks y máquinas', $contentMap)); ?>')">
                      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                        <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                      </svg>
                    </button>
                  </h3>
                  <p class="card-text editable-mode" data-section="blog" data-element="blog-1-text">
                    <span data-editable="text"><?php echo htmlspecialchars(getEditableContent('blog', 'blog-1-text', 'Ampliamos la zona de peso libre y sumamos máquinas de última generación para que entrenes con más comodidad y seguridad en tus rutinas de fuerza e hipertrofia.', $contentMap)); ?></span>
                    <button class="edit-btn" onclick="openEditModal('blog', 'blog-1-text', 'text', '<?php echo htmlspecialchars(getEditableContent('blog', 'blog-1-text', 'Ampliamos la zona de peso libre y sumamos máquinas de última generación para que entrenes con más comodidad y seguridad en tus rutinas de fuerza e hipertrofia.', $contentMap)); ?>')">
                      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                        <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                      </svg>
                    </button>
                  </p>
                </div>
              </div>
            </li>

            <li class="scrollbar-item">
              <div class="blog-card">
                <div class="card-banner img-holder editable-mode" style="--width: 440; --height: 270;" data-section="blog" data-element="blog-2-image">
                  <img src="<?php echo htmlspecialchars(getEditableContent('blog', 'blog-2-image', './assets/images/blog-2.jpg', $contentMap)); ?>" width="440" height="270" loading="lazy" alt="Lanzamiento de la app móvil del gimnasio" class="img-cover">
                  <time class="card-meta editable-mode" data-section="blog" data-element="blog-2-date" datetime="<?php echo htmlspecialchars(getEditableContent('blog', 'blog-2-date', '2025-08-28', $contentMap)); ?>">
                    <span data-editable="text"><?php echo htmlspecialchars(getEditableContent('blog', 'blog-2-date', '28 Ago 2025', $contentMap)); ?></span>
                    <button class="edit-btn" onclick="openEditModal('blog', 'blog-2-date', 'text', '<?php echo htmlspecialchars(getEditableContent('blog', 'blog-2-date', '28 Ago 2025', $contentMap)); ?>')">
                      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                        <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                      </svg>
                    </button>
                  </time>
                  <button class="edit-btn" onclick="openEditModal('blog', 'blog-2-image', 'image', '<?php echo htmlspecialchars(getEditableContent('blog', 'blog-2-image', './assets/images/blog-2.jpg', $contentMap)); ?>')">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                      <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                    </svg>
                  </button>
                </div>
                <div class="card-content">
                  <h3 class="h3 editable-mode" data-section="blog" data-element="blog-2-title">
                    <a href="#" class="card-title">
                      <span data-editable="text"><?php echo htmlspecialchars(getEditableContent('blog', 'blog-2-title', 'Presentamos nuestra app: rutinas inteligentes y acceso con QR', $contentMap)); ?></span>
                    </a>
                    <button class="edit-btn" onclick="openEditModal('blog', 'blog-2-title', 'text', '<?php echo htmlspecialchars(getEditableContent('blog', 'blog-2-title', 'Presentamos nuestra app: rutinas inteligentes y acceso con QR', $contentMap)); ?>')">
                      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                        <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                      </svg>
                    </button>
                  </h3>
                  <p class="card-text editable-mode" data-section="blog" data-element="blog-2-text">
                    <span data-editable="text"><?php echo htmlspecialchars(getEditableContent('blog', 'blog-2-text', 'Descarga la app para obtener rutinas personalizadas con IA, registrar tus entrenamientos y entrar al gym con código QR. Además, obtén 10% de descuento en tus compras.', $contentMap)); ?></span>
                    <button class="edit-btn" onclick="openEditModal('blog', 'blog-2-text', 'text', '<?php echo htmlspecialchars(getEditableContent('blog', 'blog-2-text', 'Descarga la app para obtener rutinas personalizadas con IA, registrar tus entrenamientos y entrar al gym con código QR. Además, obtén 10% de descuento en tus compras.', $contentMap)); ?>')">
                      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                        <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                      </svg>
                    </button>
                  </p>
                </div>
              </div>
            </li>

            <li class="scrollbar-item">
              <div class="blog-card">
                <div class="card-banner img-holder editable-mode" style="--width: 440; --height: 270;" data-section="blog" data-element="blog-3-image">
                  <img src="<?php echo htmlspecialchars(getEditableContent('blog', 'blog-3-image', './assets/images/blog-3.jpg', $contentMap)); ?>" width="440" height="270" loading="lazy" alt="Competencia interna y jornada de puertas abiertas" class="img-cover">
                  <time class="card-meta editable-mode" data-section="blog" data-element="blog-3-date" datetime="<?php echo htmlspecialchars(getEditableContent('blog', 'blog-3-date', '2025-07-12', $contentMap)); ?>">
                    <span data-editable="text"><?php echo htmlspecialchars(getEditableContent('blog', 'blog-3-date', '12 Jul 2025', $contentMap)); ?></span>
                    <button class="edit-btn" onclick="openEditModal('blog', 'blog-3-date', 'text', '<?php echo htmlspecialchars(getEditableContent('blog', 'blog-3-date', '12 Jul 2025', $contentMap)); ?>')">
                      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                        <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                      </svg>
                    </button>
                  </time>
                  <button class="edit-btn" onclick="openEditModal('blog', 'blog-3-image', 'image', '<?php echo htmlspecialchars(getEditableContent('blog', 'blog-3-image', './assets/images/blog-3.jpg', $contentMap)); ?>')">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                      <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                    </svg>
                  </button>
                </div>
                <div class="card-content">
                  <h3 class="h3 editable-mode" data-section="blog" data-element="blog-3-title">
                    <a href="#" class="card-title">
                      <span data-editable="text"><?php echo htmlspecialchars(getEditableContent('blog', 'blog-3-title', 'Evento especial: competencia interna y puertas abiertas', $contentMap)); ?></span>
                    </a>
                    <button class="edit-btn" onclick="openEditModal('blog', 'blog-3-title', 'text', '<?php echo htmlspecialchars(getEditableContent('blog', 'blog-3-title', 'Evento especial: competencia interna y puertas abiertas', $contentMap)); ?>')">
                      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                        <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                      </svg>
                    </button>
                  </h3>
                  <p class="card-text editable-mode" data-section="blog" data-element="blog-3-text">
                    <span data-editable="text"><?php echo htmlspecialchars(getEditableContent('blog', 'blog-3-text', 'Te invitamos a participar en nuestra competencia de fuerza y clases abiertas. Habrá premios, coaching en vivo y descuentos exclusivos para nuevos miembros.', $contentMap)); ?></span>
                    <button class="edit-btn" onclick="openEditModal('blog', 'blog-3-text', 'text', '<?php echo htmlspecialchars(getEditableContent('blog', 'blog-3-text', 'Te invitamos a participar en nuestra competencia de fuerza y clases abiertas. Habrá premios, coaching en vivo y descuentos exclusivos para nuevos miembros.', $contentMap)); ?>')">
                      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                        <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                      </svg>
                    </button>
                  </p>
                </div>
              </div>
            </li>
          </ul>
        </div>
      </section>

      <!-- 
        - #PLANES (ya se carga dinámicamente, solo hacer editables los textos estáticos)
      -->
      <section class="section bg-dark has-bg-image text-center" id="planes" aria-label="planes"
        style="background-image: url('./assets/images/classes-bg.png')">
        <div class="container">
          <p class="section-subtitle editable-mode" data-section="planes" data-element="subtitle">
            <span data-editable="text"><?php echo htmlspecialchars(getEditableContent('planes', 'subtitle', 'Nuestros Planes', $contentMap)); ?></span>
            <button class="edit-btn" onclick="openEditModal('planes', 'subtitle', 'text', '<?php echo htmlspecialchars(getEditableContent('planes', 'subtitle', 'Nuestros Planes', $contentMap)); ?>')">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
              </svg>
            </button>
          </p>

          <h2 class="h2 section-title text-center editable-mode" data-section="planes" data-element="title">
            <span data-editable="text"><?php echo htmlspecialchars(getEditableContent('planes', 'title', 'Elige tu plan', $contentMap)); ?></span>
            <button class="edit-btn" onclick="openEditModal('planes', 'title', 'text', '<?php echo htmlspecialchars(getEditableContent('planes', 'title', 'Elige tu plan', $contentMap)); ?>')">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
              </svg>
            </button>
          </h2>

          <div id="planes-loading" class="text-center" style="padding: 40px; color: var(--white);">
            <p>Cargando planes...</p>
          </div>

          <ul class="pricing-list has-scrollbar" id="pricing-list" data-carousel-3d style="display: none;">
            <!-- Los planes se cargarán aquí dinámicamente -->
          </ul>

          <div id="planes-empty" class="text-center" style="display: none; padding: 40px; color: var(--white);">
            <p>No hay planes disponibles en este momento.</p>
          </div>

          <button class="pricing-scroll-btn" aria-label="Siguiente tarjeta" id="pricing-scroll-btn">
            <ion-icon name="chevron-forward-sharp" aria-hidden="true"></ion-icon>
          </button>

          <p class="section-text editable-mode" style="margin-top: 16px;" data-section="planes" data-element="footer-text">
            <span data-editable="text"><?php echo htmlspecialchars(getEditableContent('planes', 'footer-text', 'El descuento aplica al comprar desde la aplicación móvil. Disponible para Android y iPhone.', $contentMap)); ?></span>
            <button class="edit-btn" onclick="openEditModal('planes', 'footer-text', 'text', '<?php echo htmlspecialchars(getEditableContent('planes', 'footer-text', 'El descuento aplica al comprar desde la aplicación móvil. Disponible para Android y iPhone.', $contentMap)); ?>')">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
              </svg>
            </button>
          </p>
        </div>
      </section>

      <!-- 
        - #APP MOVIL
      -->
      <section class="section text-center" id="app" aria-label="aplicación móvil">
        <div class="container">
          <p class="section-subtitle editable-mode" data-section="app" data-element="subtitle">
            <span data-editable="text"><?php echo htmlspecialchars(getEditableContent('app', 'subtitle', 'Aplicación Móvil', $contentMap)); ?></span>
            <button class="edit-btn" onclick="openEditModal('app', 'subtitle', 'text', '<?php echo htmlspecialchars(getEditableContent('app', 'subtitle', 'Aplicación Móvil', $contentMap)); ?>')">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
              </svg>
            </button>
          </p>

          <h2 class="h2 section-title editable-mode" data-section="app" data-element="title">
            <span data-editable="text"><?php echo htmlspecialchars(getEditableContent('app', 'title', 'Tu gimnasio en el bolsillo', $contentMap)); ?></span>
            <button class="edit-btn" onclick="openEditModal('app', 'title', 'text', '<?php echo htmlspecialchars(getEditableContent('app', 'title', 'Tu gimnasio en el bolsillo', $contentMap)); ?>')">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
              </svg>
            </button>
          </h2>

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
          // Para el modal de edición, usar el texto con placeholder para que el usuario pueda editarlo
          $textoParaEditar = getEditableContent('app', 'description', 'Compra tu entrada con 10% de descuento desde la app. Disponible para Android y iPhone.', $contentMap);
          // Si el texto para editar tiene un porcentaje numérico, reemplazarlo con el placeholder
          if (preg_match('/(\d+)%/', $textoParaEditar, $matches)) {
            $textoParaEditar = preg_replace('/(\d+)%/', '{DESCUENTO}%', $textoParaEditar);
          }
          ?>
          <p class="section-text editable-mode" data-section="app" data-element="description">
            <span data-editable="text"><?php echo htmlspecialchars($textoDescripcion); ?></span>
            <button class="edit-btn" onclick="openEditModal('app', 'description', 'text', '<?php echo htmlspecialchars($textoParaEditar); ?>')">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
              </svg>
            </button>
          </p>

          <!-- Resto del contenido de la app -->
        </div>
      </section>

      <!-- Footer también editable -->
      <footer class="footer">
        <div class="section footer-top bg-dark has-bg-image editable-mode" 
             data-section="footer" 
             data-element="background-image"
             style="background-image: url('<?php echo htmlspecialchars(getEditableContent('footer', 'background-image', './assets/images/footer-bg.png', $contentMap)); ?>')">
          <div class="container">
            <div class="footer-brand">
              <a href="#" class="logo editable-mode" data-section="footer" data-element="logo-text">
                <img src="<?php echo htmlspecialchars($logoLanding ?? './favicon.svg'); ?>" alt="Functional Training" width="40" height="40" aria-hidden="true">
                <span class="span" data-editable="text"><?php echo htmlspecialchars(getEditableContent('footer', 'logo-text', 'Functional Training', $contentMap)); ?></span>
                <button class="edit-btn" onclick="openEditModal('footer', 'logo-text', 'text', '<?php echo htmlspecialchars(getEditableContent('footer', 'logo-text', 'Functional Training', $contentMap)); ?>')">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                    <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                  </svg>
                </button>
              </a>

              <p class="footer-brand-text editable-mode" data-section="footer" data-element="brand-text">
                <span data-editable="text"><?php echo htmlspecialchars(getEditableContent('footer', 'brand-text', 'Entrena con nosotros y alcanza tus objetivos fitness. Instalaciones modernas, entrenadores profesionales y una comunidad activa.', $contentMap)); ?></span>
                <button class="edit-btn" onclick="openEditModal('footer', 'brand-text', 'text', '<?php echo htmlspecialchars(getEditableContent('footer', 'brand-text', 'Entrena con nosotros y alcanza tus objetivos fitness. Instalaciones modernas, entrenadores profesionales y una comunidad activa.', $contentMap)); ?>')">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                    <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                  </svg>
                </button>
              </p>

              <div class="wrapper">
                <img src="./assets/images/footer-clock.png" width="34" height="34" loading="lazy" alt="Reloj">
                <ul class="footer-brand-list">
                  <li>
                    <p class="footer-brand-title">
                      <?php 
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
                      ?>
                    </p>
                    <p>
                      <?php 
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
                        
                        echo htmlspecialchars($horaApertura . ' - ' . $horaCierre);
                      ?>
                    </p>
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
              <li><p class="footer-list-title has-before">Nuestros Enlaces</p></li>
              <li><a href="landing-editable.php#home" class="footer-link">Inicio</a></li>
              <li><a href="landing-editable.php#about" class="footer-link">Nosotros</a></li>
              <li><a href="landing-editable.php#class" class="footer-link">Clases</a></li>
              <li><a href="landing-editable.php#blog" class="footer-link">Blog</a></li>
              <li><a href="landing-editable.php#planes" class="footer-link">Planes</a></li>
              <li><a href="landing-editable.php#app" class="footer-link">App</a></li>
              <li><a href="#" class="footer-link">Productos</a></li>
            </ul>

            <ul class="footer-list">
              <li><p class="footer-list-title has-before">Contáctanos</p></li>
              <li class="footer-list-item">
                <div class="icon"><ion-icon name="location" aria-hidden="true"></ion-icon></div>
                <address class="address footer-link">
                  <?php echo htmlspecialchars($contactConfig['direccion_completa']); ?>
                </address>
              </li>
              <li class="footer-list-item">
                <div class="icon"><ion-icon name="call" aria-hidden="true"></ion-icon></div>
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
                <div class="icon"><ion-icon name="mail" aria-hidden="true"></ion-icon></div>
                <div>
                  <a href="mailto:<?php echo htmlspecialchars($contactConfig['email_1']); ?>" class="footer-link"><?php echo htmlspecialchars($contactConfig['email_1']); ?></a>

                  <?php if ($contactConfig['email_2']): ?>
                  <a href="mailto:<?php echo htmlspecialchars($contactConfig['email_2']); ?>" class="footer-link"><?php echo htmlspecialchars($contactConfig['email_2']); ?></a>
                  <?php endif; ?>
                </div>
              </li>
            </ul>

            <ul class="footer-list">
              <li><p class="footer-list-title has-before">Nuestro Boletín</p></li>
              <li>
                <form action="" class="footer-form">
                  <input type="email" name="email_address" aria-label="correo" placeholder="Correo electrónico" required class="input-field">
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
            <p class="copyright editable-mode" data-section="footer" data-element="copyright">
              <span data-editable="text"><?php echo htmlspecialchars(getEditableContent('footer', 'copyright', '© 2025 Functional Training. Todos los derechos reservados por Joel Lizarazo', $contentMap)); ?></span>
              <button class="edit-btn" onclick="openEditModal('footer', 'copyright', 'text', '<?php echo htmlspecialchars(getEditableContent('footer', 'copyright', '© 2025 Functional Training. Todos los derechos reservados por Joel Lizarazo', $contentMap)); ?>')">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                  <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                </svg>
              </button>
            </p>
            <ul class="footer-bottom-list">
              <li><a href="privacy-policy.php" class="footer-bottom-link has-before">Política de Privacidad</a></li>
              <li><a href="terms-of-use.php" class="footer-bottom-link has-before">Términos y Condiciones</a></li>
            </ul>
          </div>
        </div>
      </footer>

      <a href="https://wa.me/573185312833?text=Hola,%20me%20interesa%20saber%20más%20sobre%20Functional%20Training" 
         target="_blank" 
         rel="noopener noreferrer" 
         class="whatsapp-btn" 
         aria-label="Contáctanos por WhatsApp">
        <ion-icon name="logo-whatsapp" aria-hidden="true"></ion-icon>
      </a>

      <a href="#top" class="back-top-btn" aria-label="volver arriba" data-back-top-btn>
        <ion-icon name="caret-up-sharp" aria-hidden="true"></ion-icon>
      </a>

    </article>
  </main>

  <script src="./assets/js/script.js" defer></script>
  <script type="module" src="https://unpkg.com/ionicons@5.5.2/dist/ionicons/ionicons.esm.js"></script>
  <script nomodule src="https://unpkg.com/ionicons@5.5.2/dist/ionicons/ionicons.js"></script>
  
  <!-- Script para cargar planes dinámicamente -->
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
        const response = await fetch(apiUrl);
        
        if (!response.ok) {
          throw new Error(`Error HTTP: ${response.status} ${response.statusText}`);
        }
        
        const responseText = await response.text();
        let data;
        try {
          data = JSON.parse(responseText);
        } catch (parseError) {
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
              window.dispatchEvent(new Event('resize'));
              
              if (typeof updateCarouselPositions === 'function') {
                updateCarouselPositions(carouselList);
              }
              
              carouselList.addEventListener("scroll", function() {
                if (typeof updateCarouselPositions === 'function') {
                  window.requestAnimationFrame(() => updateCarouselPositions(carouselList));
                }
              });
              
              const pricingScrollBtn = document.querySelector(".pricing-scroll-btn");
              const pricingList = document.querySelector("#planes .pricing-list");
              const planesContainer = document.querySelector("#planes .container");
              
              if (pricingScrollBtn && pricingList && planesContainer) {
                const newCheckScrollEnd = function() {
                  const isAtEnd = pricingList.scrollWidth - pricingList.scrollLeft <= pricingList.clientWidth + 10;
                  if (isAtEnd) {
                    planesContainer.classList.add("scrolled-to-end");
                  } else {
                    planesContainer.classList.remove("scrolled-to-end");
                  }
                };
                
                pricingList.removeEventListener("scroll", newCheckScrollEnd);
                pricingList.addEventListener("scroll", newCheckScrollEnd);
                newCheckScrollEnd();
                
                const newScrollHandler = function(e) {
                  e.preventDefault();
                  const isDesktop = window.innerWidth >= 992;
                  const hasManyCards = planesCount > 3;
                  const scrollAmount = isDesktop && hasManyCards 
                    ? 380 + 30
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

  <script>
    let currentEditSection = '';
    let currentEditElement = '';
    let currentEditType = '';

    function openEditModal(section, elementId, type, currentValue) {
      currentEditSection = section;
      currentEditElement = elementId;
      currentEditType = type;
      
      const modal = document.getElementById('editModal');
      const modalTitle = document.getElementById('editModalTitle');
      const modalBody = document.getElementById('editModalBody');
      
      modalTitle.textContent = `Editar: ${section} - ${elementId}`;
      
      if (type === 'text' || type === 'html') {
        modalBody.innerHTML = `
          <label><strong>Tipo:</strong> ${type === 'html' ? 'HTML' : 'Texto'}</label>
          <textarea id="editContent" rows="6">${escapeHtml(currentValue)}</textarea>
        `;
      } else if (type === 'image') {
        modalBody.innerHTML = `
          <label><strong>Ruta de imagen actual:</strong></label>
          <input type="text" id="editContent" value="${escapeHtml(currentValue)}" placeholder="./assets/images/imagen.jpg">
          <br><br>
          <label><strong>O subir nueva imagen:</strong></label>
          <input type="file" id="editImageFile" accept="image/*" onchange="previewImage(this)">
          <div id="imagePreview"></div>
          <br>
          <label><strong>Texto alternativo (alt):</strong></label>
          <input type="text" id="editAltText" placeholder="Descripción de la imagen">
        `;
      }
      
      modal.classList.add('active');
    }

    function previewImage(input) {
      if (input.files && input.files[0]) {
        const reader = new FileReader();
        reader.onload = function(e) {
          const preview = document.getElementById('imagePreview');
          preview.innerHTML = `<img src="${e.target.result}" class="preview-image" alt="Preview">`;
        };
        reader.readAsDataURL(input.files[0]);
      }
    }

    function closeEditModal() {
      document.getElementById('editModal').classList.remove('active');
      currentEditSection = '';
      currentEditElement = '';
      currentEditType = '';
    }

    async function saveEdit() {
      const content = document.getElementById('editContent').value;
      const imageFile = document.getElementById('editImageFile')?.files[0];
      const altText = document.getElementById('editAltText')?.value || '';
      
      let imagePath = content;
      
      // Si hay una imagen nueva, subirla primero
      if (imageFile) {
        const formData = new FormData();
        formData.append('image', imageFile);
        formData.append('section', currentEditSection);
        formData.append('element_id', currentEditElement);
        
        try {
          const uploadResponse = await fetch('./api/upload_landing_image.php', {
            method: 'POST',
            body: formData
          });
          
          const uploadData = await uploadResponse.json();
          if (uploadData.success) {
            imagePath = uploadData.image_path;
          } else {
            showToast('Error al subir la imagen: ' + uploadData.message, 'error');
            return;
          }
        } catch (error) {
          showToast('Error al subir la imagen: ' + error.message, 'error');
          return;
        }
      }
      
      // Guardar el contenido
      try {
        const response = await fetch('./api/save_landing_content.php', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            section: currentEditSection,
            element_id: currentEditElement,
            content_type: currentEditType,
            content: currentEditType === 'image' ? null : content,
            image_path: currentEditType === 'image' ? imagePath : null,
            alt_text: altText
          })
        });
        
        const data = await response.json();
        
        if (data.success) {
          // Actualizar el contenido en la página
          const valueToUpdate = currentEditType === 'image' ? imagePath : content;
          updateContentOnPage(currentEditSection, currentEditElement, currentEditType, valueToUpdate);
          closeEditModal();
          
          // Mostrar mensaje de éxito
          const successMsg = document.createElement('div');
          successMsg.style.cssText = 'position: fixed; top: 20px; right: 20px; background: #4CAF50; color: white; padding: 15px 20px; border-radius: 5px; z-index: 10000; box-shadow: 0 2px 10px rgba(0,0,0,0.2);';
          successMsg.textContent = '✓ Contenido guardado exitosamente';
          document.body.appendChild(successMsg);
          
          setTimeout(() => {
            successMsg.style.transition = 'opacity 0.5s';
            successMsg.style.opacity = '0';
            setTimeout(() => successMsg.remove(), 500);
          }, 2000);
          
          // Recargar la página después de guardar para asegurar que todos los cambios se reflejen
          // Esto es especialmente importante para las tarjetas de clases
          setTimeout(() => {
            window.location.reload();
          }, 1500);
        } else {
          showToast('Error al guardar: ' + data.message, 'error');
        }
      } catch (error) {
        showToast('Error al guardar: ' + error.message, 'error');
      }
    }

    function updateContentOnPage(section, elementId, type, value) {
      // Buscar todos los elementos que coincidan (puede haber múltiples instancias)
      const elements = document.querySelectorAll(`[data-section="${section}"][data-element="${elementId}"]`);
      
      if (elements.length === 0) {
        console.warn(`No se encontró elemento con data-section="${section}" y data-element="${elementId}"`);
        return;
      }
      
      elements.forEach(element => {
        if (type === 'image') {
          const img = element.querySelector('img');
          if (img) {
            // Normalizar ruta de imagen
            let imagePath = value;
            if (imagePath && imagePath[0] !== '/' && !imagePath.startsWith('./') && !imagePath.startsWith('http')) {
              imagePath = './' + imagePath;
            }
            img.src = imagePath;
            // Actualizar también el onclick del botón de edición
            const editBtn = element.querySelector('.edit-btn');
            if (editBtn && editBtn.onclick) {
              const onclickStr = editBtn.getAttribute('onclick');
              if (onclickStr) {
                const newOnclick = onclickStr.replace(/openEditModal\([^)]+\)/, 
                  `openEditModal('${section}', '${elementId}', 'image', '${value.replace(/'/g, "\\'")}')`);
                editBtn.setAttribute('onclick', newOnclick);
              }
            }
          }
        } else {
          // Para texto, buscar el span con data-editable="text"
          const editableSpan = element.querySelector('[data-editable="text"]');
          if (editableSpan) {
            editableSpan.textContent = value;
            // Actualizar también el onclick del botón de edición
            const editBtn = element.querySelector('.edit-btn');
            if (editBtn) {
              const onclickStr = editBtn.getAttribute('onclick');
              if (onclickStr) {
                const escapedValue = value.replace(/'/g, "\\'").replace(/\n/g, '\\n');
                const newOnclick = onclickStr.replace(/openEditModal\([^)]+\)/, 
                  `openEditModal('${section}', '${elementId}', 'text', '${escapedValue}')`);
                editBtn.setAttribute('onclick', newOnclick);
              }
            }
          } else {
            // Si no hay span, actualizar el contenido del elemento directamente
            element.textContent = value;
          }
        }
      });
      
      console.log(`Actualizado: ${section}.${elementId} = ${value}`);
    }

    function escapeHtml(text) {
      const div = document.createElement('div');
      div.textContent = text;
      return div.innerHTML;
    }

    // Cerrar modal al hacer clic fuera
    document.getElementById('editModal').addEventListener('click', function(e) {
      if (e.target === this) {
        closeEditModal();
      }
    });

    // Función para mostrar toast notifications
    function showToast(message, type = 'error') {
      const toastContainer = document.querySelector('.toast-container') || (() => {
        const container = document.createElement('div');
        container.className = 'toast-container position-fixed top-0 end-0 p-3';
        container.style.zIndex = '10000';
        document.body.appendChild(container);
        return container;
      })();
      
      const toast = document.createElement('div');
      const bgColor = type === 'error' ? 'bg-danger' : type === 'success' ? 'bg-success' : 'bg-info';
      toast.className = `toast align-items-center text-white ${bgColor} border-0`;
      toast.setAttribute('role', 'alert');
      toast.innerHTML = `
        <div class="d-flex">
          <div class="toast-body">${message}</div>
          <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
        </div>
      `;
      
      toastContainer.appendChild(toast);
      
      // Intentar usar Bootstrap Toast si está disponible
      if (typeof bootstrap !== 'undefined' && bootstrap.Toast) {
        const bsToast = new bootstrap.Toast(toast, { autohide: true, delay: 5000 });
        bsToast.show();
        toast.addEventListener('hidden.bs.toast', () => toast.remove());
      } else {
        // Fallback simple
        setTimeout(() => {
          toast.style.opacity = '0';
          toast.style.transition = 'opacity 0.5s';
          setTimeout(() => toast.remove(), 500);
        }, 5000);
      }
    }
  </script>

</body>
</html>

