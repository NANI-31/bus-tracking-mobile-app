import 'package:collegebus/core/utils/type_converters.dart';

class CollegeModel {
  final String id;
  final String name;
  final List<String> allowedDomains;
  final bool verified;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  // New fields for admin module
  final String? adminId; // Assigned college admin user ID
  final bool suspended;
  final Map<String, dynamic>? settings; // College-specific settings
  final DateTime? suspendedAt;
  final String? suspensionReason;
  final int shiftCount;
  final List<ShiftConfig> shifts;

  CollegeModel({
    required this.id,
    required this.name,
    required this.allowedDomains,
    this.verified = false,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.adminId,
    this.suspended = false,
    this.settings,
    this.suspendedAt,
    this.suspensionReason,
    this.shiftCount = 1,
    this.shifts = const [],
  });

  factory CollegeModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic value) {
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }

    return CollegeModel(
      id: id,
      name: map['name'] ?? '',
      allowedDomains: List<String>.from(map['allowedDomains'] ?? []),
      verified: parseBool(map['verified'], false),
      createdBy: map['createdBy'] ?? '',
      createdAt: parseDate(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? parseDate(map['updatedAt']) : null,
      adminId: map['adminId'],
      suspended: parseBool(map['suspended'], false),
      settings: map['settings'] != null
          ? Map<String, dynamic>.from(map['settings'])
          : null,
      suspendedAt: map['suspendedAt'] != null
          ? parseDate(map['suspendedAt'])
          : null,
      suspensionReason: map['suspensionReason'],
      shiftCount: map['shiftCount'] ?? 1,
      shifts:
          (map['shifts'] as List<dynamic>?)
              ?.map((s) => ShiftConfig.fromMap(s))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'allowedDomains': allowedDomains,
      'verified': verified,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'adminId': adminId,
      'suspended': suspended,
      'settings': settings,
      'suspendedAt': suspendedAt?.toIso8601String(),
      'suspensionReason': suspensionReason,
      'shiftCount': shiftCount,
      'shifts': shifts.map((s) => s.toMap()).toList(),
    };
  }

  CollegeModel copyWith({
    String? id,
    String? name,
    List<String>? allowedDomains,
    bool? verified,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? adminId,
    bool? suspended,
    Map<String, dynamic>? settings,
    DateTime? suspendedAt,
    String? suspensionReason,
    int? shiftCount,
    List<ShiftConfig>? shifts,
  }) {
    return CollegeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      allowedDomains: allowedDomains ?? this.allowedDomains,
      verified: verified ?? this.verified,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      adminId: adminId ?? this.adminId,
      suspended: suspended ?? this.suspended,
      settings: settings ?? this.settings,
      suspendedAt: suspendedAt ?? this.suspendedAt,
      suspensionReason: suspensionReason ?? this.suspensionReason,
      shiftCount: shiftCount ?? this.shiftCount,
      shifts: shifts ?? this.shifts,
    );
  }

  /// Check if college is active (verified and not suspended)
  bool get isActive => verified && !suspended;

  /// Get a setting value with type safety
  T? getSetting<T>(String key) {
    if (settings == null) return null;
    final value = settings![key];
    if (value is T) return value;
    return null;
  }
}

class ShiftConfig {
  final String shiftId;
  final String name;
  final String? pickupTime;
  final String? dropTime;

  ShiftConfig({
    required this.shiftId,
    required this.name,
    this.pickupTime,
    this.dropTime,
  });

  factory ShiftConfig.fromMap(Map<String, dynamic> map) {
    return ShiftConfig(
      shiftId: map['shiftId'] ?? '',
      name: map['name'] ?? '',
      pickupTime: map['pickupTime'],
      dropTime: map['dropTime'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shiftId': shiftId,
      'name': name,
      'pickupTime': pickupTime,
      'dropTime': dropTime,
    };
  }
}

