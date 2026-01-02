import 'dart:async';
import 'package:collegebus/models/user_model.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/models/assignment_log_model.dart';
import 'package:collegebus/models/route_model.dart';
import 'package:collegebus/models/college_model.dart';
import 'package:collegebus/models/notification_model.dart';
import 'package:collegebus/models/schedule_model.dart';
import 'package:collegebus/models/incident_model.dart';
import 'package:collegebus/models/history_log_model.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/services/api_service.dart';
import 'package:collegebus/services/socket_service.dart';
import 'package:flutter/material.dart';
import 'package:collegebus/utils/app_logger.dart';

class DataService extends ChangeNotifier {
  ApiService _apiService;
  SocketService _socketService;
  String? _lastError;

  String? get lastError => _lastError;

  // Cache for bus locations
  final Map<String, BusLocationModel> _cachedBusLocations = {};

  // Track global subscription to prevent leaks
  StreamSubscription? _locationCacheSubscription;
  bool _isDisposed = false;

  void updateDependencies(ApiService api, SocketService socket) {
    _apiService = api;

    // Only update socket if it changed
    if (_socketService != socket) {
      _socketService = socket;
      _setupSocketListener();
    }
  }

  void _setupSocketListener() {
    // Cancel existing subscription before creating new one
    _locationCacheSubscription?.cancel();

    // Listen globally to update cache
    _locationCacheSubscription = _socketService.locationUpdateStream.listen((
      data,
    ) {
      if (_isDisposed) return;
      if (data['busId'] != null) {
        final busId = data['busId'];
        AppLogger.d(
          '[DataService] Global cache update for bus $busId. Data: $data',
        );
        _cachedBusLocations[busId] = BusLocationModel.fromMap(data, busId);
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _locationCacheSubscription?.cancel();
    _locationCacheSubscription = null;
    super.dispose();
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

  DataService(this._apiService, this._socketService) {
    _setupSocketListener();
  }

  Stream<List<BusLocationModel>> getCollegeBusLocationsStream(
    String collegeId,
  ) {
    return Stream.multi((controller) async {
      // 1. Emit cached values IMMEDIATELY
      final initialLocations = _cachedBusLocations.values
          .where((l) => l.collegeId == collegeId)
          .toList();
      AppLogger.d(
        '[DataService] getCollegeBusLocationsStream: Emitting ${initialLocations.length} cached locations. Cache size: ${_cachedBusLocations.length}',
      );
      if (initialLocations.isNotEmpty) {
        controller.add(initialLocations);
      }

      List<BusLocationModel> currentLocations = List.from(initialLocations);

      // 2. Listen to socket updates
      final subscription = _socketService.locationUpdateStream.listen((data) {
        if (data['collegeId'] == collegeId) {
          final busId = data['busId'];
          final newLoc = BusLocationModel.fromMap(data, busId);
          AppLogger.v(
            '[DataService] Live update received from socket for bus $busId',
          );

          // Update local list
          final index = currentLocations.indexWhere((l) => l.busId == busId);
          if (index != -1) {
            currentLocations[index] = newLoc;
          } else {
            currentLocations.add(newLoc);
          }

          if (!controller.isClosed) controller.add(List.from(currentLocations));
        }
      });
      controller.onCancel = () => subscription.cancel();

      Future<void> fetchAll() async {
        try {
          List<BusLocationModel> apiLocations = [];
          try {
            apiLocations = await _apiService.getCollegeBusLocations(collegeId);
          } catch (e) {
            AppLogger.e('[DataService] Bulk location fetch failed: $e');
            // Continue to fallback
          }

          // Fallback: If bulk fetch returned nothing (or failed), fetch individually
          if (apiLocations.isEmpty) {
            AppLogger.d(
              '[DataService] Bulk fetch empty/failed, attempting fallback to individual fetches',
            );
            try {
              // Get all buses to find which ones to query
              final allBuses = await _apiService.getAllBuses();
              final collegeBuses = allBuses
                  .where((b) => b.collegeId == collegeId && b.isActive)
                  .toList();

              if (collegeBuses.isNotEmpty) {
                final futures = collegeBuses.map(
                  (bus) => _apiService.getBusLocation(bus.id),
                );
                final results = await Future.wait(futures);
                apiLocations = results.whereType<BusLocationModel>().toList();
                AppLogger.d(
                  '[DataService] Fallback retrieved ${apiLocations.length} locations',
                );
              }
            } catch (e2) {
              AppLogger.e('[DataService] Fallback fetch also failed: $e2');
            }
          }

          // Merge API data
          for (var loc in apiLocations) {
            // Cache API result too
            _cachedBusLocations[loc.busId] = loc;

            final index = currentLocations.indexWhere(
              (l) => l.busId == loc.busId,
            );
            if (index != -1) {
              currentLocations[index] = loc;
            } else {
              currentLocations.add(loc);
            }
            // If present, socket data is likely newer, or we rely on stream updates
          }

          if (!controller.isClosed) controller.add(List.from(currentLocations));
          clearError();
        } catch (e) {
          _setError(e);
          // Don't add error to controller to avoid breaking the stream for UI
          // if (!controller.isClosed) controller.addError(e);
        }
      }

      await fetchAll();
    });
  }

  // In-memory cache
  List<CollegeModel>? _cachedColleges;
  final Map<String, List<RouteModel>> _cachedRoutes = {};
  final Map<String, List<String>> _cachedBusNumbers = {};

  // User operations
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

  // College operations
  Future<CollegeModel?> getCollege(String collegeId) async {
    if (_cachedColleges != null) {
      try {
        return _cachedColleges!.firstWhere((c) => c.id == collegeId);
      } catch (_) {}
    }
    try {
      final colleges = await getAllColleges().first;
      return colleges.firstWhere((c) => c.id == collegeId);
    } catch (e) {
      return null;
    }
  }

  Stream<List<CollegeModel>> getAllColleges({bool forceRefresh = false}) {
    if (!forceRefresh && _cachedColleges != null) {
      return Stream.value(_cachedColleges!);
    }
    return Stream.fromFuture(
      _apiService
          .getAllColleges()
          .then((colleges) {
            _cachedColleges = colleges;
            clearError();
            return colleges;
          })
          .catchError((e) {
            _setError(e);
            throw e;
          }),
    );
  }

  // Bus operations
  Future<void> createBus(BusModel bus) async {
    try {
      await _apiService.createBus(bus);
      clearError();
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }

  Future<void> updateBus(String busId, Map<String, dynamic> data) async {
    try {
      await _apiService.updateBus(busId, data);
      clearError();
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }

  Stream<List<BusModel>> getBusesByCollege(String collegeId) {
    return Stream.multi((controller) async {
      Future<void> fetch() async {
        try {
          final buses = await _apiService.getAllBuses();
          final filtered = buses
              .where((b) => b.collegeId == collegeId && b.isActive)
              .toList();
          if (!controller.isClosed) controller.add(filtered);
          clearError();
        } catch (e) {
          _setError(e);
          if (!controller.isClosed) controller.addError(e);
        }
      }

      await fetch();
      final subscription = _socketService.busListUpdateStream.listen(
        (_) => fetch(),
      );
      controller.onCancel = () => subscription.cancel();
    });
  }

  Future<BusModel?> getBusByDriver(String driverId) async {
    try {
      final buses = await _apiService.getAllBuses();
      // DEBUG: Log found buses for this driver
      for (var b in buses) {
        if (b.driverId == driverId) {
          AppLogger.d(
            '[DataService] Found bus match: ${b.busNumber}, Active: ${b.isActive}, Status: ${b.assignmentStatus}',
          );
        }
      }
      return buses.firstWhere((b) => b.driverId == driverId && b.isActive);
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteBus(String busId) async {
    try {
      await _apiService.deleteBus(busId);
      clearError();
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }

  Future<void> assignDriverToBus({
    required String busNumber,
    required String driverId,
    required String collegeId,
    String? routeId,
  }) async {
    try {
      final buses = await _apiService.getAllBuses();
      final existingBus = buses.firstWhere(
        (b) => b.busNumber == busNumber && b.collegeId == collegeId,
        orElse: () => throw 'Bus not found',
      );

      final Map<String, dynamic> updateData = {
        'driverId': driverId,
        'assignmentStatus': 'pending',
      };

      if (routeId != null) {
        updateData['routeId'] = routeId;
      }

      await updateBus(existingBus.id, updateData);
      _socketService.sendBusListUpdate();
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }

  Future<void> acceptBusAssignment(String busId) async {
    try {
      await _apiService.updateBus(busId, {'assignmentStatus': 'accepted'});
      _socketService.sendBusListUpdate();
      clearError();
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }

  Future<void> rejectBusAssignment(String busId) async {
    try {
      await _apiService.updateBus(busId, {
        'driverId': null,
        'assignmentStatus': 'unassigned',
        'status': 'not-running',
      });
      _socketService.sendBusListUpdate();
      clearError();
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }

  Future<void> updateBusStatus(String busId, String status) async {
    try {
      await _apiService.updateBus(busId, {'status': status});
      _socketService.sendBusListUpdate();
      clearError();
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }

  Future<void> unassignDriverFromBus(String busId) async {
    try {
      // release the bus
      await _apiService.updateBus(busId, {
        'driverId': null,
        'assignmentStatus': 'unassigned',
        'status': 'not-running',
        'routeId': null,
      });
      _socketService.sendBusListUpdate();
      clearError();
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }

  Future<List<AssignmentLogModel>> getAssignmentLogsByBus(String busId) async {
    try {
      final logs = await _apiService.getAssignmentLogsByBus(busId);
      clearError();
      return logs;
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }

  Future<List<AssignmentLogModel>> getAssignmentLogsByDriver(
    String driverId,
  ) async {
    try {
      final logs = await _apiService.getAssignmentLogsByDriver(driverId);
      clearError();
      return logs;
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }

  // Route operations
  Future<void> createRoute(RouteModel route) async {
    try {
      await _apiService.createRoute(route);
      _cachedRoutes.remove(route.collegeId);
      clearError();
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }

  Future<void> updateRoute(String routeId, Map<String, dynamic> data) async {
    try {
      await _apiService.updateRoute(routeId, data);
      _cachedRoutes.clear();
      clearError();
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }

  Stream<List<RouteModel>> getRoutesByCollege(
    String collegeId, {
    bool forceRefresh = false,
  }) {
    return Stream.multi((controller) async {
      Future<void> fetch() async {
        try {
          final routes = await _apiService.getRoutesByCollege(collegeId);
          _cachedRoutes[collegeId] = routes;
          if (!controller.isClosed) controller.add(routes);
          clearError();
        } catch (e) {
          _setError(e);
          if (!controller.isClosed) controller.addError(e);
        }
      }

      // If cached and not forcing refresh, emit cached first
      if (!forceRefresh && _cachedRoutes.containsKey(collegeId)) {
        controller.add(_cachedRoutes[collegeId]!);
      }

      await fetch();
      final subscription = _socketService.routeListUpdateStream.listen(
        (_) => fetch(),
      );
      controller.onCancel = () => subscription.cancel();
    });
  }

  Future<void> deleteRoute(String routeId) async {
    try {
      await _apiService.deleteRoute(routeId);
      _cachedRoutes.clear();
      clearError();
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }

  // Schedule operations
  Future<void> createSchedule(ScheduleModel schedule) async {
    try {
      await _apiService.createSchedule(schedule);
      clearError();
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }

  Future<void> updateSchedule(
    String scheduleId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _apiService.updateSchedule(scheduleId, data);
      clearError();
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }

  Stream<List<ScheduleModel>> getSchedulesByCollege(String collegeId) {
    return Stream.fromFuture(
      _apiService.getSchedulesByCollege(collegeId).catchError((e) {
        _setError(e);
        throw e;
      }),
    );
  }

  Future<void> deleteSchedule(String scheduleId) async {
    try {
      await _apiService.deleteSchedule(scheduleId);
      clearError();
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }

  // Bus number operations
  Future<void> addBusNumber(String collegeId, String busNumber) async {
    try {
      await _apiService.addBusNumber(collegeId, busNumber);
      _cachedBusNumbers.remove(collegeId);
      clearError();
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }

  Future<void> removeBusNumber(String collegeId, String busNumber) async {
    try {
      await _apiService.removeBusNumber(collegeId, busNumber);
      _cachedBusNumbers.remove(collegeId);
      clearError();
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }

  Future<void> renameBusNumber(
    String collegeId,
    String oldBusNumber,
    String newBusNumber,
  ) async {
    try {
      await _apiService.renameBusNumber(collegeId, oldBusNumber, newBusNumber);
      _cachedBusNumbers.remove(collegeId);
      // Also might need to refresh bus list as buses might have updated
      _socketService.sendBusListUpdate();
      clearError();
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }

  Stream<List<String>> getBusNumbers(
    String collegeId, {
    bool forceRefresh = false,
  }) {
    return Stream.multi((controller) async {
      Future<void> fetch() async {
        try {
          final numbers = await _apiService.getBusNumbers(collegeId);
          _cachedBusNumbers[collegeId] = numbers;
          if (!controller.isClosed) controller.add(numbers);
          clearError();
        } catch (e) {
          _setError(e);
          if (!controller.isClosed) controller.addError(e);
        }
      }

      // If cached and not forcing refresh, emit cached first
      if (!forceRefresh && _cachedBusNumbers.containsKey(collegeId)) {
        controller.add(_cachedBusNumbers[collegeId]!);
      }

      await fetch();
      final subscription = _socketService.busListUpdateStream.listen(
        (_) => fetch(),
      );
      controller.onCancel = () => subscription.cancel();
    });
  }

  // Bus location operations
  Future<void> updateBusLocation(
    String busId,
    String collegeId,
    BusLocationModel location,
  ) async {
    try {
      // Round coordinates to 5 decimal places (~1m precision)
      final lat = double.parse(
        location.currentLocation.latitude.toStringAsFixed(5),
      );
      final lng = double.parse(
        location.currentLocation.longitude.toStringAsFixed(5),
      );

      _socketService.updateLocation({
        'busId': busId,
        'collegeId': collegeId,
        'location': {'lat': lat, 'lng': lng},
        'speed': location.speed ?? 0.0,
        'heading': location.heading ?? 0.0,
      });

      // NOTE: REST API call removed - server now handles persistence via write-behind buffer.
      // This saves network round-trips and reduces battery usage.
      clearError();
    } catch (e) {
      _setError(e);
    }
  }

  Stream<BusLocationModel?> getBusLocation(String busId) {
    return Stream.multi((controller) async {
      Future<void> fetch() async {
        try {
          final location = await _apiService.getBusLocation(busId);
          if (!controller.isClosed) controller.add(location);
          clearError();
        } catch (e) {
          _setError(e);
          if (!controller.isClosed) controller.addError(e);
        }
      }

      await fetch();
      final subscription = _socketService.locationUpdateStream.listen((data) {
        if (data['busId'] == busId) {
          controller.add(BusLocationModel.fromMap(data, busId));
        }
      });
      controller.onCancel = () => subscription.cancel();
    });
  }

  // Notification operations
  Future<void> sendNotification(NotificationModel notification) async {
    try {
      await _apiService.sendNotification(notification);
      clearError();
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }

  Stream<List<NotificationModel>> getNotifications(String userId) {
    return Stream.fromFuture(
      _apiService.getUserNotifications(userId).catchError((e) {
        _setError(e);
        throw e;
      }),
    );
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _apiService.markNotificationAsRead(notificationId);
      clearError();
    } catch (e) {
      _setError(e);
    }
  }

  // Approval operations
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
      // In ApiService rejectUser was missing, assuming it's similar to approve
      await _apiService.updateUser(userId, {
        'approved': false,
        'needsManualApproval': false,
        'approverId': approverId,
      });
      clearError();
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }

  Future<void> sendSOS({
    required String? busId,
    required double lat,
    required double lng,
  }) async {
    try {
      await _apiService.sendSOS(busId: busId, lat: lat, lng: lng);
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }

  Future<void> createIncident(IncidentModel incident) async {
    try {
      await _apiService.createIncident(incident);
      clearError();
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }

  /// Fetch history logs for a specific driver
  Future<List<HistoryLogModel>> getDriverHistory(
    String driverId, {
    String? eventType,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _apiService.getDriverHistory(
        driverId,
        eventType: eventType,
        page: page,
        limit: limit,
      );
      clearError();
      final List data = response['data'] ?? [];
      return data.map((e) => HistoryLogModel.fromMap(e)).toList();
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }
}
