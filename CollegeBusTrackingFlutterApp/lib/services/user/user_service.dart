import 'package:collegebus/models/user_model.dart';
import 'package:collegebus/services/api/api_service.dart';

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
