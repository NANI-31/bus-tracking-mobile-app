import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/models/assignment_log_model.dart';
import 'package:collegebus/services/api/api_service.dart';
import 'package:collegebus/services/api/socket_service.dart';

class BusService {
  final ApiService _apiService;
  final SocketService _socketService;

  BusService(this._apiService, this._socketService);

  // Operations delegate to ApiService
  Future<void> createBus(BusModel bus) => _apiService.createBus(bus);

  Future<void> updateBus(String busId, Map<String, dynamic> data) async {
    await _apiService.updateBus(busId, data);
    _socketService.sendBusListUpdate();
  }

  Future<void> deleteBus(String busId) => _apiService.deleteBus(busId);

  Future<BusModel?> getBusByDriver(String driverId) async {
    try {
      final buses = await _apiService.getAllBuses();
      return buses.firstWhere((b) => b.driverId == driverId && b.isActive);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateBusStatus(String busId, String status) async {
    await _apiService.updateBus(busId, {'status': status});
    _socketService.sendBusListUpdate();
  }

  Future<List<AssignmentLogModel>> getAssignmentLogsByBus(String busId) =>
      _apiService.getAssignmentLogsByBus(busId);

  Future<List<AssignmentLogModel>> getAssignmentLogsByDriver(String driverId) =>
      _apiService.getAssignmentLogsByDriver(driverId);

  Future<void> updateBusLocation(
    String busId,
    String collegeId,
    BusLocationModel location,
  ) async {
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
  }

  // Bus Number Operations
  Future<void> addBusNumber(String collegeId, String busNumber) =>
      _apiService.addBusNumber(collegeId, busNumber);

  Future<void> removeBusNumber(String collegeId, String busNumber) =>
      _apiService.removeBusNumber(collegeId, busNumber);

  Future<void> renameBusNumber(
    String collegeId,
    String oldBusNumber,
    String newBusNumber,
  ) async {
    await _apiService.renameBusNumber(collegeId, oldBusNumber, newBusNumber);
    _socketService.sendBusListUpdate();
  }

  Future<void> updateBusDetails({
    required String collegeId,
    required String oldBusNumber,
    String? newBusNumber,
    String? defaultRouteId,
  }) async {
    await _apiService.updateBusDetails(
      collegeId,
      oldBusNumber,
      newBusNumber: newBusNumber,
      defaultRouteId: defaultRouteId,
    );
    _socketService.sendBusListUpdate();
  }
}
