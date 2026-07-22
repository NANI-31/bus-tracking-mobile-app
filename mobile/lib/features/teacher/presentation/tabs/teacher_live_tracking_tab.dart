// teacher_live_tracking_tab.dart
//
// Extracted from teacher_dashboard.dart.
// Renders the "Live Tracking" tab content in two modes:
//   1. Active override â€” teacher is broadcasting GPS; shows map with bus
//      marker, polylines, ETA card, and LiveTrackingControlPanel.
//   2. Passive view â€” teacher is watching the fleet via StudentMapTab.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/core/services/directions_result.dart';
import 'package:collegebus/core/utils/route_math_utils.dart';
import 'package:collegebus/features/bus/application/bus_provider.dart';
import 'package:collegebus/features/driver/application/driver_location_provider.dart';
import 'package:collegebus/features/driver/application/driver_map_provider.dart';
import 'package:collegebus/features/driver/presentation/widgets/live_tracking_control_panel.dart';
import 'package:collegebus/features/driver/presentation/widgets/voice_message_button.dart';
import 'package:collegebus/features/route/application/route_provider.dart';
import 'package:collegebus/features/route/domain/route_model.dart';
import 'package:collegebus/features/student/application/map_navigation_provider.dart';
import 'package:collegebus/features/student/presentation/tabs/student_map_tab.dart';
import 'package:collegebus/features/user/domain/user_model.dart';
import 'package:collegebus/shared/widgets/maps/map_skeleton_loader.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/shared/widgets/navigation/curved_bottom_nav_bar.dart';
import 'package:collegebus/shared/widgets/sos_button.dart';
import 'package:collegebus/widgets/common/common_map_view.dart';


class TeacherLiveTrackingTab extends ConsumerWidget {
  const TeacherLiveTrackingTab({
    super.key,
    required this.user,
    required this.selectedBusId,
    required this.isTracking,
    required this.currentLocation,
    required this.busIcon,
    required this.startStopIcon,
    required this.intermediateStopIcon,
    required this.endStopIcon,
    required this.onToggleSharing,
    required this.onCompleteTrip,
    required this.onBusSelected,
    required this.onRouteTypeSelected,
    required this.onBusNumberSelected,
    required this.onClearFilters,
  });

