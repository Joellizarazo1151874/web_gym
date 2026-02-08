import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../config/app_config.dart';
import '../models/user_model.dart';
import '../models/membership_model.dart';
import '../models/notification_model.dart';
import '../models/post_model.dart';
import '../models/chat_model.dart';
import '../models/chat_message_model.dart';
import '../models/chat_participant_model.dart';
import '../models/friend_request_model.dart';
import '../models/contact_model.dart';
import '../models/search_user_model.dart';
import '../models/class_model.dart';
import '../models/class_schedule_model.dart';

class ApiService {
  late Dio _dio;
  String? _sessionToken;
  Future<void> Function()? onUnauthorized;
  Completer<void>? _refreshCompleter;

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

    // Interceptor para agregar token de sesión y manejar 401
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Cargar token si no está cargado
          if (_sessionToken == null) {
            final prefs = await SharedPreferences.getInstance();
            _sessionToken = prefs.getString('session_token');
          }

          if (_sessionToken != null) {
            options.headers['Cookie'] = 'PHPSESSID=$_sessionToken';
            options.headers['X-Session-ID'] = _sessionToken;
          }
          return handler.next(options);
        },
        onResponse: (response, handler) async {
          if (response.statusCode == 401) {
            final path = response.requestOptions.path;
            if (!path.contains('mobile_login.php') && onUnauthorized != null) {
              
              if (_refreshCompleter == null) {
                _refreshCompleter = Completer<void>();
                try {
                  print('🚨 [ApiService] 401 detectado en $path. Iniciando re-login...');
                  await onUnauthorized!();
                  _refreshCompleter!.complete();
                } catch (e) {
                  _refreshCompleter!.completeError(e);
                } finally {
                  _refreshCompleter = null;
                }
              } else {
                print('⏳ [ApiService] Esperando a que termine el re-login en curso para $path...');
                try {
                  await _refreshCompleter!.future;
                } catch (_) {
                  // Si el refresh falló, dejamos que el error original siga su curso
                  return handler.next(response);
                }
              }

              // Reintentar la petición original con el nuevo token
              try {
                final options = response.requestOptions;
                final retryResponse = await _dio.request(
                  options.path,
                  data: options.data,
                  queryParameters: options.queryParameters,
                  options: Options(
                    method: options.method,
                    headers: options.headers,
                  ),
                );
                return handler.resolve(retryResponse);
              } catch (e) {
                print('❌ [ApiService] Falló el re-intento tras re-login: $e');
              }
            }
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            final path = e.requestOptions.path;
            if (!path.contains('mobile_login.php') && onUnauthorized != null) {
              
              if (_refreshCompleter == null) {
                _refreshCompleter = Completer<void>();
                try {
                  print('🚨 [ApiService] 401 detectado en Error ($path). Iniciando re-login...');
                  await onUnauthorized!();
                  _refreshCompleter!.complete();
                } catch (err) {
                  _refreshCompleter!.completeError(err);
                } finally {
                  _refreshCompleter = null;
                }
              } else {
                print('⏳ [ApiService] Esperando a que termine el re-login en curso (Error) para $path...');
                try {
                  await _refreshCompleter!.future;
                } catch (_) {
                  return handler.next(e);
                }
              }

              try {
                final options = e.requestOptions;
                final retryResponse = await _dio.request(
                  options.path,
                  data: options.data,
                  queryParameters: options.queryParameters,
                  options: Options(
                    method: options.method,
                    headers: options.headers,
                  ),
                );
                return handler.resolve(retryResponse);
              } catch (err) {
                print('❌ [ApiService] Falló el re-intento tras re-login (Error): $err');
              }
            }
          }
          return handler.next(e);
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
  Future<NotificationResponse> getNotifications({
    bool soloNoLeidas = false,
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');

      if (_sessionToken == null) {
        print('⚠️ No hay sesión activa, no se pueden obtener notificaciones');
        return NotificationResponse(notifications: [], totalNoLeidas: 0, totalTodas: 0);
      }

      print('🔔 Obteniendo notificaciones - soloNoLeidas: $soloNoLeidas, offset: $offset');
      final response = await _dio.get(
        AppConfig.notificationsEndpoint.replaceFirst(AppConfig.apiBaseUrl, ''),
        queryParameters: {
          'solo_no_leidas': soloNoLeidas ? '1' : '0',
          'limite': limit,
          'offset': offset,
        },
        options: Options(
          headers: {
            'Cookie': 'PHPSESSID=$_sessionToken',
            'X-Session-ID': _sessionToken,
          },
        ),
      );

      print('🔔 Respuesta getNotifications - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        print('🔔 Respuesta getNotifications - success: ${data['success']}');
        if (data['success'] == true) {
          final List<dynamic> notifications = data['notificaciones'] ?? [];
          final List<NotificationModel> parsedNotifications = [];
          for (int i = 0; i < notifications.length; i++) {
            try {
              final notification = NotificationModel.fromJson(
                notifications[i] as Map<String, dynamic>,
              );
              parsedNotifications.add(notification);
            } catch (e) {
              print('❌ Error parseando notificación $i: $e');
            }
          }

          return NotificationResponse(
            notifications: parsedNotifications,
            totalNoLeidas: data['total_no_leidas'] ?? 0,
            totalTodas: data['total_todas'] ?? 0,
          );
        } else {
          print('❌ Error en respuesta: ${data['message'] ?? 'Desconocido'}');
        }
      } else {
        print('❌ Error HTTP: ${response.statusCode}');
        print('❌ Respuesta: ${response.data}');
        // Si hay un mensaje de error en la respuesta, mostrarlo
        if (response.data is Map && response.data['message'] != null) {
          print('❌ Mensaje del servidor: ${response.data['message']}');
        }
      }
      return NotificationResponse(notifications: [], totalNoLeidas: 0, totalTodas: 0);
    } on DioException catch (e) {
      print('❌ Error DioException al obtener notificaciones: ${e.message}');
      if (e.response != null) {
        print('❌ Status code: ${e.response?.statusCode}');
        print('❌ Respuesta del servidor: ${e.response?.data}');
        // Si es un error 500, mostrar más detalles
        if (e.response?.statusCode == 500) {
          print(
            '❌ Error 500 del servidor - Revisar logs del servidor para más detalles',
          );
          if (e.response?.data is Map && e.response?.data['message'] != null) {
            print('❌ Mensaje del servidor: ${e.response?.data['message']}');
          }
        }
      }
      return NotificationResponse(notifications: [], totalNoLeidas: 0, totalTodas: 0);
    } catch (e, stackTrace) {
      print('❌ Error inesperado al obtener notificaciones: $e');
      print('❌ Stack trace: $stackTrace');
      return NotificationResponse(notifications: [], totalNoLeidas: 0, totalTodas: 0);
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
        data: {'id': notificationId},
        options: Options(
          headers: {
            'Cookie': 'PHPSESSID=$_sessionToken',
            'X-Session-ID': _sessionToken,
          },
        ),
      );

      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      print('❌ Error al marcar notificación como leída: $e');
      return false;
    }
  }

  // Marcar todas las notificaciones como leídas
  Future<bool> markAllNotificationsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');

      final response = await _dio.post(
        AppConfig.markNotificationReadEndpoint.replaceFirst(
          AppConfig.apiBaseUrl,
          '',
        ),
        data: {'marcar_todas': true},
        options: Options(
          headers: {
            'Cookie': 'PHPSESSID=$_sessionToken',
            'X-Session-ID': _sessionToken,
          },
        ),
      );

      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      print('❌ Error al marcar todas las notificaciones como leídas: $e');
      return false;
    }
  }

  // Eliminar notificación
  Future<bool> deleteNotification(int? notificationId, {bool deleteAll = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');

      final response = await _dio.post(
        AppConfig.deleteNotificationEndpoint.replaceFirst(
          AppConfig.apiBaseUrl,
          '',
        ),
        data: {
          if (notificationId != null) 'id': notificationId,
          if (deleteAll) 'eliminar_todas': true,
        },
        options: Options(
          headers: {
            'Cookie': 'PHPSESSID=$_sessionToken',
            'X-Session-ID': _sessionToken,
          },
        ),
      );

      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      print('❌ Error al eliminar notificación: $e');
      return false;
    }
  }

  // Cargar token guardado
  Future<void> loadSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    _sessionToken = prefs.getString('session_token');
  }

  // Obtener configuración de contacto
  Future<Map<String, dynamic>?> getContactConfig() async {
    try {
      final response = await _dio.get(
        AppConfig.contactConfigEndpoint.replaceFirst(AppConfig.apiBaseUrl, ''),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['contacto'];
      }
      return null;
    } catch (e) {
      print('❌ Error al obtener configuración de contacto: $e');
      return null;
    }
  }

  // Cerrar sesión

  Future<bool> changePassword(String currentPassword, String newPassword, String confirmPassword) async {
    try {
      final response = await _dio.post(
        '/mobile_change_password.php',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        },
      );

      return response.data['success'] == true;
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        throw e.response!.data['message'] ?? 'Error al cambiar contraseña';
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    _sessionToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_token');
    await prefs.remove('user_data');
  }

  // Obtener datos actualizados del usuario actual
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final fullUrl = AppConfig.getCurrentUserEndpoint;
      print('📡 Llamando a getCurrentUser con token: $_sessionToken');
      print('🌐 URL completa: $fullUrl');

      final response = await _dio.get(
        fullUrl,
        options: Options(
          headers: {
            'X-Session-ID': _sessionToken,
            'Accept': 'application/json',
          },
          followRedirects: false,
        ),
      );

      print('✅ Respuesta getCurrentUser: ${response.statusCode}');
      print('🔀 realUri: ${response.realUri}');
      print('📡 request uri: ${response.requestOptions.uri}');
      print('📦 Data recibida: ${response.data}');
      print('🧾 Headers: ${response.headers}');

      // Validar que la respuesta sea JSON (Map) y no HTML/string
      if (response.data is String) {
        final snippet = (response.data as String);
        print('⚠️ Respuesta no JSON (string). Status: ${response.statusCode}');
        return {
          'success': false,
          'message':
              'Respuesta no JSON del servidor (status ${response.statusCode})',
          'raw': snippet.length > 400 ? snippet.substring(0, 400) : snippet,
        };
      }

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          print('👤 Usuario data: ${data['user']}');
          print('💳 Membership data: ${data['membership']}');

          return {
            'success': true,
            'user': UserModel.fromJson(data['user']),
            'membership': data['membership'] != null
                ? MembershipModel.fromJson(data['membership'])
                : null,
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Error al obtener datos del usuario',
          };
        }
      } else {
        if (response.statusCode == 401) {
          print('⚠️ 401 No autenticado desde getCurrentUser');
          return {'success': false, 'message': 'No autenticado'};
        }
        return {
          'success': false,
          'message': 'Error del servidor (status ${response.statusCode})',
        };
      }
    } catch (e, stackTrace) {
      print('❌ Error en getCurrentUser: $e');
      print('📍 Stack trace: $stackTrace');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Actualizar perfil de usuario
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');
      
      print('📝 updateProfile - Data: $data');

      final response = await _dio.post(
        '/mobile_update_profile.php',
        data: data,
        options: Options(
          headers: {
            'Cookie': 'PHPSESSID=$_sessionToken',
            'X-Session-ID': _sessionToken,
            'Content-Type': 'application/json',
          },
        ),
      );
      
      print('📝 updateProfile - Response: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error al actualizar perfil: $e');
      return false;
    }
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

  Future<List<PostModel>> getPosts({int limite = 10, int offset = 0}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');
      print(
        '🔍 getPosts - Session token: ${_sessionToken?.substring(0, 10)}...',
      );
      final response = await _dio.get(
        '/mobile_get_posts.php',
        queryParameters: {'limite': limite, 'offset': offset},
        options: Options(headers: {'Cookie': 'PHPSESSID=$_sessionToken'}),
      );
      print('🔍 getPosts - Status: ${response.statusCode}');
      final responseStr = response.data.toString();
      print(
        '🔍 getPosts - Response: ${responseStr.length > 200 ? '${responseStr.substring(0, 200)}...' : responseStr}',
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> posts = response.data['posts'] ?? [];
        print(
          '✅ getPosts - Posts obtenidos: ${posts.length} (límite: $limite, offset: $offset)',
        );
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
      print('🔍 uploadPostImage - Archivo: $filePath');
      print(
        '🔍 uploadPostImage - Session token: ${_sessionToken?.substring(0, 10)}...',
      );

      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
        ),
      });

      print('🔍 uploadPostImage - FormData creado');

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

      print('🔍 uploadPostImage - Status: ${response.statusCode}');
      print('🔍 uploadPostImage - Response: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        print('✅ uploadPostImage - URL: ${response.data['url']}');
        return response.data['url'];
      } else {
        print('❌ uploadPostImage - Error en respuesta: ${response.data}');
      }
      return null;
    } catch (e) {
      print('❌ uploadPostImage - Exception: $e');
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
      final trimmed = contenido.trim();
      final contenidoToSend = trimmed.isEmpty && imagenUrl != null
          ? '📸'
          : trimmed;
      if (contenidoToSend.isEmpty) {
        print('📝 createPost - contenido vacío y sin imagen, abortando');
        return null;
      }
      print(
        '📝 createPost - contenido length: ${contenidoToSend.length}, hasImage: ${imagenUrl != null}',
      );
      final response = await _dio.post(
        '/mobile_create_post.php',
        data: {
          'contenido': contenidoToSend,
          if (imagenUrl != null) 'imagen_url': imagenUrl,
        },
        options: Options(headers: {'Cookie': 'PHPSESSID=$_sessionToken'}),
      );
      print('📝 createPost - Status: ${response.statusCode}');
      print('📝 createPost - Data: ${response.data}');
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

  Future<Map<String, dynamic>> getChatMessages(
    int chatId, {
    int limite = 15,
    int offset = 0,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');
      print(
        '🔍 getChatMessages - chatId: $chatId, limite: $limite, offset: $offset',
      );
      final response = await _dio.get(
        '/mobile_get_chat_messages.php',
        queryParameters: {
          'chat_id': chatId,
          'limite': limite,
          'offset': offset,
        },
        options: Options(headers: {'Cookie': 'PHPSESSID=$_sessionToken'}),
      );
      print('🔍 getChatMessages - Status: ${response.statusCode}');
      print('🔍 getChatMessages - Response: ${response.data}');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> messages = response.data['mensajes'] ?? [];
        final int total = response.data['total'] ?? 0;
        final bool hayMas = response.data['hayMas'] ?? false;
        final int unreadAfter = response.data['unread_after'] is int
            ? response.data['unread_after'] as int
            : int.tryParse(response.data['unread_after']?.toString() ?? '0') ??
                  0;
        print(
          '✅ getChatMessages - Mensajes obtenidos: ${messages.length}, Total: $total, Hay más: $hayMas, unread_after: $unreadAfter',
        );
        return {
          'mensajes': messages
              .map((json) => ChatMessageModel.fromJson(json))
              .toList(),
          'total': total,
          'hayMas': hayMas,
          'unread_after': unreadAfter,
        };
      } else {
        print('❌ getChatMessages - Error: ${response.data}');
      }
      return {'mensajes': <ChatMessageModel>[], 'total': 0, 'hayMas': false};
    } catch (e) {
      print('❌ getChatMessages - Exception: $e');
      return {'mensajes': <ChatMessageModel>[], 'total': 0, 'hayMas': false};
    }
  }

  Future<ChatMessageModel?> sendChatMessage({
    required int chatId,
    required String mensaje,
    String? imagenUrl,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');
      print(
        '🔍 sendChatMessage - chatId: $chatId, mensaje: $mensaje, imagenUrl: $imagenUrl',
      );
      final response = await _dio.post(
        '/mobile_send_chat_message.php',
        data: {
          'chat_id': chatId,
          'mensaje': mensaje,
          if (imagenUrl != null) 'imagen_url': imagenUrl,
        },
        options: Options(headers: {'Cookie': 'PHPSESSID=$_sessionToken'}),
      );
      print('🔍 sendChatMessage - Status: ${response.statusCode}');
      print('🔍 sendChatMessage - Response: ${response.data}');
      if (response.statusCode == 200 &&
          response.data['success'] == true &&
          response.data['data'] != null) {
        print('✅ sendChatMessage - Mensaje enviado correctamente');
        return ChatMessageModel.fromJson(response.data['data']);
      } else {
        print('❌ sendChatMessage - Error: ${response.data}');
      }
      return null;
    } catch (e) {
      print('❌ sendChatMessage - Exception: $e');
      return null;
    }
  }

  Future<String?> uploadChatImage(String filePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');
      print('🔍 uploadChatImage - Archivo: $filePath');

      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
        ),
      });

      final response = await _dio.post(
        '/mobile_upload_chat_image.php',
        data: formData,
        options: Options(
          headers: {
            'Cookie': 'PHPSESSID=$_sessionToken',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      print('🔍 uploadChatImage - Status: ${response.statusCode}');
      print('🔍 uploadChatImage - Response: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        print('✅ uploadChatImage - URL: ${response.data['url']}');
        return response.data['url'];
      }
      return null;
    } catch (e) {
      print('❌ Error al subir imagen de chat: $e');
      return null;
    }
  }

  Future<bool> deleteChatMessage(int mensajeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');
      print('🔍 deleteChatMessage - mensajeId: $mensajeId');
      final response = await _dio.post(
        '/mobile_delete_chat_message.php',
        data: {'mensaje_id': mensajeId},
        options: Options(headers: {'Cookie': 'PHPSESSID=$_sessionToken'}),
      );
      print('🔍 deleteChatMessage - Status: ${response.statusCode}');
      print('🔍 deleteChatMessage - Response: ${response.data}');
      if (response.statusCode == 200 && response.data['success'] == true) {
        print('✅ deleteChatMessage - Mensaje eliminado');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ deleteChatMessage - Exception: $e');
      return false;
    }
  }

  Future<ChatMessageModel?> editChatMessage({
    required int mensajeId,
    required String mensaje,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');
      print('🔍 editChatMessage - mensajeId: $mensajeId, mensaje: $mensaje');
      final response = await _dio.post(
        '/mobile_edit_chat_message.php',
        data: {'mensaje_id': mensajeId, 'mensaje': mensaje},
        options: Options(headers: {'Cookie': 'PHPSESSID=$_sessionToken'}),
      );
      print('🔍 editChatMessage - Status: ${response.statusCode}');
      print('🔍 editChatMessage - Response: ${response.data}');
      if (response.statusCode == 200 &&
          response.data['success'] == true &&
          response.data['data'] != null) {
        print('✅ editChatMessage - Mensaje editado');
        return ChatMessageModel.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      print('❌ editChatMessage - Exception: $e');
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
        final List<dynamic> requests =
            response.data['solicitudes'] ?? response.data['requests'] ?? [];
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
        data: {'para_usuario_id': destinatarioId},
        options: Options(
          headers: {
            'Cookie': 'PHPSESSID=$_sessionToken',
            'X-Session-ID': _sessionToken,
            'Accept': 'application/json',
          },
        ),
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
        data: {'request_id': solicitudId, 'accion': accion},
        options: Options(
          headers: {
            'Cookie': 'PHPSESSID=$_sessionToken',
            'X-Session-ID': _sessionToken,
            'Accept': 'application/json',
          },
        ),
      );
      if (response.statusCode == 200) {
        return response.data;
      }
      return {'success': false};
    } catch (e) {
      return {'success': false};
    }
  }

  Future<ChatModel?> createPrivateChat(int contactoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');
      final response = await _dio.post(
        '/mobile_create_private_chat.php',
        data: {'contacto_id': contactoId},
        options: Options(
          headers: {
            'Cookie': 'PHPSESSID=$_sessionToken',
            'X-Session-ID': _sessionToken,
            'Accept': 'application/json',
          },
        ),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final chat = response.data['chat'];
        return ChatModel(
          id: chat['id'] as int,
          nombre: chat['nombre']?.toString() ?? 'Chat privado',
          esGrupal: chat['es_grupal'] == true || chat['es_grupal'] == 1,
          creadoEn: chat['creado_en']?.toString() ?? '',
          ultimoMensaje: null,
          ultimoMensajeEn: null,
          ultimoRemitente: null,
          unreadCount: 0,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Obtener lista de contactos (amigos aceptados)
  Future<List<ContactModel>> getContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');
      final response = await _dio.get(
        '/mobile_get_contacts.php',
        options: Options(headers: {'Cookie': 'PHPSESSID=$_sessionToken'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> contactos = response.data['contactos'] ?? [];
        return contactos.map((json) => ContactModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error al obtener contactos: $e');
      return [];
    }
  }

  // Actualizar apodo de un contacto
  Future<bool> updateContactNickname(int contactoId, String? apodo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');
      final response = await _dio.post(
        '/mobile_update_contact_nickname.php',
        data: {'contacto_id': contactoId, 'apodo': apodo ?? ''},
        options: Options(headers: {'Cookie': 'PHPSESSID=$_sessionToken'}),
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      print('Error al actualizar apodo: $e');
      return false;
    }
  }

  // Eliminar contacto
  Future<bool> removeContact(int contactoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');
      final response = await _dio.post(
        '/mobile_remove_contact.php',
        data: {'contacto_id': contactoId},
        options: Options(headers: {'Cookie': 'PHPSESSID=$_sessionToken'}),
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      print('Error al eliminar contacto: $e');
      return false;
    }
  }

  Future<List<SearchUserModel>> searchUsers(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');
      print(
        '🔎 searchUsers - q: "$query" token: ${_sessionToken?.substring(0, 10)}...',
      );
      final response = await _dio.get(
        '/mobile_search_users.php',
        queryParameters: {'q': query},
        options: Options(
          headers: {
            'Cookie': 'PHPSESSID=$_sessionToken',
            'X-Session-ID': _sessionToken,
            'Accept': 'application/json',
          },
        ),
      );
      print('🔎 searchUsers - status: ${response.statusCode}');
      print('🔎 searchUsers - data: ${response.data}');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> users =
            response.data['usuarios'] ?? response.data['users'] ?? [];
        return users.map((json) => SearchUserModel.fromJson(json)).toList();
      }
      print('🔎 searchUsers - fallo: ${response.data}');
      return [];
    } catch (e) {
      print('🔎 searchUsers - exception: $e');
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
        options: Options(
          headers: {
            'Cookie': 'PHPSESSID=$_sessionToken',
            'X-Session-ID': _sessionToken,
          },
        ),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        // El backend devuelve 'clases' (español), no 'classes'
        final List<dynamic> classes = response.data['clases'] ?? response.data['classes'] ?? [];
        print('📚 getClasses - Clases recibidas: ${classes.length}');
        return classes.map((json) => ClassModel.fromJson(json)).toList();
      }
      
      // Manejar errores específicos
      if (response.statusCode == 401) {
        print('❌ getClasses - Error de autenticación');
      } else if (response.statusCode == 403) {
        print('❌ getClasses - Error de permisos');
      } else {
        print('❌ getClasses - Error en respuesta: ${response.data}');
      }
      return [];
    } catch (e, stackTrace) {
      print('❌ Error al obtener clases: $e');
      print('❌ Stack trace: $stackTrace');
      return [];
    }
  }

  Future<List<ClassScheduleModel>> getClassSchedules({
    DateTime? fecha,
    int? claseId,
    bool? activo,
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
      if (activo != null) queryParams['activo'] = activo ? 1 : 0;
      final response = await _dio.get(
        '/mobile_get_class_schedules.php',
        queryParameters: queryParams,
        options: Options(
          headers: {
            'Cookie': 'PHPSESSID=$_sessionToken',
            'X-Session-ID': _sessionToken,
          },
        ),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        // El backend devuelve 'horarios', pero también aceptamos 'schedules' por compatibilidad
        final List<dynamic> schedules = response.data['horarios'] ?? 
                                         response.data['schedules'] ?? [];
        print('📅 getClassSchedules - Horarios recibidos: ${schedules.length}');
        if (schedules.isNotEmpty) {
          print('📅 Primer horario: ${schedules[0]}');
        }
        return schedules
            .map((json) => ClassScheduleModel.fromJson(json))
            .toList();
      }
      
      // Manejar errores específicos
      if (response.statusCode == 401) {
        print('❌ getClassSchedules - Error de autenticación');
      } else if (response.statusCode == 403) {
        print('❌ getClassSchedules - Error de permisos');
      } else {
        print('❌ getClassSchedules - Error en respuesta: ${response.data}');
      }
      return [];
    } catch (e, stackTrace) {
      print('❌ Error al obtener horarios de clases: $e');
      print('❌ Stack trace: $stackTrace');
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
      if (response.statusCode == 200) {
        return response.data;
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Error al reservar la clase'
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: ${e.toString()}'};
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

  // ==================== CREAR CLASES Y HORARIOS ====================

  /// Crear una nueva clase
  Future<Map<String, dynamic>> createClass({
    required String nombre,
    String? descripcion,
    int? capacidadMaxima,
    int? duracionMinutos,
    int? instructorId,
    bool activo = true,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');

      final response = await _dio.post(
        '/mobile_create_class.php',
        data: {
          'nombre': nombre,
          'descripcion': descripcion,
          'instructor_id': instructorId,
          'capacidad_maxima': capacidadMaxima,
          'duracion_minutos': duracionMinutos,
          'activo': activo ? 1 : 0,
        },
        options: Options(
          headers: {
            'Cookie': 'PHPSESSID=$_sessionToken',
            'X-Session-ID': _sessionToken,
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Error al crear la clase'
      };
    } catch (e, stackTrace) {
      print('❌ Error al crear clase: $e');
      print('❌ Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}'
      };
    }
  }

  /// Crear un horario para una clase
  Future<Map<String, dynamic>> createClassSchedule({
    required int claseId,
    required int diaSemana,
    required String horaInicio,
    required String horaFin,
    bool activo = true,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');

      final response = await _dio.post(
        '/mobile_create_class_schedule.php',
        data: {
          'clase_id': claseId,
          'dia_semana': diaSemana,
          'hora_inicio': horaInicio,
          'hora_fin': horaFin,
          'activo': activo ? 1 : 0,
        },
        options: Options(
          headers: {
            'Cookie': 'PHPSESSID=$_sessionToken',
            'X-Session-ID': _sessionToken,
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Error al crear el horario'
      };
    } catch (e, stackTrace) {
      print('❌ Error al crear horario: $e');
      print('❌ Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}'
      };
    }
  }

  /// Actualizar una clase existente
  Future<Map<String, dynamic>> updateClass({
    required int id,
    required String nombre,
    String? descripcion,
    int? capacidadMaxima,
    int? duracionMinutos,
    int? instructorId,
    bool activo = true,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');

      final response = await _dio.post(
        '/mobile_update_class.php',
        data: {
          'id': id,
          'nombre': nombre,
          'descripcion': descripcion,
          'instructor_id': instructorId,
          'capacidad_maxima': capacidadMaxima,
          'duracion_minutos': duracionMinutos,
          'activo': activo ? 1 : 0,
        },
        options: Options(
          headers: {
            'Cookie': 'PHPSESSID=$_sessionToken',
            'X-Session-ID': _sessionToken,
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Error al actualizar la clase'
      };
    } catch (e, stackTrace) {
      print('❌ Error al actualizar clase: $e');
      print('❌ Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}'
      };
    }
  }

  /// Eliminar una clase
  Future<Map<String, dynamic>> deleteClass(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');

      final response = await _dio.post(
        '/mobile_delete_class.php',
        data: {'id': id},
        options: Options(
          headers: {
            'Cookie': 'PHPSESSID=$_sessionToken',
            'X-Session-ID': _sessionToken,
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Error al eliminar la clase'
      };
    } catch (e, stackTrace) {
      print('❌ Error al eliminar clase: $e');
      print('❌ Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}'
      };
    }
  }

  /// Actualizar un horario de clase
  Future<Map<String, dynamic>> updateClassSchedule({
    required int id,
    required int diaSemana,
    required String horaInicio,
    required String horaFin,
    bool activo = true,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');

      final response = await _dio.post(
        '/mobile_update_class_schedule.php',
        data: {
          'id': id,
          'dia_semana': diaSemana,
          'hora_inicio': horaInicio,
          'hora_fin': horaFin,
          'activo': activo ? 1 : 0,
        },
        options: Options(
          headers: {
            'Cookie': 'PHPSESSID=$_sessionToken',
            'X-Session-ID': _sessionToken,
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Error al actualizar el horario'
      };
    } catch (e, stackTrace) {
      print('❌ Error al actualizar horario: $e');
      print('❌ Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}'
      };
    }
  }

  /// Eliminar un horario de clase
  Future<Map<String, dynamic>> deleteClassSchedule(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');

      final response = await _dio.post(
        '/mobile_delete_class_schedule.php',
        data: {'id': id},
        options: Options(
          headers: {
            'Cookie': 'PHPSESSID=$_sessionToken',
            'X-Session-ID': _sessionToken,
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Error al eliminar el horario'
      };
    } catch (e, stackTrace) {
      print('❌ Error al eliminar horario: $e');
      print('❌ Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}'
      };
    }
  }

  /// Obtener lista de instructores (solo para admin)
  Future<List<Map<String, dynamic>>> getInstructors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');

      final response = await _dio.get(
        '/mobile_get_instructors.php',
        options: Options(
          headers: {
            'Cookie': 'PHPSESSID=$_sessionToken',
            'X-Session-ID': _sessionToken,
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['instructores'] ?? [];
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error al obtener instructores: $e');
      return [];
    }
  }

  /// Obtener horarios de una clase específica
  Future<List<ClassScheduleModel>> getClassSchedulesByClassId(int claseId) async {
    return await getClassSchedules(claseId: claseId);
  }

  // ==================== FCM TOKEN ====================

  /// Registrar token FCM en el servidor
  Future<bool> registerFCMToken(String token, String plataforma) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');

      if (_sessionToken == null) {
        print('⚠️ No hay sesión activa, no se puede registrar token FCM');
        return false;
      }

      final response = await _dio.post(
        '/mobile_register_fcm_token.php',
        data: {'token': token, 'plataforma': plataforma},
        options: Options(headers: {'Cookie': 'PHPSESSID=$_sessionToken'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        print('✅ Token FCM registrado correctamente');
        return true;
      } else {
        print('❌ Error al registrar token FCM: ${response.data}');
        return false;
      }
    } catch (e) {
      print('❌ Error al registrar token FCM: $e');
      return false;
    }
  }

  // ==================== ENTRENADOR DE IA ====================

  /// Obtener respuesta del entrenador de IA
  Future<Map<String, dynamic>> getAIResponse(String mensaje, {List<Map<String, String>>? historial}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');

      final response = await _dio.post(
        '/mobile_get_ai_response.php',
        data: {
          'mensaje': mensaje,
          'historial': historial ?? [],
        },
        options: Options(
          headers: {
            'Cookie': 'PHPSESSID=$_sessionToken',
            'X-Session-ID': _sessionToken,
          },
        ),
      );

      return response.data;
    } catch (e) {
      print('❌ Error en getAIResponse: $e');
      return {
        'success': false,
        'message': 'Error de conexión con el entrenador de IA'
      };
    }
  }

  /// Obtener el plan activo del día generado por la IA

  Future<Map<String, dynamic>> getActivePlan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');

      final response = await _dio.get(
        '/mobile_get_active_plan.php',
        options: Options(
          headers: {
            'Cookie': 'PHPSESSID=$_sessionToken',
            'X-Session-ID': _sessionToken,
          },
        ),
      );
      return response.data;
    } catch (e) {
      print('❌ Error en getActivePlan: $e');
      return {'success': false, 'message': 'No se pudo cargar el plan'};
    }
  }
}



