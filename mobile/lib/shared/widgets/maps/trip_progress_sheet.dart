import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:collegebus/features/route/domain/route_model.dart';
import 'package:collegebus/core/services/directions_result.dart';
import 'package:collegebus/core/services/persistence_service.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/shared/widgets/navigation/curved_bottom_nav_bar.dart';

/// Ola/Uber-style trip progress bottom sheet showing route stops,
/// ETA, distance, and real-time bus progress along the route.
class TripProgressSheet extends StatelessWidget {
  final RouteModel route;
  final DirectionsResult? directionsResult;
  final LatLng? busLocation;
  final String busNumber;
  final String? preferredStop;
  final String? tripType;

  const TripProgressSheet({
    super.key,
    required this.route,
    required this.directionsResult,
    required this.busLocation,
    required this.busNumber,
    this.preferredStop,
    this.tripType,
  });

  @override
  Widget build(BuildContext context) {

    final allStops = _buildStopList();
    final completedIndex = _getCompletedStopIndex(allStops);
    final etaToPreferred = _getETAToPreferredStop(allStops);
    final totalDistance = directionsResult?.totalDistanceKm ?? 0;

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        PersistenceService.setDouble('sheet_extent', notification.extent);
        return true;
      },
      child: DraggableScrollableSheet(
        initialChildSize: (PersistenceService.getDouble('sheet_extent') ?? 0.18)
            .clamp(0.12, 0.55),
        minChildSize: 0.12,
        maxChildSize: 0.55,
        snap: true,
        snapSizes: const [0.18, 0.55],
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: ListView.builder(
              controller: scrollController,
              padding: EdgeInsets.zero,
              itemCount: 5 + allStops.length,
              itemBuilder: (context, index) {
                if (index == 0) {
                  // Drag handle
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                } else if (index == 1) {
                  // Collapsed Header
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        // Bus icon
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.turkishBlue.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.directions_bus_filled_rounded,
                            color: AppColors.turkishBlue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Bus info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Row(
                                  children: [
                                    Text(
                                      'Bus $busNumber',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (tripType == 'pickup' || tripType == 'drop') ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: (tripType == 'drop'
                                                  ? const Color(0xFF10B981)
                                                  : const Color(0xFF6366F1))
                                              .withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: (tripType == 'drop'
                                                    ? const Color(0xFF10B981)
                                                    : const Color(0xFF6366F1))
                                                .withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              tripType == 'drop'
                                                  ? Icons.arrow_downward_rounded
                                                  : Icons.arrow_upward_rounded,
                                              size: 11,
                                              color: tripType == 'drop'
                                                  ? const Color(0xFF10B981)
                                                  : const Color(0xFF6366F1),
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              tripType == 'drop' ? 'DROP' : 'PICKUP',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.5,
                                                color: tripType == 'drop'
                                                    ? const Color(0xFF10B981)
                                                    : const Color(0xFF6366F1),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),

                              Text(
                                completedIndex < allStops.length - 1
                                    ? 'Heading to ${allStops[completedIndex + 1].name}'
                                    : 'Trip Completed',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // ETA & Distance
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (etaToPreferred != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${etaToPreferred}min',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.success,
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.turkishBlue.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${directionsResult?.totalDurationMin ?? "—"}min',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.turkishBlue,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              '${totalDistance.toStringAsFixed(1)} km',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                } else if (index == 2) {
                  // Divider
                  return const Divider(height: 1);
                } else if (index == 3) {
                  // Route: Name
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.route_rounded,
                          size: 16,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Route: ${route.routeName}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (index < 4 + allStops.length) {
                  final stopIndex = index - 4;
                  final stop = allStops[stopIndex];
                  final isCompleted = stopIndex <= completedIndex;
                  final isCurrent = stopIndex == completedIndex + 1;
                  final isPreferred = stop.name == preferredStop;
                  final isFirst = stopIndex == 0;
                  final isLast = stopIndex == allStops.length - 1;

                  return _buildTimelineItem(
                    context: context,
                    stopName: stop.name,
                    isCompleted: isCompleted,
                    isCurrent: isCurrent,
                    isPreferred: isPreferred,
                    isFirst: isFirst,
                    isLast: isLast,
                    legInfo: stopIndex < (directionsResult?.legs.length ?? 0)
                        ? directionsResult!.legs[stopIndex]
                        : null,
                  );
                } else {
                  return const BottomNavSpacer();
                }
              },
            ),
          );
        },
      ),
    );
  }

  /// Build the ordered list of all stops (start + intermediates + end) based on trip direction.
  List<RoutePoint> _buildStopList() {
    final ordered = route.getOrderedStops(tripType);
    if (ordered.isEmpty) return [];

    final firstPt = ordered.first;
    final lastPt = ordered.last;

    final firstPtName = firstPt.name.trim().toLowerCase();
    final lastPtName = lastPt.name.trim().toLowerCase();

    final middleStops = ordered.sublist(1, ordered.length - 1);

    // Filter out intermediate stops that match first or last coordinates/name
    final filteredStops = middleStops.where((stop) {
      final name = stop.name.trim().toLowerCase();
      final isAtStart =
          (stop.lat - firstPt.lat).abs() < 0.00001 &&
          (stop.lng - firstPt.lng).abs() < 0.00001;
      final isAtEnd =
          (stop.lat - lastPt.lat).abs() < 0.00001 &&
          (stop.lng - lastPt.lng).abs() < 0.00001;
      final isSameNameStart = firstPtName.isNotEmpty && name == firstPtName;
      final isSameNameEnd = lastPtName.isNotEmpty && name == lastPtName;

      return !(isAtStart || isAtEnd || isSameNameStart || isSameNameEnd);
    }).toList();

    return [firstPt, ...filteredStops, lastPt];
  }


  /// Determine which stop the bus has most recently passed.
  /// Returns -1 if the bus hasn't passed any stop yet.
  int _getCompletedStopIndex(List<RoutePoint> stops) {
    if (busLocation == null) return -1;

    final rawPoints = directionsResult?.polylinePoints ?? [];
    if (rawPoints.isEmpty) {
      // Fallback: simple proximity check when no polyline is available.
      // Only mark consecutive stops in order — if stop[i] is within threshold
      // AND stop[i-1] was already passed, mark stop[i] as passed.
      // This prevents the bus being near stop[2] from marking stop[1] as done
      // before the bus ever reaches stop[1].
      int lastPassedIndex = -1;
      const double proximityThresholdMeters = 30;
      for (int i = 0; i < stops.length; i++) {
        // Only consider this stop if the previous stop was already passed
        // (or this is the first stop, which has no predecessor).
        if (i > 0 && lastPassedIndex < i - 1) break;

        final stop = stops[i];
        if (stop.lat == 0 && stop.lng == 0) continue;
        final distance = Geolocator.distanceBetween(
          busLocation!.latitude,
          busLocation!.longitude,
          stop.lat,
          stop.lng,
        );
        if (distance < proximityThresholdMeters) {
          lastPassedIndex = i;
        }
      }
      return lastPassedIndex;
    }

    // For drop trips, the polyline from DirectionsService is always in
    // pickup order (stops→college). Since getOrderedStops('drop') returns
    // college first (index 0 in ordered stops), we reverse the polyline so
    // that polyline indices and stop ordering are aligned in the same direction.
    final points = tripType == 'drop'
        ? rawPoints.reversed.toList()
        : rawPoints;

    // 1. Check if the bus is on-route (within 300m of the polyline)
    double minTrackDistance = double.infinity;
    int closestPolylineIndex = -1;

    for (int i = 0; i < points.length; i++) {
      final dist = Geolocator.distanceBetween(
        busLocation!.latitude,
        busLocation!.longitude,
        points[i].latitude,
        points[i].longitude,
      );
      if (dist < minTrackDistance) {
        minTrackDistance = dist;
        closestPolylineIndex = i;
      }
    }

    // If the bus is far from the route path (e.g. at the garage or driving to the start),
    // do not mark any stops as completed.
    if (minTrackDistance > 300) {
      return -1;
    }

    // 2. Find the last stop passed based on polyline progression.
    //
    // A stop is considered "passed" ONLY when the bus's current closest
    // polyline index is STRICTLY GREATER than the stop's mapped polyline
    // index by a meaningful margin (kPassedBuffer points).
    //
    // Why a buffer?
    //   - When the bus is at exactly the same polyline index as the stop it
    //     is *approaching*, not yet past it.
    //   - A small buffer (3 points ≈ ~15–30 m on a typical Google Maps
    //     polyline) prevents premature completion while remaining responsive.
    //
    // Proximity alone (distanceToStop < N) is intentionally NOT used here
    // because it caused stops to be marked "passed" before the bus arrived.
    const int kPassedBuffer = 3;

    int lastPassedIndex = -1;
    for (int i = 0; i < stops.length; i++) {
      final stop = stops[i];
      if (stop.lat == 0 && stop.lng == 0) continue;

      // Find the polyline point closest to this stop.
      double minStopDist = double.infinity;
      int stopPolyIndex = -1;
      for (int j = 0; j < points.length; j++) {
        final dist = Geolocator.distanceBetween(
          stop.lat,
          stop.lng,
          points[j].latitude,
          points[j].longitude,
        );
        if (dist < minStopDist) {
          minStopDist = dist;
          stopPolyIndex = j;
        }
      }

      // The bus must have moved kPassedBuffer or more polyline indices past
      // the stop before we consider it completed.
      if (closestPolylineIndex > stopPolyIndex + kPassedBuffer) {
        lastPassedIndex = i;
      }
    }

    return lastPassedIndex;
  }

  /// Get ETA to the user's preferred stop (if set and in route).

  int? _getETAToPreferredStop(List<RoutePoint> stops) {
    if (preferredStop == null ||
        directionsResult == null ||
        directionsResult!.legs.isEmpty) {
      return null;
    }

    final preferredIndex = stops.indexWhere((s) => s.name == preferredStop);
    if (preferredIndex < 0) return null;

    final completedIndex = _getCompletedStopIndex(stops);
    if (completedIndex >= preferredIndex) return 0; // Already passed

    final isDrop = tripType == 'drop';
    int etaMin = 0;

    if (!isDrop) {
      // Pickup trip: legs[i] corresponds to leg from stops[i] to stops[i+1]
      final startLeg = (completedIndex + 1).clamp(
        0,
        directionsResult!.legs.length,
      );
      final endLeg = preferredIndex.clamp(0, directionsResult!.legs.length);

      for (int i = startLeg; i < endLeg; i++) {
        etaMin += directionsResult!.legs[i].durationMin;
      }
    } else {
      // Drop trip: stops array is reversed [endPoint, ..., startPoint].
      // Pickup legs array goes [startPoint -> ... -> endPoint].
      // Map reversed stop indices to pickup legs indices.
      final n = stops.length;
      final pickupCompletedIdx = n - 1 - completedIndex;
      final pickupPreferredIdx = n - 1 - preferredIndex;

      final startLeg = pickupPreferredIdx.clamp(
        0,
        directionsResult!.legs.length,
      );
      final endLeg = pickupCompletedIdx.clamp(
        0,
        directionsResult!.legs.length,
      );

      for (int i = startLeg; i < endLeg; i++) {
        etaMin += directionsResult!.legs[i].durationMin;
      }
    }

    return etaMin > 0 ? etaMin : null;
  }


  Widget _buildTimelineItem({
    required BuildContext context,
    required String stopName,
    required bool isCompleted,
    required bool isCurrent,
    required bool isPreferred,
    required bool isFirst,
    required bool isLast,
    LegInfo? legInfo,
  }) {
    // Colors
    final completedColor = AppColors.success;
    final currentColor = AppColors.turkishBlue;
    final upcomingColor = Colors.grey.shade300;
    final preferredColor = AppColors.amberAccent;

    Color dotColor;
    Color lineColor;
    if (isCompleted) {
      dotColor = completedColor;
      lineColor = completedColor;
    } else if (isCurrent) {
      dotColor = currentColor;
      lineColor = upcomingColor;
    } else {
      dotColor = upcomingColor;
      lineColor = upcomingColor;
    }

    if (isPreferred && !isCompleted) {
      dotColor = preferredColor;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline column
          SizedBox(
            width: 50,
            child: Column(
              children: [
                // Top line
                if (!isFirst)
                  Expanded(child: Container(width: 2.5, color: lineColor)),
                // Dot
                Container(
                  width: isCurrent || isPreferred ? 18 : 14,
                  height: isCurrent || isPreferred ? 18 : 14,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? dotColor
                        : dotColor.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                    border: Border.all(color: dotColor, width: 2.5),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: currentColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 10, color: Colors.white)
                      : null,
                ),
                // Bottom line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2.5,
                      color: isCompleted ? completedColor : upcomingColor,
                    ),
                  ),
              ],
            ),
          ),

          // Content column
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          stopName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isCurrent || isPreferred
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isCompleted
                                ? Colors.grey
                                : Theme.of(context).colorScheme.onSurface,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      if (isPreferred && !isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: preferredColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'YOUR STOP',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.amberAccent,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (legInfo != null && !isLast)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${legInfo.distanceKm.toStringAsFixed(1)} km · ${legInfo.durationMin} min',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                  if (isFirst)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Start',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  if (isLast)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Destination',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.danger.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
