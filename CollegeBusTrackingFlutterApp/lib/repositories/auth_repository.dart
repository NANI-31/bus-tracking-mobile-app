import 'package:collegebus/repositories/base_repository.dart';

/// Repository for authentication operations
class AuthRepository extends BaseRepository {
  /// Register a new user
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await dio.post('/auth/register', data: userData);
      return response.data;
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Login with email and password
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return response.data;
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Send OTP for password reset
  Future<Map<String, dynamic>> sendOtp(String email) async {
    try {
      final response = await dio.post('/auth/send-otp', data: {'email': email});
      return {'success': true, 'message': response.data['message']};
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Verify OTP code
  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    try {
      final response = await dio.post(
        '/auth/verify-otp',
        data: {'email': email, 'otp': otp},
      );
      return {'success': true, 'message': response.data['message']};
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Reset password after OTP verification
  Future<Map<String, dynamic>> resetPassword(
    String email,
    String newPassword,
  ) async {
    try {
      final response = await dio.post(
        '/auth/reset-password',
        data: {'email': email, 'newPassword': newPassword},
      );
      return {'success': true, 'message': response.data['message']};
    } catch (e) {
      throw handleError(e);
    }
  }
}
