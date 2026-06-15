import 'package:collegebus/features/user/domain/user_model.dart';
import 'package:collegebus/core/data/base_repository.dart';

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
          .map((data) => UserModel.fromMap(data, data['_id'] ?? ''))
          .toList();
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Get paginated users
  Future<Map<String, dynamic>> getPaginatedUsers({
    int page = 1,
    int limit = 20,
    String? search,
    String? role,
    String? collegeId,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'limit': limit};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (role != null && role.isNotEmpty) params['role'] = role;
      if (collegeId != null && collegeId.isNotEmpty) params['collegeId'] = collegeId;

      final response = await dio.get('/users', queryParameters: params);
      final data = response.data;
      final users = (data['users'] as List)
          .map((d) => UserModel.fromMap(d, d['_id'] ?? ''))
          .toList();
      return {
        'users': users,
        'totalCount': data['totalCount'],
        'totalPages': data['totalPages'],
      };

    } catch (e) {
      throw handleError(e);
    }
  }

  /// Update user data
  Future<UserModel> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      final response = await dio.put('/users/$userId', data: data);
      final userData = response.data is Map && response.data['user'] != null
          ? response.data['user']
          : response.data;
      return UserModel.fromMap(userData, userId);
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

  /// Delete a user
  Future<void> deleteUser(String userId) async {
    try {
      await dio.delete('/users/$userId');
    } catch (e) {
      throw handleError(e);
    }
  }
}
