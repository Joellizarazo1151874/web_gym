import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import '../services/api_service.dart';
import '../models/chat_model.dart';
import '../screens/social/chat_conversation_screen.dart';
import '../screens/social/friend_requests_screen.dart';
import '../utils/navigator_key.dart';

/// Servicio para manejar notificaciones push con Firebase Cloud Messaging
class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final ApiService _apiService = ApiService();
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Rastrear el chat actual en el que está el usuario
  static int? _currentChatId;
  
  // Stream para notificar a la UI sobre nuevos mensajes/eventos
  static final StreamController<Map<String, dynamic>> _onNotificationReceivedController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  /// Stream que emite los datos de las notificaciones recibidas en primer plano
  static Stream<Map<String, dynamic>> get onNotificationReceived => _onNotificationReceivedController.stream;
  
  
  /// Obtener el ID del chat actual
  static int? get currentChatId => _currentChatId;
  
  /// Establecer el chat actual
  static void setCurrentChatId(int? chatId) {
    _currentChatId = chatId;
    if (kDebugMode) {
      print('📱 Chat actual establecido: ${chatId ?? "ninguno"}');
    }
  }

  /// Inicializar el servicio de notificaciones push
  static Future<void> initialize() async {
    try {
      // Inicializar notificaciones locales
      await _initializeLocalNotifications();
      
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

  /// Inicializar notificaciones locales
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Cuando el usuario toca una notificación local
        if (response.payload != null) {
          try {
            // El payload es JSON string
            final data = Map<String, dynamic>.from(
              jsonDecode(response.payload!) as Map,
            );
            final type = data['type'] as String?;
            if (type == 'chat_message') {
              final chatId = int.tryParse(data['chat_id']?.toString() ?? '');
              if (chatId != null) {
                _handleChatNotification(chatId, data['remitente_nombre']?.toString());
              }
            } else if (type == 'new_post') {
              _handlePostNotification();
            } else if (type == 'friend_request') {
              _handleFriendRequestNotification();
            } else if (type == 'system_notification') {
              _handleSystemNotification();
            }
          } catch (e) {
            if (kDebugMode) {
              print('❌ Error al procesar notificación local: $e');
            }
          }
        }
      },
    );
    
    // Crear canal de notificaciones para Android
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'Notificaciones importantes',
        description: 'Este canal se usa para notificaciones importantes',
        importance: Importance.high,
        playSound: true,
      );
      
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }
  
  /// Mostrar notificación local
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    required Map<String, String> data,
    String? imageUrl,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel',
      'Notificaciones importantes',
      channelDescription: 'Este canal se usa para notificaciones importantes',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );
    
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    
    // Convertir data a JSON string para payload
    final payload = jsonEncode(data);
    
    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
      payload: payload,
    );
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
      
      final data = message.data;
      final type = data['type'] as String?;
      
      // Notificaciones de posts: siempre mostrar
      if (type == 'new_post') {
        _showLocalNotification(
          title: message.notification?.title ?? 'Nuevo post',
          body: message.notification?.body ?? '',
          data: Map<String, String>.from(data),
          imageUrl: data['usuario_foto'] as String?,
        );
      }
      // Notificaciones de solicitudes: siempre mostrar
      else if (type == 'friend_request') {
        _showLocalNotification(
          title: message.notification?.title ?? 'Nueva solicitud',
          body: message.notification?.body ?? '',
          data: Map<String, String>.from(data),
          imageUrl: data['remitente_foto'] as String?,
        );
      }
      // Notificaciones del sistema (cumpleaños, membresía, etc.): siempre mostrar
      else if (type == 'system_notification') {
        _showLocalNotification(
          title: message.notification?.title ?? 'Notificación',
          body: message.notification?.body ?? '',
          data: Map<String, String>.from(data),
          imageUrl: data['usuario_foto'] as String?,
        );
      }
      // Notificaciones de mensajes: solo si NO está en ese chat
      else if (type == 'chat_message') {
        final chatIdStr = data['chat_id'] as String?;
        if (chatIdStr != null) {
          final chatId = int.tryParse(chatIdStr);
          // Solo mostrar si no está en ese chat específico
          if (chatId != null && _currentChatId != chatId) {
            _showLocalNotification(
              title: message.notification?.title ?? '',
              body: message.notification?.body ?? '',
              data: Map<String, String>.from(data),
              imageUrl: data['remitente_foto'] as String?,
            );
          } else {
            if (kDebugMode) {
              print('🔕 No se muestra notificación: usuario está en el chat $chatId');
            }
          }
        }
      
      // Notificar a través del stream para que las pantallas puedan actualizarse
      _onNotificationReceivedController.add(data);
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
  static void _handleNotificationTap(RemoteMessage message) async {
    final data = message.data;
    final type = data['type'] as String?;

    if (kDebugMode) {
      print('🔔 Manejando tap en notificación - Tipo: $type');
    }

    // Esperar un poco para que la app termine de inicializar
    await Future.delayed(const Duration(milliseconds: 500));

    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      if (kDebugMode) {
        print('⚠️ Navigator no disponible aún');
      }
      // Reintentar después de un segundo
      Future.delayed(const Duration(seconds: 1), () {
        _handleNotificationTap(message);
      });
      return;
    }

    if (type == 'new_post') {
      // Navegar a la pantalla de posts/social (índice 4 en MainNavigation)
      navigator.pushNamedAndRemoveUntil(
        '/home', 
        (route) => false,
        arguments: {'initialIndex': 4},
      );
      if (kDebugMode) {
        print('📝 Navegando a posts/social (Tab index 4)');
      }
    } else if (type == 'friend_request') {
      // Navegar a la pantalla de solicitudes
      // Primero ir a home en el tab social (índice 4)
      navigator.pushNamedAndRemoveUntil(
        '/home', 
        (route) => false,
        arguments: {'initialIndex': 4},
      );
      
      // Esperar un poco para que la navegación se complete
      await Future.delayed(const Duration(milliseconds: 400));
      
      // Navegar a la pantalla de solicitudes
      navigator.push(
        MaterialPageRoute(
          builder: (_) => const FriendRequestsScreen(),
        ),
      );
      
      if (kDebugMode) {
        print('👤 Navegando a solicitudes de amistad');
      }
    } else if (type == 'system_notification') {
      // Navegar a la pantalla de notificaciones
      navigator.pushNamedAndRemoveUntil('/home', (route) => false);
      
      // Esperar un poco para que la navegación se complete
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Navegar a la pantalla de notificaciones
      navigator.pushNamed('/notifications');
      
      if (kDebugMode) {
        print('🔔 Navegando a notificaciones del sistema');
      }
    } else if (type == 'chat_message') {
      final chatIdStr = data['chat_id'] as String?;
      if (chatIdStr != null) {
        final chatId = int.tryParse(chatIdStr);
        if (chatId != null) {
          if (kDebugMode) {
            print('💬 Navegando al chat ID: $chatId');
          }
          
          // Navegar primero a home en el tab de mensajes (índice 4 en MainNavigation)
          navigator.pushNamedAndRemoveUntil(
            '/home', 
            (route) => false,
            arguments: {'initialIndex': 4},
          );
          
          // Esperar un poco para que la navegación se complete y el tab social se cargue
          await Future.delayed(const Duration(milliseconds: 400));
          
          // Obtener la lista de chats y buscar el chat específico
          try {
            final chats = await _apiService.getChats();
            final chat = chats.firstWhere(
              (c) => c.id == chatId,
              orElse: () => ChatModel(
                id: chatId,
                nombre: data['remitente_nombre'] as String? ?? 'Chat',
                esGrupal: false,
                creadoEn: DateTime.now().toIso8601String(),
                ultimoMensaje: null,
                ultimoMensajeEn: null,
                ultimoRemitente: null,
                unreadCount: 0,
              ),
            );
            
            // Navegar al chat
            navigator.push(
              MaterialPageRoute(
                builder: (_) => ChatConversationScreen(chat: chat),
              ),
            );
            
            if (kDebugMode) {
              print('✅ Navegado al chat: ${chat.nombre}');
            }
          } catch (e) {
            if (kDebugMode) {
              print('❌ Error al navegar al chat: $e');
            }
            // Si hay error, crear un chat básico con la información disponible
            final chat = ChatModel(
              id: chatId,
              nombre: data['remitente_nombre'] as String? ?? 'Chat',
              esGrupal: false,
              creadoEn: DateTime.now().toIso8601String(),
              ultimoMensaje: null,
              ultimoMensajeEn: null,
              ultimoRemitente: null,
              unreadCount: 0,
            );
            navigator.push(
              MaterialPageRoute(
                builder: (_) => ChatConversationScreen(chat: chat),
              ),
            );
          }
        }
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
  
  /// Manejar notificación de chat (helper)
  static void _handleChatNotification(int chatId, String? remitenteNombre) {
    _handleNotificationTap(RemoteMessage(
      notification: RemoteNotification(
        title: remitenteNombre ?? 'Mensaje',
        body: '',
      ),
      data: {
        'type': 'chat_message',
        'chat_id': chatId.toString(),
      },
    ));
  }
  
  /// Manejar notificación de post (helper)
  static void _handlePostNotification() {
    _handleNotificationTap(RemoteMessage(
      notification: const RemoteNotification(
        title: 'Nuevo post',
        body: '',
      ),
      data: {
        'type': 'new_post',
      },
    ));
  }
  
  /// Manejar notificación de solicitud (helper)
  static void _handleFriendRequestNotification() {
    _handleNotificationTap(RemoteMessage(
      notification: const RemoteNotification(
        title: 'Nueva solicitud',
        body: '',
      ),
      data: {
        'type': 'friend_request',
      },
    ));
  }
  
  /// Manejar notificación del sistema (helper)
  static void _handleSystemNotification() {
    _handleNotificationTap(RemoteMessage(
      notification: const RemoteNotification(
        title: 'Notificación',
        body: '',
      ),
      data: {
        'type': 'system_notification',
      },
    ));
  }
}
