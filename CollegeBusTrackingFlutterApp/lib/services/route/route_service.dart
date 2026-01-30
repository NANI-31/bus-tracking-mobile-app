import 'dart:async';
import 'package:collegebus/models/route_model.dart';
import 'package:collegebus/models/schedule_model.dart';
import 'package:collegebus/services/api/api_service.dart';
import 'package:collegebus/services/api/socket_service.dart';
import 'package:flutter/material.dart';

class RouteService extends ChangeNotifier {
  ApiService _apiService;
  SocketService _socketService;
  String? _lastError;

  String? get lastError => _lastError;

  final Map<String, List<RouteModel>> _cachedRoutes = {};

  RouteService(this._apiService, this._socketService);

  void updateDependencies(ApiService api, SocketService socket) {
    _apiService = api;
    // Update socket if needed, similar to BusService if it holds subscriptions
    if (_socketService != socket) {
      _socketService = socket;
    }
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

  // Route Operations
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
      _cachedRoutes
          .clear(); // Clear all or just specific college? DataService cleared all.
      clearError();
    } catch (e) {
      _setError(e);
      rethrow;
    }
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

  // Schedule Operations
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

  Future<void> deleteSchedule(String scheduleId) async {
    try {
      await _apiService.deleteSchedule(scheduleId);
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
}
