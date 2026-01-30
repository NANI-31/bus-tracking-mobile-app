import 'package:collegebus/models/user_model.dart';
import 'package:collegebus/models/college_model.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/models/sos_model.dart';
import 'package:collegebus/repositories/repositories.dart';
import 'package:flutter/material.dart';
import 'package:collegebus/utils/app_logger.dart';
import 'dart:async';
import 'package:collegebus/services/api/socket_service.dart';

/// Service for College Admin operations and state management
class CollegeAdminService extends ChangeNotifier {
  final CollegeRepository _collegeRepo = CollegeRepository();
  final UserRepository _userRepo = UserRepository();
  final BusRepository _busRepo = BusRepository();

  bool _isLoading = false;
  String? _error;
  List<UserModel> _pendingUsers = [];
  List<UserModel> _collegeUsers = [];
  List<BusModel> _collegeBuses = [];
  Map<String, BusLocationModel> _fleetLocations = {};
  List<SosModel> _activeSos = [];
  List<SosModel> _sosLogs = [];
  CollegeModel? _college;

  // Socket management
  StreamSubscription? _locationSubscription;
  StreamSubscription? _sosAlertSubscription;
  StreamSubscription? _sosResolvedSubscription;
  final SocketService? _socketService;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<UserModel> get pendingUsers => _pendingUsers;
  List<UserModel> get collegeUsers => _collegeUsers;
  List<BusModel> get collegeBuses => _collegeBuses;
  Map<String, BusLocationModel> get fleetLocations => _fleetLocations;
  List<SosModel> get activeSos => _activeSos;
  List<SosModel> get sosLogs => _sosLogs;
  CollegeModel? get college => _college;

  CollegeAdminService({SocketService? socketService})
    : _socketService = socketService;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Load all data relevant to a specific college
  Future<void> loadCollegeDashboard(String collegeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Parallel fetch for efficiency
      final results = await Future.wait([
        _userRepo.getAllUsers(),
        _collegeRepo.getAllColleges(),
        _busRepo
            .getAllBuses(), // Assuming BusRepository has this or we filter by collegeId
      ]);

      final allUsers = results[0] as List<UserModel>;
      final allColleges = results[1] as List<CollegeModel>;
      final allBuses = results[2] as List<BusModel>;

      _college = allColleges.firstWhere((c) => c.id == collegeId);
      _collegeUsers = allUsers.where((u) => u.collegeId == collegeId).toList();
      _collegeBuses = allBuses.where((b) => b.collegeId == collegeId).toList();
      _pendingUsers = _collegeUsers
          .where((u) => u.needsManualApproval && !u.approved)
          .toList();

      AppLogger.d(
        'College Dashboard loaded for $collegeId: ${_collegeUsers.length} users, ${_pendingUsers.length} pending',
      );

      // Start listening to live locations if socket is available
      _listenToLiveLocations(collegeId);
      _listenToSosAlerts(collegeId);

      // Fetch initial data
      _fetchInitialFleetLocations(collegeId);
      fetchActiveSos(collegeId);
      fetchSosLogs(collegeId);
    } catch (e) {
      _error = e.toString();
      AppLogger.e('Failed to load college dashboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Approve a user request
  Future<void> approveUser(String userId, String adminId) async {
    try {
      await _userRepo.approveUser(userId, adminId);

      // Update local state instead of full reload
      final index = _pendingUsers.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _pendingUsers.removeAt(index);
        _collegeUsers = _collegeUsers
            .map(
              (u) => u.id == userId
                  ? u.copyWith(approved: true, needsManualApproval: false)
                  : u,
            )
            .toList();
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Reject/Suspened a user
  Future<void> updateUserStatus(String userId, {required bool approved}) async {
    try {
      await _userRepo.updateUser(userId, {'approved': approved});

      _collegeUsers = _collegeUsers
          .map((u) => u.id == userId ? u.copyWith(approved: approved) : u)
          .toList();
      if (!approved) {
        _pendingUsers.removeWhere((u) => u.id == userId);
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Delete a user
  Future<void> deleteUser(String userId) async {
    try {
      await _userRepo.deleteUser(userId);
      _collegeUsers.removeWhere((u) => u.id == userId);
      _pendingUsers.removeWhere((u) => u.id == userId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Initial fetch of latest locations for the fleet
  Future<void> _fetchInitialFleetLocations(String collegeId) async {
    try {
      final locations = await _busRepo.getCollegeBusLocations(collegeId);
      for (var loc in locations) {
        _fleetLocations[loc.busId] = loc;
      }
      notifyListeners();
    } catch (e) {
      AppLogger.e('Failed to fetch initial fleet locations: $e');
    }
  }

  /// Listen to real-time location updates via socket
  void _listenToLiveLocations(String collegeId) {
    _locationSubscription?.cancel();

    if (_socketService == null) return;

    _socketService.joinCollege(collegeId);
    _locationSubscription = _socketService.locationUpdateStream.listen((data) {
      final busId = data['busId'];
      if (busId != null) {
        // Only track if it belongs to our buses (optional check)
        _fleetLocations[busId] = BusLocationModel.fromMap(data, busId);
        notifyListeners();
      }
    });
  }

  /// Initial fetch of active SOS alerts
  Future<void> fetchActiveSos(String collegeId) async {
    try {
      final incidentRepo = IncidentRepository();
      final sosData = await incidentRepo.getActiveSos(collegeId);
      _activeSos = sosData.map((map) => SosModel.fromMap(map)).toList();
      notifyListeners();
    } catch (e) {
      AppLogger.e('Failed to fetch active SOS: $e');
    }
  }

  /// Initial fetch of SOS logs
  Future<void> fetchSosLogs(String collegeId) async {
    try {
      final incidentRepo = IncidentRepository();
      final sosData = await incidentRepo.getSosLogs(collegeId);
      _sosLogs = sosData.map((map) => SosModel.fromMap(map)).toList();
      notifyListeners();
    } catch (e) {
      AppLogger.e('Failed to fetch SOS logs: $e');
    }
  }

  /// Listen to real-time SOS alerts
  void _listenToSosAlerts(String collegeId) {
    _sosAlertSubscription?.cancel();
    _sosResolvedSubscription?.cancel();

    if (_socketService == null) return;

    _sosAlertSubscription = _socketService.sosAlertStream.listen((data) {
      final newSos = SosModel.fromMap(data);
      if (newSos.collegeId == collegeId) {
        _activeSos.insert(0, newSos);
        notifyListeners();
      }
    });

    _sosResolvedSubscription = _socketService.sosResolvedStream.listen((data) {
      final sosId = data['sos_id'];
      if (sosId != null) {
        // Move from active to logs if we have the full model, or just refresh logs
        _activeSos.removeWhere((s) => s.sosId == sosId);
        fetchSosLogs(collegeId); // Refresh logs to get full resolution info
        notifyListeners();
      }
    });
  }

  /// Resolve an SOS alert
  Future<void> resolveSos(String sosId, {String? notes}) async {
    try {
      final incidentRepo = IncidentRepository();
      await incidentRepo.resolveSos(sosId, notes: notes);

      // Socket will handle local state update via sosResolvedStream
      if (_socketService != null) {
        _socketService.resolveSos(sosId); // This notifies backend to broadcast
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _sosAlertSubscription?.cancel();
    _sosResolvedSubscription?.cancel();
    super.dispose();
  }
}
