import 'dart:async';
import 'package:collegebus/features/route/domain/route_model.dart';
import 'package:collegebus/features/schedule/domain/schedule_model.dart';
import 'package:collegebus/core/services/api_service.dart';
import 'package:collegebus/core/services/socket_service.dart';

class RouteService {
  final ApiService _apiService;

  RouteService(this._apiService, SocketService socket);

  // Route Operations
  Future<void> createRoute(RouteModel route) => _apiService.createRoute(route);

  Future<void> updateRoute(String routeId, Map<String, dynamic> data) =>
      _apiService.updateRoute(routeId, data);

  Future<void> deleteRoute(String routeId) => _apiService.deleteRoute(routeId);

  // Schedule Operations
  Future<void> createSchedule(ScheduleModel schedule) =>
      _apiService.createSchedule(schedule);

  Future<void> updateSchedule(String scheduleId, Map<String, dynamic> data) =>
      _apiService.updateSchedule(scheduleId, data);

  Future<void> deleteSchedule(String scheduleId) =>
      _apiService.deleteSchedule(scheduleId);
}
