# FTGym App - Aplicación Móvil

Aplicación móvil Flutter para el sistema de gestión de gimnasio FTGym.

## Características

- ✅ **Onboarding**: Guía interactiva para nuevos usuarios
- ✅ **Login Moderno**: Autenticación con animaciones
- ✅ **Home**: Dashboard con información de membresía y notificaciones
- ✅ **Calendario**: Visualización de eventos y clases del gimnasio
- ✅ **QR Check-in**: Código QR para acceso rápido al gimnasio
- ✅ **Perfil**: Información del usuario y configuración
- ✅ **IA Trainer**: Placeholder para entrenador de IA (próximamente)

## Requisitos

- Flutter SDK 3.9.2 o superior
- Dart 3.9.2 o superior
- Android Studio / VS Code con extensiones de Flutter
- Dispositivo Android/iOS o emulador

## Instalación

1. Asegúrate de tener Flutter instalado:
```bash
flutter --version
```

2. Instala las dependencias:
```bash
cd app
flutter pub get
```

3. Ejecuta la aplicación:
```bash
flutter run
```

## Configuración

La aplicación está configurada para conectarse al servidor en:
- **URL Base**: `https://ftgym.free.nf`

Puedes modificar esta URL en `lib/config/app_config.dart`

## Estructura del Proyecto

```
lib/
├── config/           # Configuración (colores, tema, API)
├── models/          # Modelos de datos
├── providers/       # State management (Provider)
├── screens/         # Pantallas de la aplicación
│   ├── auth/       # Login
│   ├── onboarding/  # Onboarding
│   ├── home/       # Home screen
│   ├── calendar/   # Calendario
│   ├── qr/         # QR Check-in
│   ├── profile/    # Perfil
│   ├── ai_trainer/ # IA Trainer
│   └── main/       # Navegación principal
└── services/       # Servicios API
```

## Colores y Tema

Los colores están basados en el landing page:
- **Primary**: Coquelicot (Rojo/Naranja) - `#E63946`
- **Rich Black**: `#1A1F2E`
- **Silver Metallic**: `#A8B0B8`

Los colores son configurables en `lib/config/app_colors.dart`

## APIs Utilizadas

- `POST /api/mobile_login.php` - Login
- `POST /api/checkin.php` - Check-in
- `GET /api/get_notifications.php` - Notificaciones
- `POST /api/mark_notification_read.php` - Marcar notificación como leída

## Desarrollo

### Agregar nuevas pantallas

1. Crea el archivo en `lib/screens/`
2. Agrega la ruta en `lib/main.dart`
3. Si es necesario, agrega al menú de navegación en `lib/screens/main/main_navigation.dart`

### Modificar colores

Edita `lib/config/app_colors.dart` para cambiar los colores de la aplicación.

## Notas

- La aplicación usa Provider para el manejo de estado
- Las sesiones se guardan en SharedPreferences
- El token de sesión se envía en las cookies para autenticación
- El entrenador de IA es un placeholder y se implementará más adelante

## Licencia

Este proyecto es privado y propiedad de FTGym.
