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
    final token = prefs.getString('session_token');

    if (userData != null && token != null) {
      try {
        final userMap = jsonDecode(userData) as Map<String, dynamic>;
        _user = UserModel.fromJson(userMap);
        _isAuthenticated = true;
        await _apiService.loadSavedToken();
        notifyListeners();
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

        // Guardar datos del usuario
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(_user!.toJson()));

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

  Future<void> logout() async {
    await _apiService.logout();
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
}
