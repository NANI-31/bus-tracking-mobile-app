import 'dart:async';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/models/assignment_log_model.dart';
import 'package:collegebus/services/api/api_service.dart';
import 'package:collegebus/services/api/socket_service.dart';
import 'package:collegebus/utils/app_logger.dart';
import 'package:flutter/material.dart';

class BusService extends ChangeNotifier {
  ApiService _apiService;
  SocketService _socketService;
  String? _lastError;

  String? get lastError => _lastError;

  // Cache/State
  final Map<String, BusLocationModel> _cachedBusLocations = {};
  final Map<String, List<String>> _cachedBusNumbers = {};
  StreamSubscription? _locationCacheSubscription;
  bool _isDisposed = false;

  BusService(this._apiService, this._socketService) {
    _setupSocketListener();
  }

  void updateDependencies(ApiService api, SocketService socket) {
    _apiService = api;
    if (_socketService != socket) {
      _socketService = socket;
      _setupSocketListener();
    }
  }

  void _setupSocketListener() {
    _locationCacheSubscription?.cancel();
    _locationCacheSubscription = _socketService.locationUpdateStream.listen((
      data,
    ) {
      if (_isDisposed) return;
      if (data['busId'] != null) {
        final busId = data['busId'];
        AppLogger.d('[BusService] Global cache update for bus $busId');
        _cachedBusLocations[busId] = BusLocationModel.fromMap(data, busId);
        notifyListeners(); // Notify listeners of location update if needed
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _locationCacheSubscription?.cancel();
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

  // Bus Management Operations
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
      _socketService.sendBusListUpdate();
      clearError();
    } catch (e) {
      _setError(e);
      rethrow;
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
      return buses.firstWhere((b) => b.driverId == driverId && b.isActive);
    } catch (e) {
      return null;
    }
  }

  // Assignment Operations
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

  // Bus Location Operations
  Stream<List<BusLocationModel>> getCollegeBusLocationsStream(
    String collegeId,
  ) {
    return Stream.multi((controller) async {
      final initialLocations = _cachedBusLocations.values
          .where((l) => l.collegeId == collegeId)
          .toList();
      if (initialLocations.isNotEmpty) {
        controller.add(initialLocations);
      }

      List<BusLocationModel> currentLocations = List.from(initialLocations);

      final subscription = _socketService.locationUpdateStream.listen((data) {
        if (data['collegeId'] == collegeId) {
          final busId = data['busId'];
          final newLoc = BusLocationModel.fromMap(data, busId);
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

      // Similar fetchAll logic as DataService...
      // Simplified for brevity in this initial split, or should copy fully?
      // I will implement a simplified fetch to start, relying on REST API
      try {
        final apiLocations = await _apiService.getCollegeBusLocations(
          collegeId,
        );
        for (var loc in apiLocations) {
          _cachedBusLocations[loc.busId] = loc;
          final index = currentLocations.indexWhere(
            (l) => l.busId == loc.busId,
          );
          if (index != -1) {
            currentLocations[index] = loc;
          } else {
            currentLocations.add(loc);
          }
        }
        if (!controller.isClosed) controller.add(List.from(currentLocations));
      } catch (e) {
        _setError(e);
      }
    });
  }

  Future<void> updateBusLocation(
    String busId,
    String collegeId,
    BusLocationModel location,
  ) async {
    try {
      // Round coordinates
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
      clearError();
    } catch (e) {
      _setError(e);
    }
  }

  Stream<BusLocationModel?> getBusLocationSteam(String busId) {
    return Stream.multi((controller) async {
      // Try API first
      try {
        final location = await _apiService.getBusLocation(busId);
        if (!controller.isClosed) controller.add(location);
      } catch (e) {
        // ignore initial error
      }

      final subscription = _socketService.locationUpdateStream.listen((data) {
        if (data['busId'] == busId) {
          controller.add(BusLocationModel.fromMap(data, busId));
        }
      });
      controller.onCancel = () => subscription.cancel();
    });
  }

  // Bus Number Operations
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
      _socketService.sendBusListUpdate();
      clearError();
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }

  Future<void> updateBusDetails({
    required String collegeId,
    required String oldBusNumber,
    String? newBusNumber,
    String? defaultRouteId,
  }) async {
    try {
      await _apiService.updateBusDetails(
        collegeId,
        oldBusNumber,
        newBusNumber: newBusNumber,
        defaultRouteId: defaultRouteId,
      );
      _cachedBusNumbers.remove(collegeId);
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
}
