// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/user/domain/user_model.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/features/coordinator/domain/assignment_log_model.dart';
import 'package:collegebus/features/route/domain/route_model.dart';
import 'package:collegebus/features/college/domain/college_model.dart';
import 'package:collegebus/features/notification/domain/notification_model.dart';
import 'package:collegebus/features/schedule/domain/schedule_model.dart';
import 'package:collegebus/features/incident/domain/incident_model.dart';
import 'package:collegebus/features/coordinator/domain/history_log_model.dart';
import 'package:collegebus/features/sos/domain/sos_model.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/features/bus/services/bus_service.dart';
import 'package:collegebus/features/user/services/user_service.dart';
import 'package:collegebus/features/route/services/route_service.dart';
import 'package:collegebus/features/incident/services/incident_service.dart';
import 'package:collegebus/features/notification/services/notification_data_service.dart';
import 'package:collegebus/features/payment/services/payment_service.dart';
import 'package:collegebus/features/college/application/college_provider.dart';
import 'package:collegebus/features/bus/application/bus_provider.dart';
import 'package:collegebus/features/user/application/user_provider.dart';
import 'package:collegebus/features/route/application/route_provider.dart';
import 'package:flutter/material.dart';

/// DataService - Facade that delegates to domain-specific services.
/// Kept for backward compatibility.
class DataService extends ChangeNotifier {
  BusService _busService;
  UserService _userService;
  RouteService _routeService;
  final Ref _ref;
  IncidentService _incidentService;
  NotificationDataService _notificationService;
  PaymentService _paymentService;

  String? get lastError =>
      _incidentService.lastError ??
      _notificationService.lastError ??
      _paymentService.lastError;

  DataService(
    this._busService,
    this._userService,
    this._routeService,
    this._ref,
    this._incidentService,
    this._notificationService,
    this._paymentService,
  ) {
    // Listen to all services to bubble up notifications
    _incidentService.addListener(notifyListeners);
    _notificationService.addListener(notifyListeners);
    _paymentService.addListener(notifyListeners);
  }

  void updateServices(
    BusService bus,
    UserService user,
    RouteService route,
    IncidentService incident,
    NotificationDataService notif,
    PaymentService payment,
  ) {
    // Check if services changed and update references/listeners
    // No longer adding/removing listeners for BusService
    if (_busService != bus) {
      _busService = bus;
    }
    // No longer adding/removing listeners for UserService
    if (_userService != user) {
      _userService = user;
    }
    // No longer adding/removing listeners for RouteService
    if (_routeService != route) {
      _routeService = route;
    }
    if (_incidentService != incident) {
      _incidentService.removeListener(notifyListeners);
      _incidentService = incident;
      _incidentService.addListener(notifyListeners);
    }
    if (_notificationService != notif) {
      _notificationService.removeListener(notifyListeners);
      _notificationService = notif;
      _notificationService.addListener(notifyListeners);
    }
    if (_paymentService != payment) {
      _paymentService.removeListener(notifyListeners);
      _paymentService = payment;
      _paymentService.addListener(notifyListeners);
    }
  }

  @override
  void dispose() {
    _incidentService.removeListener(notifyListeners);
    _notificationService.removeListener(notifyListeners);
    _paymentService.removeListener(notifyListeners);
    super.dispose();
  }

  void clearError() {
    _incidentService.clearError();
    _notificationService.clearError();
    _paymentService.clearError();
  }

  // ============== Delegated Methods ==============

  // Bus Operations
  Stream<List<BusLocationModel>> getCollegeBusLocationsStream(
    String collegeId,
  ) => _ref.watch(collegeBusLocationsProvider(collegeId).stream);

  Future<void> createBus(BusModel bus) => _busService.createBus(bus);

  Future<void> updateBus(String busId, Map<String, dynamic> data) =>
      _busService.updateBus(busId, data);

  Stream<List<BusModel>> getBusesByCollege(String collegeId) =>
      _ref.watch(collegeBusesStreamProvider(collegeId).stream);

  Future<BusModel?> getBusByDriver(String driverId) =>
      _busService.getBusByDriver(driverId);

