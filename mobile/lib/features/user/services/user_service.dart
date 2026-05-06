import 'package:collegebus/features/user/domain/user_model.dart';
import 'package:collegebus/core/data/repositories.dart';

class UserService {
  final UserRepository _userRepo;

  UserService(this._userRepo);

  // User CRUD
  Future<UserModel?> getUser(String userId) => _userRepo.getUser(userId);

  Future<void> updateUser(String userId, Map<String, dynamic> data) =>
      _userRepo.updateUser(userId, data);

  Future<void> approveUser(String userId, String approverId) =>
      _userRepo.approveUser(userId, approverId);

  Future<void> rejectUser(String userId, String approverId) =>
      _userRepo.updateUser(userId, {
        'approved': false,
        'needsManualApproval': false,
        'approverId': approverId,
      });

  Future<void> deleteUser(String userId) => _userRepo.deleteUser(userId);

  Future<Map<String, dynamic>> getDriverHistory(
    String driverId, {
    String? eventType,
    int page = 1,
    int limit = 50,
  }) => _userRepo.getDriverHistory(
    driverId,
    eventType: eventType,
    page: page,
    limit: limit,
  );
}
