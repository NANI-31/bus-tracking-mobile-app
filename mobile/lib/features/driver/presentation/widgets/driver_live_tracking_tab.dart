// driver_live_tracking_tab.dart
//
// Extracted from driver_dashboard.dart.
// Renders the "Live Tracking" tab content — the Google Map with the bus
// marker, route polylines, stop markers, an ETA card, and the
// LiveTrackingControlPanel. The deviation toast is still owned by the
// parent dashboard state because it uses an OverlayEntry that lives above
// the tab stack; only the display data is passed down here.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:velocity_x/velocity_x.dart';

import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/core/services/directions_result.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/features/driver/application/driver_location_provider.dart';
import 'package:collegebus/features/driver/application/driver_map_provider.dart';
import 'package:collegebus/features/route/domain/route_model.dart';
import 'package:collegebus/core/utils/route_math_utils.dart';
import 'package:collegebus/shared/widgets/sos_button.dart';
import 'package:collegebus/widgets/common/common_map_view.dart';
import 'package:collegebus/shared/widgets/global_connectivity_banner.dart';
import 'live_tracking_control_panel.dart';
import 'voice_message_button.dart';

class DriverLiveTrackingTab extends ConsumerWidget {
  const DriverLiveTrackingTab({
    super.key,
    required this.myBus,
    required this.busIcon,
    required this.startStopIcon,
    required this.intermediateStopIcon,
    required this.endStopIcon,
    required this.onToggleSharing,
    required this.onCompleteTrip,
  });

  final BusModel? myBus;
  final BitmapDescriptor? busIcon;
  final BitmapDescriptor? startStopIcon;
  final BitmapDescriptor? intermediateStopIcon;
  final BitmapDescriptor? endStopIcon;
  final VoidCallback onToggleSharing;
  final VoidCallback onCompleteTrip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        Column(
          children: [
            Consumer(
              builder: (context, ref, child) {
                final currentLocation = ref.watch(
                  driverLocationProvider.select((s) => s.currentLocation),
                );
                final heading = ref.watch(
                  driverLocationProvider.select((s) => s.heading),
                );
                final mapState = ref.watch(driverMapStateProvider);
                final route = mapState.selectedRoute;
                final result = mapState.directionsResult;

                final mapTheme =
                    Theme.of(context).extension<MapThemeExtension>();
                final routeColorTheme =
                    mapTheme?.routeColor ?? const Color(0xFF1565C0);

                final stopMarkers = _buildStopMarkers(route, myBus?.tripType);

                final polylines =
                    _buildPolylines(result, currentLocation, routeColorTheme, myBus?.tripType);


                final mapMarkers = {...stopMarkers};
                if (currentLocation != null) {
                  mapMarkers.add(
                    Marker(
                      markerId: const MarkerId('driver_bus'),
                      position: currentLocation,
                      icon: busIcon ?? BitmapDescriptor.defaultMarker,
                      rotation: heading,
                      anchor: const Offset(0.5, 0.2),
                      flat: true,
                      zIndexInt: 2,
                    ),
                  );
                }

                return CommonMapView(
                  currentLocation: currentLocation,
                  markers: mapMarkers,
                  polylines: polylines,
                  onMapCreated: (controller) {},
                  initialZoom: 17.0,
                );
              },
            ).expand(),

            Consumer(
              builder: (context, ref, child) {
                final currentLocation = ref.watch(
                  driverLocationProvider.select((s) => s.currentLocation),
                );
                final isSharing = ref.watch(
                  driverLocationProvider.select((s) => s.isSharing),
                );
                final selectedRoute = ref.watch(
                  driverMapStateProvider.select((s) => s.selectedRoute),
                );

                return LiveTrackingControlPanel(
                  bus: myBus,
                  route: selectedRoute,
                  isSharing: isSharing,
                  currentLocation: currentLocation,
                  onToggleSharing: onToggleSharing,
                  onCompleteTrip: onCompleteTrip,
                );
              },
            ),
          ],
        ),

