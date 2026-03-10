import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/features/coordinator/domain/assignment_log_model.dart';
import 'package:collegebus/core/data/repositories.dart';
import 'package:collegebus/core/services/socket_service.dart';

class BusService {
  final BusRepository _busRepo;
  final CollegeRepository _collegeRepo;
  final SocketService _socketService;

  BusService(this._busRepo, this._collegeRepo, this._socketService);

  // Operations delegate to repositories
  Future<void> createBus(BusModel bus) => _busRepo.createBus(bus);

  Future<void> updateBus(String busId, Map<String, dynamic> data) async {
    await _busRepo.updateBus(busId, data);
    _socketService.sendBusListUpdate();
  }

  Future<void> deleteBus(String busId) => _busRepo.deleteBus(busId);

  Future<BusModel?> getBusByDriver(String driverId) async {
    try {
      final buses = await _busRepo.getAllBuses();
      return buses.firstWhere((b) => b.driverId == driverId && b.isActive);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateBusStatus(String busId, String status) async {
    await _busRepo.updateBus(busId, {'status': status});
    _socketService.sendBusListUpdate();
  }

  Future<List<AssignmentLogModel>> getAssignmentLogsByBus(String busId) =>
      _busRepo.getAssignmentLogsByBus(busId);

  Future<List<AssignmentLogModel>> getAssignmentLogsByDriver(String driverId) =>
      _busRepo.getAssignmentLogsByDriver(driverId);

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

  // Bus Number Operations (via CollegeRepository)
  Future<void> addBusNumber(String collegeId, String busNumber) =>
      _collegeRepo.addBusNumber(collegeId, busNumber);

  Future<void> removeBusNumber(String collegeId, String busNumber) =>
      _collegeRepo.removeBusNumber(collegeId, busNumber);

  Future<void> renameBusNumber(
    String collegeId,
    String oldBusNumber,
    String newBusNumber,
  ) async {
    await _collegeRepo.renameBusNumber(collegeId, oldBusNumber, newBusNumber);
    _socketService.sendBusListUpdate();
  }

  Future<void> updateBusDetails({
    required String collegeId,
    required String oldBusNumber,
    String? newBusNumber,
    String? defaultRouteId,
  }) async {
    await _collegeRepo.updateBusDetails(
      collegeId: collegeId,
      oldBusNumber: oldBusNumber,
      newBusNumber: newBusNumber,
      details: defaultRouteId != null
          ? {'defaultRouteId': defaultRouteId}
          : null,
    );
    _socketService.sendBusListUpdate();
  }
}
