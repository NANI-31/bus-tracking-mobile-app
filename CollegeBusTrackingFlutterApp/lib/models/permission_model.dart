/// Represents a permission that can be granted to a role or user.
/// Used for fine-grained access control in admin modules.
class PermissionModel {
  final String id;
  final String name;
  final String description;
  final String resource; // e.g., 'users', 'buses', 'routes', 'colleges'
  final List<String> actions; // e.g., ['create', 'read', 'update', 'delete']
  final String? scope; // 'college' or 'system'

  PermissionModel({
    required this.id,
    required this.name,
    required this.description,
    required this.resource,
    required this.actions,
    this.scope,
  });

  factory PermissionModel.fromMap(Map<String, dynamic> map, String id) {
    return PermissionModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      resource: map['resource'] ?? '',
      actions: List<String>.from(map['actions'] ?? []),
      scope: map['scope'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'resource': resource,
      'actions': actions,
      'scope': scope,
    };
  }

  PermissionModel copyWith({
    String? id,
    String? name,
    String? description,
    String? resource,
    List<String>? actions,
    String? scope,
  }) {
    return PermissionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      resource: resource ?? this.resource,
      actions: actions ?? this.actions,
      scope: scope ?? this.scope,
    );
  }

  /// Check if this permission allows a specific action on a resource
  bool allows(String action) => actions.contains(action);

  /// Check if this permission applies to a specific resource
  bool appliesTo(String resourceName) => resource == resourceName;
}

/// Predefined permissions for the admin system
class AdminPermissions {
  // College Admin permissions
  static const String viewCollegeUsers = 'college:users:read';
  static const String approveUsers = 'college:users:approve';
  static const String manageCoordinators = 'college:coordinators:manage';
  static const String manageBuses = 'college:buses:manage';
  static const String manageRoutes = 'college:routes:manage';
  static const String viewCollegeReports = 'college:reports:read';
  static const String editCollegeSettings = 'college:settings:edit';

  // Super Admin permissions
  static const String viewAllColleges = 'system:colleges:read';
  static const String verifyColleges = 'system:colleges:verify';
  static const String createCollegeAdmins = 'system:admins:create';
  static const String viewSystemConfig = 'system:config:read';
  static const String editSystemConfig = 'system:config:edit';
  static const String viewAuditLogs = 'system:audit:read';
  static const String manageFeatureFlags = 'system:features:manage';
  static const String performDangerZoneActions = 'system:danger:execute';
}
