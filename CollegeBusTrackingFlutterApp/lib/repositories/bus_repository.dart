import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/models/assignment_log_model.dart';
import 'package:collegebus/repositories/base_repository.dart';

/// Repository for bus and location operations
class BusRepository extends BaseRepository {
  // ============== Bus CRUD ==============

  /// Get all buses
  Future<List<BusModel>> getAllBuses() async {
    try {
      final response = await dio.get('/buses');
      return (response.data as List)
          .map((data) => BusModel.fromMap(data, data['_id']))
          .toList();
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Create a new bus
  Future<BusModel> createBus(BusModel bus) async {
    try {
      final response = await dio.post('/buses', data: bus.toMap());
      return BusModel.fromMap(response.data, response.data['_id']);
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Update bus data
  Future<void> updateBus(String busId, Map<String, dynamic> data) async {
    try {
      await dio.put('/buses/$busId', data: data);
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Delete a bus
  Future<void> deleteBus(String busId) async {
    try {
      await dio.delete('/buses/$busId');
    } catch (e) {
      throw handleError(e);
    }
  }

  // ============== Location Operations ==============

  /// Update bus location (REST API fallback - prefer socket)
  Future<void> updateBusLocation(
    String busId,
    double lat,
    double lng,
    double speed,
    double heading,
  ) async {
    try {
      await dio.post(
        '/buses/location',
        data: {
          'busId': busId,
          'currentLocation': {'lat': lat, 'lng': lng},
          'speed': speed,
          'heading': heading,
        },
      );
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Get latest location for a single bus
  Future<BusLocationModel?> getBusLocation(String busId) async {
    try {
      final response = await dio.get('/buses/$busId/location');
      if (response.data == null) return null;
      return BusLocationModel.fromMap(response.data, busId);
    } catch (e) {
      // Location might not exist yet
      return null;
    }
  }

  /// Get latest locations for all buses in a college
  Future<List<BusLocationModel>> getCollegeBusLocations(
    String collegeId,
  ) async {
    try {
      final response = await dio.get('/buses/college/$collegeId/locations');
      return (response.data as List)
          .map((data) => BusLocationModel.fromMap(data, data['busId']))
          .toList();
    } catch (e) {
      throw handleError(e);
    }
  }

  // ============== Assignment Logs ==============

  /// Get assignment logs for a bus
  Future<List<AssignmentLogModel>> getAssignmentLogsByBus(String busId) async {
    try {
      final response = await dio.get('/assignments/bus/$busId');
      return (response.data as List)
          .map((data) => AssignmentLogModel.fromMap(data))
          .toList();
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Get assignment logs for a driver
  Future<List<AssignmentLogModel>> getAssignmentLogsByDriver(
    String driverId,
  ) async {
    try {
      final response = await dio.get('/assignments/driver/$driverId');
      return (response.data as List)
          .map((data) => AssignmentLogModel.fromMap(data))
          .toList();
    } catch (e) {
      throw handleError(e);
    }
  }
}
