import 'dart:async';
import 'package:collegebus/features/route/domain/route_model.dart';
import 'package:collegebus/features/schedule/domain/schedule_model.dart';
import 'package:collegebus/core/data/repositories.dart';
import 'package:collegebus/core/services/socket_service.dart';

class RouteService {
  final RouteRepository _routeRepo;
  final ScheduleRepository _scheduleRepo;

  RouteService(this._routeRepo, this._scheduleRepo, SocketService socket);

  // Route Operations
  Future<void> createRoute(RouteModel route) => _routeRepo.createRoute(route);

  Future<void> updateRoute(String routeId, Map<String, dynamic> data) =>
      _routeRepo.updateRoute(routeId, data);

  Future<void> deleteRoute(String routeId) => _routeRepo.deleteRoute(routeId);

  // Schedule Operations
  Future<void> createSchedule(ScheduleModel schedule) =>
      _scheduleRepo.createSchedule(schedule);

  Future<void> updateSchedule(String scheduleId, Map<String, dynamic> data) =>
      _scheduleRepo.updateSchedule(scheduleId, data);

  Future<void> deleteSchedule(String scheduleId) =>
      _scheduleRepo.deleteSchedule(scheduleId);
}
