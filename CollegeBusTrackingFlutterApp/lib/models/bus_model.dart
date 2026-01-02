import 'package:google_maps_flutter/google_maps_flutter.dart';

class BusModel {
  final String id;
  final String busNumber;
  final String driverId;
  final String? routeId;
  final String? defaultRouteId;
  final String collegeId;
  final bool isActive;
  final String status;
  final String assignmentStatus;
  final int delay;
  final DateTime createdAt;
  final DateTime? updatedAt;

  BusModel({
    required this.id,
    required this.busNumber,
    required this.driverId,
    this.routeId,
    this.defaultRouteId,
    required this.collegeId,
    this.isActive = true,
    this.status = 'on-time',
    this.assignmentStatus = 'unassigned',
    this.delay = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory BusModel.fromMap(Map<String, dynamic> map, String id) {
    return BusModel(
      id: id,
      busNumber: map['busNumber'] ?? '',
      driverId: map['driverId'] ?? '',
      routeId: map['routeId'],
      defaultRouteId: map['defaultRouteId'],
      collegeId: map['collegeId'] ?? '',
      isActive: map['isActive'] ?? true,
      status: map['status'] ?? 'on-time',
      assignmentStatus: map['assignmentStatus'] ?? 'unassigned',
      delay: map['delay'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'busNumber': busNumber,
      'driverId': driverId,
      'routeId': routeId,
      'defaultRouteId': defaultRouteId,
      'collegeId': collegeId,
      'isActive': isActive,
      'status': status,
      'assignmentStatus': assignmentStatus,
      'delay': delay,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  BusModel copyWith({
    String? id,
    String? busNumber,
    String? driverId,
    String? routeId,
    String? defaultRouteId,
    String? collegeId,
    bool? isActive,
    String? status,
    String? assignmentStatus,
    int? delay,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusModel(
      id: id ?? this.id,
      busNumber: busNumber ?? this.busNumber,
      driverId: driverId ?? this.driverId,
      routeId: routeId ?? this.routeId,
      defaultRouteId: defaultRouteId ?? this.defaultRouteId,
      collegeId: collegeId ?? this.collegeId,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      assignmentStatus: assignmentStatus ?? this.assignmentStatus,
      delay: delay ?? this.delay,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class BusLocationModel {
  final String busId;
  final LatLng currentLocation;
  final DateTime timestamp;
  final double? speed;
  final double? heading;
  final String? collegeId;

  BusLocationModel({
    required this.busId,
    required this.currentLocation,
    required this.timestamp,
    this.speed,
    this.heading,
    this.collegeId,
  });

  factory BusLocationModel.fromMap(Map<String, dynamic> map, String busId) {
    final locData = map['currentLocation'] ?? map['location'];
    return BusLocationModel(
      busId: busId,
      currentLocation: LatLng(
        locData?['lat']?.toDouble() ?? 0.0,
        locData?['lng']?.toDouble() ?? 0.0,
      ),
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
      speed: map['speed']?.toDouble(),
      heading: map['heading']?.toDouble(),
      collegeId: map['collegeId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currentLocation': {
        'lat': currentLocation.latitude,
        'lng': currentLocation.longitude,
      },
      'timestamp': timestamp.toIso8601String(),
      'speed': speed,
      'heading': heading,
      'collegeId': collegeId,
    };
  }
}
