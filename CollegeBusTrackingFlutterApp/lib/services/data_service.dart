import 'dart:async';
import 'package:collegebus/models/user_model.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/models/route_model.dart';
import 'package:collegebus/models/college_model.dart';
import 'package:collegebus/models/notification_model.dart';
import 'package:collegebus/models/schedule_model.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/services/api_service.dart';
import 'package:collegebus/services/socket_service.dart';
import 'package:flutter/material.dart';

class DataService extends ChangeNotifier {
  ApiService _apiService;
  SocketService _socketService;

  void updateDependencies(ApiService api, SocketService socket) {
    _apiService = api;
    _socketService = socket;
    // We don't notifyListeners here because that would cause an infinite rebuild loop
    // if ProxyProvider re-evaluates. ProxyProvider handles the value identity.
  }

  // In-memory cache
  List<CollegeModel>? _cachedColleges;
  final Map<String, List<RouteModel>> _cachedRoutes = {};
  final Map<String, List<String>> _cachedBusNumbers = {};

  DataService(this._apiService, this._socketService);

  // User operations
  Future<UserModel?> getUser(String userId) async {
    return await _apiService.getUser(userId);
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _apiService.updateUser(userId, data);
  }

  Stream<List<UserModel>> getUsersByRole(UserRole role, String collegeId) {
    return Stream.fromFuture(
      _apiService.getAllUsers().then(
        (users) => users
            .where((u) => u.role == role && u.collegeId == collegeId)
            .toList(),
      ),
    );
  }

  Stream<List<UserModel>> getAllUsers() {
    return Stream.fromFuture(_apiService.getAllUsers());
  }

  Stream<List<UserModel>> getPendingApprovals(String collegeId) {
    return Stream.fromFuture(
      _apiService.getAllUsers().then(
        (users) => users
            .where(
              (u) =>
                  u.collegeId == collegeId &&
                  u.needsManualApproval &&
                  !u.approved,
            )
            .toList(),
      ),
    );
  }

  // College operations
  Future<CollegeModel?> getCollege(String collegeId) async {
    if (_cachedColleges != null) {
      try {
        return _cachedColleges!.firstWhere((c) => c.id == collegeId);
      } catch (_) {
        // Not in cache, proceed to fetch
      }
    }
    final colleges = await getAllColleges().first;
    try {
      return colleges.firstWhere((c) => c.id == collegeId);
    } catch (_) {
      return null;
    }
  }

  Stream<List<CollegeModel>> getAllColleges({bool forceRefresh = false}) {
    if (!forceRefresh && _cachedColleges != null) {
      return Stream.value(_cachedColleges!);
    }
    return Stream.fromFuture(
      _apiService.getAllColleges().then((colleges) {
        _cachedColleges = colleges;
        return colleges;
      }),
    );
  }

  // Bus operations
  Future<void> createBus(BusModel bus) async {
    await _apiService.createBus(bus);
  }

  Future<void> updateBus(String busId, Map<String, dynamic> data) async {
    await _apiService.updateBus(busId, data);
  }

  Stream<List<BusModel>> getBusesByCollege(String collegeId) {
    // Initial fetch from REST, then updates from Socket or Refresh event
    return Stream.multi((controller) async {
      Future<void> fetch() async {
        try {
          final buses = await _apiService.getAllBuses();
          final filtered = buses
              .where((b) => b.collegeId == collegeId && b.isActive)
              .toList();
          if (!controller.isClosed) controller.add(filtered);
        } catch (e) {
          if (!controller.isClosed) controller.addError(e);
        }
      }

      // Initial fetch
      await fetch();

      // Listen for socket updates instead of polling
      final subscription = _socketService.busListUpdateStream.listen((_) {
        fetch();
      });

      controller.onCancel = () {
        subscription.cancel();
      };
    });
  }

