/// Represents a system configuration setting.
/// Used by Super Admin to manage global system settings.
class SystemConfigModel {
  final String key;
  final dynamic value;
  final String? description;
  final ConfigDataType dataType;
  final bool isPublic; // Whether visible to non-admins
  final bool isEditable; // Whether can be edited via UI
  final String? category; // Grouping for UI display
  final DateTime updatedAt;
  final String? updatedBy;

  SystemConfigModel({
    required this.key,
    required this.value,
    this.description,
    required this.dataType,
    this.isPublic = false,
    this.isEditable = true,
    this.category,
    required this.updatedAt,
    this.updatedBy,
  });

  factory SystemConfigModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }

    return SystemConfigModel(
      key: map['key'] ?? '',
      value: map['value'],
      description: map['description'],
      dataType: ConfigDataType.fromString(map['dataType'] ?? 'string'),
      isPublic: map['isPublic'] ?? false,
      isEditable: map['isEditable'] ?? true,
      category: map['category'],
      updatedAt: parseDate(map['updatedAt']),
      updatedBy: map['updatedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'value': value,
      'description': description,
      'dataType': dataType.name,
      'isPublic': isPublic,
      'isEditable': isEditable,
      'category': category,
      'updatedAt': updatedAt.toIso8601String(),
      'updatedBy': updatedBy,
    };
  }

  SystemConfigModel copyWith({
    String? key,
    dynamic value,
    String? description,
    ConfigDataType? dataType,
    bool? isPublic,
    bool? isEditable,
    String? category,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return SystemConfigModel(
      key: key ?? this.key,
      value: value ?? this.value,
      description: description ?? this.description,
      dataType: dataType ?? this.dataType,
      isPublic: isPublic ?? this.isPublic,
      isEditable: isEditable ?? this.isEditable,
      category: category ?? this.category,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  /// Get the value as a specific type
  T? getAs<T>() {
    if (value is T) return value as T;
    return null;
  }

  /// Get value as boolean
  bool get asBool => value == true || value == 'true';

  /// Get value as string
  String get asString => value?.toString() ?? '';

  /// Get value as int
  int get asInt =>
      value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;

  /// Get value as double
  double get asDouble =>
      value is double ? value : double.tryParse(value?.toString() ?? '') ?? 0.0;
}

/// Data types for system configuration values
enum ConfigDataType {
  string,
  boolean,
  number,
  json,
  email,
  url;

  static ConfigDataType fromString(String value) {
    return ConfigDataType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ConfigDataType.string,
    );
  }
}

/// Predefined system configuration keys
class SystemConfigKeys {
  // Email settings
  static const String smtpHost = 'email.smtp.host';
  static const String smtpPort = 'email.smtp.port';
  static const String smtpUser = 'email.smtp.user';
  static const String emailFromName = 'email.from.name';
  static const String emailFromAddress = 'email.from.address';

  // Notification settings
  static const String pushNotificationsEnabled = 'notifications.push.enabled';
  static const String emailNotificationsEnabled = 'notifications.email.enabled';

  // Rate limiting
  static const String rateLimitEnabled = 'rateLimit.enabled';
  static const String rateLimitRequests = 'rateLimit.requests';
  static const String rateLimitWindow = 'rateLimit.windowMs';

  // Feature flags
  static const String sosFeatureEnabled = 'features.sos.enabled';
  static const String liveTrackingEnabled = 'features.liveTracking.enabled';
  static const String paymentEnabled = 'features.payment.enabled';

  // System settings
  static const String maintenanceMode = 'system.maintenance.enabled';
  static const String maintenanceMessage = 'system.maintenance.message';
  static const String registrationEnabled = 'system.registration.enabled';
  static const String autoApproveStudents = 'system.autoApprove.students';
}

/// Configuration categories for UI grouping
class ConfigCategory {
  static const String email = 'Email Settings';
  static const String notifications = 'Notifications';
  static const String rateLimiting = 'Rate Limiting';
  static const String features = 'Feature Flags';
  static const String system = 'System Settings';
}
