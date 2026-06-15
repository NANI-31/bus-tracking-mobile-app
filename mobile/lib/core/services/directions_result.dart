import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Represents a single leg of a directions route (between two waypoints).
class LegInfo {
  final String startAddress;
  final String endAddress;
  final double distanceKm;
  final int durationMin;

  const LegInfo({
    required this.startAddress,
    required this.endAddress,
    required this.distanceKm,
    required this.durationMin,
  });

  factory LegInfo.fromMap(Map<String, dynamic> map) {
    return LegInfo(
      startAddress: map['startAddress'] ?? '',
      endAddress: map['endAddress'] ?? '',
      distanceKm: (map['distanceKm'] ?? 0.0).toDouble(),
      durationMin: (map['durationMin'] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'startAddress': startAddress,
      'endAddress': endAddress,
      'distanceKm': distanceKm,
      'durationMin': durationMin,
    };
  }

  @override
  String toString() =>
      'LegInfo($startAddress → $endAddress, ${distanceKm}km, ${durationMin}min)';
}

/// The result of a directions API call — contains the decoded polyline,
/// total distance/duration, and per-leg breakdowns.
class DirectionsResult {
  /// The full list of LatLng points that form the route polyline.
  final List<LatLng> polylinePoints;

  /// Total distance of the entire route in kilometers.
  final double totalDistanceKm;

  /// Total estimated duration of the entire route in minutes.
  final int totalDurationMin;

  /// Per-leg breakdown (e.g., Start → Stop1, Stop1 → Stop2, ..., StopN → End).
  final List<LegInfo> legs;

  const DirectionsResult({
    required this.polylinePoints,
    required this.totalDistanceKm,
    required this.totalDurationMin,
    required this.legs,
  });

  factory DirectionsResult.fromMap(Map<String, dynamic> map) {
    final rawPoints = map['polylinePoints'] as List<dynamic>? ?? [];
    final points = rawPoints.map((p) {
      final lat = (p['latitude'] ?? p['lat'] ?? 0.0).toDouble();
      final lng = (p['longitude'] ?? p['lng'] ?? 0.0).toDouble();
      return LatLng(lat, lng);
    }).toList();

    final rawLegs = map['legs'] as List<dynamic>? ?? [];
    final legsList = rawLegs
        .map((l) => LegInfo.fromMap(Map<String, dynamic>.from(l)))
        .toList();

    return DirectionsResult(
      polylinePoints: points,
      totalDistanceKm: (map['totalDistanceKm'] ?? 0.0).toDouble(),
      totalDurationMin: (map['totalDurationMin'] ?? 0).toInt(),
      legs: legsList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'polylinePoints': polylinePoints
          .map((p) => {'latitude': p.latitude, 'longitude': p.longitude})
          .toList(),
      'totalDistanceKm': totalDistanceKm,
      'totalDurationMin': totalDurationMin,
      'legs': legs.map((l) => l.toMap()).toList(),
    };
  }

  /// Returns true if this result has valid polyline data.
  bool get hasRoute => polylinePoints.isNotEmpty;

  @override
  String toString() =>
      'DirectionsResult(${polylinePoints.length} points, ${totalDistanceKm}km, ${totalDurationMin}min, ${legs.length} legs)';
}