  Future<BusModel?> getBusByDriver(String driverId) async {
    final buses = await _apiService.getAllBuses();
    try {
      return buses.firstWhere((b) => b.driverId == driverId && b.isActive);
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteBus(String busId) async {
    await _apiService.deleteBus(busId);
  }

  // Route operations
  Future<void> createRoute(RouteModel route) async {
    await _apiService.createRoute(route);
    _cachedRoutes.remove(route.collegeId);
  }

  Future<void> updateRoute(String routeId, Map<String, dynamic> data) async {
    await _apiService.updateRoute(routeId, data);
    // Invalidate for all as we don't easily know which collegeId it belongs to without fetching
    // Optimally, we'd pass collegeId or find it in cache
    _cachedRoutes.clear();
  }

  Stream<List<RouteModel>> getRoutesByCollege(
    String collegeId, {
    bool forceRefresh = false,
  }) {
    if (!forceRefresh && _cachedRoutes.containsKey(collegeId)) {
      return Stream.value(_cachedRoutes[collegeId]!);
    }
    return Stream.fromFuture(
      _apiService.getRoutesByCollege(collegeId).then((routes) {
        _cachedRoutes[collegeId] = routes;
        return routes;
      }),
    );
  }

  Future<void> deleteRoute(String routeId) async {
    await _apiService.deleteRoute(routeId);
    _cachedRoutes.clear();
  }

  // Schedule operations
  Future<void> createSchedule(ScheduleModel schedule) async {
    await _apiService.createSchedule(schedule);
  }

  Future<void> updateSchedule(
    String scheduleId,
    Map<String, dynamic> data,
  ) async {
    await _apiService.updateSchedule(scheduleId, data);
  }

  Stream<List<ScheduleModel>> getSchedulesByCollege(String collegeId) {
    return Stream.fromFuture(_apiService.getSchedulesByCollege(collegeId));
  }

  Future<void> deleteSchedule(String scheduleId) async {
    await _apiService.deleteSchedule(scheduleId);
  }

  // Bus number operations
  Future<void> addBusNumber(String collegeId, String busNumber) async {
    await _apiService.addBusNumber(collegeId, busNumber);
    _cachedBusNumbers.remove(collegeId);
  }

  Future<void> removeBusNumber(String collegeId, String busNumber) async {
    await _apiService.removeBusNumber(collegeId, busNumber);
    _cachedBusNumbers.remove(collegeId);
  }

  Stream<List<String>> getBusNumbers(
    String collegeId, {
    bool forceRefresh = false,
  }) {
    if (!forceRefresh && _cachedBusNumbers.containsKey(collegeId)) {
      return Stream.value(_cachedBusNumbers[collegeId]!);
    }
    return Stream.fromFuture(
      _apiService.getBusNumbers(collegeId).then((numbers) {
        _cachedBusNumbers[collegeId] = numbers;
        return numbers;
      }),
    );
  }

  // Bus location operations
  Future<void> updateBusLocation(
    String busId,
    String collegeId,
    BusLocationModel location,
  ) async {
    // Notify server via Socket (instantly)
    _socketService.updateLocation({
      'busId': busId,
      'collegeId': collegeId,
      'currentLocation': {
        'lat': location.currentLocation.latitude,
        'lng': location.currentLocation.longitude,
      },
      'speed': location.speed ?? 0.0,
      'heading': location.heading ?? 0.0,
    });

    // Also persist via REST
    await _apiService.updateBusLocation(
      busId,
      location.currentLocation.latitude,
      location.currentLocation.longitude,
      location.speed ?? 0.0,
      location.heading ?? 0.0,
    );
  }

  Stream<BusLocationModel?> getBusLocation(String busId) {
    return Stream.multi((controller) async {
      Future<void> fetch() async {
        try {
          final location = await _apiService.getBusLocation(busId);
          if (!controller.isClosed) controller.add(location);
        } catch (e) {
          if (!controller.isClosed) controller.addError(e);
        }
      }

      // Initial fetch
      await fetch();

      // Listen for socket updates for this SPECIFIC bus
      final subscription = _socketService.locationUpdateStream.listen((data) {
        if (data['busId'] == busId) {
          controller.add(BusLocationModel.fromMap(data, busId));
        }
      });

      controller.onCancel = () {
        subscription.cancel();
      };
    });
  }

  Stream<List<BusLocationModel>> getCollegeBusLocationsStream(
    String collegeId,
  ) {
    return Stream.multi((controller) async {
      List<BusLocationModel> currentLocations = [];

      Future<void> fetchAll() async {
        try {
          currentLocations = await _apiService.getCollegeBusLocations(
            collegeId,
          );
          if (!controller.isClosed) controller.add(currentLocations);
        } catch (e) {
          if (!controller.isClosed) controller.addError(e);
        }
      }

      // Initial fetch
      await fetchAll();

      // Listen for socket updates for ANY bus in this college
      final subscription = _socketService.locationUpdateStream.listen((data) {
        if (data['collegeId'] == collegeId) {
          final busId = data['busId'];
          final newLoc = BusLocationModel.fromMap(data, busId);

          // Update the local list and emit
          final index = currentLocations.indexWhere((l) => l.busId == busId);
          if (index != -1) {
            currentLocations[index] = newLoc;
          } else {
            currentLocations.add(newLoc);
          }
          if (!controller.isClosed) controller.add(List.from(currentLocations));
        }
      });

      controller.onCancel = () {
        subscription.cancel();
      };
    });
  }

  // Notification operations
  Future<void> sendNotification(NotificationModel notification) async {
    await _apiService.sendNotification(notification);
  }

  Stream<List<NotificationModel>> getNotifications(String userId) {
    return Stream.fromFuture(_apiService.getUserNotifications(userId));
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _apiService.markNotificationAsRead(notificationId);
  }

  // Approval operations
  Future<void> approveUser(String userId, String approverId) async {
    await _apiService.approveUser(userId, approverId);
  }

  Future<void> rejectUser(String userId, String approverId) async {
    await _apiService.rejectUser(userId, approverId);
  }
}
