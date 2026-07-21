import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:collegebus/core/utils/type_converters.dart';

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
  final int? capacity;
  final String? shiftId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  final String? trackingTeacherId;
  /// Active trip direction chosen by the coordinator at assignment time.
  /// 'pickup' = normal stop order (A → stops → B).
  /// 'drop'   = reversed stop order (B → stops → A).
  /// Null means unset — treated as 'pickup' everywhere.
  final String? tripType;

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
    this.capacity,
    this.shiftId,
    this.trackingTeacherId,
    this.tripType,
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
      isActive: parseBool(map['isActive'], true),
      status: map['status'] ?? 'on-time',
      assignmentStatus: map['assignmentStatus'] ?? 'unassigned',
      // delay may arrive as double (e.g. 0.0) from some API versions;
      // cast via num to avoid TypeError.
      delay: (map['delay'] as num?)?.toInt() ?? 0,
      capacity: map['capacity'],
      shiftId: map['shiftId'],
      trackingTeacherId: map['trackingTeacherId'],
      tripType: map['tripType'] as String?,
      createdAt: parseDateTime(map['createdAt']),
      updatedAt: map['updatedAt'] != null
          ? parseDateTime(map['updatedAt'])
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
      'capacity': capacity,
      'shiftId': shiftId,
      'trackingTeacherId': trackingTeacherId,
      if (tripType != null) 'tripType': tripType,
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
    int? capacity,
    String? shiftId,
    String? trackingTeacherId,
    String? tripType,
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
      capacity: capacity ?? this.capacity,
      shiftId: shiftId ?? this.shiftId,
      trackingTeacherId: trackingTeacherId ?? this.trackingTeacherId,
      tripType: tripType ?? this.tripType,
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
  /// Driver-computed ETA to the nearest stop (whole minutes).
  /// Populated only while the driver is actively sharing location.
  final int? etaMinutes;

  BusLocationModel({
    required this.busId,
    required this.currentLocation,
    required this.timestamp,
    this.speed,
    this.heading,
    this.collegeId,
    this.etaMinutes,
  });

  factory BusLocationModel.fromMap(Map<String, dynamic> map, String busId) {
    final locData = map['currentLocation'] ?? map['location'];
    return BusLocationModel(
      busId: busId,
      currentLocation: LatLng(
        locData?['lat']?.toDouble() ?? 0.0,
        locData?['lng']?.toDouble() ?? 0.0,
      ),
      // Use parseDateTime for safe null/malformed handling
      timestamp: parseDateTime(map['timestamp']),
      speed: map['speed']?.toDouble(),
      heading: map['heading']?.toDouble(),
      collegeId: map['collegeId'],
      etaMinutes: map['etaMinutes']?.toInt(),
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
      if (etaMinutes != null) 'etaMinutes': etaMinutes,
    };
  }
}