        // Next-stop ETA card (navigation style — top of map above SOS button)
        Consumer(
          builder: (context, ref, child) {
            final currentLocation = ref.watch(
              driverLocationProvider.select((s) => s.currentLocation),
            );
            final nextStopETA = ref.watch(
              driverLocationProvider.select((s) => s.nextStopETA),
            );
            final isSharing = ref.watch(
              driverLocationProvider.select((s) => s.isSharing),
            );
            final mapState = ref.watch(driverMapStateProvider);
            final selectedRoute = mapState.selectedRoute;
            final result = mapState.directionsResult;

            if (!isSharing || selectedRoute == null) {
              return const SizedBox.shrink();
            }

            String? directionsETA;
            if (result != null && currentLocation != null) {
              directionsETA = _computeNextStopETAFromDirections(
                currentLocation,
                selectedRoute,
                result,
                myBus?.tripType,
              );
            }

            final displayETA =
                directionsETA ??
                (nextStopETA != null ? 'ETA: $nextStopETA' : null);
            if (displayETA == null) return const SizedBox.shrink();

            // Compute remaining road distance by walking polyline from
            // driver's nearest point index to the end.
            String distLabel = '';
            if (result != null && currentLocation != null) {
              final poly = result.polylinePoints;
              final driverIdx = findClosestPointIndex(currentLocation, poly);
              final remainKm = polylineRoadDistanceKm(
                poly,
                driverIdx,
                poly.length,
              );
              final totalKm = result.totalDistanceKm;
              if (remainKm > 0) {
                distLabel =
                    '${remainKm.toStringAsFixed(1)} / ${totalKm.toStringAsFixed(1)} km';
              } else {
                distLabel = '${totalKm.toStringAsFixed(1)} km';
              }
            } else if (result != null) {
              distLabel = '${result.totalDistanceKm.toStringAsFixed(1)} km';
            }

            return Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.turkishBlue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.navigation_rounded,
                        color: AppColors.turkishBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        displayETA,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (distLabel.isNotEmpty)
                      Text(
                        distLabel,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),

        // ── Teacher Override Active Banner ────────────────────────────────
        // Shown when coordinator has approved a teacher override and the
        // driver's GPS emission is paused. Sits above the control panel
        // so it is always visible without covering the map.
        Consumer(
          builder: (context, ref, child) {
            final isOverridePaused = ref.watch(
              driverLocationProvider.select((s) => s.isOverridePaused),
            );
            if (!isOverridePaused) return const SizedBox.shrink();

            final isDark = Theme.of(context).brightness == Brightness.dark;
            final statusTokens = context.appStatus;

            return Positioned(
              left: 16,
              right: 16,
              bottom: 140,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.75)
                      : Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: statusTokens.delayColor.withValues(alpha: 0.70),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: statusTokens.delayColor.withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusTokens.delayColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.pause_circle_filled_rounded,
                        color: statusTokens.delayColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Location Sharing Paused',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1A1A2E),
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Teacher override is active. Contact coordinator to resume.',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.65)
                                  : Colors.black.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // Off-Route Notification Banner — scoped strictly to Map Tab view only
        Consumer(
          builder: (context, ref, child) {
            final offRouteDistance = ref.watch(
              driverLocationProvider.select((s) => s.offRouteDistance),
            );
            final isSharing = ref.watch(
              driverLocationProvider.select((s) => s.isSharing),
            );
            final isOverridePaused = ref.watch(
              driverLocationProvider.select((s) => s.isOverridePaused),
            );
            // Hide off-route banner during override — driver is not emitting GPS
            if (!isSharing || offRouteDistance == null || isOverridePaused) {
              return const SizedBox.shrink();
            }

            final currentLocation = ref.watch(
              driverLocationProvider.select((s) => s.currentLocation),
            );
            final nextStopETA = ref.watch(
              driverLocationProvider.select((s) => s.nextStopETA),
            );
            final mapState = ref.watch(driverMapStateProvider);
            final selectedRoute = mapState.selectedRoute;
            final result = mapState.directionsResult;

            String? directionsETA;
            if (result != null && currentLocation != null && selectedRoute != null) {
              directionsETA = _computeNextStopETAFromDirections(
                currentLocation,
                selectedRoute,
                result,
                myBus?.tripType,
              );
            }
            final hasETA = (directionsETA ?? (nextStopETA != null ? 'ETA: $nextStopETA' : null)) != null;
            final topOffset = MediaQuery.of(context).padding.top + (hasETA ? 80 : 12);

            // Use appStatus token for off-route banner color so it respects
            // dark / light mode theming instead of hardcoded orange shade.
            return Positioned(
              top: topOffset,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: context.appStatus.offRouteColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Off route • ${offRouteDistance}m from path',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // SOS & Voice Message Buttons (positioned below ETA card if present)

        Consumer(
          builder: (context, ref, child) {
            final isSharing = ref.watch(
              driverLocationProvider.select((s) => s.isSharing),
            );
            final selectedRoute = ref.watch(
              driverMapStateProvider.select((s) => s.selectedRoute),
            );
            final currentLocation = ref.watch(
              driverLocationProvider.select((s) => s.currentLocation),
            );
            final result = ref.watch(
              driverMapStateProvider.select((s) => s.directionsResult),
            );
            final nextStopETA = ref.watch(
              driverLocationProvider.select((s) => s.nextStopETA),
            );

            bool hasETA = false;
            if (isSharing && selectedRoute != null) {
              String? directionsETA;
              if (result != null && currentLocation != null) {
                directionsETA = _computeNextStopETAFromDirections(
                  currentLocation,
                  selectedRoute,
                  result,
                  myBus?.tripType,
                );
              }
              hasETA = (directionsETA ?? nextStopETA) != null;
            }

            final topOffset = MediaQuery.of(context).padding.top + (hasETA ? 80 : 16);

            return Positioned(
              top: topOffset,
              left: 16,
              child: Column(
                children: [
                  SOSButton(
                    currentLocation: currentLocation,
                    busId: myBus?.id,
                    routeId: selectedRoute?.id,
                  ),
                  if (myBus != null && myBus!.assignmentStatus == 'accepted') ...[
                    16.heightBox,
                    const VoiceMessageButton(),
                  ],
                ],
              ),
            );
          },
        ),

        // ── Trip-type badge (top-right of map, offset if ETA is present) ─────
        Consumer(
          builder: (context, ref, child) {
            final route = ref.watch(
              driverMapStateProvider.select((s) => s.selectedRoute),
            );
            if (route == null) return const SizedBox.shrink();

            final isSharing = ref.watch(
              driverLocationProvider.select((s) => s.isSharing),
            );
            final currentLocation = ref.watch(
              driverLocationProvider.select((s) => s.currentLocation),
            );
            final result = ref.watch(
              driverMapStateProvider.select((s) => s.directionsResult),
            );
            final nextStopETA = ref.watch(
              driverLocationProvider.select((s) => s.nextStopETA),
            );

            bool hasETA = false;
            if (isSharing) {
              String? directionsETA;
              if (result != null && currentLocation != null) {
                directionsETA = _computeNextStopETAFromDirections(
                  currentLocation,
                  route,
                  result,
                  myBus?.tripType,
                );
              }
              hasETA = (directionsETA ?? nextStopETA) != null;
            }

            final isPickup = (myBus?.tripType ?? 'pickup') != 'drop';
            final topOffset = MediaQuery.of(context).padding.top + (hasETA ? 80 : 12);

            // Use AppStatusThemeExtension tokens for pickup/drop badge colors.
            final badgeColor = isPickup
                ? context.appStatus.pickupColor
                : context.appStatus.dropColor;
            final badgeForeground = isPickup
                ? context.appStatus.pickupForeground
                : context.appStatus.dropForeground;

            return Positioned(
              top: topOffset,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPickup ? Icons.school_rounded : Icons.home_rounded,
                      color: badgeForeground,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPickup ? 'PICKUP' : 'DROP',
                      style: TextStyle(
                        color: badgeForeground,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // Cached-position offline banner — visible when sharing and socket drops.
        Consumer(
          builder: (context, ref, child) {
            final isSharing = ref.watch(
              driverLocationProvider.select((s) => s.isSharing),
            );
            final currentLocation = ref.watch(
              driverLocationProvider.select((s) => s.currentLocation),
            );
            if (!isSharing) return const SizedBox.shrink();
            return CachedPositionBanner(
              lastKnownPosition: currentLocation,
              bottomOffset: 120.0,
            );
          },
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns the ordered list of waypoints for a trip.
  /// - pickup : [startPoint, ...stopPoints, endPoint]   (A → B)
  /// - drop   : [endPoint, ...stopPoints.reversed, startPoint]  (B → A)
  List<RoutePoint> _orderedStops(RouteModel route, String? tripType) {
    if (tripType == 'drop') {
      return [
        route.endPoint,
        ...route.stopPoints.reversed,
        route.startPoint,
      ];
    }
    return [
      route.startPoint,
      ...route.stopPoints,
      route.endPoint,
    ];
  }

  Set<Marker> _buildStopMarkers(RouteModel? route, String? tripType) {
    final stopMarkers = <Marker>{};
    if (route == null) return stopMarkers;

    final isPickup = tripType != 'drop';
    final ordered = _orderedStops(route, tripType);
    if (ordered.isEmpty) return stopMarkers;

    // First point in the ordered list gets the "start" (green) icon.
    final firstPt = ordered.first;
    // Last point gets the "end" (red) icon.
    final lastPt = ordered.last;
    // Middle points get the intermediate (orange) icon.

    if (firstPt.lat != 0 || firstPt.lng != 0) {
      stopMarkers.add(
        Marker(
          markerId: const MarkerId('dstop_start'),
          position: LatLng(firstPt.lat, firstPt.lng),
          icon:
              startStopIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: isPickup
                ? 'Start: ${firstPt.name}'
                : 'Drop Start: ${firstPt.name}',
          ),
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 1,
        ),
      );
    }

    // Intermediate stops (skip first and last)
    for (int i = 1; i < ordered.length - 1; i++) {
      final stop = ordered[i];
      if (stop.lat == 0 && stop.lng == 0) continue;
      stopMarkers.add(
        Marker(
          markerId: MarkerId('dstop_$i'),
          position: LatLng(stop.lat, stop.lng),
          icon:
              intermediateStopIcon ??
              BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange,
              ),
          infoWindow: InfoWindow(title: 'Stop $i: ${stop.name}'),
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 1,
        ),
      );
    }

    if (ordered.length > 1 && (lastPt.lat != 0 || lastPt.lng != 0)) {
      stopMarkers.add(
        Marker(
          markerId: const MarkerId('dstop_end'),
          position: LatLng(lastPt.lat, lastPt.lng),
          icon:
              endStopIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: isPickup
                ? 'End: ${lastPt.name}'
                : 'Drop End: ${lastPt.name}',
          ),
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 1,
        ),
      );
    }

    return stopMarkers;
  }

  Set<Polyline> _buildPolylines(
    DirectionsResult? result,
    LatLng? currentLocation,
    Color routeColor,
    String? tripType,
  ) {
    final polylines = <Polyline>{};
    if (result == null || !result.hasRoute) return polylines;

    List<LatLng> points = List<LatLng>.from(result.polylinePoints);
    if (tripType == 'drop') {
      points = points.reversed.toList();
    }

    if (currentLocation != null && points.isNotEmpty) {
      // Project the driver onto the nearest segment and start the polyline
      // exactly at that projected foot — eliminates the line extending behind
      // the bus marker when the driver is mid-segment.
      points = trimPolylineAtBus(currentLocation, points);
    }


    polylines.addAll({
      Polyline(
        polylineId: const PolylineId('driver_route_glow'),
        points: points,
        color: routeColor.withValues(alpha: 0.3),
        width: 10,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      ),
      Polyline(
        polylineId: const PolylineId('driver_route'),
        points: points,
        color: routeColor,
        width: 6,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      ),
    });

    return polylines;
  }

  /// Computes a human-readable ETA string to the next upcoming stop using
  /// the Directions API leg data and the driver's progress along the polyline.
  ///
  /// Uses road distance (walking polyline segments) instead of crow-fly to
  /// avoid the 30-50% underestimation that occurs on winding routes.
  String? _computeNextStopETAFromDirections(
    LatLng currentLocation,
    RouteModel selectedRoute,
    DirectionsResult directionsResult, [
    String? tripType,
  ]) {
    final polyline = directionsResult.polylinePoints;
    if (polyline.isEmpty) return null;

    final allStops = _orderedStops(selectedRoute, myBus?.tripType);

    // Find the polyline index closest to the driver's current position.
    final driverIdx = findClosestPointIndex(currentLocation, polyline);

    // Find the next upcoming stop (the first stop whose nearest polyline index
    // is strictly ahead of the driver's current index).
    int nextStopPolyIdx = -1;
    int nextStopIndex = -1;
    for (int i = 0; i < allStops.length; i++) {
      final stop = allStops[i];
      if (stop.lat == 0 && stop.lng == 0) continue;
      final stopPolyIdx = findClosestPointIndex(
        LatLng(stop.lat, stop.lng),
        polyline,
      );
      if (stopPolyIdx > driverIdx) {
        nextStopIndex = i;
        nextStopPolyIdx = stopPolyIdx;
        break;
      }
    }

    if (nextStopIndex < 0 || nextStopPolyIdx < 0) return null;

    // Road distance from driver to the next stop by walking polyline segments.
    // This is much more accurate than crow-fly on winding Indian bus routes.
    final remainingRoadKm = polylineRoadDistanceKm(
      polyline,
      driverIdx,
      nextStopPolyIdx,
    );

    int etaMin = 1;
    if (directionsResult.legs.isNotEmpty) {
      // Pick the leg that covers the next stop.
      final legIndex = (nextStopIndex - 1).clamp(
        0,
        directionsResult.legs.length - 1,
      );
      final leg = directionsResult.legs[legIndex];
      if (leg.distanceKm > 0 && remainingRoadKm > 0) {
        // Scale leg duration by the proportion of road distance remaining.
        final proportion = (remainingRoadKm / leg.distanceKm).clamp(0.0, 1.0);
        etaMin =
            (proportion * leg.durationMin).round().clamp(1, leg.durationMin);
      } else {
        etaMin = leg.durationMin;
      }
    } else {
      // No leg data — fall back to 30 km/h speed estimate.
      etaMin = (remainingRoadKm / 0.5).ceil().clamp(1, 120);
    }

    final nextStop = allStops[nextStopIndex];
    return 'Next: ${nextStop.name} \u00B7 $etaMin min';
  }
}
