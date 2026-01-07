import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/user_model.dart';
import '../models/membership_model.dart';
import '../models/notification_model.dart';

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
          // Guardar token en SharedPreferences
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
}
