import 'package:collegebus/models/user_model.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/models/route_model.dart';
import 'package:collegebus/models/college_model.dart';
import 'package:collegebus/models/schedule_model.dart';
import 'package:collegebus/models/notification_model.dart';
import 'package:collegebus/models/assignment_log_model.dart';
import 'package:collegebus/models/incident_model.dart';
import 'package:collegebus/repositories/repositories.dart';

/// ApiService - Facade that delegates to domain-specific repositories.
///
/// This class is kept for backward compatibility with existing code.
/// New code should prefer injecting specific repositories directly.
class ApiService {
  // Repository instances (lazy-initialized)
  final AuthRepository _authRepo = AuthRepository();
  final UserRepository _userRepo = UserRepository();
  final BusRepository _busRepo = BusRepository();
  final RouteRepository _routeRepo = RouteRepository();
  final ScheduleRepository _scheduleRepo = ScheduleRepository();
  final NotificationRepository _notificationRepo = NotificationRepository();
  final CollegeRepository _collegeRepo = CollegeRepository();
  final IncidentRepository _incidentRepo = IncidentRepository();

  // ============== Auth Operations (delegates to AuthRepository) ==============
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) =>
      _authRepo.register(userData);

  Future<Map<String, dynamic>> login(String email, String password) =>
      _authRepo.login(email, password);

  Future<Map<String, dynamic>> sendOtp(String email) =>
      _authRepo.sendOtp(email);

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) =>
      _authRepo.verifyOtp(email, otp);

  Future<Map<String, dynamic>> resetPassword(
    String email,
    String newPassword,
  ) => _authRepo.resetPassword(email, newPassword);

  // ============== User Operations (delegates to UserRepository) ==============
  Future<UserModel?> getUser(String userId) => _userRepo.getUser(userId);

  Future<List<UserModel>> getAllUsers() => _userRepo.getAllUsers();

  Future<UserModel> updateUser(String userId, Map<String, dynamic> data) =>
      _userRepo.updateUser(userId, data);

  Future<void> approveUser(String userId, String approverId) =>
      _userRepo.approveUser(userId, approverId);

  Future<Map<String, dynamic>> getDriverHistory(
    String driverId, {
    String? eventType,
    int page = 1,
    int limit = 50,
  }) => _userRepo.getDriverHistory(
    driverId,
    eventType: eventType,
    page: page,
    limit: limit,
  );

  // ============== Bus Operations (delegates to BusRepository) ==============
  Future<List<BusModel>> getAllBuses() => _busRepo.getAllBuses();

  Future<BusModel> createBus(BusModel bus) => _busRepo.createBus(bus);

  Future<void> updateBus(String busId, Map<String, dynamic> data) =>
      _busRepo.updateBus(busId, data);

  Future<void> deleteBus(String busId) => _busRepo.deleteBus(busId);

  Future<void> updateBusLocation(
    String busId,
    double lat,
    double lng,
    double speed,
    double heading,
  ) => _busRepo.updateBusLocation(busId, lat, lng, speed, heading);

  Future<BusLocationModel?> getBusLocation(String busId) =>
      _busRepo.getBusLocation(busId);

  Future<List<BusLocationModel>> getCollegeBusLocations(String collegeId) =>
      _busRepo.getCollegeBusLocations(collegeId);

  Future<List<AssignmentLogModel>> getAssignmentLogsByBus(String busId) =>
      _busRepo.getAssignmentLogsByBus(busId);

  Future<List<AssignmentLogModel>> getAssignmentLogsByDriver(String driverId) =>
      _busRepo.getAssignmentLogsByDriver(driverId);

  // ============== Route Operations (delegates to RouteRepository) ==============
  Future<List<RouteModel>> getRoutesByCollege(String collegeId) =>
      _routeRepo.getRoutesByCollege(collegeId);

  Future<RouteModel> createRoute(RouteModel route) =>
      _routeRepo.createRoute(route);

  Future<void> updateRoute(String routeId, Map<String, dynamic> data) =>
      _routeRepo.updateRoute(routeId, data);

  Future<void> deleteRoute(String routeId) => _routeRepo.deleteRoute(routeId);

  // ============== Schedule Operations (delegates to ScheduleRepository) ==============
  Future<List<ScheduleModel>> getSchedulesByCollege(String collegeId) =>
      _scheduleRepo.getSchedulesByCollege(collegeId);

  Future<ScheduleModel> createSchedule(ScheduleModel schedule) =>
      _scheduleRepo.createSchedule(schedule);

  Future<void> updateSchedule(String scheduleId, Map<String, dynamic> data) =>
      _scheduleRepo.updateSchedule(scheduleId, data);

  Future<void> deleteSchedule(String scheduleId) =>
      _scheduleRepo.deleteSchedule(scheduleId);

  // ============== Notification Operations (delegates to NotificationRepository) ==============
  Future<void> sendNotification(NotificationModel notification) =>
      _notificationRepo.sendNotification(notification);

  Future<List<NotificationModel>> getUserNotifications(String userId) =>
      _notificationRepo.getUserNotifications(userId);

  Future<void> markNotificationAsRead(String notificationId) =>
      _notificationRepo.markNotificationAsRead(notificationId);

  Future<void> removeFcmToken(String userId) =>
      _notificationRepo.removeFcmToken(userId);

  Future<Map<String, dynamic>> broadcastToCollege(String message) =>
      _notificationRepo.broadcastToCollege(message);

  Future<void> updateBusDetails(
    String collegeId,
    String oldBusNumber, {
    String? newBusNumber,
    String? defaultRouteId,
  }) => _collegeRepo.updateBusDetails(
    collegeId: collegeId,
    oldBusNumber: oldBusNumber,
    newBusNumber: newBusNumber,
    details: defaultRouteId != null ? {'defaultRouteId': defaultRouteId} : null,
  );

  // ============== College Operations (delegates to CollegeRepository) ==============
  Future<List<CollegeModel>> getAllColleges() => _collegeRepo.getAllColleges();

  Future<void> addBusNumber(String collegeId, String busNumber) =>
      _collegeRepo.addBusNumber(collegeId, busNumber);

  Future<List<String>> getBusNumbers(String collegeId) =>
      _collegeRepo.getBusNumbers(collegeId);

  Future<void> removeBusNumber(String collegeId, String busNumber) =>
      _collegeRepo.removeBusNumber(collegeId, busNumber);

  Future<void> renameBusNumber(
    String collegeId,
    String oldBusNumber,
    String newBusNumber,
  ) => _collegeRepo.renameBusNumber(collegeId, oldBusNumber, newBusNumber);

  // ============== Incident Operations (delegates to IncidentRepository) ==============
  Future<Map<String, dynamic>> sendSOS({
    required String? busId,
    required String? routeId,
    required double lat,
    required double lng,
  }) =>
      _incidentRepo.sendSOS(busId: busId, routeId: routeId, lat: lat, lng: lng);

  Future<void> resolveSos(String sosId) => _incidentRepo.resolveSos(sosId);

  Future<List<Map<String, dynamic>>> getActiveSos(String collegeId) =>
      _incidentRepo.getActiveSos(collegeId);

  Future<void> createIncident(IncidentModel incident) =>
      _incidentRepo.createIncident(incident);
}
