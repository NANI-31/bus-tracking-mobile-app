import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble, Offset;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/features/bus/application/bus_provider.dart';
import 'package:collegebus/features/route/domain/route_model.dart';
import 'package:collegebus/widgets/common/common_map_view.dart';
import 'package:collegebus/core/providers/service_providers.dart';
import 'package:collegebus/core/utils/map_marker_helper.dart';
import 'package:collegebus/core/providers/repository_providers.dart';
import 'package:collegebus/core/services/directions_service.dart';
import 'package:collegebus/core/services/directions_result.dart';
import 'package:collegebus/features/student/application/map_navigation_provider.dart';
import 'package:collegebus/shared/widgets/maps/map_skeleton_loader.dart';
import 'package:collegebus/shared/widgets/skeleton_transition.dart';
import 'package:collegebus/core/services/theme_service.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/features/sos/domain/sos_model.dart';
import 'package:collegebus/features/sos/application/sos_provider.dart';

class LiveBusMap extends ConsumerStatefulWidget {
  final List<BusModel> buses;
  final BusModel? selectedBus;
  final Function(BusModel)? onBusTap;

  /// The active route to draw on the map (polyline + stop markers).
  final RouteModel? activeRoute;

  /// Callback when directions result is loaded (for trip progress sheet).
  final Function(DirectionsResult?)? onDirectionsLoaded;

  final bool showUserLocation;
  final Function(GoogleMapController)? onMapCreated;
  final double bottomPadding;

  const LiveBusMap({
    super.key,
    required this.buses,
    this.selectedBus,
    this.onBusTap,
    this.activeRoute,
    this.onDirectionsLoaded,
    this.showUserLocation = true,
    this.onMapCreated,
    this.bottomPadding = 0.0,
  });

  @override
  ConsumerState<LiveBusMap> createState() => LiveBusMapState();
}

