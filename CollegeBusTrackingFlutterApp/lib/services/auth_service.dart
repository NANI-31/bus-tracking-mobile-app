import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collegebus/models/user_model.dart';
import 'package:collegebus/services/api_service.dart';
import 'package:collegebus/utils/constants.dart';

class AuthService extends ChangeNotifier {
  ApiService? _apiService;
  UserModel? _currentUserModel;
  bool _isInitialized = false;

  UserModel? get currentUserModel => _currentUserModel;
  bool get isInitialized => _isInitialized;
  UserRole? get userRole => _currentUserModel?.role;
  bool get isLoggedIn => _currentUserModel != null;

  void updateApiService(ApiService apiService) {
    _apiService = apiService;
  }

  AuthService() {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userId = prefs.getString('user_id');

    if (token != null && userId != null) {
      if (_apiService != null) {
        // Here we could validate token with backend, but for now just load user
        await _loadUserModel(userId);
        _isInitialized = true;
        notifyListeners();
      } else {
        // Retry loading if service not ready
        Future.delayed(const Duration(seconds: 1), _checkLoginStatus);
      }
    } else {
      _currentUserModel = null;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _loadUserModel(String uid) async {
    try {
      if (_apiService == null) return;
      print('DEBUG: Loading user model for UID: $uid');
      final user = await _apiService!.getUser(uid);
      if (user != null) {
        _currentUserModel = user;
        print('DEBUG: User model loaded: ${_currentUserModel!.fullName}');
      } else {
        print('DEBUG: User document does not exist for UID: $uid');
        // If user not found but we have token, maybe we should logout?
        await signOut();
      }
      notifyListeners();
    } catch (e) {
      print('DEBUG: Error loading user model: $e');
    }
  }

  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String fullName,
    required String collegeId,
    required UserRole role,
    String? phoneNumber,
    String? rollNumber,
  }) async {
    if (_apiService == null) {
      return {'success': false, 'message': 'Service not available'};
    }

    try {
      final userData = {
        'email': email,
        'password': password,
        'fullName': fullName,
        'role': role.value,
        'collegeId': collegeId,
        'phoneNumber': phoneNumber,
        'rollNumber': rollNumber,
      };

      final result = await _apiService!.register(userData);

      if (result['success'] == true) {
        // Do NOT auto-login. User must verify email first.
        // We just return success and let the UI handle navigation to OTP screen.
        return {'success': true, 'message': 'Registration successful'};
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Registration failed: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    if (_apiService == null) {
      return {'success': false, 'message': 'Service not available'};
    }

    try {
      final result = await _apiService!.login(email, password);

      if (result['success'] == true) {
        if (result['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', result['token']);
          if (result['user'] != null && result['user']['id'] != null) {
            await prefs.setString('user_id', result['user']['id']);
            await _loadUserModel(result['user']['id']);
          }
        }
        return {'success': true, 'message': 'Login successful'};
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Login failed',
          'requiresVerification': result['requiresVerification'] == true,
        };
      }
    } catch (e) {
      print('CRITICAL: Login exception: $e');
      return {'success': false, 'message': 'Login failed: ${e.toString()}'};
    }
  }

  // Not implementing password reset yet as it requires email service on backend
  Future<Map<String, dynamic>> sendOtp(String email) async {
    if (_apiService == null) {
      return {'success': false, 'message': 'Service not available'};
    }
    return await _apiService!.sendOtp(email);
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    if (_apiService == null) {
      return {'success': false, 'message': 'Service not available'};
    }
    return await _apiService!.verifyOtp(email, otp);
  }

  Future<Map<String, dynamic>> resetPassword(
    String email,
    String newPassword,
  ) async {
    if (_apiService == null) {
      return {'success': false, 'message': 'Service not available'};
    }
    return await _apiService!.resetPassword(email, newPassword);
  }

  Future<void> resendEmailVerification() async {
    // Not implemented
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    _currentUserModel = null;
    notifyListeners();
  }

  void updateCurrentUser(UserModel user) {
    _currentUserModel = user;
    notifyListeners();
  }
}
