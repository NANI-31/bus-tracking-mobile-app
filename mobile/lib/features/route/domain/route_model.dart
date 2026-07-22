import 'package:collegebus/core/utils/type_converters.dart';
import 'package:collegebus/core/services/directions_result.dart';

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
  final DirectionsResult? directions;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String color;

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
    this.directions,
    required this.createdAt,
    this.updatedAt,
    this.color = '#0097B2',
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
      isActive: parseBool(map['isActive'], true),
      directions: map['directions'] != null
          ? DirectionsResult.fromMap(Map<String, dynamic>.from(map['directions']))
          : null,
      createdAt: parseDateTime(map['createdAt']),
      updatedAt: map['updatedAt'] != null
          ? parseDateTime(map['updatedAt'])
          : null,
      color: map['color'] ?? '#0097B2',
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
      'directions': directions?.toMap(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'color': color,
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
    DirectionsResult? directions,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? color,
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
      directions: directions ?? this.directions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      color: color ?? this.color,
    );
  }

  /// Returns the ordered list of waypoints based on active trip direction.
  /// - pickup : [startPoint, ...stopPoints, endPoint]
  /// - drop   : [endPoint, ...stopPoints.reversed, startPoint]
  List<RoutePoint> getOrderedStops([String? tripType]) {
    final effectiveType = tripType ?? routeType;
    if (effectiveType == 'drop') {
      return [
        endPoint,
        ...stopPoints.reversed,
        startPoint,
      ];
    }
    return [
      startPoint,
      ...stopPoints,
      endPoint,
    ];
  }

  String get displayName => '$routeName (${routeType.toUpperCase()})';
}

