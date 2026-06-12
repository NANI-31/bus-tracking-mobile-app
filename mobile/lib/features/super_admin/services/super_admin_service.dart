import 'package:collegebus/features/user/domain/user_model.dart';
import 'package:collegebus/features/sos/domain/sos_model.dart';
import 'package:collegebus/core/data/repositories.dart';
import 'package:collegebus/core/utils/app_logger.dart';
import 'package:collegebus/features/payment/domain/transaction_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/super_admin/services/super_admin_state.dart';
import 'dart:async';
import 'package:collegebus/core/constants/constants.dart';

/// Service for Super Admin operations and state management
class SuperAdminService extends AsyncNotifier<SuperAdminState> {
  final AuditRepository _auditRepo = AuditRepository();
  final SystemRepository _systemRepo = SystemRepository();
  final CollegeRepository _collegeRepo = CollegeRepository();
  final UserRepository _userRepo = UserRepository();
  final PaymentRepository _paymentRepo = PaymentRepository();

  @override
  FutureOr<SuperAdminState> build() {
    return const SuperAdminState();
  }

  /// Load all system-wide data
  Future<void> loadSystemDashboard() async {
    state = const AsyncValue.loading();
    try {
      AppLogger.d('DEBUG: Loading Audit Logs...');
      final auditLogs = await _auditRepo.getAuditLogs(limit: 50);

      AppLogger.d('DEBUG: Loading Colleges...');
      final colleges = await _collegeRepo.getAllColleges();

      AppLogger.d('DEBUG: Loading Global Users...');
      final globalUsersData = await _userRepo.getPaginatedUsers(page: 1, limit: 20);
      final globalUsers = (globalUsersData['users'] as List<UserModel>);
      final globalUsersTotalPages = globalUsersData['totalPages'] as int;

      AppLogger.d('DEBUG: Loading System Config...');
      final systemConfig = await _systemRepo.getSystemConfig();

      AppLogger.d('DEBUG: Loading SOS Logs...');
      final logsData = await IncidentRepository().getSosLogs('all');
      final sosLogs = logsData.map((m) => SosModel.fromMap(m)).toList();

      AppLogger.d('DEBUG: Loading Active SOS...');
      final activeData = await IncidentRepository().getActiveSos('all');
      final globalActiveSos = activeData.map((m) => SosModel.fromMap(m)).toList();

      AppLogger.d('DEBUG: Loading Transactions...');
      final transData = await _paymentRepo.getPaginatedTransactions(page: 1, limit: 20);
      final transactionsRaw = (transData['transactions'] as List);
      final transactions = transactionsRaw
          .map((m) => TransactionModel.fromJson(m))
          .toList();
      final transactionsTotalPages = transData['totalPages'] as int;

      AppLogger.d(
        'System Dashboard loaded: ${colleges.length} colleges, ${globalUsers.length} users, ${transactions.length} transactions',
      );

      state = AsyncValue.data(SuperAdminState(
        auditLogs: auditLogs,
        colleges: colleges,
        globalUsers: globalUsers,
        systemConfig: systemConfig,
        sosLogs: sosLogs,
        globalActiveSos: globalActiveSos,
        transactions: transactions,
        transactionsHasMore: 1 < transactionsTotalPages,
        globalUsersHasMore: 1 < globalUsersTotalPages,
      ));
    } catch (e, st) {
      AppLogger.e('Failed to load system dashboard: $e');
      state = AsyncValue.error(e, st);
    }
  }

