import 'package:collegebus/models/bus_model.dart';

/// Model representing a single history log entry for a driver
class HistoryLogModel {
  final String id;
  final String? busId;
  final String? driverId;
  final String eventType;
  final String description;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;
  final BusModel? bus; // Populated from backend

  HistoryLogModel({
    required this.id,
    this.busId,
    this.driverId,
    required this.eventType,
    required this.description,
    this.metadata,
    required this.timestamp,
    this.bus,
  });

  factory HistoryLogModel.fromMap(Map<String, dynamic> map) {
    return HistoryLogModel(
      id: map['_id'] ?? map['id'] ?? '',
      busId: map['busId'] is String ? map['busId'] : map['busId']?['_id'],
      driverId: map['driverId'] is String
          ? map['driverId']
          : map['driverId']?['_id'],
      eventType: map['eventType'] ?? '',
      description: map['description'] ?? '',
      metadata: map['metadata'] as Map<String, dynamic>?,
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
      bus: map['busId'] is Map
          ? BusModel.fromMap(map['busId'], map['busId']['_id'] ?? '')
          : null,
    );
  }

  /// Returns a human-readable title based on the event type
  String get title {
    switch (eventType) {
      case 'trip_started':
        return 'Trip Started';
      case 'trip_completed':
        return 'Trip Completed';
      case 'assignment_update':
        return 'Bus Assignment';
      case 'incident_report':
        return 'Incident Reported';
      case 'sos_alert':
        return 'SOS Alert';
      case 'approval':
        return 'Account Approved';
      case 'shift_ended':
        return 'Shift Ended';
      default:
        return eventType.replaceAll('_', ' ').toUpperCase();
    }
  }

  /// Returns the icon type for UI display
  String get iconType {
    switch (eventType) {
      case 'trip_completed':
      case 'approval':
        return 'success';
      case 'assignment_update':
        return 'warning';
      case 'sos_alert':
      case 'incident_report':
        return 'error';
      default:
        return 'info';
    }
  }
}
