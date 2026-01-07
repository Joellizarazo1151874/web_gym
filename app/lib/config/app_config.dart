/// Configuración de la aplicación
class AppConfig {
  // URL base del servidor
  static const String baseUrl = 'https://ftgym.free.nf';

  // Endpoints de la API
  static const String apiBaseUrl = '$baseUrl/api';

  // Endpoints específicos
  static const String loginEndpoint = '$apiBaseUrl/mobile_login.php';
  static const String checkinEndpoint = '$apiBaseUrl/checkin.php';
  static const String notificationsEndpoint =
      '$apiBaseUrl/get_notifications.php';
  static const String userEndpoint = '$apiBaseUrl/get_user.php';
  static const String markNotificationReadEndpoint =
      '$apiBaseUrl/mark_notification_read.php';

  // Configuración de la app
  static const String appName = 'FTGym';
  static const String appVersion = '1.0.0';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
