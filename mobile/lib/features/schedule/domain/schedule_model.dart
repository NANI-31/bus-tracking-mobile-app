import 'package:collegebus/core/utils/type_converters.dart';

class ScheduleModel {
  final String id;
  final String routeId;
  final String busId;
  final String shift; // '1st' or '2nd'
  final String tripType; // 'pickup' or 'drop'
  final List<StopSchedule> stopSchedules;
  final String collegeId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  ScheduleModel({
    required this.id,
    required this.routeId,
    required this.busId,
    required this.shift,
    required this.tripType,
    required this.stopSchedules,
    required this.collegeId,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  factory ScheduleModel.fromMap(Map<String, dynamic> map, String id) {
    return ScheduleModel(
      id: id,
      routeId: map['routeId'] as String? ?? '',
      busId: map['busId'] as String? ?? '',
      shift: map['shift'] as String? ?? '1st',
      tripType: map['tripType'] as String? ?? 'pickup',
      // Defensive: item may arrive as Map<String, dynamic> or LinkedMap —
      // cast explicitly to avoid ClassCastException.
      stopSchedules:
          (map['stopSchedules'] as List<dynamic>?)
              ?.map((item) => StopSchedule.fromMap(
                    Map<String, dynamic>.from(item as Map),
                  ))
              .toList() ??
          [],
      collegeId: map['collegeId'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
      // Use parseDateTime to safely handle null / malformed date strings
      // instead of raw DateTime.parse() which throws on null.
      createdAt: parseDateTime(map['createdAt']),
      updatedAt: map['updatedAt'] != null
          ? parseDateTime(map['updatedAt'])
          : null,
      isActive: parseBool(map['isActive'], true),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'routeId': routeId,
      'busId': busId,
      'shift': shift,
      'tripType': tripType,
      'stopSchedules': stopSchedules
          .map((schedule) => schedule.toMap())
          .toList(),
      'collegeId': collegeId,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  ScheduleModel copyWith({
    String? id,
    String? routeId,
    String? busId,
    String? shift,
    String? tripType,
    List<StopSchedule>? stopSchedules,
    String? collegeId,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      busId: busId ?? this.busId,
      shift: shift ?? this.shift,
      tripType: tripType ?? this.tripType,
      stopSchedules: stopSchedules ?? this.stopSchedules,
      collegeId: collegeId ?? this.collegeId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

class StopSchedule {
  final String stopName;
  final String arrivalTime; // Format: "HH:mm"
  final String departureTime; // Format: "HH:mm"

  StopSchedule({
    required this.stopName,
    required this.arrivalTime,
    required this.departureTime,
  });

  factory StopSchedule.fromMap(Map<String, dynamic> map) {
    return StopSchedule(
      stopName: map['stopName'] ?? '',
      arrivalTime: map['arrivalTime'] ?? '',
      departureTime: map['departureTime'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stopName': stopName,
      'arrivalTime': arrivalTime,
      'departureTime': departureTime,
    };
  }

  StopSchedule copyWith({
    String? stopName,
    String? arrivalTime,
    String? departureTime,
  }) {
    return StopSchedule(
      stopName: stopName ?? this.stopName,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      departureTime: departureTime ?? this.departureTime,
    );
  }
}

