import 'dart:async';
import 'package:flutter/material.dart';
import 'package:collegebus/models/user_model.dart';
import 'package:collegebus/services/api_service.dart';
import 'package:collegebus/services/persistence_service.dart';
import 'package:collegebus/services/fcm_service.dart';
import 'package:collegebus/utils/constants.dart';

class AuthService extends ChangeNotifier {
  ApiService? _apiService;
  UserModel? _currentUserModel;
  String? _token;
  bool _isInitialized = false;

  UserModel? get currentUserModel => _currentUserModel;
  bool get isInitialized => _isInitialized;
  String? get token => _token;
  UserRole? get userRole => _currentUserModel?.role;
  bool get isLoggedIn => _currentUserModel != null;

  void updateApiService(ApiService apiService) {
    _apiService = apiService;
  }

  AuthService() {
    _init();
  }

  Future<void> _init() async {
    await PersistenceService.init();
    await _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final token = PersistenceService.getAuthToken();
    final userId = PersistenceService.getUserId();

    if (token != null && userId != null) {
      _token = token;
      if (_apiService != null) {
        await _loadUserModel(userId);
        await _registerFCMToken();
        _isInitialized = true;
        notifyListeners();
      } else {
        Future.delayed(const Duration(seconds: 1), _checkLoginStatus);
      }
    } else {
      _currentUserModel = null;
      _token = null;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _loadUserModel(String uid) async {
    try {
      if (_apiService == null) return;
      final user = await _apiService!.getUser(uid);
      if (user != null) {
        _currentUserModel = user;
      } else {
        await signOut();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('\x1B[31mError loading user model: $e\x1B[0m');
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
          _token = result['token'];
          await PersistenceService.setAuthToken(_token!);
          if (result['user'] != null && result['user']['id'] != null) {
            final userId = result['user']['id'];
            await PersistenceService.setUserId(userId);
            await _loadUserModel(userId);
            await _registerFCMToken();
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
      return {'success': false, 'message': 'Login failed: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> sendOtp(String email) async {
    if (_apiService == null)
      return {'success': false, 'message': 'Service not available'};
    return await _apiService!.sendOtp(email);
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    if (_apiService == null)
      return {'success': false, 'message': 'Service not available'};
    return await _apiService!.verifyOtp(email, otp);
  }

  Future<Map<String, dynamic>> resetPassword(
    String email,
    String newPassword,
  ) async {
    if (_apiService == null)
      return {'success': false, 'message': 'Service not available'};
    return await _apiService!.resetPassword(email, newPassword);
  }

  Future<void> signOut() async {
    try {
      if (_currentUserModel != null && _apiService != null) {
        await _apiService!.removeFcmToken(_currentUserModel!.id);
      }
    } catch (e) {
      debugPrint('\x1B[31mError removing FCM token during logout: $e\x1B[0m');
    }

    await PersistenceService.removeAuthToken();
    await PersistenceService.removeUserId();
    _token = null;
    _currentUserModel = null;
    notifyListeners();
  }

  void updateCurrentUser(UserModel user) {
    _currentUserModel = user;
    notifyListeners();
  }

  Future<void> _registerFCMToken() async {
    if (_currentUserModel == null || _apiService == null) return;
    try {
      final token = await FCMService().getStoredToken();
      if (token != null) {
        await _apiService!.updateUser(_currentUserModel!.id, {
          'fcmToken': token,
        });
        debugPrint('\x1B[32mFCM Token registered with backend\x1B[0m');
      }
    } catch (e) {
      debugPrint('\x1B[31mError registering FCM token: $e\x1B[0m');
    }
  }
}
