import 'package:collegebus/features/user/domain/user_model.dart';
import 'package:collegebus/core/services/api_service.dart';

class UserService {
  final ApiService _apiService;

  UserService(this._apiService);

  // User CRUD
  Future<UserModel?> getUser(String userId) => _apiService.getUser(userId);

  Future<void> updateUser(String userId, Map<String, dynamic> data) =>
      _apiService.updateUser(userId, data);

  Future<void> approveUser(String userId, String approverId) =>
      _apiService.approveUser(userId, approverId);

  Future<void> rejectUser(String userId, String approverId) =>
      _apiService.updateUser(userId, {
        'approved': false,
        'needsManualApproval': false,
        'approverId': approverId,
      });

  Future<void> deleteUser(String userId) => _apiService.deleteUser(userId);

  Future<Map<String, dynamic>> getDriverHistory(
    String driverId, {
    String? eventType,
    int page = 1,
    int limit = 50,
  }) => _apiService.getDriverHistory(
    driverId,
    eventType: eventType,
    page: page,
    limit: limit,
  );
}
