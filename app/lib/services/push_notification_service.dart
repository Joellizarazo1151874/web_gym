import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../services/api_service.dart';

/// Servicio para manejar notificaciones push con Firebase Cloud Messaging
class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final ApiService _apiService = ApiService();

  /// Inicializar el servicio de notificaciones push
  static Future<void> initialize() async {
    try {
      // Solicitar permisos de notificación
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        print('🔔 Permisos de notificación: ${settings.authorizationStatus}');
      }

      // Obtener token FCM
      String? token = await _messaging.getToken();
      
      if (token != null) {
        if (kDebugMode) {
          print('📱 Token FCM obtenido: ${token.substring(0, 20)}...');
        }
        
        // Determinar plataforma
        String plataforma = 'android';
        if (Platform.isIOS) {
          plataforma = 'ios';
        }
        
        // Registrar token en el servidor
        await _registerToken(token, plataforma);
      } else {
        if (kDebugMode) {
          print('⚠️ No se pudo obtener el token FCM');
        }
      }

      // Escuchar cuando el token se actualiza
      _messaging.onTokenRefresh.listen((newToken) {
        if (kDebugMode) {
          print('🔄 Token FCM actualizado: ${newToken.substring(0, 20)}...');
        }
        
        String plataforma = Platform.isIOS ? 'ios' : 'android';
        _registerToken(newToken, plataforma);
      });

      // Configurar handlers para notificaciones
      _setupNotificationHandlers();
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al inicializar notificaciones push: $e');
      }
    }
  }

  /// Registrar token FCM en el servidor
  static Future<void> _registerToken(String token, String plataforma) async {
    try {
      final success = await _apiService.registerFCMToken(token, plataforma);
      if (kDebugMode) {
        if (success) {
          print('✅ Token FCM registrado en el servidor');
        } else {
          print('❌ Error al registrar token FCM en el servidor');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al registrar token: $e');
      }
    }
  }

  /// Configurar handlers para notificaciones
  static void _setupNotificationHandlers() {
    // Notificaciones cuando la app está en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('📬 Notificación recibida (app en primer plano)');
        print('📬 Título: ${message.notification?.title}');
        print('📬 Cuerpo: ${message.notification?.body}');
        print('📬 Datos: ${message.data}');
      }
      
      // Aquí puedes mostrar una notificación local o actualizar la UI
      // Por ejemplo, actualizar el contador de notificaciones no leídas
    });

    // Notificaciones cuando el usuario toca la notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('👆 Usuario tocó la notificación');
        print('📬 Datos: ${message.data}');
      }
      
      // Navegar a la pantalla correspondiente según el tipo de notificación
      _handleNotificationTap(message);
    });

    // Verificar si la app se abrió desde una notificación
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        if (kDebugMode) {
          print('🚀 App abierta desde notificación');
        }
        _handleNotificationTap(message);
      }
    });
  }

  /// Manejar cuando el usuario toca una notificación
  static void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] as String?;

    if (type == 'new_post') {
      // Navegar a la pantalla de posts/social
      // Navigator.pushNamed(context, '/home', arguments: {'tab': 'social'});
    } else if (type == 'chat_message') {
      final chatId = data['chat_id'] as String?;
      if (chatId != null) {
        // Navegar al chat específico
        // Navigator.pushNamed(context, '/chat', arguments: {'chatId': chatId});
      }
    }
  }

  /// Obtener el token FCM actual
  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  /// Suscribirse a un tema (opcional, para notificaciones por temas)
  static Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    if (kDebugMode) {
      print('✅ Suscrito al tema: $topic');
    }
  }

  /// Desuscribirse de un tema
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    if (kDebugMode) {
      print('✅ Desuscrito del tema: $topic');
    }
  }
}
