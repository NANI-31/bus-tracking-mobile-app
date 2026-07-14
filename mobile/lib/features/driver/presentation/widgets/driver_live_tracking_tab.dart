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
import 'package:geolocator/geolocator.dart';
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

                final stopMarkers = _buildStopMarkers(route);
                final polylines =
                    _buildPolylines(result, currentLocation, routeColorTheme);

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

        // Next-stop ETA card (navigation style)
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
              );
            }

            final displayETA =
                directionsETA ??
                (nextStopETA != null ? 'ETA: $nextStopETA' : null);
            if (displayETA == null) return const SizedBox.shrink();

            return Positioned(
              bottom: 240,
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
            );
          },
        ),

        // SOS & Voice Message Buttons
        Positioned(
          top: 16,
          left: 16,
          child: Column(
            children: [
              Consumer(
                builder: (context, ref, child) {
                  final currentLocation = ref.watch(
                    driverLocationProvider.select((s) => s.currentLocation),
                  );
                  final selectedRoute = ref.watch(
                    driverMapStateProvider.select((s) => s.selectedRoute),
                  );
                  return SOSButton(
                    currentLocation: currentLocation,
                    busId: myBus?.id,
                    routeId: selectedRoute?.id,
                  );
                },
              ),
              if (myBus != null && myBus!.assignmentStatus == 'accepted') ...[
                16.heightBox,
                const VoiceMessageButton(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Set<Marker> _buildStopMarkers(RouteModel? route) {
    final stopMarkers = <Marker>{};
    if (route == null) return stopMarkers;

    if (route.startPoint.lat != 0 && route.startPoint.lng != 0) {
      stopMarkers.add(
        Marker(
          markerId: const MarkerId('dstop_start'),
          position: LatLng(route.startPoint.lat, route.startPoint.lng),
          icon:
              startStopIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: 'Start: ${route.startPoint.name}'),
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 1,
        ),
      );
    }

    for (int i = 0; i < route.stopPoints.length; i++) {
      final stop = route.stopPoints[i];
      if (stop.lat == 0 && stop.lng == 0) continue;

      final isAtStart =
          (stop.lat - route.startPoint.lat).abs() < 0.00001 &&
          (stop.lng - route.startPoint.lng).abs() < 0.00001;
      final isAtEnd =
          (stop.lat - route.endPoint.lat).abs() < 0.00001 &&
          (stop.lng - route.endPoint.lng).abs() < 0.00001;
      final isSameNameStart =
          route.startPoint.name.isNotEmpty &&
          stop.name.trim().toLowerCase() ==
              route.startPoint.name.trim().toLowerCase();
      final isSameNameEnd =
          route.endPoint.name.isNotEmpty &&
          stop.name.trim().toLowerCase() ==
              route.endPoint.name.trim().toLowerCase();

      if (isAtStart || isAtEnd || isSameNameStart || isSameNameEnd) continue;

      stopMarkers.add(
        Marker(
          markerId: MarkerId('dstop_$i'),
          position: LatLng(stop.lat, stop.lng),
          icon:
              intermediateStopIcon ??
              BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange,
              ),
          infoWindow: InfoWindow(title: 'Stop ${i + 1}: ${stop.name}'),
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 1,
        ),
      );
    }

    if (route.endPoint.lat != 0 && route.endPoint.lng != 0) {
      stopMarkers.add(
        Marker(
          markerId: const MarkerId('dstop_end'),
          position: LatLng(route.endPoint.lat, route.endPoint.lng),
          icon:
              endStopIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: 'End: ${route.endPoint.name}'),
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
  ) {
    final polylines = <Polyline>{};
    if (result == null || !result.hasRoute) return polylines;

    List<LatLng> points = List<LatLng>.from(result.polylinePoints);
    if (currentLocation != null && points.isNotEmpty) {
      final closestIdx = findClosestPointIndex(currentLocation, points);
      // Slice the polyline at the driver's current position —
      // removes already-traveled portion. No connecting line to start.
      points = points.sublist(closestIdx);
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
  String? _computeNextStopETAFromDirections(
    LatLng currentLocation,
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

    final driverIdx = findClosestIdx(currentLocation);

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
    final remainingDistanceKm =
        Geolocator.distanceBetween(
          currentLocation.latitude,
          currentLocation.longitude,
          nextStop.lat,
          nextStop.lng,
        ) /
        1000.0;

    int etaMin = 1;
    if (directionsResult.legs.isNotEmpty) {
      final legIndex = (nextStopIndex - 1).clamp(
        0,
        directionsResult.legs.length - 1,
      );
      final leg = directionsResult.legs[legIndex];
      if (leg.distanceKm > 0) {
        final proportion = (remainingDistanceKm / leg.distanceKm).clamp(
          0.0,
          1.0,
        );
        etaMin =
            (proportion * leg.durationMin).round().clamp(1, leg.durationMin);
      } else {
        etaMin = leg.durationMin;
      }
    } else {
      etaMin = (remainingDistanceKm / 0.5).ceil().clamp(1, 120);
    }

    return 'Next: ${nextStop.name} · $etaMin min';
  }
}

