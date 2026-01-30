import 'package:collegebus/models/audit_log_model.dart';
import 'package:collegebus/repositories/base_repository.dart';

/// Repository for audit log operations
class AuditRepository extends BaseRepository {
  /// Fetch audit logs with filtering and pagination
  Future<List<AuditLogModel>> getAuditLogs({
    String? collegeId,
    String? adminId,
    String? action,
    int? limit,
    int? skip,
  }) async {
    try {
      final response = await dio.get(
        '/admin/audit-logs',
        queryParameters: {
          if (collegeId != null) 'collegeId': collegeId,
          if (adminId != null) 'adminId': adminId,
          if (action != null) 'action': action,
          if (limit != null) 'limit': limit,
          if (skip != null) 'skip': skip,
        },
      );
      final data = response.data;
      final List logsList = data is Map ? data['logs'] : data;

      return logsList
          .map((data) => AuditLogModel.fromMap(data, data['_id'] ?? ''))
          .toList();
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Create a new audit log entry (usually server-side, but provided for testing)
  Future<AuditLogModel> createAuditLog(AuditLogModel log) async {
    try {
      final response = await dio.post('/admin/audit-logs', data: log.toMap());
      return AuditLogModel.fromMap(response.data, response.data['_id']);
    } catch (e) {
      throw handleError(e);
    }
  }
}