  Future<void> deleteBus(String busId) => _busService.deleteBus(busId);

  Future<void> assignDriverToBus({
    required String busNumber,
    required String driverId,
    required String collegeId,
    String? routeId,
  }) async {
    final buses = await _ref.read(busListProvider.future);
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
  }

  Future<void> acceptBusAssignment(String busId) =>
      _busService.updateBus(busId, {'assignmentStatus': 'accepted'});

  Future<void> rejectBusAssignment(String busId) =>
      _busService.updateBus(busId, {
        'driverId': null,
        'assignmentStatus': 'unassigned',
        'status': 'not-running',
      });

  Future<void> updateBusStatus(String busId, String status) =>
      _busService.updateBusStatus(busId, status);

  Future<void> unassignDriverFromBus(String busId) =>
      _busService.updateBus(busId, {
        'driverId': null,
        'assignmentStatus': 'unassigned',
        'status': 'not-running',
        'routeId': null,
      });

  Future<List<AssignmentLogModel>> getAssignmentLogsByBus(String busId) =>
      _busService.getAssignmentLogsByBus(busId);

  Future<List<AssignmentLogModel>> getAssignmentLogsByDriver(String driverId) =>
      _busService.getAssignmentLogsByDriver(driverId);

  Future<void> updateBusLocation(
    String busId,
    String collegeId,
    BusLocationModel location,
  ) => _busService.updateBusLocation(busId, collegeId, location);

  Stream<BusLocationModel?> getBusLocation(String busId) =>
      _ref.watch(busLocationProvider(busId).stream);

  // User Operations
  Future<UserModel?> getUser(String userId) => _userService.getUser(userId);

  Future<void> updateUser(String userId, Map<String, dynamic> data) =>
      _userService.updateUser(userId, data);

  Stream<List<UserModel>> getUsersByRole(UserRole role, String collegeId) {
    final controller = StreamController<List<UserModel>>();
    final arg = (role: role, collegeId: collegeId);
    final subscription = _ref.listen<AsyncValue<List<UserModel>>>(
      usersByRoleProvider(arg),
      (previous, next) {
        if (next.hasValue && !controller.isClosed) {
          controller.add(next.value!);
        } else if (next.hasError && !controller.isClosed) {
          controller.addError(next.error!, next.stackTrace);
        }
      },
      fireImmediately: true,
    );
    controller.onCancel = () {
      subscription.close();
    };
    return controller.stream;
  }

  Stream<List<UserModel>> getAllUsers() =>
      _ref.watch(allUsersStreamProvider.stream);

  Stream<List<UserModel>> getPendingApprovals(String collegeId) =>
      _ref.watch(pendingApprovalsProvider(collegeId).stream);

  Future<void> approveUser(String userId, String approverId) =>
      _userService.approveUser(userId, approverId);

  Future<void> rejectUser(String userId, String approverId) =>
      _userService.rejectUser(userId, approverId);

  // Super Admin Operations
  Future<void> deleteUserGlobal(String userId) =>
      _userService.deleteUser(userId);

  // College Operations
  Future<CollegeModel?> getCollege(String collegeId) =>
      _ref.read(collegeServiceProvider.notifier).getCollege(collegeId);

  Stream<List<CollegeModel>> getAllColleges({bool forceRefresh = false}) {
    if (forceRefresh) {
      _ref.read(collegeServiceProvider.notifier).refresh();
    }
    // Return a stream from the future to maintain compatibility
    return Stream.fromFuture(_ref.read(collegeServiceProvider.future));
  }

  // Route Operations
  Future<RouteModel> createRoute(RouteModel route) =>
      _routeService.createRoute(route);

  Future<void> updateRoute(String routeId, Map<String, dynamic> data) =>
      _routeService.updateRoute(routeId, data);

