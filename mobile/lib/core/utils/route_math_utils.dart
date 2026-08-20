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

/// Trims [points] so the polyline starts exactly at the bus position.
///
/// For each consecutive segment (i, i+1), computes the perpendicular
/// projection of [busPos] onto the segment. Picks the segment with the
/// smallest perpendicular distance, then returns:
///   [projectedFoot, points[i+1], points[i+2], ..., points.last]
///
/// This guarantees the remaining-route line always starts precisely at the
/// bus — not at the nearest discrete route point, which can be tens of
/// metres ahead of or behind the actual position on a long segment.
///
/// Falls back to a simple [sublist] from the nearest-point index when there
/// are fewer than 2 points.
List<LatLng> trimPolylineAtBus(LatLng busPos, List<LatLng> points) {
  if (points.length < 2) return points;

  int bestSegmentIdx = 0;
  double bestDist = double.infinity;

  for (int i = 0; i < points.length - 1; i++) {
    final d = distanceToSegment(busPos, points[i], points[i + 1]);
    if (d < bestDist) {
      bestDist = d;
      bestSegmentIdx = i;
    }
  }

  // Compute the perpendicular foot on the best segment.
  final LatLng segStart = points[bestSegmentIdx];
  final LatLng segEnd = points[bestSegmentIdx + 1];

  final double ax = busPos.latitude - segStart.latitude;
  final double ay = busPos.longitude - segStart.longitude;
  final double bx = segEnd.latitude - segStart.latitude;
  final double by = segEnd.longitude - segStart.longitude;
  final double lenSq = bx * bx + by * by;

  final LatLng projectedFoot;
  if (lenSq == 0) {
    projectedFoot = segStart;
  } else {
    final double t = ((ax * bx + ay * by) / lenSq).clamp(0.0, 1.0);
    projectedFoot = LatLng(
      segStart.latitude + t * bx,
      segStart.longitude + t * by,
    );
  }

  // Build the trimmed list: [foot, segEnd, rest...]
  final trimmed = <LatLng>[projectedFoot];
  for (int i = bestSegmentIdx + 1; i < points.length; i++) {
    trimmed.add(points[i]);
  }
  return trimmed;
}

/// Computes the road distance in kilometres by summing individual segment
/// lengths between polyline indices [fromIdx] (inclusive) and [toIdx]
/// (exclusive). If [fromIdx] >= [toIdx] or the list is too short, returns 0.
///
/// Use this for accurate remaining-distance computation instead of
/// Geolocator.distanceBetween() (crow-fly), which underestimates on winding
/// roads by 30–50 % on typical Indian bus routes.
double polylineRoadDistanceKm(
  List<LatLng> polyline,
  int fromIdx,
  int toIdx,
) {
  if (polyline.length < 2) return 0.0;
  final start = fromIdx.clamp(0, polyline.length - 1);
  final end = toIdx.clamp(0, polyline.length);
  if (start >= end - 1) return 0.0;

  double totalMetres = 0.0;
  for (int i = start; i < end - 1; i++) {
    totalMetres += Geolocator.distanceBetween(
      polyline[i].latitude,
      polyline[i].longitude,
      polyline[i + 1].latitude,
      polyline[i + 1].longitude,
    );
  }
  return totalMetres / 1000.0;
}

/// Finds the minimum perpendicular distance (metres) from [point] to any
/// segment of the full dense [polyline].
///
/// Used by off-route detection: checking against the full polyline (hundreds
/// of points) rather than just the sparse stop waypoints (3–8 points)
/// prevents false off-route alerts on winding roads where the straight-line
/// between two stops passes far from the actual road path.
double minDistanceToPolyline(LatLng point, List<LatLng> polyline) {
  if (polyline.isEmpty) return double.infinity;
  if (polyline.length == 1) {
    return Geolocator.distanceBetween(
      point.latitude,
      point.longitude,
      polyline[0].latitude,
      polyline[0].longitude,
    );
  }
  double minDist = double.infinity;
  for (int i = 0; i < polyline.length - 1; i++) {
    final d = distanceToSegment(point, polyline[i], polyline[i + 1]);
    if (d < minDist) minDist = d;
  }
  return minDist;
}
