import 'package:collegebus/models/schedule_model.dart';
import 'package:collegebus/repositories/base_repository.dart';

/// Repository for schedule operations
class ScheduleRepository extends BaseRepository {
  /// Get all schedules for a college
  Future<List<ScheduleModel>> getSchedulesByCollege(String collegeId) async {
    try {
      final response = await dio.get('/schedules/college/$collegeId');
      return (response.data as List)
          .map((data) => ScheduleModel.fromMap(data, data['_id']))
          .toList();
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Create a new schedule
  Future<ScheduleModel> createSchedule(ScheduleModel schedule) async {
    try {
      final response = await dio.post('/schedules', data: schedule.toMap());
      return ScheduleModel.fromMap(response.data, response.data['_id']);
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Update schedule data
  Future<void> updateSchedule(
    String scheduleId,
    Map<String, dynamic> data,
  ) async {
    try {
      await dio.put('/schedules/$scheduleId', data: data);
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Delete a schedule
  Future<void> deleteSchedule(String scheduleId) async {
    try {
      await dio.delete('/schedules/$scheduleId');
    } catch (e) {
      throw handleError(e);
    }
  }
}
