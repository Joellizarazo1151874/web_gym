<?php
/**
 * Página de Productos - Functional Training Gym
 */
require_once __DIR__ . '/database/config.php';
require_once __DIR__ . '/database/config_helpers.php';

// Obtener logo de la configuración
$logoProductos = './favicon.svg';
$faviconProductos = './favicon.svg';

try {
    $db = getDB();
    $config = obtenerConfiguracion($db);
    
    if (!empty($config['logo_empresa'])) {
        $relativeLogo = $config['logo_empresa'];
        if ($relativeLogo[0] !== '/' && substr($relativeLogo, 0, 2) !== './') {
            $relativeLogo = './' . $relativeLogo;
        }
        $logoPathFs = __DIR__ . '/' . ltrim($relativeLogo, './');
        if (file_exists($logoPathFs)) {
            $logoProductos = $relativeLogo;
            $faviconProductos = $relativeLogo;
        }
    }
} catch (Exception $e) {
    // Si hay error, usar logo por defecto
    error_log("Error al obtener logo de configuración en productos.php: " . $e->getMessage());
}
?>
<!DOCTYPE html>
<html lang="es">

<head>
  <meta charset="UTF-8">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Productos - Functional Training</title>

  <!-- 
    - favicon
  -->
  <link rel="shortcut icon" href="<?php echo htmlspecialchars($faviconProductos); ?>" type="<?php echo (pathinfo($faviconProductos, PATHINFO_EXTENSION) === 'svg' ? 'image/svg+xml' : 'image/x-icon'); ?>">

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

</head>