  Stream<List<RouteModel>> getRoutesByCollege(
    String collegeId, {
    bool forceRefresh = false,
  }) {
    if (forceRefresh) {
      _ref.read(collegeRoutesProvider(collegeId).notifier).refresh();
    }
    final controller = StreamController<List<RouteModel>>();
    final subscription = _ref.listen<AsyncValue<List<RouteModel>>>(
      collegeRoutesProvider(collegeId),
      (previous, next) {
        if (next.hasValue && !controller.isClosed) {
          controller.add(next.value!);
        } else if (next.hasError && !controller.isClosed) {
          controller.addError(next.error!, next.stackTrace);
        }
      },
      fireImmediately: true,
    );
    controller.onCancel = () {
      subscription.close();
    };
    return controller.stream;
  }

  Future<void> deleteRoute(String routeId) =>
      _routeService.deleteRoute(routeId);

  // Schedule Operations
  Future<void> createSchedule(ScheduleModel schedule) =>
      _routeService.createSchedule(schedule);

  Future<void> updateSchedule(String scheduleId, Map<String, dynamic> data) =>
      _routeService.updateSchedule(scheduleId, data);

  Stream<List<ScheduleModel>> getSchedulesByCollege(String collegeId) =>
      _ref.watch(collegeSchedulesProvider(collegeId).stream);

  Future<void> deleteSchedule(String scheduleId) =>
      _routeService.deleteSchedule(scheduleId);

  // Bus Number Operations (Delegated to BusService)
  Future<void> addBusNumber(String collegeId, String busNumber) =>
      _busService.addBusNumber(collegeId, busNumber);

  Future<void> removeBusNumber(String collegeId, String busNumber) =>
      _busService.removeBusNumber(collegeId, busNumber);

  Future<void> renameBusNumber(
    String collegeId,
    String oldBusNumber,
    String newBusNumber,
  ) => _busService.renameBusNumber(collegeId, oldBusNumber, newBusNumber);

  Future<void> updateBusDetails({
    required String collegeId,
    required String oldBusNumber,
    String? newBusNumber,
    String? defaultRouteId,
  }) => _busService.updateBusDetails(
    collegeId: collegeId,
    oldBusNumber: oldBusNumber,
    newBusNumber: newBusNumber,
    defaultRouteId: defaultRouteId,
  );

  Stream<List<String>> getBusNumbers(
    String collegeId, {
    bool forceRefresh = false,
  }) => _ref.watch(busNumbersProvider(collegeId).stream);

  // Notification Operations
  Future<void> sendNotification(NotificationModel notification) =>
      _notificationService.sendNotification(notification);

  Stream<List<NotificationModel>> getNotifications(String userId) =>
      _notificationService.getNotifications(userId);

  Future<void> markNotificationAsRead(String notificationId) =>
      _notificationService.markNotificationAsRead(notificationId);

  Future<void> broadcastNotification(String message) =>
      _notificationService.broadcastNotification(message);

  // Incident Operations
  Future<Map<String, dynamic>> sendSOS({
    required String? busId,
    required String? routeId,
    required double lat,
    required double lng,
  }) => _incidentService.sendSOS(
    busId: busId,
    routeId: routeId,
    lat: lat,
    lng: lng,
  );

  Future<void> resolveSos(String sosId) => _incidentService.resolveSos(sosId);

  Future<List<SosModel>> getActiveSos(String collegeId) =>
      _incidentService.getActiveSos(collegeId);

  Future<void> createIncident(IncidentModel incident) =>
      _incidentService.createIncident(incident);
  Future<List<HistoryLogModel>> getDriverHistory(
    String driverId, {
    String? eventType,
    int page = 1,
    int limit = 50,
  }) async {
    final result = await _userService.getDriverHistory(
      driverId,
      eventType: eventType,
      page: page,
      limit: limit,
    );
    // Assuming API returns { 'logs': [...] }
    if (result.containsKey('logs')) {
      return (result['logs'] as List)
          .map((log) => HistoryLogModel.fromMap(log))
          .toList();
    }
    return [];
  }

  // Payment Operations
  Future<Map<String, dynamic>> createPaymentOrder(
    int amount,
    String currency,
  ) => _paymentService.createPaymentOrder(amount, currency);

  Future<Map<String, dynamic>> verifyPayment(
    String orderId,
    String paymentId,
    String signature,
  ) => _paymentService.verifyPayment(orderId, paymentId, signature);
}
