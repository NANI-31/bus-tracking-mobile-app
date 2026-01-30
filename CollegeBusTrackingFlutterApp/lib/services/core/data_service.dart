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
import 'package:collegebus/models/sos_model.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/services/bus/bus_service.dart';
import 'package:collegebus/services/user/user_service.dart';
import 'package:collegebus/services/route/route_service.dart';
import 'package:collegebus/services/college/college_service.dart';
import 'package:collegebus/services/incident/incident_service.dart';
import 'package:collegebus/services/notification/notification_data_service.dart';
import 'package:collegebus/services/payment/payment_service.dart';
import 'package:flutter/material.dart';

/// DataService - Facade that delegates to domain-specific services.
/// Kept for backward compatibility.
class DataService extends ChangeNotifier {
  BusService _busService;
  UserService _userService;
  RouteService _routeService;
  CollegeService _collegeService;
  IncidentService _incidentService;
  NotificationDataService _notificationService;
  PaymentService _paymentService;

  String? get lastError =>
      _busService.lastError ??
      _userService.lastError ??
      _routeService.lastError ??
      _collegeService.lastError ??
      _incidentService.lastError ??
      _notificationService.lastError ??
      _paymentService.lastError;

  DataService(
    this._busService,
    this._userService,
    this._routeService,
    this._collegeService,
    this._incidentService,
    this._notificationService,
    this._paymentService,
  ) {
    // Listen to all services to bubble up notifications
    _busService.addListener(notifyListeners);
    _userService.addListener(notifyListeners);
    _routeService.addListener(notifyListeners);
    _collegeService.addListener(notifyListeners);
    _incidentService.addListener(notifyListeners);
    _notificationService.addListener(notifyListeners);
    _paymentService.addListener(notifyListeners);
  }

  void updateServices(
    BusService bus,
    UserService user,
    RouteService route,
    CollegeService college,
    IncidentService incident,
    NotificationDataService notif,
    PaymentService payment,
  ) {
    // Check if services changed and update references/listeners
    if (_busService != bus) {
      _busService.removeListener(notifyListeners);
      _busService = bus;
      _busService.addListener(notifyListeners);
    }
    if (_userService != user) {
      _userService.removeListener(notifyListeners);
      _userService = user;
      _userService.addListener(notifyListeners);
    }
    if (_routeService != route) {
      _routeService.removeListener(notifyListeners);
      _routeService = route;
      _routeService.addListener(notifyListeners);
    }
    if (_collegeService != college) {
      _collegeService.removeListener(notifyListeners);
      _collegeService = college;
      _collegeService.addListener(notifyListeners);
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
    _busService.removeListener(notifyListeners);
    _userService.removeListener(notifyListeners);
    _routeService.removeListener(notifyListeners);
    _collegeService.removeListener(notifyListeners);
    _incidentService.removeListener(notifyListeners);
    _notificationService.removeListener(notifyListeners);
    _paymentService.removeListener(notifyListeners);
    super.dispose();
  }

  void clearError() {
    _busService.clearError();
    _userService.clearError();
    _routeService.clearError();
    _collegeService.clearError();
    _incidentService.clearError();
    _notificationService.clearError();
    _paymentService.clearError();
  }

  // ============== Delegated Methods ==============

  // Bus Operations
  Stream<List<BusLocationModel>> getCollegeBusLocationsStream(
    String collegeId,
  ) => _busService.getCollegeBusLocationsStream(collegeId);

  Future<void> createBus(BusModel bus) => _busService.createBus(bus);

  Future<void> updateBus(String busId, Map<String, dynamic> data) =>
      _busService.updateBus(busId, data);

  Stream<List<BusModel>> getBusesByCollege(String collegeId) =>
      _busService.getBusesByCollege(collegeId);

  Future<BusModel?> getBusByDriver(String driverId) =>
      _busService.getBusByDriver(driverId);

  Future<void> deleteBus(String busId) => _busService.deleteBus(busId);

  Future<void> assignDriverToBus({
    required String busNumber,
    required String driverId,
    required String collegeId,
    String? routeId,
  }) => _busService.assignDriverToBus(
    busNumber: busNumber,
    driverId: driverId,
    collegeId: collegeId,
    routeId: routeId,
  );

  Future<void> acceptBusAssignment(String busId) =>
      _busService.acceptBusAssignment(busId);

  Future<void> rejectBusAssignment(String busId) =>
      _busService.rejectBusAssignment(busId);

  Future<void> updateBusStatus(String busId, String status) =>
      _busService.updateBusStatus(busId, status);

  Future<void> unassignDriverFromBus(String busId) =>
      _busService.unassignDriverFromBus(busId);

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
      _busService.getBusLocationSteam(
        busId,
      ); // Fixed typo in usage: Steam -> Stream check if BusService has typo

  // User Operations
  Future<UserModel?> getUser(String userId) => _userService.getUser(userId);

  Future<void> updateUser(String userId, Map<String, dynamic> data) =>
      _userService.updateUser(userId, data);

  Stream<List<UserModel>> getUsersByRole(UserRole role, String collegeId) =>
      _userService.getUsersByRole(role, collegeId);

  Stream<List<UserModel>> getAllUsers() => _userService.getAllUsers();

  Stream<List<UserModel>> getPendingApprovals(String collegeId) =>
      _userService.getPendingApprovals(collegeId);

  Future<void> approveUser(String userId, String approverId) =>
      _userService.approveUser(userId, approverId);

  Future<void> rejectUser(String userId, String approverId) =>
      _userService.rejectUser(userId, approverId);

  // College Operations
  Future<CollegeModel?> getCollege(String collegeId) =>
      _collegeService.getCollege(collegeId);

  Stream<List<CollegeModel>> getAllColleges({bool forceRefresh = false}) =>
      _collegeService.getAllColleges(forceRefresh: forceRefresh);

  // Route Operations
  Future<void> createRoute(RouteModel route) =>
      _routeService.createRoute(route);

  Future<void> updateRoute(String routeId, Map<String, dynamic> data) =>
      _routeService.updateRoute(routeId, data);

  Stream<List<RouteModel>> getRoutesByCollege(
    String collegeId, {
    bool forceRefresh = false,
  }) => _routeService.getRoutesByCollege(collegeId, forceRefresh: forceRefresh);

  Future<void> deleteRoute(String routeId) =>
      _routeService.deleteRoute(routeId);

  // Schedule Operations
  Future<void> createSchedule(ScheduleModel schedule) =>
      _routeService.createSchedule(schedule);

  Future<void> updateSchedule(String scheduleId, Map<String, dynamic> data) =>
      _routeService.updateSchedule(scheduleId, data);

  Stream<List<ScheduleModel>> getSchedulesByCollege(String collegeId) =>
      _routeService.getSchedulesByCollege(collegeId);

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
  }) => _busService.getBusNumbers(collegeId, forceRefresh: forceRefresh);

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
