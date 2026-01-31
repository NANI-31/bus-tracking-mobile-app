class RoutePoint {
  final String name;
  final double lat;
  final double lng;

  RoutePoint({required this.name, required this.lat, required this.lng});

  factory RoutePoint.fromMap(dynamic map) {
    if (map is String) {
      // Handle legacy or string-only data
      return RoutePoint(name: map, lat: 0.0, lng: 0.0);
    }
    final location = map['location'] ?? {};
    return RoutePoint(
      name: map['name'] ?? '',
      lat: (location['lat'] ?? 0.0).toDouble(),
      lng: (location['lng'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': {'lat': lat, 'lng': lng},
    };
  }
}

class RouteModel {
  final String id;
  final String routeName;
  final String routeType; // 'pickup' or 'drop'
  final RoutePoint startPoint;
  final RoutePoint endPoint;
  final List<RoutePoint> stopPoints;
  final String collegeId;
  final String createdBy;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  RouteModel({
    required this.id,
    required this.routeName,
    required this.routeType,
    required this.startPoint,
    required this.endPoint,
    required this.stopPoints,
    required this.collegeId,
    required this.createdBy,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory RouteModel.fromMap(Map<String, dynamic> map, String id) {
    return RouteModel(
      id: id,
      routeName: map['routeName'] ?? '',
      routeType: map['routeType'] ?? 'pickup',
      startPoint: RoutePoint.fromMap(map['startPoint']),
      endPoint: RoutePoint.fromMap(map['endPoint']),
      stopPoints: (map['stopPoints'] as List? ?? [])
          .map((e) => RoutePoint.fromMap(e))
          .toList(),
      collegeId: map['collegeId'] ?? '',
      createdBy: map['createdBy'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'routeName': routeName,
      'routeType': routeType,
      'startPoint': startPoint.toMap(),
      'endPoint': endPoint.toMap(),
      'stopPoints': stopPoints.map((s) => s.toMap()).toList(),
      'collegeId': collegeId,
      'createdBy': createdBy,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  RouteModel copyWith({
    String? id,
    String? routeName,
    String? routeType,
    RoutePoint? startPoint,
    RoutePoint? endPoint,
    List<RoutePoint>? stopPoints,
    String? collegeId,
    String? createdBy,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RouteModel(
      id: id ?? this.id,
      routeName: routeName ?? this.routeName,
      routeType: routeType ?? this.routeType,
      startPoint: startPoint ?? this.startPoint,
      endPoint: endPoint ?? this.endPoint,
      stopPoints: stopPoints ?? this.stopPoints,
      collegeId: collegeId ?? this.collegeId,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get displayName => '$routeName (${routeType.toUpperCase()})';
}
