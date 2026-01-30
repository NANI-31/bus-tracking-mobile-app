import 'package:collegebus/models/audit_log_model.dart';
import 'package:collegebus/models/system_config_model.dart';
import 'package:collegebus/models/college_model.dart';
import 'package:collegebus/models/user_model.dart';
import 'package:collegebus/models/sos_model.dart';
import 'package:collegebus/repositories/repositories.dart';
import 'package:flutter/material.dart';
import 'package:collegebus/utils/app_logger.dart';

/// Service for Super Admin operations and state management
class SuperAdminService extends ChangeNotifier {
  final AuditRepository _auditRepo = AuditRepository();
  final SystemRepository _systemRepo = SystemRepository();
  final CollegeRepository _collegeRepo = CollegeRepository();
  final UserRepository _userRepo = UserRepository();

  bool _isLoading = false;
  String? _error;
  List<AuditLogModel> _auditLogs = [];
  SystemConfigModel? _systemConfig;
  List<CollegeModel> _colleges = [];
  List<UserModel> _globalUsers = [];
  List<SosModel> _sosLogs = [];
  List<SosModel> _globalActiveSos = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<AuditLogModel> get auditLogs => _auditLogs;
  SystemConfigModel? get systemConfig => _systemConfig;
  List<CollegeModel> get colleges => _colleges;
  List<UserModel> get globalUsers => _globalUsers;
  List<SosModel> get sosLogs => _sosLogs;
  List<SosModel> get globalActiveSos => _globalActiveSos;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Load all system-wide data
  Future<void> loadSystemDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Parallel fetch for global data
      final results = await Future.wait([
        _auditRepo.getAuditLogs(limit: 50),
        _collegeRepo.getAllColleges(),
        _userRepo.getAllUsers(),
        _systemRepo.getSystemConfig(),
        IncidentRepository().getSosLogs('all'),
        IncidentRepository().getActiveSos('all'),
      ]);

      _auditLogs = results[0] as List<AuditLogModel>;
      _colleges = results[1] as List<CollegeModel>;
      _globalUsers = results[2] as List<UserModel>;
      _systemConfig = results[3] as SystemConfigModel;
      final logsData = results[4] as List<Map<String, dynamic>>;
      _sosLogs = logsData.map((m) => SosModel.fromMap(m)).toList();
      final activeData = results[5] as List<Map<String, dynamic>>;
      _globalActiveSos = activeData.map((m) => SosModel.fromMap(m)).toList();

      AppLogger.d(
        'System Dashboard loaded: ${_colleges.length} colleges, ${_globalUsers.length} users',
      );
    } catch (e) {
      _error = e.toString();
      AppLogger.e('Failed to load system dashboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Verify a pending college
  Future<void> verifyCollege(String collegeId) async {
    try {
      await _collegeRepo.verifyCollege(collegeId);

      _colleges = _colleges
          .map((c) => c.id == collegeId ? c.copyWith(verified: true) : c)
          .toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Suspend a college
  Future<void> suspendCollege(String collegeId, String reason) async {
    try {
      await _collegeRepo.suspendCollege(collegeId, reason);

      _colleges = _colleges
          .map((c) => c.id == collegeId ? c.copyWith(suspended: true) : c)
          .toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Toggle system maintenance mode
  Future<void> toggleMaintenance(bool enabled) async {
    try {
      _systemConfig = await _systemRepo.setMaintenanceMode(enabled);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Delete a user (Super Admin can delete any user)
  Future<void> deleteUser(String userId) async {
    try {
      await _userRepo.deleteUser(userId);
      _globalUsers.removeWhere((u) => u.id == userId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
