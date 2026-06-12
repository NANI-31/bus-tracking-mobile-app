import 'package:collegebus/features/user/domain/user_model.dart';
import 'package:collegebus/features/payment/domain/transaction_model.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/features/sos/domain/sos_model.dart';
import 'package:collegebus/core/data/repositories.dart';
import 'package:flutter/material.dart';
import 'package:collegebus/core/utils/app_logger.dart';
import 'dart:async';
import 'package:collegebus/core/providers/socket_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/college_admin/services/college_admin_state.dart';

/// Service for College Admin operations and state management
class CollegeAdminService extends AsyncNotifier<CollegeAdminState> {
  final CollegeRepository _collegeRepo = CollegeRepository();
  final UserRepository _userRepo = UserRepository();
  final BusRepository _busRepo = BusRepository();
  final PaymentRepository _paymentRepo = PaymentRepository();

  // Socket management
  StreamSubscription? _locationSubscription;
  StreamSubscription? _sosAlertSubscription;
  StreamSubscription? _sosResolvedSubscription;

  @override
  FutureOr<CollegeAdminState> build() {
    // Initial empty state before loadCollegeDashboard is called
    // We could load it here if we had collegeId in scope, but typically it's called after login.
    return const CollegeAdminState();
  }

  /// Load all data relevant to a specific college
  Future<void> loadCollegeDashboard(String collegeId) async {
    state = const AsyncValue.loading();
    try {
      AppLogger.d('DEBUG: Loading Users...');
      final allUsers = await _userRepo.getAllUsers();

      AppLogger.d('DEBUG: Loading Colleges...');
      final allColleges = await _collegeRepo.getAllColleges();

      AppLogger.d('DEBUG: Loading Buses...');
      final allBuses = await _busRepo.getAllBuses();

      debugPrint(
        'SERVICE: Fetched ${allUsers.length} total users, ${allColleges.length} colleges, ${allBuses.length} buses',
      );

      final college = allColleges.firstWhere((c) => c.id == collegeId);
      final collegeUsers = allUsers.where((u) => u.collegeId == collegeId).toList();
      final collegeBuses = allBuses.where((b) => b.collegeId == collegeId).toList();
      final pendingUsers = collegeUsers
          .where((u) => u.needsManualApproval && !u.approved)
          .toList();

      AppLogger.d(
        'College Dashboard core data loaded for $collegeId: ${collegeUsers.length} users',
      );

      // Start listening to live locations if socket is available
      _listenToLiveLocations(collegeId);
      _listenToSosAlerts(collegeId);

      // Initial fleet locations
      final locations = await _busRepo.getCollegeBusLocations(collegeId);
      final fleetMap = <String, BusLocationModel>{};
      for (var loc in locations) {
        fleetMap[loc.busId] = loc;
      }

      // Initial active SOS
      final incidentRepo = IncidentRepository();
      final sosData = await incidentRepo.getActiveSos(collegeId);
      final activeSos = sosData.map((map) => SosModel.fromMap(map)).toList();

      // Initial SOS logs
      final logsData = await incidentRepo.getSosLogs(collegeId);
      final sosLogs = logsData.map((map) => SosModel.fromMap(map)).toList();

      // Initial Transactions
      final transData = await _paymentRepo.getPaginatedTransactions(
        collegeId: collegeId,
        page: 1,
        limit: 20,
      );
      final transactionsRaw = (transData['transactions'] as List);
      final transactions = transactionsRaw.map((m) => TransactionModel.fromJson(m)).toList();
      final transactionsTotalPages = transData['totalPages'] as int;

      AppLogger.d('College Dashboard fully loaded for $collegeId');

      state = AsyncValue.data(
        CollegeAdminState(
          college: college,
          collegeUsers: collegeUsers,
          collegeBuses: collegeBuses,
          pendingUsers: pendingUsers,
          fleetLocations: fleetMap,
          activeSos: activeSos,
          sosLogs: sosLogs,
          transactions: transactions,
          transactionsHasMore: 1 < transactionsTotalPages,
        ),
      );
    } catch (e, st) {
      AppLogger.e('Failed to load college dashboard: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> fetchTransactions({
    required String collegeId,
    String? plan,
    DateTime? startDate,
    DateTime? endDate,
    bool isLoadMore = false,
  }) async {
    final current = state.value;
    if (current == null) return;
    
    int page = isLoadMore ? current.transactionsPage + 1 : 1;

    try {
      final transData = await _paymentRepo.getPaginatedTransactions(
        collegeId: collegeId,
        plan: plan,
        startDate: startDate,
        endDate: endDate,
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
      AppLogger.e('Error fetching college transactions: $e');
    }
  }

  /// Approve a user request
  Future<void> approveUser(String userId, String adminId) async {
    try {
      await _userRepo.approveUser(userId, adminId);

      if (state.hasValue) {
        final current = state.value!;
        final pending = List<UserModel>.from(current.pendingUsers)..removeWhere((u) => u.id == userId);
        final users = current.collegeUsers.map((u) {
          if (u.id == userId) {
            return u.copyWith(approved: true, needsManualApproval: false);
          }
          return u;
        }).toList();

        state = AsyncValue.data(current.copyWith(pendingUsers: pending, collegeUsers: users));
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Reject/Suspened a user
  Future<void> updateUserStatus(String userId, {required bool approved}) async {
    try {
      await _userRepo.updateUser(userId, {'approved': approved});

      if (state.hasValue) {
        final current = state.value!;
        final users = current.collegeUsers.map((u) {
          if (u.id == userId) return u.copyWith(approved: approved);
          return u;
        }).toList();

        final pending = List<UserModel>.from(current.pendingUsers);
        if (!approved) {
          pending.removeWhere((u) => u.id == userId);
        }

        state = AsyncValue.data(current.copyWith(collegeUsers: users, pendingUsers: pending));
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a user
  Future<void> deleteUser(String userId) async {
    try {
      await _userRepo.deleteUser(userId);
      if (state.hasValue) {
        final current = state.value!;
        final users = List<UserModel>.from(current.collegeUsers)..removeWhere((u) => u.id == userId);
        final pending = List<UserModel>.from(current.pendingUsers)..removeWhere((u) => u.id == userId);
        state = AsyncValue.data(current.copyWith(collegeUsers: users, pendingUsers: pending));
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Listen to real-time location updates via socket
  void _listenToLiveLocations(String collegeId) {
    _locationSubscription?.cancel();
    final socketService = ref.read(socketServiceProvider);

    socketService.joinCollege(collegeId);
    _locationSubscription = socketService.locationUpdateStream.listen((data) {
      final busId = data['busId'];
      if (busId != null && state.hasValue) {
        final fleetMap = Map<String, BusLocationModel>.from(state.value!.fleetLocations);
        fleetMap[busId] = BusLocationModel.fromMap(data, busId);
        state = AsyncValue.data(state.value!.copyWith(fleetLocations: fleetMap));
      }
    });
  }

  Future<void> fetchActiveSos(String collegeId) async {
    try {
      final incidentRepo = IncidentRepository();
      final sosData = await incidentRepo.getActiveSos(collegeId);
      final activeSos = sosData.map((map) => SosModel.fromMap(map)).toList();
      if (state.hasValue) {
        state = AsyncValue.data(state.value!.copyWith(activeSos: activeSos));
      }
    } catch (e) {
      AppLogger.e('Failed to fetch active SOS: $e');
    }
  }

  Future<void> fetchSosLogs(String collegeId) async {
    try {
      final incidentRepo = IncidentRepository();
      final sosData = await incidentRepo.getSosLogs(collegeId);
      final logs = sosData.map((map) => SosModel.fromMap(map)).toList();
      if (state.hasValue) {
        state = AsyncValue.data(state.value!.copyWith(sosLogs: logs));
      }
    } catch (e) {
      AppLogger.e('Failed to fetch SOS logs: $e');
    }
  }

  /// Listen to real-time SOS alerts
  void _listenToSosAlerts(String collegeId) {
    _sosAlertSubscription?.cancel();
    _sosResolvedSubscription?.cancel();
    final socketService = ref.read(socketServiceProvider);

    _sosAlertSubscription = socketService.sosAlertStream.listen((data) {
      final newSos = SosModel.fromMap(data);
      if (newSos.collegeId == collegeId && state.hasValue) {
        final active = List<SosModel>.from(state.value!.activeSos)..insert(0, newSos);
        state = AsyncValue.data(state.value!.copyWith(activeSos: active));
      }
    });

    _sosResolvedSubscription = socketService.sosResolvedStream.listen((data) {
      final sosId = data['sos_id'];
      if (sosId != null && state.hasValue) {
        final active = List<SosModel>.from(state.value!.activeSos)..removeWhere((s) => s.sosId == sosId);
        state = AsyncValue.data(state.value!.copyWith(activeSos: active));
        fetchSosLogs(collegeId); // Refresh logs
      }
    });
  }

  /// Resolve an SOS alert
  Future<void> resolveSos(String sosId, {String? notes}) async {
    try {
      final incidentRepo = IncidentRepository();
      await incidentRepo.resolveSos(sosId, notes: notes);

      final socketService = ref.read(socketServiceProvider);
      socketService.resolveSos(sosId); 
    } catch (e) {
      rethrow;
    }
  }

  // Cleanup
  void dispose() {
    _locationSubscription?.cancel();
    _sosAlertSubscription?.cancel();
    _sosResolvedSubscription?.cancel();
  }
}