  final UserModel user;
  final String? selectedBusId;
  final bool isTracking;
  final LatLng? currentLocation;
  final BitmapDescriptor? busIcon;
  final BitmapDescriptor? startStopIcon;
  final BitmapDescriptor? intermediateStopIcon;
  final BitmapDescriptor? endStopIcon;
  final void Function(BusModel? bus) onToggleSharing;
  final VoidCallback onCompleteTrip;
  final void Function(BusModel bus, RouteModel? route) onBusSelected;
  final void Function(String? type) onRouteTypeSelected;
  final void Function(String? busNum, List<BusModel> buses, List<RouteModel> routes) onBusNumberSelected;
  final VoidCallback onClearFilters;


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isTracking && selectedBusId != null) {
      return _buildActiveOverrideMap(context, ref);
    }
    return _buildPassiveFleetMap(context, ref);
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Active override: teacher is broadcasting GPS
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildActiveOverrideMap(BuildContext context, WidgetRef ref) {
    final mapState = ref.watch(driverMapStateProvider);
    final route = mapState.selectedRoute;
    final result = mapState.directionsResult;

    final locationState = ref.watch(driverLocationProvider);
    final effectiveLocation =
        locationState.currentLocation ?? currentLocation;
    final heading = locationState.heading;
    final nextStopETA = locationState.nextStopETA;
    final isSharing = locationState.isSharing;

    final stopMarkers = _buildStopMarkers(route);
    final polylines = _buildPolylines(result, effectiveLocation, route);
    final mapMarkers = {...stopMarkers};

    if (effectiveLocation != null) {
      mapMarkers.add(
        Marker(
          markerId: const MarkerId('teacher_bus'),
          position: effectiveLocation,
          icon: busIcon ?? BitmapDescriptor.defaultMarker,
          rotation: heading,
          anchor: const Offset(0.5, 0.2),
          flat: true,
          zIndexInt: 2,
        ),
      );
    }

    final buses =
        ref.watch(collegeBusesStreamProvider(user.collegeId)).valueOrNull ?? [];
    final bus = buses.cast<dynamic>().firstWhere(
          (b) => b.id == selectedBusId,
          orElse: () => null,
        );

    String? directionsETA;
    if (result != null && effectiveLocation != null && route != null) {
      directionsETA = _computeNextStopETAFromDirections(
        effectiveLocation,
        route,
        result,
      );
    }
    final displayETA =
        directionsETA ?? (nextStopETA != null ? 'ETA: $nextStopETA' : null);

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: CommonMapView(
                currentLocation: effectiveLocation,
                markers: mapMarkers,
                polylines: polylines,
                onMapCreated: (controller) {},
                initialZoom: 17.0,
              ),
            ),
            LiveTrackingControlPanel(
              bus: bus,
              route: route,
              isSharing: isSharing,
              currentLocation: effectiveLocation,
              onToggleSharing: () => onToggleSharing(bus),
              onCompleteTrip: onCompleteTrip,

            ),
            SizedBox(height: CurvedBottomNavBar.clearance(context)),
          ],
        ),

        // ETA card
        if (isSharing && route != null && displayETA != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.navigation_rounded,
                      color: AppColors.primary,
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
                  if (result != null)
                    Text(
                      '${result.totalDistanceKm.toStringAsFixed(1)} km',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ),

        // SOS & Voice Message Buttons
        Positioned(
          top: MediaQuery.of(context).padding.top +
              (isSharing && route != null && displayETA != null ? 80 : 16),
          left: 16,
          child: Column(
            children: [
              SOSButton(
                currentLocation: effectiveLocation,
                busId: selectedBusId,
                routeId: route?.id,
              ),
              if (bus != null && bus.assignmentStatus == 'accepted') ...[
                const SizedBox(height: 16),
                const VoiceMessageButton(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Passive fleet view: teacher is watching buses via StudentMapTab
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildPassiveFleetMap(BuildContext context, WidgetRef ref) {
    final mapNavState = ref.watch(mapNavigationProvider);
    final selectedBus = mapNavState.selectedBus;
    final activeRoute = mapNavState.activeRoute;
    final selectedRouteType = mapNavState.selectedRouteType;

    final busesAsync = ref.watch(collegeBusesStreamProvider(user.collegeId));
    final liveBusIds = ref.watch(studentLiveBusIdsProvider(user.collegeId));
    final routesAsync = ref.watch(collegeRoutesProvider(user.collegeId));

    return busesAsync.when(
      loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: MapSkeletonLoader(),
        ),
      error: (err, stack) =>
          Center(child: Text('Error loading fleet map: $err')),
      data: (buses) {
        final routes = routesAsync.valueOrNull ?? [];

        return StudentMapTab(
          currentLocation: currentLocation,
          buses: selectedBus != null &&
                  selectedBus.assignmentStatus == 'accepted' &&
                  liveBusIds.contains(selectedBus.id)
              ? [selectedBus]
              : const [],
          selectedBus: selectedBus != null &&
                  selectedBus.assignmentStatus == 'accepted'
              ? selectedBus
              : null,
          selectedRouteType: selectedRouteType,
          allBuses: buses,
          filteredBusesCount: selectedBus != null &&
                  selectedBus.assignmentStatus == 'accepted' &&
                  liveBusIds.contains(selectedBus.id)
              ? 1
              : 0,
          onMapCreated: (controller) {},
          onRouteTypeSelected: (type) => onRouteTypeSelected(type),
          onBusNumberSelected: (busNum) => onBusNumberSelected(busNum, buses, routes),
          onClearFilters: onClearFilters,
          onBusSelected: (bus) {
            if (bus != null && bus.assignmentStatus != 'accepted') {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Bus ${bus.busNumber} is not active yet '
                    '(pending driver acceptance).',
                  ),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
            RouteModel? busRoute;
            if (bus != null) {
              final targetRouteId = bus.routeId ?? bus.defaultRouteId;
              busRoute = routes.cast<RouteModel?>().firstWhere(
                (r) => r!.id == targetRouteId,
                orElse: () => null,
              );
            }
            ref.read(mapNavigationProvider.notifier).selectBus(bus, busRoute);
          },
          activeRoute: selectedBus != null &&
                  selectedBus.assignmentStatus == 'accepted'
              ? activeRoute
              : null,
        );
      },
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Helpers
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Set<Marker> _buildStopMarkers(RouteModel? route) {
    final stopMarkers = <Marker>{};
    if (route == null) return stopMarkers;

    if (route.startPoint.lat != 0 && route.startPoint.lng != 0) {
      stopMarkers.add(Marker(
        markerId: const MarkerId('tstop_start'),
        position: LatLng(route.startPoint.lat, route.startPoint.lng),
        icon: startStopIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: 'Start: ${route.startPoint.name}'),
        anchor: const Offset(0.5, 0.5),
        zIndexInt: 1,
      ));
    }

    for (int i = 0; i < route.stopPoints.length; i++) {
      final stop = route.stopPoints[i];
      if (stop.lat == 0 && stop.lng == 0) continue;

      final isAtStart = (stop.lat - route.startPoint.lat).abs() < 0.00001 &&
          (stop.lng - route.startPoint.lng).abs() < 0.00001;
      final isAtEnd = (stop.lat - route.endPoint.lat).abs() < 0.00001 &&
          (stop.lng - route.endPoint.lng).abs() < 0.00001;
      final isSameNameStart = route.startPoint.name.isNotEmpty &&
          stop.name.trim().toLowerCase() ==
              route.startPoint.name.trim().toLowerCase();
      final isSameNameEnd = route.endPoint.name.isNotEmpty &&
          stop.name.trim().toLowerCase() ==
              route.endPoint.name.trim().toLowerCase();

      if (isAtStart || isAtEnd || isSameNameStart || isSameNameEnd) continue;

      stopMarkers.add(Marker(
        markerId: MarkerId('tstop_$i'),
        position: LatLng(stop.lat, stop.lng),
        icon: intermediateStopIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(title: 'Stop ${i + 1}: ${stop.name}'),
        anchor: const Offset(0.5, 0.5),
        zIndexInt: 1,
      ));
    }

    if (route.endPoint.lat != 0 && route.endPoint.lng != 0) {
      stopMarkers.add(Marker(
        markerId: const MarkerId('tstop_end'),
        position: LatLng(route.endPoint.lat, route.endPoint.lng),
        icon: endStopIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: 'End: ${route.endPoint.name}'),
        anchor: const Offset(0.5, 0.5),
        zIndexInt: 1,
      ));
    }

    return stopMarkers;
  }

  Set<Polyline> _buildPolylines(
    DirectionsResult? result,
    LatLng? currentLoc,
    RouteModel? route,
  ) {
    // ── Fallback: Directions API not ready yet but route is known ─────────
    // Draw a dashed straight-line path between the ordered stop coordinates
    // so the teacher sees *something* immediately on the map. The widget will
    // rebuild automatically once loadRouteOverlay() finishes and stores the
    // real DirectionsResult in driverMapStateProvider.
    if ((result == null || !result.hasRoute) && route != null) {
      return _buildFallbackPolylines(currentLoc, route);
    }
    if (result == null || !result.hasRoute) return {};

    List<LatLng> points = List<LatLng>.from(result.polylinePoints);
    if (currentLoc != null && points.isNotEmpty) {
      final closestIdx = findClosestPointIndex(currentLoc, points);
      points = [currentLoc, ...points.sublist(closestIdx)];
    }

    final routeColor = route != null
        ? Color(int.parse(route.color.replaceAll('#', '0xFF')))
        : const Color(0xFF1565C0);

    return {
      Polyline(
        polylineId: const PolylineId('teacher_route_glow'),
        points: points,
        color: routeColor.withValues(alpha: 0.3),
        width: 10,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      ),
      Polyline(
        polylineId: const PolylineId('teacher_route'),
        points: points,
        color: routeColor,
        width: 6,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      ),
    };
  }

  /// Straight-line fallback polyline drawn between ordered stop coordinates.
  /// Used while the Directions API is still loading. Rendered dashed to
  /// communicate to the teacher that this is an estimate, not a road-snapped route.
  Set<Polyline> _buildFallbackPolylines(LatLng? currentLoc, RouteModel route) {
    final points = <LatLng>[
      if (route.startPoint.lat != 0 || route.startPoint.lng != 0)
        LatLng(route.startPoint.lat, route.startPoint.lng),
      for (final s in route.stopPoints)
        if (s.lat != 0 || s.lng != 0) LatLng(s.lat, s.lng),
      if (route.endPoint.lat != 0 || route.endPoint.lng != 0)
        LatLng(route.endPoint.lat, route.endPoint.lng),
    ];

    if (points.length < 2) return {};

    // Prepend teacher's current location so the line starts from where they are
    final allPoints = currentLoc != null ? [currentLoc, ...points] : points;

    final routeColor =
        Color(int.parse(route.color.replaceAll('#', '0xFF')));

    return {
      Polyline(
        polylineId: const PolylineId('teacher_route_fallback'),
        points: allPoints,
        color: routeColor.withValues(alpha: 0.6),
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        geodesic: true,
      ),
    };
  }

  /// Computes a human-readable ETA string to the next upcoming stop.
  String? _computeNextStopETAFromDirections(
    LatLng currentLoc,
    RouteModel selectedRoute,
    DirectionsResult directionsResult,
  ) {
    final polyline = directionsResult.polylinePoints;
    if (polyline.isEmpty) return null;

    final allStops = [
      selectedRoute.startPoint,
      ...selectedRoute.stopPoints,
      selectedRoute.endPoint,
    ];

    int findClosestIdx(LatLng target) {
      double minDistance = double.infinity;
      int closestIndex = 0;
      for (int i = 0; i < polyline.length; i++) {
        final dist = Geolocator.distanceBetween(
          target.latitude,
          target.longitude,
          polyline[i].latitude,
          polyline[i].longitude,
        );
        if (dist < minDistance) {
          minDistance = dist;
          closestIndex = i;
        }
      }
      return closestIndex;
    }

    final driverIdx = findClosestIdx(currentLoc);

    int nextStopIndex = -1;
    for (int i = 0; i < allStops.length; i++) {
      final stop = allStops[i];
      if (stop.lat == 0 && stop.lng == 0) continue;
      final stopIdx = findClosestIdx(LatLng(stop.lat, stop.lng));
      if (stopIdx > driverIdx) {
        nextStopIndex = i;
        break;
      }
    }

    if (nextStopIndex < 0) return null;

    final nextStop = allStops[nextStopIndex];
    final remainingDistanceKm = Geolocator.distanceBetween(
          currentLoc.latitude,
          currentLoc.longitude,
          nextStop.lat,
          nextStop.lng,
        ) /
        1000.0;

    int etaMin = 1;
    if (directionsResult.legs.isNotEmpty) {
      final legIndex = (nextStopIndex - 1)
          .clamp(0, directionsResult.legs.length - 1);
      final leg = directionsResult.legs[legIndex];
      if (leg.distanceKm > 0) {
        final proportion =
            (remainingDistanceKm / leg.distanceKm).clamp(0.0, 1.0);
        etaMin =
            (proportion * leg.durationMin).round().clamp(1, leg.durationMin);
      } else {
        etaMin = leg.durationMin;
      }
    } else {
      etaMin = (remainingDistanceKm / 0.5).ceil().clamp(1, 120);
    }

    return 'Next: ${nextStop.name} Â· $etaMin min';
  }
}

