/// Represents an audit log entry for tracking administrative actions.
/// Used by Super Admin to monitor all system activities.
class AuditLogModel {
  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final String action; // e.g., 'user.approve', 'college.verify', 'bus.create'
  final String resource; // e.g., 'user', 'college', 'bus'
  final String resourceId;
  final String? resourceName;
  final Map<String, dynamic>? previousState;
  final Map<String, dynamic>? newState;
  final String? ipAddress;
  final String? userAgent;
  final String? collegeId;
  final DateTime createdAt;

  AuditLogModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.action,
    required this.resource,
    required this.resourceId,
    this.resourceName,
    this.previousState,
    this.newState,
    this.ipAddress,
    this.userAgent,
    this.collegeId,
    required this.createdAt,
  });

  factory AuditLogModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic value) {
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }

    return AuditLogModel(
      id: id,
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'] ?? '',
      userName: map['userName'] ?? '',
      action: map['action'] ?? '',
      resource: map['resource'] ?? '',
      resourceId: map['resourceId'] ?? '',
      resourceName: map['resourceName'],
      previousState: map['previousState'] != null
          ? Map<String, dynamic>.from(map['previousState'])
          : null,
      newState: map['newState'] != null
          ? Map<String, dynamic>.from(map['newState'])
          : null,
      ipAddress: map['ipAddress'],
      userAgent: map['userAgent'],
      collegeId: map['collegeId'],
      createdAt: parseDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'action': action,
      'resource': resource,
      'resourceId': resourceId,
      'resourceName': resourceName,
      'previousState': previousState,
      'newState': newState,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'collegeId': collegeId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Get a human-readable description of the action
  String get actionDescription {
    final parts = action.split('.');
    if (parts.length != 2) return action;

    final resourceType = parts[0];
    final actionType = parts[1];

    final resourceLabels = {
      'user': 'User',
      'college': 'College',
      'bus': 'Bus',
      'route': 'Route',
      'driver': 'Driver',
      'config': 'Configuration',
    };

    final actionLabels = {
      'create': 'created',
      'update': 'updated',
      'delete': 'deleted',
      'approve': 'approved',
      'reject': 'rejected',
      'verify': 'verified',
      'suspend': 'suspended',
      'activate': 'activated',
    };

    final resourceLabel = resourceLabels[resourceType] ?? resourceType;
    final actionLabel = actionLabels[actionType] ?? actionType;

    return '$resourceLabel $actionLabel';
  }

  /// Get the severity level of the action (info, warning, danger)
  String get severity {
    if (action.contains('delete') || action.contains('suspend')) {
      return 'danger';
    }
    if (action.contains('update') || action.contains('reject')) {
      return 'warning';
    }
    return 'info';
  }
}

/// Common audit actions
class AuditActions {
  // User actions
  static const String userCreated = 'user.create';
  static const String userUpdated = 'user.update';
  static const String userApproved = 'user.approve';
  static const String userRejected = 'user.reject';
  static const String userDeleted = 'user.delete';
  static const String userRoleChanged = 'user.role_change';

  // College actions
  static const String collegeCreated = 'college.create';
  static const String collegeVerified = 'college.verify';
  static const String collegeSuspended = 'college.suspend';
  static const String collegeActivated = 'college.activate';
  static const String collegeDeleted = 'college.delete';

  // Bus actions
  static const String busCreated = 'bus.create';
  static const String busUpdated = 'bus.update';
  static const String busDeleted = 'bus.delete';
  static const String driverAssigned = 'bus.driver_assign';
  static const String driverUnassigned = 'bus.driver_unassign';

  // Route actions
  static const String routeCreated = 'route.create';
  static const String routeUpdated = 'route.update';
  static const String routeDeleted = 'route.delete';

  // System actions
  static const String configUpdated = 'config.update';
  static const String featureFlagToggled = 'feature.toggle';
  static const String maintenanceModeToggled = 'system.maintenance';
}





