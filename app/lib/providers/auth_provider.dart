import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../models/membership_model.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  UserModel? _user;
  MembershipModel? _membership;
  bool _isLoading = false;
  bool _isAuthenticated = false;

  UserModel? get user => _user;
  MembershipModel? get membership => _membership;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    final membershipData = prefs.getString('membership_data');
    final token = prefs.getString('session_token');

    if (userData != null && token != null) {
      try {
        final userMap = jsonDecode(userData) as Map<String, dynamic>;
        _user = UserModel.fromJson(userMap);

        // Restaurar membresía si existe
        if (membershipData != null) {
          try {
            final membershipMap =
                jsonDecode(membershipData) as Map<String, dynamic>;
            _membership = MembershipModel.fromJson(membershipMap);
          } catch (e) {
            if (kDebugMode) {
              print('Error restaurando membership_data: $e');
            }
            _membership = null;
          }
        } else {
          _membership = null;
        }

        _isAuthenticated = true;
        await _apiService.loadSavedToken();
        notifyListeners();

        // Refrescar datos desde el servidor automáticamente
        if (kDebugMode) {
          print('🔄 Refrescando datos del usuario desde el servidor...');
        }
        await refreshUserData();
      } catch (e) {
        await logout();
      }
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _apiService.login(email, password);

      if (result['success'] == true) {
        _user = result['user'] as UserModel;
        _membership = result['membership'] as MembershipModel?;
        _isAuthenticated = true;

        // Guardar datos del usuario y membresía
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(_user!.toJson()));
        if (_membership != null) {
          await prefs.setString(
            'membership_data',
            jsonEncode(_membership!.toJson()),
          );
        } else {
          await prefs.remove('membership_data');
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

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
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _apiService.register(
        nombre: nombre,
        apellido: apellido,
        email: email,
        tipoDocumento: tipoDocumento,
        documento: documento,
        password: password,
        passwordConfirm: passwordConfirm,
        telefono: telefono,
        fechaNacimiento: fechaNacimiento,
        genero: genero,
        direccion: direccion,
        ciudad: ciudad,
      );

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': 'Error inesperado: $e',
      };
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _apiService.forgotPassword(email);
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': 'Error inesperado: $e',
      };
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirm,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _apiService.resetPassword(
        token: token,
        email: email,
        password: password,
        passwordConfirm: passwordConfirm,
      );
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': 'Error inesperado: $e',
      };
    }
  }

  Future<void> logout() async {
    await _apiService.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    await prefs.remove('membership_data');
    await prefs.remove('session_token');
    _user = null;
    _membership = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  void updateUser(UserModel newUser) {
    _user = newUser;
    notifyListeners();
  }

  void updateMembership(MembershipModel? newMembership) {
    _membership = newMembership;
    notifyListeners();
  }

  // Refrescar datos del usuario desde el servidor
  Future<bool> refreshUserData() async {
    if (!_isAuthenticated) {
      print('⚠️ No autenticado, no se puede refrescar');
      return false;
    }

    try {
      print('🔄 Iniciando refreshUserData...');
      final result = await _apiService.getCurrentUser();
      print('📦 Resultado de getCurrentUser: $result');

      if (result['success'] == true) {
        print('✅ Success = true');
        print('👤 User en result: ${result['user']}');
        print('💳 Membership en result: ${result['membership']}');
        
        _user = result['user'] as UserModel;
        _membership = result['membership'] as MembershipModel?;

        print('✅ Modelos asignados correctamente');
        print('👤 _user: ${_user?.toJson()}');
        print('💳 _membership: ${_membership?.toJson()}');

        // Guardar datos actualizados
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(_user!.toJson()));
        if (_membership != null) {
          await prefs.setString(
            'membership_data',
            jsonEncode(_membership!.toJson()),
          );
        } else {
          await prefs.remove('membership_data');
        }

        print('💾 Datos guardados en SharedPreferences');
        notifyListeners();
        return true;
      } else {
        print('❌ Success = false: ${result['message']}');
        if (result['raw'] != null) {
          print('🧾 Respuesta cruda (recortada): ${result['raw']}');
        }
        return false;
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error refrescando datos del usuario: $e');
        print('📍 Stack trace: $stackTrace');
      }
      return false;
    }
  }
}
