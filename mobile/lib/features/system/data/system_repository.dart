import 'package:collegebus/features/system/domain/system_config_model.dart';
import 'package:collegebus/core/data/base_repository.dart';

/// Repository for system configuration operations
class SystemRepository extends BaseRepository {
  /// Fetch the current system configuration
  Future<SystemConfigModel> getSystemConfig() async {
    try {
      // Assuming a single global config document
      final response = await dio.get('/admin/system-config');
      final data = response.data;

      if (data is List) {
        // Find the 'maintenanceMode' config or return a default
        final maintenanceConfig = data.firstWhere(
          (c) => c['key'] == 'maintenanceMode',
          orElse: () => {'key': 'maintenanceMode', 'value': false},
        );
        return SystemConfigModel.fromMap(maintenanceConfig);
      }

      return SystemConfigModel.fromMap(data);
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Fetch all system configurations
  Future<List<SystemConfigModel>> getAllConfigs() async {
    try {
      final response = await dio.get('/admin/system-config');
      final data = response.data;

      if (data is List) {
        return data.map((c) => SystemConfigModel.fromMap(c)).toList();
      }

      return [];
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Update system configuration
  Future<SystemConfigModel> updateSystemConfig(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await dio.put('/admin/system-config', data: data);
      return SystemConfigModel.fromMap(response.data);
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Toggle maintenance mode
  Future<SystemConfigModel> setMaintenanceMode(bool enabled) async {
    return updateSystemConfig({'maintenanceMode': enabled});
  }

  /// Fetch storage statistics (MongoDB, Redis, AWS S3)
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final response = await dio.get('/admin/super/storage-stats');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Fetch historical storage metrics for a specific college
  Future<List<dynamic>> getCollegeStorageHistory(
    String collegeId, {
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final response = await dio.get(
        '/admin/super/colleges/$collegeId/storage-history',
        queryParameters: queryParams,
      );
      return response.data as List<dynamic>;
    } catch (e) {
      throw handleError(e);
    }
  }
}





