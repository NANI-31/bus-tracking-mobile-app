import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/user/domain/user_model.dart';
import 'package:collegebus/features/auth/data/auth_repository.dart';
import 'package:collegebus/features/user/data/user_repository.dart';
import 'package:collegebus/features/notification/data/notification_repository.dart';
import 'package:collegebus/core/services/persistence_service.dart';
import 'package:collegebus/core/services/secure_storage_service.dart';
import 'package:collegebus/features/notification/services/fcm_service.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/features/auth/data/auth_service.dart';

// Repository providers
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);
final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(),
);
final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(),
);

/// Auth state class - simplified
class AuthState {
  final UserModel? currentUser;
  final String? token;

  const AuthState({this.currentUser, this.token});

  bool get isLoggedIn => currentUser != null && token != null;
  UserRole? get userRole => currentUser?.role;

  AuthState copyWith({
    UserModel? currentUser,
    String? token,
    bool clearUser = false,
    bool clearToken = false,
  }) {
    return AuthState(
      currentUser: clearUser ? null : (currentUser ?? this.currentUser),
      token: clearToken ? null : (token ?? this.token),
    );
  }
}

/// Auth notifier - manages authentication state as AsyncNotifier
class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    debugPrint('AUTH NOTIFIER: build() started');
    // Standard initialization: check storage
    await PersistenceService.init();
    debugPrint('AUTH NOTIFIER: PersistenceService initialized');

    final token = PersistenceService.getAuthToken();
    final userId = PersistenceService.getUserId();
    debugPrint('AUTH NOTIFIER: Token=$token, UserId=$userId');

    if (token != null && userId != null) {
      try {
        final user = await ref.read(userRepositoryProvider).getUser(userId);
        if (user != null) {
          debugPrint(
            'AUTH NOTIFIER: User loaded ${user.fullName}, registering FCM',
          );
          await _registerFCMToken(user.id);
          debugPrint('AUTH NOTIFIER: returning Authenticated State');
          return AuthState(currentUser: user, token: token);
        }
      } catch (e) {
        debugPrint('\x1B[31mError loading user model during init: $e\x1B[0m');
      }
    }

    debugPrint('AUTH NOTIFIER: returning Unauthenticated State');
    return const AuthState();
  }

  AuthRepository get _authRepo => ref.read(authRepositoryProvider);
  UserRepository get _userRepo => ref.read(userRepositoryProvider);
  NotificationRepository get _notificationRepo =>
      ref.read(notificationRepositoryProvider);

  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String fullName,
    required String collegeId,
    required UserRole role,
    String? phoneNumber,
    String? rollNumber,
  }) async {
    try {
      // We don't need 'isLoading' boolean in state anymore,
      // but if we want to show loading specifically for the button,
      // the UI can use the notifier's status if we wrap this in another AsyncValue.
      // For now, we'll just return the result.
      final userData = {
        'email': email,
        'password': password,
        'fullName': fullName,
        'role': role.value,
        'collegeId': collegeId,
        'phoneNumber': phoneNumber,
        'rollNumber': rollNumber,
      };

      final result = await _authRepo.register(userData);

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
    state = const AsyncValue.loading();
    try {
      final result = await _authRepo.login(email, password);

      if (result['success'] == true && result['token'] != null) {
        final token = result['token'] as String;
        await PersistenceService.setAuthToken(token);

        final userId = result['user']?['id'];
        if (userId != null) {
          await PersistenceService.setUserId(userId);
          final user = await _userRepo.getUser(userId);
          if (user != null) {
            await _registerFCMToken(user.id);
            state = AsyncValue.data(AuthState(currentUser: user, token: token));
            return {'success': true, 'message': 'Login successful'};
          }
        }
      }

      state = AsyncValue.data(const AuthState());
      return {
        'success': false,
        'message': result['message'] ?? 'Login failed',
        'requiresVerification': result['requiresVerification'] == true,
      };
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return {'success': false, 'message': 'Login failed: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> sendOtp(String email) async {
    return await _authRepo.sendOtp(email);
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    return await _authRepo.verifyOtp(email, otp);
  }

  Future<Map<String, dynamic>> resetPassword(
    String email,
    String newPassword,
  ) async {
    return await _authRepo.resetPassword(email, newPassword);
  }

  Future<void> signOut() async {
    final currentUser = state.value?.currentUser;
    try {
      if (currentUser != null) {
        // 1. Remove FCM Token
        await _notificationRepo.removeFcmToken(currentUser.id);

        // 2. Call Server Logout to clear isLoggedIn flag
        await _authRepo.logout();
        debugPrint('AUTH NOTIFIER: Server logout successful');
      }
    } catch (e) {
      debugPrint('\x1B[31mError during logout: $e\x1B[0m');
    }

    // 3. Clear Local Storage
    await SecureStorageService.clearAll();
    await PersistenceService.removeAuthToken();
    await PersistenceService.removeUserId();

    // Clear Dashboard Preferences
    await PersistenceService.setBottomNavIndex(0);
    await PersistenceService.removeSelectedBusId();

    state = AsyncValue.data(const AuthState());
  }

  void updateCurrentUser(UserModel user) {
    if (state.hasValue) {
      state = AsyncValue.data(state.value!.copyWith(currentUser: user));
    }
  }

  Future<void> refreshUser() async {
    final currentUser = state.value?.currentUser;
    if (currentUser != null) {
      try {
        final updatedUser = await _userRepo.getUser(currentUser.id);
        if (updatedUser != null) {
          updateCurrentUser(updatedUser);
        }
      } catch (e) {
        debugPrint('\x1B[31mError refreshing user: $e\x1B[0m');
      }
    }
  }

  Future<void> _registerFCMToken(String userId) async {
    try {
      // Request permission now (Post-Login)
      await FCMService().requestPermission();

      final token = await FCMService().getStoredToken();
      if (token != null) {
        await _userRepo.updateUser(userId, {'fcmToken': token});
        debugPrint('\x1B[32mFCM Token registered with backend\x1B[0m');
      }
    } catch (e) {
      debugPrint('\x1B[31mError registering FCM token: $e\x1B[0m');
    }
  }
}

/// Main auth provider
final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

/// Convenience providers for common auth state
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).value?.isLoggedIn ?? false;
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).value?.currentUser;
});

final userRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(authProvider).value?.userRole;
});

final authTokenProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).value?.token;
});

/// Legacy AuthService provider for backward compatibility
final authServiceProvider = ChangeNotifierProvider<AuthService>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final userRepo = ref.watch(userRepositoryProvider);
  final notificationRepo = ref.watch(notificationRepositoryProvider);
  final authService = AuthService();
  authService.updateRepositories(authRepo, userRepo, notificationRepo);
  return authService;
});
