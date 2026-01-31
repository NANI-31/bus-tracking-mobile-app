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
}