  /// Verify a pending college
  Future<void> verifyCollege(String collegeId) async {
    try {
      await _collegeRepo.verifyCollege(collegeId);

      if (state.hasValue) {
        final current = state.value!;
        final colleges = current.colleges
            .map((c) => c.id == collegeId ? c.copyWith(verified: true) : c)
            .toList();
        state = AsyncValue.data(current.copyWith(colleges: colleges));
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Suspend a college
  Future<void> suspendCollege(String collegeId, String reason) async {
    try {
      await _collegeRepo.suspendCollege(collegeId, reason);

      if (state.hasValue) {
        final current = state.value!;
        final colleges = current.colleges
            .map((c) => c.id == collegeId ? c.copyWith(suspended: true) : c)
            .toList();
        state = AsyncValue.data(current.copyWith(colleges: colleges));
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Toggle system maintenance mode
  Future<void> toggleMaintenance(bool enabled) async {
    try {
      final systemConfig = await _systemRepo.setMaintenanceMode(enabled);
      if (state.hasValue) {
        state = AsyncValue.data(state.value!.copyWith(systemConfig: systemConfig));
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a user (Super Admin can delete any user)
  Future<void> deleteUser(String userId) async {
    try {
      await _userRepo.deleteUser(userId);
      if (state.hasValue) {
        final current = state.value!;
        final users = List<UserModel>.from(current.globalUsers)..removeWhere((u) => u.id == userId);
        state = AsyncValue.data(current.copyWith(globalUsers: users));
      }
    } catch (e) {
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
      await loadSystemDashboard(); // Safer to reload for complex updates
    } catch (e) {
      rethrow;
    }
  }

  /// Super Admin: Update user role globally
  Future<void> updateUserRole(String userId, UserRole role) async {
    try {
      await _userRepo.updateUser(userId, {'role': role.value});
      if (state.hasValue) {
        final current = state.value!;
        final users = current.globalUsers
            .map((u) => u.id == userId ? u.copyWith(role: role) : u)
            .toList();
        state = AsyncValue.data(current.copyWith(globalUsers: users));
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Super Admin: Clear all system logs (Danger Zone)
  Future<void> clearSystemLogs() async {
    state = const AsyncValue.loading();
    try {
      await IncidentRepository().dio.delete('/admin/super/logs/clear');
      if (state.hasValue) {
        state = AsyncValue.data(state.value!.copyWith(sosLogs: [], auditLogs: []));
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> fetchTransactions({
    String? plan,
    DateTime? startDate,
    DateTime? endDate,
    String? collegeId,
    bool isLoadMore = false,
  }) async {
    try {
      final current = state.value;
      if (current == null) return;

      int page = isLoadMore ? current.transactionsPage + 1 : 1;

      AppLogger.d(
        'DEBUG: Fetching Transactions: page=$page, plan=$plan, start=$startDate, end=$endDate',
      );
      
      final transData = await _paymentRepo.getPaginatedTransactions(
        plan: plan,
        startDate: startDate,
        endDate: endDate,
        collegeId: collegeId,
        page: page,
        limit: 20,
      );
      
      final transactionsRaw = (transData['transactions'] as List);
      final newTransactions = transactionsRaw
          .map((m) => TransactionModel.fromJson(m))
          .toList();

      final totalPages = transData['totalPages'] as int;
      final hasMore = page < totalPages;

      final updatedTransactions = isLoadMore 
          ? [...current.transactions, ...newTransactions]
          : newTransactions;

      state = AsyncValue.data(current.copyWith(
        transactions: updatedTransactions,
        transactionsPage: page,
        transactionsHasMore: hasMore,
      ));
    } catch (e) {
      AppLogger.e('Error fetching transactions: $e');
    }
  }

  Future<void> fetchGlobalUsers({
    String? search,
    String? role,
    bool isLoadMore = false,
  }) async {
    try {
      final current = state.value;
      if (current == null) return;

      int page = isLoadMore ? current.globalUsersPage + 1 : 1;

      AppLogger.d(
        'DEBUG: Fetching Global Users: page=$page, search=$search, role=$role',
      );
      
      final usersData = await _userRepo.getPaginatedUsers(
        page: page,
        limit: 20,
        search: search,
        role: role,
      );
      
      final newUsers = (usersData['users'] as List<UserModel>);
      final totalPages = usersData['totalPages'] as int;
      final hasMore = page < totalPages;

      final updatedUsers = isLoadMore 
          ? [...current.globalUsers, ...newUsers]
          : newUsers;

      state = AsyncValue.data(current.copyWith(
        globalUsers: updatedUsers,
        globalUsersPage: page,
        globalUsersHasMore: hasMore,
      ));
    } catch (e) {
      AppLogger.e('Error fetching global users: $e');
    }
  }
}
