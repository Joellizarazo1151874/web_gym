import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/user_model.dart';
import '../models/membership_model.dart';
import '../models/notification_model.dart';
import '../models/post_model.dart';
import '../models/chat_model.dart';
import '../models/chat_message_model.dart';
import '../models/chat_participant_model.dart';
import '../models/friend_request_model.dart';
import '../models/search_user_model.dart';
import '../models/class_model.dart';
import '../models/class_schedule_model.dart';

class ApiService {
  late Dio _dio;
  String? _sessionToken;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.connectionTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        followRedirects: true,
        maxRedirects: 5,
        validateStatus: (status) {
          return status != null && status < 500;
        },
      ),
    );

    // Interceptor para agregar token de sesión
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_sessionToken != null) {
            options.headers['Cookie'] = 'PHPSESSID=$_sessionToken';
          }
          return handler.next(options);
        },
      ),
    );
  }

  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        AppConfig.loginEndpoint.replaceFirst(AppConfig.apiBaseUrl, ''),
        data: {'email': email, 'password': password},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          _sessionToken = data['token'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('session_token', _sessionToken!);

          return {
            'success': true,
            'user': UserModel.fromJson(data['user']),
            'membership': data['membership'] != null
                ? MembershipModel.fromJson(data['membership'])
                : null,
            'token': _sessionToken,
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Error en el login',
          };
        }
      }
      throw Exception('Error en la respuesta del servidor');
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response?.data;
        return {
          'success': false,
          'message': data['message'] ?? 'Error en el login',
        };
      }
      return {
        'success': false,
        'message': 'Error de conexión. Verifica tu internet.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error inesperado: $e'};
    }
  }

  // Check-in
  Future<Map<String, dynamic>> checkIn(String documento) async {
    try {
      final response = await _dio.post(
        AppConfig.checkinEndpoint.replaceFirst(AppConfig.apiBaseUrl, ''),
        data: {
          'cedula': documento,
          'codigo_qr': documento,
          'dispositivo': 'mobile-app',
        },
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? '',
          'data': data,
        };
      }
      throw Exception('Error en la respuesta del servidor');
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response?.data;
        return {
          'success': false,
          'message': data['message'] ?? 'Error en el check-in',
          'code': data['code'],
        };
      }
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  // Obtener notificaciones
  Future<List<NotificationModel>> getNotifications({
    bool soloNoLeidas = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');

      final response = await _dio.get(
        AppConfig.notificationsEndpoint.replaceFirst(AppConfig.apiBaseUrl, ''),
        queryParameters: {
          'solo_no_leidas': soloNoLeidas ? '1' : '0',
          'limite': 50,
        },
        options: Options(headers: {'Cookie': 'PHPSESSID=$_sessionToken'}),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final List<dynamic> notifications = data['notificaciones'] ?? [];
          return notifications
              .map((json) => NotificationModel.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Marcar notificación como leída
  Future<bool> markNotificationRead(int notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');

      final response = await _dio.post(
        AppConfig.markNotificationReadEndpoint.replaceFirst(
          AppConfig.apiBaseUrl,
          '',
        ),
        data: {'notificacion_id': notificationId},
        options: Options(headers: {'Cookie': 'PHPSESSID=$_sessionToken'}),
      );

      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // Cargar token guardado
  Future<void> loadSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    _sessionToken = prefs.getString('session_token');
  }

  // Cerrar sesión
  Future<void> logout() async {
    _sessionToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_token');
    await prefs.remove('user_data');
  }

  // Registro de usuario
  Future<Map<String, dynamic>> register({
    required String nombre,
    required String apellido,
    required String email,
    required String tipoDocumento,
    required String documento,
    required String password,
    required String passwordConfirm,
    String? telefono,
    DateTime? fechaNacimiento,
    String? genero,
    String? direccion,
    String? ciudad,
  }) async {
    try {
      final data = {
        'nombre': nombre,
        'apellido': apellido,
        'email': email,
        'tipo_documento': tipoDocumento,
        'documento': documento,
        'password': password,
        'password_confirm': passwordConfirm,
        if (telefono != null) 'telefono': telefono,
        if (fechaNacimiento != null)
          'fecha_nacimiento':
              '${fechaNacimiento.year}-${fechaNacimiento.month.toString().padLeft(2, '0')}-${fechaNacimiento.day.toString().padLeft(2, '0')}',
        if (genero != null) 'genero': genero,
        if (direccion != null) 'direccion': direccion,
        if (ciudad != null) 'ciudad': ciudad,
      };

      final response = await _dio.post(
        '/mobile_register.php',
        data: data,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      return {'success': false, 'message': 'Error al procesar la solicitud'};
    } catch (e) {
      print('Error en register: $e');
      return {
        'success': false,
        'message': 'Error de conexión. Verifica tu internet.',
      };
    }
  }

  // Recuperar contraseña
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        '/mobile_forgot_password.php',
        data: {'email': email},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      return {'success': false, 'message': 'Error al procesar la solicitud'};
    } catch (e) {
      print('Error en forgotPassword: $e');
      return {
        'success': false,
        'message': 'Error de conexión. Verifica tu internet.',
      };
    }
  }

  // Restablecer contraseña
  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirm,
  }) async {
    try {
      final response = await _dio.post(
        '/mobile_reset_password.php',
        data: {
          'token': token,
          'email': email,
          'password': password,
          'password_confirm': passwordConfirm,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      return {'success': false, 'message': 'Error al procesar la solicitud'};
    } catch (e) {
      print('Error en resetPassword: $e');
      return {
        'success': false,
        'message': 'Error de conexión. Verifica tu internet.',
      };
    }
  }

  // ==================== POSTS ====================

  Future<List<PostModel>> getPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');
      print(
        '🔍 getPosts - Session token: ${_sessionToken?.substring(0, 10)}...',
      );
      final response = await _dio.get(
        '/mobile_get_posts.php',
        options: Options(headers: {'Cookie': 'PHPSESSID=$_sessionToken'}),
      );
      print('🔍 getPosts - Status: ${response.statusCode}');
      print('🔍 getPosts - Response: ${response.data}');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> posts = response.data['posts'] ?? [];
        print('✅ getPosts - Posts obtenidos: ${posts.length}');
        return posts.map((json) => PostModel.fromJson(json)).toList();
      } else {
        print('❌ getPosts - Error: ${response.data}');
      }
      return [];
    } catch (e) {
      print('❌ getPosts - Exception: $e');
      return [];
    }
  }

  Future<String?> uploadPostImage(String filePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');
      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
        ),
      });
      final response = await _dio.post(
        '/mobile_upload_image.php',
        data: formData,
        options: Options(
          headers: {
            'Cookie': 'PHPSESSID=$_sessionToken',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['url'];
      }
      return null;
    } catch (e) {
      print('Error al subir imagen: $e');
      return null;
    }
  }

  Future<PostModel?> createPost({
    required String contenido,
    String? imagenUrl,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');
      final response = await _dio.post(
        '/mobile_create_post.php',
        data: {
          'contenido': contenido,
          if (imagenUrl != null) 'imagen_url': imagenUrl,
        },
        options: Options(headers: {'Cookie': 'PHPSESSID=$_sessionToken'}),
      );
      if (response.statusCode == 200 &&
          response.data['success'] == true &&
          response.data['post'] != null) {
        return PostModel.fromJson(response.data['post']);
      }
      return null;
    } catch (e) {
      print('Error al crear post: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> togglePostLike(int postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');
      final response = await _dio.post(
        '/mobile_toggle_post_like.php',
        data: {'post_id': postId},
        options: Options(headers: {'Cookie': 'PHPSESSID=$_sessionToken'}),
      );
      if (response.statusCode == 200) return response.data;
      return {'success': false};
    } catch (e) {
      return {'success': false};
    }
  }

  Future<bool> updatePost({
    required int postId,
    required String contenido,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');
      final response = await _dio.post(
        '/mobile_update_post.php',
        data: {'post_id': postId, 'contenido': contenido},
        options: Options(headers: {'Cookie': 'PHPSESSID=$_sessionToken'}),
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deletePost(int postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');
      final response = await _dio.post(
        '/mobile_delete_post.php',
        data: {'post_id': postId},
        options: Options(headers: {'Cookie': 'PHPSESSID=$_sessionToken'}),
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> reportPost(int postId, String motivo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');
      final response = await _dio.post(
        '/mobile_report_post.php',
        data: {'post_id': postId, 'motivo': motivo},
        options: Options(headers: {'Cookie': 'PHPSESSID=$_sessionToken'}),
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // ==================== CHATS ====================

  Future<List<ChatModel>> getChats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');
      print(
        '🔍 getChats - Session token: ${_sessionToken?.substring(0, 10)}...',
      );
      final response = await _dio.get(
        '/mobile_get_chats.php',
        options: Options(headers: {'Cookie': 'PHPSESSID=$_sessionToken'}),
      );
      print('🔍 getChats - Status: ${response.statusCode}');
      print('🔍 getChats - Response: ${response.data}');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> chats = response.data['chats'] ?? [];
        print('✅ getChats - Chats obtenidos: ${chats.length}');
        return chats.map((json) => ChatModel.fromJson(json)).toList();
      } else {
        print('❌ getChats - Error: ${response.data}');
      }
      return [];
    } catch (e) {
      print('❌ getChats - Exception: $e');
      return [];
    }
  }

  Future<List<ChatMessageModel>> getChatMessages(int chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');
      final response = await _dio.get(
        '/mobile_get_chat_messages.php',
        queryParameters: {'chat_id': chatId},
        options: Options(headers: {'Cookie': 'PHPSESSID=$_sessionToken'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> messages = response.data['messages'] ?? [];
        return messages.map((json) => ChatMessageModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<ChatMessageModel?> sendChatMessage({
    required int chatId,
    required String mensaje,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');
      final response = await _dio.post(
        '/mobile_send_chat_message.php',
        data: {'chat_id': chatId, 'mensaje': mensaje},
        options: Options(headers: {'Cookie': 'PHPSESSID=$_sessionToken'}),
      );
      if (response.statusCode == 200 &&
          response.data['success'] == true &&
          response.data['message'] != null) {
        return ChatMessageModel.fromJson(response.data['message']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<ChatParticipantModel>> getChatParticipants(int chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');
      final response = await _dio.get(
        '/mobile_get_chat_participants.php',
        queryParameters: {'chat_id': chatId},
        options: Options(headers: {'Cookie': 'PHPSESSID=$_sessionToken'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> participants = response.data['participants'] ?? [];
        return participants
            .map((json) => ChatParticipantModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> addChatParticipant({
    required int chatId,
    required String email,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');
      final response = await _dio.post(
        '/mobile_add_chat_participant.php',
        data: {'chat_id': chatId, 'email': email},
        options: Options(headers: {'Cookie': 'PHPSESSID=$_sessionToken'}),
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteChat(int chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');
      final response = await _dio.post(
        '/mobile_delete_chat.php',
        data: {'chat_id': chatId},
        options: Options(headers: {'Cookie': 'PHPSESSID=$_sessionToken'}),
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // ==================== FRIEND REQUESTS ====================

  Future<List<FriendRequestModel>> getFriendRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');
      final response = await _dio.get(
        '/mobile_get_friend_requests.php',
        options: Options(headers: {'Cookie': 'PHPSESSID=$_sessionToken'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> requests = response.data['requests'] ?? [];
        return requests
            .map((json) => FriendRequestModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> sendFriendRequest(int destinatarioId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');
      final response = await _dio.post(
        '/mobile_send_friend_request.php',
        data: {'destinatario_id': destinatarioId},
        options: Options(headers: {'Cookie': 'PHPSESSID=$_sessionToken'}),
      );
      if (response.statusCode == 200) return response.data;
      return {'success': false};
    } catch (e) {
      return {'success': false};
    }
  }

  Future<Map<String, dynamic>> respondFriendRequest({
    required int solicitudId,
    required String accion,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');
      final response = await _dio.post(
        '/mobile_respond_friend_request.php',
        data: {'solicitud_id': solicitudId, 'accion': accion},
        options: Options(headers: {'Cookie': 'PHPSESSID=$_sessionToken'}),
      );
      if (response.statusCode == 200) {
        return response.data;
      }
      return {'success': false};
    } catch (e) {
      return {'success': false};
    }
  }

  Future<List<SearchUserModel>> searchUsers(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');
      final response = await _dio.get(
        '/mobile_search_users.php',
        queryParameters: {'q': query},
        options: Options(headers: {'Cookie': 'PHPSESSID=$_sessionToken'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> users = response.data['users'] ?? [];
        return users.map((json) => SearchUserModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ==================== CLASES ====================

  Future<List<ClassModel>> getClasses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');
      final response = await _dio.get(
        '/mobile_get_classes.php',
        options: Options(headers: {'Cookie': 'PHPSESSID=$_sessionToken'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> classes = response.data['classes'] ?? [];
        return classes.map((json) => ClassModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<ClassScheduleModel>> getClassSchedules({
    DateTime? fecha,
    int? claseId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');
      final queryParams = <String, dynamic>{};
      if (fecha != null) {
        queryParams['fecha'] =
            '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
      }
      if (claseId != null) queryParams['clase_id'] = claseId;
      final response = await _dio.get(
        '/mobile_get_class_schedules.php',
        queryParameters: queryParams,
        options: Options(headers: {'Cookie': 'PHPSESSID=$_sessionToken'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> schedules = response.data['schedules'] ?? [];
        return schedules
            .map((json) => ClassScheduleModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> reserveClass(int horarioId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');
      final response = await _dio.post(
        '/mobile_reserve_class.php',
        data: {'horario_id': horarioId},
        options: Options(headers: {'Cookie': 'PHPSESSID=$_sessionToken'}),
      );
      if (response.statusCode == 200) return response.data;
      return {'success': false};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  Future<bool> cancelReservation(int reservaId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');
      final response = await _dio.post(
        '/mobile_cancel_reservation.php',
        data: {'reserva_id': reservaId},
        options: Options(headers: {'Cookie': 'PHPSESSID=$_sessionToken'}),
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }
}
