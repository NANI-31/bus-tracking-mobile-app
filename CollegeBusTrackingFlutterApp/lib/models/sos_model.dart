enum SosStatus { active, resolved }

extension SosStatusExtension on SosStatus {
  String get value {
    switch (this) {
      case SosStatus.active:
        return 'ACTIVE';
      case SosStatus.resolved:
        return 'RESOLVED';
    }
  }

  static SosStatus fromValue(String value) {
    if (value.toUpperCase() == 'ACTIVE') return SosStatus.active;
    if (value.toUpperCase() == 'RESOLVED') return SosStatus.resolved;
    return SosStatus.active;
  }
}

class SosModel {
  final String sosId;
  final String collegeId;
  final String userId;
  final String userRole;
  final String busId;
  final String busNumber;
  final String routeId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final SosStatus status;

  SosModel({
    required this.sosId,
    required this.collegeId,
    required this.userId,
    required this.userRole,
    required this.busId,
    required this.busNumber,
    required this.routeId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.status,
  });

  factory SosModel.fromMap(Map<String, dynamic> map) {
    return SosModel(
      sosId: map['sos_id'] ?? '',
      collegeId: map['collegeId'] ?? '',
      userId: map['user_id'] ?? '',
      userRole: map['user_role'] ?? '',
      busId: map['bus_id'] ?? '',
      busNumber: map['bus_number'] ?? (map['bus_id'] ?? 'N/A'),
      routeId: map['route_id'] ?? '',
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
      status: SosStatusExtension.fromValue(map['status'] ?? 'ACTIVE'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sos_id': sosId,
      'collegeId': collegeId,
      'user_id': userId,
      'user_role': userRole,
      'bus_id': busId,
      'bus_number': busNumber,
      'route_id': routeId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'status': status.value,
    };
  }

  SosModel copyWith({
    String? sosId,
    String? collegeId,
    String? userId,
    String? userRole,
    String? busId,
    String? busNumber,
    String? routeId,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    SosStatus? status,
  }) {
    return SosModel(
      sosId: sosId ?? this.sosId,
      collegeId: collegeId ?? this.collegeId,
      userId: userId ?? this.userId,
      userRole: userRole ?? this.userRole,
      busId: busId ?? this.busId,
      busNumber: busNumber ?? this.busNumber,
      routeId: routeId ?? this.routeId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }
}
