// route_math_utils.dart
//
// Shared geometry helpers used by the driver and teacher live-tracking
// screens for polyline proximity and ETA calculations.
// Extracted from DriverDashboard and TeacherDashboard to avoid duplication.

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Returns the shortest distance in metres from point [p] to the line
/// segment defined by [start] and [end].
double distanceToSegment(LatLng p, LatLng start, LatLng end) {
  final double x = p.latitude;
  final double y = p.longitude;
  final double x1 = start.latitude;
  final double y1 = start.longitude;
  final double x2 = end.latitude;
  final double y2 = end.longitude;

  final double A = x - x1;
  final double B = y - y1;
  final double C = x2 - x1;
  final double D = y2 - y1;

  final double dot = A * C + B * D;
  final double lenSq = C * C + D * D;
  double param = -1;
  if (lenSq != 0) {
    param = dot / lenSq;
  }

  double xx, yy;

  if (param < 0) {
    xx = x1;
    yy = y1;
  } else if (param > 1) {
    xx = x2;
    yy = y2;
  } else {
    xx = x1 + param * C;
    yy = y1 + param * D;
  }

  return Geolocator.distanceBetween(x, y, xx, yy);
}

/// Returns the index of the point in [points] that is closest to [target].
int findClosestPointIndex(LatLng target, List<LatLng> points) {
  if (points.isEmpty) return 0;
  int closestIdx = 0;
  double minDistance = double.infinity;
  for (int i = 0; i < points.length; i++) {
    final p = points[i];
    final dist = Geolocator.distanceBetween(
      target.latitude,
      target.longitude,
      p.latitude,
      p.longitude,
    );
    if (dist < minDistance) {
      minDistance = dist;
      closestIdx = i;
    }
  }
  return closestIdx;
}
