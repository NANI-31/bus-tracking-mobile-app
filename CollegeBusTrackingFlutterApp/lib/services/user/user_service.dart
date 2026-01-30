import 'dart:async';
import 'package:collegebus/models/user_model.dart';
import 'package:collegebus/services/api/api_service.dart';
import 'package:collegebus/services/api/socket_service.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:flutter/material.dart';

class UserService extends ChangeNotifier {
  ApiService _apiService;
  SocketService _socketService;
  String? _lastError;

  String? get lastError => _lastError;

  UserService(this._apiService, this._socketService);

  void updateDependencies(ApiService api, SocketService socket) {
    _apiService = api;
    // UserService might not need to listen to socket for internal state
    // unless caching user lists, but we do expose streams that use it.
    _socketService = socket;
  }

  void clearError() {
    if (_lastError != null) {
      _lastError = null;
      notifyListeners();
    }
  }

  void _setError(dynamic e) {
    _lastError = e.toString();
    notifyListeners();
  }

  // User CRUD
  Future<UserModel?> getUser(String userId) async {
    try {
      return await _apiService.getUser(userId);
    } catch (e) {
      _setError(e);
      return null;
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _apiService.updateUser(userId, data);
      clearError();
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }

  Stream<List<UserModel>> getUsersByRole(UserRole role, String collegeId) {
    return Stream.multi((controller) async {
      Future<void> fetch() async {
        try {
          final allUsers = await _apiService.getAllUsers();
          final filteredUsers = allUsers
              .where((u) => u.role == role && u.collegeId == collegeId)
              .toList();
          if (!controller.isClosed) controller.add(filteredUsers);
          clearError();
        } catch (e) {
          _setError(e);
          if (!controller.isClosed) controller.addError(e);
        }
      }

      await fetch();
      final subscription = _socketService.userListUpdateStream.listen(
        (_) => fetch(),
      );
      controller.onCancel = () => subscription.cancel();
    });
  }

  Stream<List<UserModel>> getAllUsers() {
    return Stream.fromFuture(
      _apiService.getAllUsers().catchError((e) {
        _setError(e);
        throw e;
      }),
    );
  }

  Stream<List<UserModel>> getPendingApprovals(String collegeId) {
    return Stream.fromFuture(
      _apiService
          .getAllUsers()
          .then(
            (users) => users
                .where(
                  (u) =>
                      u.collegeId == collegeId &&
                      u.needsManualApproval &&
                      !u.approved,
                )
                .toList(),
          )
          .catchError((e) {
            _setError(e);
            throw e;
          }),
    );
  }

  Future<void> approveUser(String userId, String approverId) async {
    try {
      await _apiService.approveUser(userId, approverId);
      clearError();
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }

  Future<void> rejectUser(String userId, String approverId) async {
    try {
      await _apiService.updateUser(userId, {
        'approved': false,
        'needsManualApproval':
            false, // Assuming rejection logic implies no more pending state?
        // Or maybe rejection means they stay unapproved?
        // Logic copied from DataService:
        // 'approved': false, 'needsManualApproval': false, 'approverId': approverId
        'approverId': approverId,
      });
      clearError();
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getDriverHistory(
    String driverId, {
    String? eventType,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final result = await _apiService.getDriverHistory(
        driverId,
        eventType: eventType,
        page: page,
        limit: limit,
      );
      clearError();
      return result;
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }
}
