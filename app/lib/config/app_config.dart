/// Configuración de la aplicación
class AppConfig {
  // URL base del servidor
  static const String baseUrl = 'https://functionaltraining.site';

  // Endpoints de la API
  static const String apiBaseUrl = '$baseUrl/api';

  // Endpoints específicos
  static const String loginEndpoint = '$apiBaseUrl/mobile_login.php';
  static const String registerEndpoint = '$apiBaseUrl/mobile_register.php';
  static const String forgotPasswordEndpoint =
      '$apiBaseUrl/mobile_forgot_password.php';
  static const String resetPasswordEndpoint =
      '$apiBaseUrl/mobile_reset_password.php';
  static const String checkinEndpoint = '$apiBaseUrl/checkin.php';
  static const String notificationsEndpoint =
      '$apiBaseUrl/get_notifications.php';
  static const String userEndpoint = '$apiBaseUrl/get_user.php';
  static const String getCurrentUserEndpoint =
      '$apiBaseUrl/mobile_get_current_user.php';
  static const String markNotificationReadEndpoint =
      '$apiBaseUrl/mark_notification_read.php';
  static const String deleteNotificationEndpoint =
      '$apiBaseUrl/mobile_delete_notification.php';
  static const String classesEndpoint = '$apiBaseUrl/mobile_get_classes.php';
  static const String classSchedulesEndpoint =
      '$apiBaseUrl/mobile_get_class_schedules.php';
  static const String createClassEndpoint =
      '$apiBaseUrl/mobile_create_class.php';
  static const String updateClassEndpoint =
      '$apiBaseUrl/mobile_update_class.php';
  static const String deleteClassEndpoint =
      '$apiBaseUrl/mobile_delete_class.php';
  static const String createClassScheduleEndpoint =
      '$apiBaseUrl/mobile_create_class_schedule.php';
  static const String updateClassScheduleEndpoint =
      '$apiBaseUrl/mobile_update_class_schedule.php';
  static const String deleteClassScheduleEndpoint =
      '$apiBaseUrl/mobile_delete_class_schedule.php';
  static const String aiTrainerEndpoint = '$apiBaseUrl/mobile_get_ai_response.php';

  // Social / Posts

  static const String postsEndpoint = '$apiBaseUrl/mobile_get_posts.php';
  static const String createPostEndpoint = '$apiBaseUrl/mobile_create_post.php';
  static const String togglePostLikeEndpoint =
      '$apiBaseUrl/mobile_toggle_post_like.php';
  static const String updatePostEndpoint = '$apiBaseUrl/mobile_update_post.php';
  static const String deletePostEndpoint = '$apiBaseUrl/mobile_delete_post.php';
  static const String reportPostEndpoint = '$apiBaseUrl/mobile_report_post.php';

  // Social / Chats
  static const String getChatsEndpoint = '$apiBaseUrl/mobile_get_chats.php';
  static const String getChatMessagesEndpoint =
      '$apiBaseUrl/mobile_get_chat_messages.php';
  static const String sendChatMessageEndpoint =
      '$apiBaseUrl/mobile_send_chat_message.php';
  static const String createChatEndpoint = '$apiBaseUrl/mobile_create_chat.php';
  static const String getChatParticipantsEndpoint =
      '$apiBaseUrl/mobile_get_chat_participants.php';
  static const String addChatParticipantEndpoint =
      '$apiBaseUrl/mobile_add_chat_participant.php';
  static const String deleteChatEndpoint = '$apiBaseUrl/mobile_delete_chat.php';

  // Social / Solicitudes de chat
  static const String sendFriendRequestEndpoint =
      '$apiBaseUrl/mobile_send_friend_request.php';
  static const String getFriendRequestsEndpoint =
      '$apiBaseUrl/mobile_get_friend_requests.php';
  static const String respondFriendRequestEndpoint =
      '$apiBaseUrl/mobile_respond_friend_request.php';
  static const String createPrivateChatEndpoint =
      '$apiBaseUrl/mobile_create_private_chat.php';

  // Social / Buscar usuarios
  static const String searchUsersEndpoint =
      '$apiBaseUrl/mobile_search_users.php';

  // Configuración de contacto
  static const String contactConfigEndpoint = '$apiBaseUrl/get_contact_config.php';

  // Configuración de la app

  static const String appName = 'FTGym';
  static const String appVersion = '1.0.0';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
