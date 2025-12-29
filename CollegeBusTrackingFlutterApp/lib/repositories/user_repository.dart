import 'package:collegebus/models/user_model.dart';
import 'package:collegebus/repositories/base_repository.dart';

/// Repository for user operations
class UserRepository extends BaseRepository {
  /// Get a single user by ID
  Future<UserModel?> getUser(String userId) async {
    try {
      final response = await dio.get('/users/$userId');
      return UserModel.fromMap(response.data, userId);
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Get all users
  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await dio.get('/users');
      return (response.data as List)
          .map((data) => UserModel.fromMap(data, data['_id']))
          .toList();
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Update user data
  Future<UserModel> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      final response = await dio.put('/users/$userId', data: data);
      return UserModel.fromMap(response.data, userId);
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Approve a user (wrapper around updateUser)
  Future<void> approveUser(String userId, String approverId) async {
    await updateUser(userId, {
      'approved': true,
      'needsManualApproval': false,
      'approverId': approverId,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Fetch history logs for a specific driver
  Future<Map<String, dynamic>> getDriverHistory(
    String driverId, {
    String? eventType,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'limit': limit};
      if (eventType != null) params['eventType'] = eventType;

      final response = await dio.get(
        '/users/$driverId/history',
        queryParameters: params,
      );
      return response.data;
    } catch (e) {
      throw handleError(e);
    }
  }
}
