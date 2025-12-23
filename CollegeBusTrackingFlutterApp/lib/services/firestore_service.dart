import 'package:collegebus/models/user_model.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/models/route_model.dart';
import 'package:collegebus/models/college_model.dart';
import 'package:collegebus/models/notification_model.dart';
import 'package:collegebus/models/schedule_model.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/services/api_service.dart';

class FirestoreService {
  final ApiService _apiService;

  FirestoreService(this._apiService);

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
    // Basic implementation: fetch all and find
    // Using API efficiently would require a specific endpoint
    final colleges = await _apiService.getAllColleges();
    try {
      return colleges.firstWhere((c) => c.id == collegeId);
    } catch (_) {
      return null;
    }
  }

  Stream<List<CollegeModel>> getAllColleges() {
    return Stream.fromFuture(_apiService.getAllColleges());
  }

  // Bus operations
  Future<void> createBus(BusModel bus) async {
    await _apiService.createBus(bus);
  }

  Future<void> updateBus(String busId, Map<String, dynamic> data) async {
    await _apiService.updateBus(busId, data);
  }

  Stream<List<BusModel>> getBusesByCollege(String collegeId) {
    // Polling every 10 seconds to refresh list? Or just one-shot?
    // User dashboard expects live updates if new buses are added, but maybe less critical.
    // Bus location is critical.
    // Let's do a simple poll for lists too, but longer interval.
    return Stream.periodic(const Duration(seconds: 15))
        .asyncMap((_) => _apiService.getAllBuses())
        .map(
          (buses) => buses
              .where((b) => b.collegeId == collegeId && b.isActive)
              .toList(),
        );
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
  }

  Future<void> updateRoute(String routeId, Map<String, dynamic> data) async {
    await _apiService.updateRoute(routeId, data);
  }

  Stream<List<RouteModel>> getRoutesByCollege(String collegeId) {
    return Stream.fromFuture(_apiService.getRoutesByCollege(collegeId));
  }

  Future<void> deleteRoute(String routeId) async {
    await _apiService.deleteRoute(routeId);
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
    // API gap
    return Stream.value([]);
  }

  Future<void> deleteSchedule(String scheduleId) async {
    await _apiService.deleteSchedule(scheduleId);
  }

  // Bus number operations
  Future<void> addBusNumber(String collegeId, String busNumber) async {
    await _apiService.addBusNumber(collegeId, busNumber);
  }

  Future<void> removeBusNumber(String collegeId, String busNumber) async {
    await _apiService.removeBusNumber(collegeId, busNumber);
  }

  Stream<List<String>> getBusNumbers(String collegeId) {
    return Stream.fromFuture(_apiService.getBusNumbers(collegeId));
  }

  // Bus location operations
  Future<void> updateBusLocation(
    String busId,
    BusLocationModel location,
  ) async {
    await _apiService.updateBusLocation(
      busId,
      location.currentLocation.latitude,
      location.currentLocation.longitude,
      location.speed ?? 0.0,
      location.heading ?? 0.0,
    );
  }

  Stream<BusLocationModel?> getBusLocation(String busId) {
    // Poll for location updates
    return Stream.periodic(
      const Duration(seconds: 4),
    ).asyncMap((_) => _apiService.getBusLocation(busId));
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