<body id="top" class="page-productos">

  <!-- 
    - #HEADER
  -->

  <header class="header" data-header>
    <div class="container">

      <a href="index.php" class="logo">
        <img src="<?php echo htmlspecialchars($logoProductos); ?>" alt="Functional Training" width="40" height="40" aria-hidden="true">

        <span class="span logo-full">Functional Training</span>
        <span class="span logo-short">FT GYM</span>
      </a>

      <nav class="navbar" data-navbar>

        <button class="nav-close-btn" aria-label="cerrar menú" data-nav-toggler>
          <ion-icon name="close-sharp" aria-hidden="true"></ion-icon>
        </button>

        <ul class="navbar-list">

          <li>
            <a href="index.php#home" class="navbar-link" data-nav-link>Inicio</a>
          </li>

          <li>
            <a href="index.php#about" class="navbar-link" data-nav-link>Nosotros</a>
          </li>

          <li>
            <a href="index.php#class" class="navbar-link" data-nav-link>Clases</a>
          </li>

          <li>
            <a href="index.php#blog" class="navbar-link" data-nav-link>Blog</a>
          </li>

          <li>
            <a href="index.php#planes" class="navbar-link" data-nav-link>Planes</a>
          </li>

          <li>
            <a href="index.php#app" class="navbar-link" data-nav-link>App</a>
          </li>

          <li>
            <a href="productos.php" class="navbar-link active" data-nav-link>Productos</a>
          </li>

        </ul>

      </nav>

      <a href="index.php#planes" class="btn btn-secondary">Únete ahora</a>

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
        - #PRODUCTOS
      -->

      <section class="section productos" id="productos" aria-label="productos" style="padding-block-start: calc(var(--section-padding) + 80px);">
        <div class="container">

          <p class="section-subtitle">Tienda</p>

          <h2 class="h2 section-title text-center">Nuestros Productos</h2>

          <p class="section-text text-center" style="max-width: 700px; margin-inline: auto; margin-block-end: 50px;">
            Descubre nuestra selección de productos premium para complementar tu entrenamiento. 
            Proteínas, accesorios, ropa deportiva y más, disponibles en nuestro gimnasio.
          </p>

          <div id="productos-loading" class="text-center" style="padding: 40px;">
            <p>Cargando productos...</p>
          </div>

          <ul class="productos-list" id="productos-list" style="display: none;">
            <!-- Los productos se cargarán aquí dinámicamente -->
          </ul>

          <div id="productos-empty" class="text-center" style="display: none; padding: 40px;">
            <p>No hay productos disponibles en este momento.</p>
          </div>

          <p class="section-text text-center" style="margin-block-start: 40px; max-width: 600px; margin-inline: auto;">
            <strong>Nota:</strong> Todos los productos están disponibles en nuestro gimnasio. 
            Consulta disponibilidad y realiza tu compra directamente en recepción o a través de nuestra app móvil.
          </p>

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

          <a href="index.php" class="logo">
            <img src="<?php echo htmlspecialchars($logoProductos); ?>" alt="Functional Training" width="40" height="40" aria-hidden="true">

            <span class="span">Functional Training</span>
          </a>

          <p class="footer-brand-text">
            Entrena con nosotros y alcanza tus objetivos fitness. Instalaciones modernas, 
            entrenadores profesionales y una comunidad activa.
          </p>

          <div class="wrapper">

            <img src="./assets/images/footer-clock.png" width="34" height="34" loading="lazy" alt="Reloj">

            <ul class="footer-brand-list">

              <li>
                <p class="footer-brand-title">Lunes - Viernes</p>

                <p>5:00am - 10:00pm</p>
              </li>

              <li>
                <p class="footer-brand-title">Sábado - Domingo</p>

                <p>7:00am - 2:00pm</p>
              </li>

            </ul>

          </div>

        </div>

        <ul class="footer-list">

          <li>
            <p class="footer-list-title has-before">Nuestros Enlaces</p>
          </li>

          <li>
            <a href="index.php#home" class="footer-link">Inicio</a>
          </li>

          <li>
            <a href="index.php#about" class="footer-link">Nosotros</a>
          </li>

          <li>
            <a href="index.php#class" class="footer-link">Clases</a>
          </li>

          <li>
            <a href="index.php#blog" class="footer-link">Blog</a>
          </li>

          <li>
            <a href="#" class="footer-link">Contáctanos</a>
          </li>

          <li>
            <a href="index.php#planes" class="footer-link">Planes</a>
          </li>

          <li>
            <a href="index.php#app" class="footer-link">App</a>
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
              Los Patios, Colombia Calle principal 123-45-67
            </address>
          </li>

          <li class="footer-list-item">
            <div class="icon">
              <ion-icon name="call" aria-hidden="true"></ion-icon>
            </div>

            <div>
              <a href="tel:3185312833" class="footer-link">3185312833</a>

              <a href="tel:+573185312833" class="footer-link">+57 3185312833</a>
            </div>
          </li>

          <li class="footer-list-item">
            <div class="icon">
              <ion-icon name="mail" aria-hidden="true"></ion-icon>
            </div>

            <div>
              <a href="mailto:info@Functional Training.com" class="footer-link">info@Functional Training.com</a>

              <a href="mailto:services@Functional Training.com" class="footer-link">services@Functional Training.com</a>
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

              <li>
                <a href="#" class="social-link">
                  <ion-icon name="logo-facebook"></ion-icon>
                </a>
              </li>

              <li>
                <a href="#" class="social-link">
                  <ion-icon name="logo-instagram"></ion-icon>
                </a>
              </li>

              <li>
                <a href="#" class="social-link">
                  <ion-icon name="logo-twitter"></ion-icon>
                </a>
              </li>

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
            <a href="#" class="footer-bottom-link has-before">Política de Privacidad</a>
          </li>

          <li>
            <a href="#" class="footer-bottom-link has-before">Términos y Condiciones</a>
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
    - Script para cargar productos dinámicamente
  -->
  <script>
    // Función para formatear precio
    function formatPrice(precio) {
      return '$ ' + precio.toLocaleString('es-CO');
    }

    // Función para obtener la URL base de la API
    function getApiBaseUrl() {
      // Obtener la ruta base del sitio
      const currentPath = window.location.pathname;
      const pathParts = currentPath.split('/').filter(part => part);
      
      // Construir ruta relativa hacia la API desde productos.php
      // productos.php está en la raíz, así que api/ está al mismo nivel
      // Usar ruta relativa simple
      return './api/';
    }

    // Función para cargar productos desde la API
    async function loadProducts() {
      const loadingEl = document.getElementById('productos-loading');
      const listEl = document.getElementById('productos-list');
      const emptyEl = document.getElementById('productos-empty');

      try {
        const apiUrl = getApiBaseUrl() + 'get_public_products.php';
        console.log('Cargando productos desde:', apiUrl);
        
        const response = await fetch(apiUrl);
        
        // Verificar si la respuesta es OK
        if (!response.ok) {
          throw new Error(`Error HTTP: ${response.status} ${response.statusText}`);
        }
        
        // Obtener el texto de la respuesta primero para depuración
        const responseText = await response.text();
        console.log('Respuesta de la API:', responseText);
        
        // Intentar parsear JSON
        let data;
        try {
          data = JSON.parse(responseText);
        } catch (parseError) {
          console.error('Error al parsear JSON:', parseError);
          console.error('Respuesta recibida:', responseText);
          throw new Error('La respuesta del servidor no es válida JSON');
        }

        loadingEl.style.display = 'none';

        if (data.success && data.productos && data.productos.length > 0) {
          listEl.innerHTML = '';
          listEl.style.display = ''; // Mostrar la lista (el CSS ya tiene display: grid)

          data.productos.forEach(producto => {
            const li = document.createElement('li');
            
            // Imagen por defecto si no hay imagen
            const imagenSrc = producto.imagen_url || './assets/images/producto-default.jpg';
            const imagenAlt = producto.nombre || 'Producto';
            
            li.innerHTML = `
              <div class="producto-card">
                <div class="card-banner img-holder" style="--width: 440; --height: 270;">
                  <img src="${imagenSrc}" 
                       width="440" 
                       height="270" 
                       loading="lazy"
                       alt="${imagenAlt}" 
                       class="img-cover"
                       onerror="this.src='./assets/images/producto-default.jpg'">
                </div>

                <div class="card-content">
                  <h3 class="h3">
                    <a href="#" class="card-title">${escapeHtml(producto.nombre || 'Producto')}</a>
                  </h3>

                  <p class="card-text">
                    ${escapeHtml(producto.descripcion || 'Sin descripción disponible.')}
                  </p>

                  <div class="producto-price">
                    <span class="price">${producto.precio_formateado || formatPrice(producto.precio || 0)}</span>
                  </div>
                </div>
              </div>
            `;
            
            listEl.appendChild(li);
          });

          emptyEl.style.display = 'none';
        } else {
          listEl.style.display = 'none';
          if (data.message) {
            emptyEl.innerHTML = `<p>${escapeHtml(data.message)}</p>`;
          } else {
            emptyEl.innerHTML = '<p>No hay productos disponibles en este momento.</p>';
          }
          emptyEl.style.display = 'block';
        }
      } catch (error) {
        console.error('Error al cargar productos:', error);
        loadingEl.style.display = 'none';
        listEl.style.display = 'none';
        emptyEl.innerHTML = `<p>Error al cargar los productos: ${escapeHtml(error.message)}. Por favor, intenta más tarde.</p>`;
        emptyEl.style.display = 'block';
      }
    }

    // Función para escapar HTML (prevenir XSS)
    function escapeHtml(text) {
      const div = document.createElement('div');
      div.textContent = text;
      return div.innerHTML;
    }

    // Cargar productos cuando el DOM esté listo
    document.addEventListener('DOMContentLoaded', function() {
      loadProducts();
    });
  </script>

  <!-- 
    - ionicon link
  -->
  <script type="module" src="https://unpkg.com/ionicons@5.5.2/dist/ionicons/ionicons.esm.js"></script>
  <script nomodule src="https://unpkg.com/ionicons@5.5.2/dist/ionicons/ionicons.js"></script>

</body>

</html>