class LiveBusMapState extends ConsumerState<LiveBusMap>
    with TickerProviderStateMixin {
  final Map<String, Marker> _markers = {};
  final ValueNotifier<Set<Marker>> _markersNotifier = ValueNotifier({});
  // Cache locations to handle updates
  final Map<String, BusLocationModel> _liveLocations = {};

  // Animation maps
  final Map<String, AnimationController> _animationControllers = {};
  final List<AnimationController> _controllersPendingDispose = [];
  final Map<String, LatLng> _animatedLocations = {};
  final Map<String, double> _animatedRotations = {};

  LatLng? _centerLocation;
  GoogleMapController? _mapController;
  AnimationController? _cameraAnimationController;
  final Map<String, Offset> _sosScreenPositions = {};

  // Smart centering logic
  bool _isProgrammaticMove = false;

  // Route overlay state
  Set<Polyline> _routePolylines = {};
  final Map<String, Marker> _stopMarkers = {};
  DirectionsResult? _directionsResult;
  String? _loadedRouteId;

  void resumeFollowing() {
    if (mounted) {
      ref.read(mapNavigationProvider.notifier).setFollowing(true);
      if (widget.selectedBus != null) {
        _animateToBus(widget.selectedBus!);
      }
    }
  }

  BitmapDescriptor? _busIcon;
  BitmapDescriptor? _startStopIcon;
  BitmapDescriptor? _intermediateStopIcon;
  BitmapDescriptor? _endStopIcon;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _loadCustomMarker();
    _loadCustomStopMarkers(
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFFE53935),
    );

    if (widget.activeRoute != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadRouteOverlay(widget.activeRoute!);
        }
      });
    }

    // Catch current location state immediately after first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _seedLocationsFromProvider();
    });
  }

  Future<void> _loadCustomMarker() async {
    try {
      final icon = await MapMarkerHelper.createBusMarker();
      debugPrint('[LiveBusMap] Custom bus marker loaded successfully');
      if (mounted) {
        setState(() {
          _busIcon = icon;
        });
        _rebuildMarkers();
      }
    } catch (e) {
      debugPrint('[LiveBusMap] Error creating custom marker: $e');
    }
  }

  Color? _lastStartColor;
  Color? _lastStopColor;
  Color? _lastEndColor;

  Future<void> _loadCustomStopMarkers(
    Color startColor,
    Color stopColor,
    Color endColor,
  ) async {
    if (_lastStartColor == startColor &&
        _lastStopColor == stopColor &&
        _lastEndColor == endColor) {
      return;
    }
    _lastStartColor = startColor;
    _lastStopColor = stopColor;
    _lastEndColor = endColor;

    try {
      final startIcon = await MapMarkerHelper.getStartMarker(color: startColor);
      final stopIcon = await MapMarkerHelper.getStopMarker(color: stopColor);
      final endIcon = await MapMarkerHelper.getEndMarker(color: endColor);
      if (mounted) {
        setState(() {
          _startStopIcon = startIcon;
          _intermediateStopIcon = stopIcon;
          _endStopIcon = endIcon;
        });
        if (widget.activeRoute != null) {
          _buildStopMarkers(widget.activeRoute!);
        }
        _rebuildMarkers();
      }
    } catch (e) {
      debugPrint('[LiveBusMap] Error creating custom stop markers: $e');
    }
  }

  @override
  void didUpdateWidget(LiveBusMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    final busSelectionChanged = oldWidget.selectedBus != widget.selectedBus;

    if (oldWidget.buses != widget.buses || busSelectionChanged) {
      // Re-seed live locations from provider so new buses immediately have data
      _seedLocationsFromProvider();
      _rebuildMarkers();

      if (busSelectionChanged) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          if (widget.selectedBus != null) {
            // A new bus was selected — center on it and start following
            ref.read(mapNavigationProvider.notifier).setFollowing(true);
            _animateToBus(widget.selectedBus!);
            _waitForSelectedBusLocation(widget.selectedBus!);
          } else if (oldWidget.selectedBus != null) {
            // Bus was deselected — return camera to student's own location
            _returnToUserLocation();
          }
        });
      }
    }

    // Handle route changes
    if (widget.activeRoute?.id != oldWidget.activeRoute?.id) {
      if (widget.activeRoute != null) {
        _loadRouteOverlay(widget.activeRoute!);
      } else {
        _clearRouteOverlay();
      }
    }
  }

  /// Animate the camera back to the student's own GPS position when a bus
  /// is deselected, so the map doesn't remain stuck on the last bus location.
  Future<void> _returnToUserLocation() async {
    final locationService = ref.read(locationServiceProvider);
    try {
      final pos = await locationService.getCurrentLocation();
      if (pos != null && mounted && _mapController != null) {
        _animateCameraTo(pos, 15.0);
        ref.read(mapNavigationProvider.notifier).updateUserLocation(pos);
      }
    } catch (_) {}
  }


  @override
  void dispose() {
    _markersNotifier.dispose();
    for (var controller in _animationControllers.values) {
      controller.dispose();
    }
    _animationControllers.clear();
    for (var controller in _controllersPendingDispose) {
      controller.dispose();
    }
    _controllersPendingDispose.clear();
    _cameraAnimationController?.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    // Try to restore from provider cache first so skeleton doesn't flash on tab switch
    final navState = ref.read(mapNavigationProvider);

    // Only use the cached nav position as the initial center if there's
    // no selected bus context that might have placed the camera on a bus.
    // This prevents the student from seeing a stale bus location when
    // they open the map without selecting any bus.
    final hasCachedCenter = navState.centerLocation != null;
    final hasSelectedBus = widget.selectedBus != null;

    if (hasCachedCenter && hasSelectedBus) {
      // Following a bus — restore last known camera position immediately
      if (mounted) {
        setState(() {
          _centerLocation = navState.centerLocation;
        });
      }
      return;
    }

    // No bus selected (or no cached center): always resolve to the
    // student's own GPS position so we don't show a stale bus location.
    final locationService = ref.read(locationServiceProvider);
    try {
      final pos = await locationService.getCurrentLocation();
      if (pos != null && mounted) {
        setState(() {
          _centerLocation = pos;
        });
        ref.read(mapNavigationProvider.notifier).updateUserLocation(pos);
      } else if (hasCachedCenter && mounted) {
        // GPS failed — fall back to cached position as last resort
        setState(() {
          _centerLocation = navState.centerLocation;
        });
      } else if (mounted) {
        // Absolute fallback: use college default
        const fallback = LatLng(16.2345, 80.4567);
        setState(() {
          _centerLocation = fallback;
        });
        ref.read(mapNavigationProvider.notifier).updateUserLocation(fallback);
      }
    } catch (e) {
      if (_centerLocation == null && mounted) {
        final fallback = hasCachedCenter
            ? navState.centerLocation!
            : const LatLng(16.2345, 80.4567);
        setState(() {
          _centerLocation = fallback;
        });
        ref.read(mapNavigationProvider.notifier).updateUserLocation(fallback);
      }
    }
  }

  /// Reads all current locations from the provider and seeds them into
  /// _liveLocations so that markers can be built even if ref.listen has not
  /// yet fired a change event (e.g. on first load or after tab switch).
  void _seedLocationsFromProvider() {
    if (!mounted) return;
    final user = ref.read(currentUserProvider);
    if (user?.collegeId == null) return;
    final currentLocs =
        ref.read(collegeBusLocationsProvider(user!.collegeId)).valueOrNull;
    if (currentLocs != null && currentLocs.isNotEmpty) {
      for (final loc in currentLocs) {
        _handleLocationUpdate(loc);
      }
    }
  }

  /// Polls until the selected bus has location data in _liveLocations,
  /// then triggers _rebuildMarkers and re-projection. This handles the race
  /// condition where the coordinator selects a bus before the socket/API has
  /// delivered the first location update for that bus.
  void _waitForSelectedBusLocation(BusModel bus, {int attemptCount = 0}) {
    if (!mounted || widget.selectedBus?.id != bus.id) return;
    if (_liveLocations.containsKey(bus.id) || _animatedLocations.containsKey(bus.id)) {
      // We now have data — rebuild markers and re-project
      _seedLocationsFromProvider();
      _rebuildMarkers();
      _animateToBus(bus);
      return;
    }
    // Retry up to 20 times (10 seconds total)
    if (attemptCount < 20) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _waitForSelectedBusLocation(bus, attemptCount: attemptCount + 1);
      });
    }
  }

  Future<void> _updateSosOverlayPositions() async {
    if (_mapController == null || !mounted) return;

    final user = ref.read(currentUserProvider);
    final collegeId = user?.collegeId;
    if (collegeId == null) return;

    final activeSosList = ref.read(activeSosProvider(collegeId)).value ?? [];

    final Map<String, Offset> newPositions = {};
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    for (final sos in activeSosList) {
      if (sos.status == SosStatus.active) {
        final LatLng pos;
        final liveLoc = _animatedLocations[sos.busId] ?? _liveLocations[sos.busId]?.currentLocation;
        if (liveLoc != null) {
          pos = liveLoc;
        } else {
          pos = LatLng(sos.latitude, sos.longitude);
        }

        try {
          final screenCoord = await _mapController!.getScreenCoordinate(pos);
          newPositions[sos.busId] = Offset(
            screenCoord.x.toDouble() / devicePixelRatio,
            screenCoord.y.toDouble() / devicePixelRatio,
          );
        } catch (e) {
          debugPrint('Error getting screen coordinate for SOS bus ${sos.busId}: $e');
        }
      }
    }

    if (mounted) {
      setState(() {
        _sosScreenPositions.clear();
        _sosScreenPositions.addAll(newPositions);
      });
    }
  }

  void _handleLocationUpdate(BusLocationModel nextLoc) {
    final busId = nextLoc.busId;
    final prevLoc = _liveLocations[busId];

    // 1. Timestamp out-of-order check
    if (prevLoc != null && nextLoc.timestamp.isBefore(prevLoc.timestamp)) {
      debugPrint('Ignoring stale location update for bus $busId');
      return;
    }

    _liveLocations[busId] = nextLoc;

    final startPos = _animatedLocations[busId] ?? nextLoc.currentLocation;
    LatLng endPos = nextLoc.currentLocation;

    final startRot = _animatedRotations[busId] ?? nextLoc.heading ?? 0.0;
    
    // Determine target rotation
    double targetRot = nextLoc.heading ?? startRot;

    // If the bus has moved, compute bearing mathematically from coordinates
    final distanceMeters = Geolocator.distanceBetween(
      startPos.latitude,
      startPos.longitude,
      endPos.latitude,
      endPos.longitude,
    );

    if (distanceMeters > 3.0) {
      targetRot = _calculateBearing(startPos, endPos);
    }

    // Calculate shortest angular difference (handles 360-degree wrap-around)
    double diff = (targetRot - startRot + 180) % 360 - 180;
    if (diff < -180) diff += 360;

    // Apply low-pass filter (moving average) on the angle change
    final double smoothedDiff = diff * 0.5; // Smooth factor: 0.5
    double endRot = startRot + smoothedDiff;
    endRot = (endRot + 360) % 360;

    // Calculate dynamic animation duration based on distance
    final int durationMs;
    if (distanceMeters < 1.0) {
      durationMs = 300; // Quick adjust for tiny updates
    } else {
      // Scale duration based on 10 m/s average speed, clamped to [500ms, 3500ms]
      durationMs = ((distanceMeters / 10.0) * 1000).round().clamp(500, 3500);
    }
    final duration = Duration(milliseconds: durationMs);

    // 2. Initialize or obtain AnimationController
    var controller = _animationControllers[busId];
    if (controller == null) {
      controller = AnimationController(
        vsync: this,
        duration: duration,
      );
      _animationControllers[busId] = controller;
      _animatedLocations[busId] = startPos;
      _animatedRotations[busId] = startRot;

      controller.addListener(() {
        if (mounted) {
          final t = controller!.value;
          _animatedLocations[busId] = LatLng(
            lerpDouble(startPos.latitude, endPos.latitude, t)!,
            lerpDouble(startPos.longitude, endPos.longitude, t)!,
          );
          _animatedRotations[busId] = lerpDouble(startRot, endRot, t)!;
          _rebuildMarkers();
          _updateSosOverlayPositions();
        }
      });
    } else {
      // Re-target existing animation
      controller.stop();
      // Simple way: Clear listener and recreate or just reset targets
      // Since we use the local state startPos/endPos in the listener closure,
      // we should recreate it or use a more dynamic closure.
      controller.dispose();
      controller = AnimationController(
        vsync: this,
        duration: duration,
      );
      _animationControllers[busId] = controller;

      controller.addListener(() {
        if (mounted) {
          final t = controller!.value;
          _animatedLocations[busId] = LatLng(
            lerpDouble(startPos.latitude, endPos.latitude, t)!,
            lerpDouble(startPos.longitude, endPos.longitude, t)!,
          );
          _animatedRotations[busId] = lerpDouble(startRot, endRot, t)!;
          _rebuildMarkers();
          _updateSosOverlayPositions();
        }
      });
    }

    controller.forward(from: 0.0);

    // Auto-center if following
    final isFollowing = ref.read(mapNavigationProvider).isFollowing;
    if (isFollowing && widget.selectedBus?.id == busId) {
      _animateToBus(widget.selectedBus!);
    }
  }

  void _rebuildMarkers() {
    final Map<String, Marker> newMarkers = {};

    final user = ref.read(currentUserProvider);
    final collegeId = user?.collegeId;
    final Set<String> liveBusIds = {};
    if (collegeId != null) {
      final locations = ref.read(collegeBusLocationsProvider(collegeId)).valueOrNull;
      if (locations != null) {
        liveBusIds.addAll(locations.map((l) => l.busId));
      }
    }

    final activeSosList = collegeId != null ? (ref.read(activeSosProvider(collegeId)).value ?? []) : <SosModel>[];

    // Seed locations for active SOS alerts if not present
    for (final sos in activeSosList) {
      if (sos.status == SosStatus.active && !_liveLocations.containsKey(sos.busId)) {
        _liveLocations[sos.busId] = BusLocationModel(
          busId: sos.busId,
          currentLocation: LatLng(sos.latitude, sos.longitude),
          timestamp: sos.timestamp,
          heading: 0.0,
          collegeId: sos.collegeId,
        );
      }
    }

    final allBuses = List<BusModel>.from(widget.buses);
    for (final sos in activeSosList) {
      if (sos.status == SosStatus.active && !allBuses.any((b) => b.id == sos.busId)) {
        allBuses.add(
          BusModel(
            id: sos.busId,
            busNumber: sos.busNumber,
            driverId: sos.userId,
            collegeId: sos.collegeId,
            createdAt: sos.timestamp,
            assignmentStatus: 'accepted',
            isActive: true,
            status: 'emergency',
          ),
        );
      }
    }

    for (var bus in allBuses) {
      final isSelectedBus = widget.selectedBus?.id == bus.id;
      final isSos = activeSosList.any((s) => s.busId == bus.id && s.status == SosStatus.active);
      // Only show a bus on the map when its driver is actively broadcasting GPS
      // (liveBusIds). bus.status alone is NOT sufficient — it updates on DB
      // assignment, not when the driver actually starts sending location data.
      final isLive = liveBusIds.contains(bus.id) || isSelectedBus || isSos;
      // Remove marker if bus has no live broadcast AND is not the selected bus.
      if (!isLive || (bus.assignmentStatus != 'accepted' && !isSelectedBus && !isSos)) {
        // Preserve the selected bus's data even if temporarily unassigned —
        // clearing it would prevent the BusTrackerMarker from ever projecting.
        _liveLocations.remove(bus.id);
        _animatedLocations.remove(bus.id);
        final controller = _animationControllers.remove(bus.id);
        if (controller != null) {
          _controllersPendingDispose.add(controller);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _controllersPendingDispose.contains(controller)) {
              controller.dispose();
              _controllersPendingDispose.remove(controller);
            }
          });
        }
        continue;
      }

      var pos =
          _animatedLocations[bus.id] ?? _liveLocations[bus.id]?.currentLocation;
      if (pos != null) {
        final rot =
            _animatedRotations[bus.id] ??
            _liveLocations[bus.id]?.heading ??
            0.0;
        final marker = _createMarker(bus, pos, rot, activeSosList);
        newMarkers[bus.id] = marker;
      }
    }

    _markers.clear();
    _markers.addAll(newMarkers);
    // Include BOTH bus markers AND stop markers so the Google Maps native layer
    // always shows bus pins (as a reliable fallback when the custom overlay
    // BusTrackerMarker cannot be projected yet).
    _markersNotifier.value = {..._markers.values, ..._stopMarkers.values};
  }

  Marker _createMarker(BusModel bus, LatLng pos, double rotation, List<SosModel> activeSosList) {
    final isSos = activeSosList.any((s) => s.busId == bus.id && s.status == SosStatus.active);

    return Marker(
      markerId: MarkerId(bus.id),
      position: pos,
      rotation: rotation,
      icon: isSos
          ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
          : (_busIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure)),
      anchor: const Offset(0.5, 0.5),
      infoWindow: InfoWindow(
        title: isSos ? 'Bus ${bus.busNumber} [SOS ACTIVE]' : 'Bus ${bus.busNumber}',
        snippet: isSos ? 'EMERGENCY SOS ALERT' : bus.status,
      ),
      onTap: () => widget.onBusTap?.call(bus),
    );
  }

  void _animateToBus(BusModel bus) {
    final pos =
        _animatedLocations[bus.id] ?? _liveLocations[bus.id]?.currentLocation;
    if (pos != null && _mapController != null) {
      _animateCameraTo(pos, 17.0);
    }
  }

  void _animateCameraTo(LatLng target, double targetZoom) {
    if (_mapController == null || !mounted) return;

    final navState = ref.read(mapNavigationProvider);
    final startLatLng = navState.centerLocation ?? _centerLocation ?? const LatLng(16.2345, 80.4567);
    final startZoom = navState.zoom;

    _cameraAnimationController?.stop();
    _cameraAnimationController?.dispose();

    final distanceMeters = Geolocator.distanceBetween(
      startLatLng.latitude,
      startLatLng.longitude,
      target.latitude,
      target.longitude,
    );
    
    final durationMs = (800 + (distanceMeters / 15.0).clamp(0.0, 1000.0)).round();
    final duration = Duration(milliseconds: durationMs);

    _cameraAnimationController = AnimationController(
      vsync: this,
      duration: duration,
    );

    final curve = CurvedAnimation(
      parent: _cameraAnimationController!,
      curve: const Cubic(0.05, 0.7, 0.1, 1.0),
    );

    _isProgrammaticMove = true;

    _cameraAnimationController!.addListener(() {
      if (!mounted || _mapController == null) return;
      final t = curve.value;
      
      final lat = lerpDouble(startLatLng.latitude, target.latitude, t)!;
      final lng = lerpDouble(startLatLng.longitude, target.longitude, t)!;
      
      double zoom;
      if (distanceMeters > 150.0) {
        final maxDip = (distanceMeters / 250.0).clamp(0.0, 2.2);
        final dip = maxDip * math.sin(math.pi * t);
        zoom = lerpDouble(startZoom, targetZoom, t)! - dip;
      } else {
        zoom = lerpDouble(startZoom, targetZoom, t)!;
      }
      
      _mapController!.moveCamera(
        CameraUpdate.newLatLngZoom(LatLng(lat, lng), zoom),
      );
    });

    _cameraAnimationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        if (mounted) {
          _isProgrammaticMove = false;
        }
      }
    });

    _cameraAnimationController!.forward();
  }

  // ===== Route Overlay Methods =====

  /// Fetch directions and build polyline + stop markers for a route.
  Future<void> _loadRouteOverlay(RouteModel route) async {
    // Skip if already loaded for this route
    if (_loadedRouteId == route.id) return;

    debugPrint('[LiveBusMap] Loading route overlay for ${route.routeName}');

    try {
      final directionsService = DirectionsService();
      final result = await directionsService.getDirectionsForRoute(route);

      if (!mounted) return;

      final themeState = ref.read(themeServiceProvider);
      final routeColor = _getRouteColor(themeState);

      if (result != null && result.hasRoute) {
        setState(() {
          _directionsResult = result;
          _loadedRouteId = route.id;

          // Build a single solid route polyline
          _routePolylines = {
            Polyline(
              polylineId: const PolylineId('active_route'),
              points: result.polylinePoints,
              color: routeColor,
              width: 6,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
              geodesic: true,
            ),
          };

          // Build stop markers
          _stopMarkers.clear();
          _buildStopMarkers(route);

          // Fit camera to show entire route
          _fitCameraToRoute(result.polylinePoints);
        });
      }

      // Notify parent about directions result (for trip progress sheet)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onDirectionsLoaded?.call(result);
        }
      });
    } catch (e) {
      debugPrint('[LiveBusMap] Error loading route overlay: $e');
    }
  }

  /// Build markers for route stops (start, stops, end).
  void _buildStopMarkers(RouteModel route) {
    // Start point marker
    if (route.startPoint.lat != 0 && route.startPoint.lng != 0) {
      _stopMarkers['stop_start'] = Marker(
        markerId: const MarkerId('stop_start'),
        position: LatLng(route.startPoint.lat, route.startPoint.lng),
        icon: _startStopIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Start: ${route.startPoint.name}',
          snippet: 'Route start point',
        ),
        anchor: const Offset(0.5, 0.5),
        zIndexInt: 1,
      );
    }

    // Intermediate stop markers
    for (int i = 0; i < route.stopPoints.length; i++) {
      final stop = route.stopPoints[i];
      if (stop.lat == 0 && stop.lng == 0) continue;

      // Filter out intermediate stops that are at the exact same location as start or end points
      final isAtStart = (stop.lat - route.startPoint.lat).abs() < 0.00001 &&
          (stop.lng - route.startPoint.lng).abs() < 0.00001;
      final isAtEnd = (stop.lat - route.endPoint.lat).abs() < 0.00001 &&
          (stop.lng - route.endPoint.lng).abs() < 0.00001;
      if (isAtStart || isAtEnd) continue;

      _stopMarkers['stop_$i'] = Marker(
        markerId: MarkerId('stop_$i'),
        position: LatLng(stop.lat, stop.lng),
        icon: _intermediateStopIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(
          title: 'Stop ${i + 1}: ${stop.name}',
        ),
        anchor: const Offset(0.5, 0.5),
        zIndexInt: 1,
      );
    }

    // End point marker
    if (route.endPoint.lat != 0 && route.endPoint.lng != 0) {
      _stopMarkers['stop_end'] = Marker(
        markerId: const MarkerId('stop_end'),
        position: LatLng(route.endPoint.lat, route.endPoint.lng),
        icon: _endStopIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'End: ${route.endPoint.name}',
          snippet: 'Route end point',
        ),
        anchor: const Offset(0.5, 0.5),
        zIndexInt: 1,
      );
    }
  }

  /// Fit the camera to show the entire route polyline.
  void _fitCameraToRoute(List<LatLng> points) {
    if (points.isEmpty || _mapController == null) return;

    double minLat = points[0].latitude;
    double maxLat = points[0].latitude;
    double minLng = points[0].longitude;
    double maxLng = points[0].longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _isProgrammaticMove = true;
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 60),
    ).then((_) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) _isProgrammaticMove = false;
      });
    });
  }

  /// Clear route overlay.
  void _clearRouteOverlay() {
    setState(() {
      _routePolylines = {};
      _stopMarkers.clear();
      _directionsResult = null;
      _loadedRouteId = null;
    });
    _rebuildMarkers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onDirectionsLoaded?.call(null);
      }
    });
  }

  /// Get the current directions result (for parent widgets).
  DirectionsResult? get directionsResult => _directionsResult;


  /// Calculate the bearing/heading angle between two coordinates.
  double _calculateBearing(LatLng start, LatLng end) {
    final lat1 = start.latitude * (math.pi / 180.0);
    final lon1 = start.longitude * (math.pi / 180.0);
    final lat2 = end.latitude * (math.pi / 180.0);
    final lon2 = end.longitude * (math.pi / 180.0);

    final dLon = lon2 - lon1;

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final radians = math.atan2(y, x);
    final degrees = radians * (180.0 / math.pi);
    
    return (degrees + 360.0) % 360.0;
  }




  Color _getRouteColor(ThemeState themeState) {
    final bool isDark;
    if (themeState.mapTheme == 'auto') {
      isDark = themeState.isDarkMode;
    } else {
      isDark = themeState.mapTheme == 'dark' ||
          themeState.mapTheme == 'aubergine' ||
          themeState.mapTheme == 'uber';
    }

    if (isDark) {
      return const Color(0xFF00E5FF); // Electric Cyan for high contrast on dark maps
    } else {
      return const Color(0xFF1565C0); // Deep Royal Blue for high contrast on light maps
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final collegeId = user?.collegeId;
    final themeState = ref.watch(themeServiceProvider);
    final routeColor = _getRouteColor(themeState);

    final mapTheme = Theme.of(context).extension<MapThemeExtension>();
    final startColor = mapTheme?.startStopColor ?? const Color(0xFF4CAF50);
    final stopColor = mapTheme?.intermediateStopColor ?? const Color(0xFFFF9800);
    final endColor = mapTheme?.endStopColor ?? const Color(0xFFE53935);
    final routeColorTheme = mapTheme?.routeColor ?? routeColor;

    _loadCustomStopMarkers(startColor, stopColor, endColor);

    // Reactively update route polyline colors when map theme changes
    if (_routePolylines.isNotEmpty && _directionsResult != null) {
      _routePolylines = {
        Polyline(
          polylineId: const PolylineId('active_route'),
          points: _directionsResult!.polylinePoints,
          color: routeColorTheme,
          width: 6,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          geodesic: true,
        ),
      };
    }

    if (collegeId != null) {
      // ref.watch ensures we process the CURRENT value on every build
      // (not just future changes like ref.listen would).
      ref.watch(collegeBusLocationsProvider(collegeId)).whenData((locations) {
        // Process inside post-frame so we don't call setState during build.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            for (final loc in locations) {
              _handleLocationUpdate(loc);
            }
          }
        });
      });
    }

    if (collegeId != null) {
      ref.watch(activeSosProvider(collegeId)).whenData((alerts) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _updateSosOverlayPositions();
          }
        });
      });
    }

    ref.listen<bool>(
      mapNavigationProvider.select((s) => s.isFollowing),
      (previous, next) {
        if (next && widget.selectedBus != null) {
          _animateToBus(widget.selectedBus!);
        }
      },
    );

    return SkeletonTransition(
      isLoading: _centerLocation == null,
      skeleton: MapSkeletonLoader(bottomPadding: widget.bottomPadding),
      child: _centerLocation == null
          ? const SizedBox.shrink()
          : LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    ValueListenableBuilder<Set<Marker>>(
                      valueListenable: _markersNotifier,
                      builder: (context, markers, child) {
                        return CommonMapView(
                          currentLocation: _centerLocation!,
                          markers: markers,
                          polylines: _routePolylines,
                          onMapCreated: (controller) {
                            _mapController = controller;
                            widget.onMapCreated?.call(controller);
                            // Seed any existing locations into _liveLocations
                            _seedLocationsFromProvider();
                            _rebuildMarkers();
                            Future.delayed(const Duration(milliseconds: 300), () {
                              _updateSosOverlayPositions();
                            });
                          },
                          onCameraMove: (position) {
                            ref.read(mapNavigationProvider.notifier).updateCamera(position.target, position.zoom);
                            _updateSosOverlayPositions();
                          },
                          onCameraIdle: () async {
                            if (_mapController != null && collegeId != null) {
                              final user = ref.read(currentUserProvider);
                              final isAuthorized = user != null &&
                                  user.role != UserRole.student &&
                                  user.role != UserRole.parent &&
                                  user.role != UserRole.teacher;
                              if (isAuthorized) {
                                final bounds = await _mapController!.getVisibleRegion();
                                try {
                                  final repo = ref.read(busRepositoryProvider);
                                  final locations = await repo.getCollegeBusLocations(
                                    collegeId,
                                    minLat: bounds.southwest.latitude,
                                    maxLat: bounds.northeast.latitude,
                                    minLng: bounds.southwest.longitude,
                                    maxLng: bounds.northeast.longitude,
                                  );
                                  if (mounted) {
                                    for (var loc in locations) {
                                      _handleLocationUpdate(loc);
                                    }
                                  }
                                } catch (e) {
                                  debugPrint('Failed to fetch bounded buses: $e');
                                }
                              }
                            }
                          },
                          onCameraMoveStarted: () {
                            if (!_isProgrammaticMove) {
                              final isFollowing = ref.read(mapNavigationProvider).isFollowing;
                              if (isFollowing) {
                                ref.read(mapNavigationProvider.notifier).setFollowing(false);
                              }
                            }
                          },
                          initialZoom: ref.read(mapNavigationProvider).zoom,
                          myLocationEnabled: widget.showUserLocation,
                          myLocationButtonEnabled: widget.showUserLocation,
                          bottomPadding: widget.bottomPadding,
                        );
                      },
                    ),

                    // Radar pulse overlays for active SOS alerts
                    ..._sosScreenPositions.entries.map((entry) {
                      final offset = entry.value;
                      final busId = entry.key;
                      return Positioned(
                        left: offset.dx - 60,
                        top: offset.dy - 60,
                        child: IgnorePointer(
                          child: Hero(
                            tag: 'sos-marker-$busId',
                            child: const RadarPulseWidget(),
                          ),
                        ),
                      );
                    }),

                    if (!ref.watch(mapNavigationProvider.select((s) => s.isFollowing)) && widget.selectedBus != null)
                      Positioned(
                        bottom: 20 + widget.bottomPadding,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: FloatingActionButton.extended(
                            onPressed: resumeFollowing,
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            icon: const Icon(Icons.gps_fixed),
                            label: const Text("Recenter Bus"),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}

class RadarPulseWidget extends StatefulWidget {
  const RadarPulseWidget({super.key});

  @override
  State<RadarPulseWidget> createState() => _RadarPulseWidgetState();
}

class _RadarPulseWidgetState extends State<RadarPulseWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return CustomPaint(
          painter: _RadarPulsePainter(progress: _animationController.value),
          size: const Size(120, 120),
        );
      },
    );
  }
}

class _RadarPulsePainter extends CustomPainter {
  final double progress;

  _RadarPulsePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < 3; i++) {
      final ringProgress = (progress + i / 3.0) % 1.0;
      final radius = maxRadius * ringProgress;
      final opacity = (1.0 - ringProgress).clamp(0.0, 1.0);

      // Glow fill
      final glowPaint = Paint()
        ..color = Colors.red.withValues(alpha: opacity * 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, glowPaint);

      // Stroke ring
      final linePaint = Paint()
        ..color = Colors.red.withValues(alpha: opacity * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, radius, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPulsePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

