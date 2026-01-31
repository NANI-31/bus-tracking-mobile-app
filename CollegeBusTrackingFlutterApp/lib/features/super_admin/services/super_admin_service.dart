import 'package:collegebus/features/audit/domain/audit_log_model.dart';
import 'package:collegebus/features/system/domain/system_config_model.dart';
import 'package:collegebus/features/college/domain/college_model.dart';
import 'package:collegebus/features/user/domain/user_model.dart';
import 'package:collegebus/features/sos/domain/sos_model.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/core/data/repositories.dart';
import 'package:flutter/material.dart';
import 'package:collegebus/core/utils/app_logger.dart';

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
      // DEBUG: Sequential fetch to isolate timeout
      AppLogger.d('DEBUG: Loading Audit Logs...');
      _auditLogs = await _auditRepo.getAuditLogs(limit: 50);

      AppLogger.d('DEBUG: Loading Colleges...');
      _colleges = await _collegeRepo.getAllColleges();

      AppLogger.d('DEBUG: Loading Global Users...');
      _globalUsers = await _userRepo.getAllUsers();

      AppLogger.d('DEBUG: Loading System Config...');
      _systemConfig = await _systemRepo.getSystemConfig();

      AppLogger.d('DEBUG: Loading SOS Logs...');
      final logsData = await IncidentRepository().getSosLogs('all');
      _sosLogs = logsData.map((m) => SosModel.fromMap(m)).toList();

      AppLogger.d('DEBUG: Loading Active SOS...');
      final activeData = await IncidentRepository().getActiveSos('all');
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

  /// Super Admin: Update college details
  Future<void> updateCollege(
    String collegeId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _collegeRepo.updateCollege(collegeId, data);
      _colleges = _colleges.map((c) {
        if (c.id == collegeId) {
          // Ideally we'd have a fromMap but we can use copyWith if fields are primitive
          // For now, reload dashboard is safer or we refresh the specific item
          return c;
        }
        return c;
      }).toList();
      await loadSystemDashboard(); // Safer to reload for complex updates
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Super Admin: Update user role globally
  Future<void> updateUserRole(String userId, UserRole role) async {
    try {
      await _userRepo.updateUser(userId, {'role': role.value});
      _globalUsers = _globalUsers
          .map((u) => u.id == userId ? u.copyWith(role: role) : u)
          .toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Super Admin: Clear all system logs (Danger Zone)
  Future<void> clearSystemLogs() async {
    _isLoading = true;
    notifyListeners();
    try {
      await IncidentRepository().dio.delete('/admin/super/logs/clear');
      _sosLogs.clear();
      _auditLogs.clear();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
