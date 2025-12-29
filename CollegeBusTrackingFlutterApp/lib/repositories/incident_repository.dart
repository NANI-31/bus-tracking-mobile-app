import 'package:collegebus/models/incident_model.dart';
import 'package:collegebus/repositories/base_repository.dart';

/// Repository for incident and SOS operations
class IncidentRepository extends BaseRepository {
  /// Send an SOS alert
  Future<Map<String, dynamic>> sendSOS({
    required String? busId,
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await dio.post(
        '/sos',
        data: {
          'busId': busId,
          'location': {'lat': lat, 'lng': lng},
        },
      );
      return response.data;
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Create an incident report
  Future<void> createIncident(IncidentModel incident) async {
    try {
      await dio.post('/incidents', data: incident.toJson());
    } catch (e) {
      throw handleError(e);
    }
  }
}
