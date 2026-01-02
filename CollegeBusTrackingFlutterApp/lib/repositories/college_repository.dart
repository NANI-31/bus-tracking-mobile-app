import 'package:collegebus/models/college_model.dart';
import 'package:collegebus/repositories/base_repository.dart';

/// Repository for college operations
class CollegeRepository extends BaseRepository {
  /// Get all colleges
  Future<List<CollegeModel>> getAllColleges() async {
    try {
      final response = await dio.get('/colleges');
      return (response.data as List)
          .map((data) => CollegeModel.fromMap(data, data['_id']))
          .toList();
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Add a bus number to a college
  Future<void> addBusNumber(String collegeId, String busNumber) async {
    try {
      await dio.post(
        '/colleges/bus-numbers',
        data: {'collegeId': collegeId, 'busNumber': busNumber},
      );
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Get all bus numbers for a college
  Future<List<String>> getBusNumbers(String collegeId) async {
    try {
      final response = await dio.get('/colleges/$collegeId/bus-numbers');
      return (response.data as List).map((e) => e.toString()).toList();
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Remove a bus number from a college
  Future<void> removeBusNumber(String collegeId, String busNumber) async {
    try {
      await dio.delete('/colleges/$collegeId/bus-numbers/$busNumber');
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Rename a bus number
  Future<void> renameBusNumber(
    String collegeId,
    String oldBusNumber,
    String newBusNumber,
  ) async {
    try {
      await dio.put(
        '/colleges/bus-numbers/rename',
        data: {
          'collegeId': collegeId,
          'oldBusNumber': oldBusNumber,
          'newBusNumber': newBusNumber,
        },
      );
    } catch (e) {
      throw handleError(e);
    }
  }
}
