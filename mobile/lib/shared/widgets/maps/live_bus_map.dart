import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;
import 'dart:ui' as ui;
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
import 'package:collegebus/shared/widgets/maps/route_path_skeleton.dart';
import 'package:collegebus/core/services/theme_service.dart';
import 'package:collegebus/core/constants/constants.dart';

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
  final Map<String, LatLng> _animatedLocations = {};
  final Map<String, double> _animatedRotations = {};

  LatLng? _centerLocation;
  GoogleMapController? _mapController;

  // Smart centering logic
  bool _isProgrammaticMove = false;

  // Route overlay state
  Set<Polyline> _routePolylines = {};
  final Map<String, Marker> _stopMarkers = {};
  DirectionsResult? _directionsResult;
  String? _loadedRouteId;
  bool _isFetchingRoute = false;

  Map<String, Offset> _screenPositions = {};

  LatLng? _positionsProjectedCenter;
  double _positionsProjectedZoom = 17.0;
  LatLng? _routeProjectedCenter;
  double _routeProjectedZoom = 17.0;

  bool _isProjectingPositions = false;
  bool _isProjectingRoute = false;

  DateTime _lastPositionsUpdateTime = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> _updateScreenPositions({bool force = false}) async {
    if (_mapController == null || _isProjectingPositions) return;
    
    final now = DateTime.now();
    if (!force && now.difference(_lastPositionsUpdateTime).inMilliseconds < 150) {
      return;
    }
    
    _isProjectingPositions = true;
    try {
      final navState = ref.read(mapNavigationProvider);
      final LatLng? projCenter = navState.centerLocation;
      final double projZoom = navState.zoom;

      final user = ref.read(currentUserProvider);
      final collegeId = user?.collegeId;
      final Set<String> liveBusIds = {};
      if (collegeId != null) {
        final locations = ref.read(collegeBusLocationsProvider(collegeId)).value;
        if (locations != null) {
          liveBusIds.addAll(locations.map((l) => l.busId));
        }
      }

      int projectedCount = 0;
      final Map<String, Offset> nextPositions = {};
      for (var bus in widget.buses) {
        final isSelectedBus = widget.selectedBus?.id == bus.id;
        final isLive = bus.status != 'not-running' || liveBusIds.contains(bus.id) || isSelectedBus;
        // Skip buses that are not live — EXCEPT the selected bus which should
        // always project if it has a known position (even if temporarily unassigned).
        if (!isLive) continue;
        if (bus.assignmentStatus == 'unassigned' && !isSelectedBus) continue;
        var pos = _animatedLocations[bus.id] ?? _liveLocations[bus.id]?.currentLocation;
        if (pos != null) {
          projectedCount++;
          try {
            final screenCoord = await _mapController!.getScreenCoordinate(pos);
            nextPositions[bus.id] = Offset(screenCoord.x.toDouble(), screenCoord.y.toDouble());
          } catch (e) {
            // Ignore projection failures in test or when controller is being disposed
          }
        }
      }
      if (mounted) {
        setState(() {
          _screenPositions = nextPositions;
          _positionsProjectedCenter = projCenter;
          _positionsProjectedZoom = projZoom;
          _lastPositionsUpdateTime = now;
        });

        final bool isUninitialized = projectedCount > 0 &&
            (nextPositions.isEmpty || nextPositions.values.every((pt) => pt == Offset.zero));
        if (isUninitialized) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) _updateScreenPositions(force: true);
          });
        }
      }
    } finally {
      _isProjectingPositions = false;
    }
  }

  ui.FragmentShader? _shader;
  List<Offset> _routeScreenPoints = [];

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset('shaders/glow_route.frag');
      if (mounted) {
        setState(() {
          _shader = program.fragmentShader();
        });
      }
    } catch (e) {
      debugPrint('Failed to load shader: $e. Using canvas fallback.');
    }
  }



  Future<void> _updateRouteScreenPoints() async {
    if (_mapController == null || _directionsResult == null || _isProjectingRoute) return;
    _isProjectingRoute = true;
    try {
      final navState = ref.read(mapNavigationProvider);
      final LatLng? projCenter = navState.centerLocation;
      final double projZoom = navState.zoom;

      final simplifiedPoints = DouglasPeucker.simplifyToMaxPoints(
        _directionsResult!.polylinePoints,
        25,
      );
      
      final List<Offset> points = [];
      for (final latLng in simplifiedPoints) {
        try {
          final screenCoord = await _mapController!.getScreenCoordinate(latLng);
          points.add(Offset(screenCoord.x.toDouble(), screenCoord.y.toDouble()));
        } catch (e) {
          // Ignore
        }
      }
      if (mounted) {
        setState(() {
          _routeScreenPoints = points;
          _routeProjectedCenter = projCenter;
          _routeProjectedZoom = projZoom;
        });

        // If projection failed to return any points, retry after a short delay
        final bool isUninitialized = points.isEmpty || points.every((pt) => pt == Offset.zero);
        if (isUninitialized && _directionsResult != null) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) _updateRouteScreenPoints();
          });
        }
      }
    } finally {
      _isProjectingRoute = false;
    }
  }

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
    _loadShader();

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
      // Clear cache to pick up any size changes
      MapMarkerHelper.clearCache();
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
            _schedulePositionRetries();
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
        _isProgrammaticMove = true;
        _mapController!.animateCamera(CameraUpdate.newLatLngZoom(pos, 15.0)).then((_) {
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) _isProgrammaticMove = false;
          });
        });
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
        ref.read(collegeBusLocationsProvider(user!.collegeId)).value;
    if (currentLocs != null && currentLocs.isNotEmpty) {
      for (final loc in currentLocs) {
        _handleLocationUpdate(loc);
      }
    }
  }

  /// Schedules staggered re-projection calls so the map has time to
  /// fully stabilise before we ask for screen coordinates.
  void _schedulePositionRetries() {
    for (final delay in [200, 600, 1200, 2000]) {
      Future.delayed(Duration(milliseconds: delay), () {
        if (mounted) {
          _updateScreenPositions(force: true);
          _updateRouteScreenPoints();
        }
      });
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
      _schedulePositionRetries();
      return;
    }
    // Retry up to 20 times (10 seconds total)
    if (attemptCount < 20) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _waitForSelectedBusLocation(bus, attemptCount: attemptCount + 1);
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
      final locations = ref.read(collegeBusLocationsProvider(collegeId)).value;
      if (locations != null) {
        liveBusIds.addAll(locations.map((l) => l.busId));
      }
    }

    for (var bus in widget.buses) {
      final isSelectedBus = widget.selectedBus?.id == bus.id;
      final isLive = bus.status != 'not-running' || liveBusIds.contains(bus.id) || isSelectedBus;
      // If bus is not live, or it's unassigned AND not the coordinator-selected bus,
      // remove it from the map and clear its cached position data.
      if (!isLive || (bus.assignmentStatus == 'unassigned' && !isSelectedBus)) {
        // Preserve the selected bus's data even if temporarily unassigned —
        // clearing it would prevent the BusTrackerMarker from ever projecting.
        _liveLocations.remove(bus.id);
        _animatedLocations.remove(bus.id);
        final controller = _animationControllers.remove(bus.id);
        if (controller != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            controller.dispose();
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
        final marker = _createMarker(bus, pos, rot);
        newMarkers[bus.id] = marker;
      }
    }

    _markers.clear();
    _markers.addAll(newMarkers);
    // Include BOTH bus markers AND stop markers so the Google Maps native layer
    // always shows bus pins (as a reliable fallback when the custom overlay
    // BusTrackerMarker cannot be projected yet).
    _markersNotifier.value = {..._markers.values, ..._stopMarkers.values};
    _updateScreenPositions();
  }

  // Removed _updateScreenPositions for Rive

  Marker _createMarker(BusModel bus, LatLng pos, double rotation) {
    return Marker(
      markerId: MarkerId(bus.id),
      position: pos,
      rotation: rotation,
      icon:
          _busIcon ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      anchor: const Offset(0.5, 0.5),
      infoWindow: InfoWindow(
        title: 'Bus ${bus.busNumber}',
        snippet: bus.status,
      ),
      onTap: () => widget.onBusTap?.call(bus),
    );
  }

  // Removed _deriveTripStatus for Rive

  void _animateToBus(BusModel bus) {
    final pos =
        _animatedLocations[bus.id] ?? _liveLocations[bus.id]?.currentLocation;
    if (pos != null && _mapController != null) {
      _isProgrammaticMove = true;
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(pos, 17.0)).then(
        (_) {
          // Reset flag after animation completes/starts
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) _isProgrammaticMove = false;
          });
        },
      );
    }
  }

  // ===== Route Overlay Methods =====

  /// Fetch directions and build polyline + stop markers for a route.
  Future<void> _loadRouteOverlay(RouteModel route) async {
    // Skip if already loaded for this route
    if (_loadedRouteId == route.id) return;

    debugPrint('[LiveBusMap] Loading route overlay for ${route.routeName}');

    setState(() {
      _isFetchingRoute = true;
    });

    final startTime = DateTime.now();

    try {
      final directionsService = DirectionsService();
      final result = await directionsService.getDirectionsForRoute(route);

      if (!mounted) return;

      final themeState = ref.read(themeServiceProvider);
      final routeColor = _getRouteColor(themeState);

      // Force a minimum loading delay of 3.0 seconds to allow the skeleton route animation to complete
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      final remainingDelay = 3000 - elapsed;
      if (remainingDelay > 0) {
        await Future.delayed(Duration(milliseconds: remainingDelay));
      }

      if (!mounted) return;

      setState(() {
        _directionsResult = result;
        _loadedRouteId = route.id;

        if (result != null && result.hasRoute) {
          // Build the route polyline with modern dual glowing style
          _routePolylines = {
            // Glow background layer
            Polyline(
              polylineId: const PolylineId('active_route_glow'),
              points: result.polylinePoints,
              color: routeColor.withValues(alpha: 0.3),
              width: 10,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
              geodesic: true,
            ),
            // Clean solid core layer
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
          _updateRouteScreenPoints();

          // Fit camera to show entire route
          _fitCameraToRoute(result.polylinePoints);
        }
      });

      // Notify parent about directions result (for trip progress sheet)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onDirectionsLoaded?.call(result);
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingRoute = false;
        });
      }
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
        zIndex: 1,
      );
    }

    // Intermediate stop markers
    for (int i = 0; i < route.stopPoints.length; i++) {
      final stop = route.stopPoints[i];
      if (stop.lat == 0 && stop.lng == 0) continue;
      _stopMarkers['stop_$i'] = Marker(
        markerId: MarkerId('stop_$i'),
        position: LatLng(stop.lat, stop.lng),
        icon: _intermediateStopIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(
          title: 'Stop ${i + 1}: ${stop.name}',
        ),
        anchor: const Offset(0.5, 0.5),
        zIndex: 1,
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
        zIndex: 1,
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
      _routeScreenPoints = [];
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
        // Glow background layer
        Polyline(
          polylineId: const PolylineId('active_route_glow'),
          points: _directionsResult!.polylinePoints,
          color: routeColorTheme.withValues(alpha: 0.3),
          width: 10,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          geodesic: true,
        ),
        // Clean solid core layer
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
                final mapSize = Size(constraints.maxWidth, constraints.maxHeight);
                return Stack(
                  children: [
                    ValueListenableBuilder<Set<Marker>>(
                      valueListenable: _markersNotifier,
                      builder: (context, markers, child) {
                        return CommonMapView(
                          currentLocation: _centerLocation!,
                          markers: markers,
                          polylines: const {},
                          onMapCreated: (controller) {
                            _mapController = controller;
                            widget.onMapCreated?.call(controller);
                            // Seed any existing locations into _liveLocations
                            // immediately so that _updateScreenPositions has data.
                            _seedLocationsFromProvider();
                            _rebuildMarkers();
                            // Staggered retries — getScreenCoordinate can silently
                            // return (0,0) until the map layout is fully stable.
                            _schedulePositionRetries();
                          },
                          onCameraMove: (position) {
                            ref.read(mapNavigationProvider.notifier).updateCamera(position.target, position.zoom);
                            _updateScreenPositions();
                          },
                          onCameraIdle: () async {
                            _isProjectingPositions = false;
                            _isProjectingRoute = false;
                            _updateScreenPositions(force: true);
                            _updateRouteScreenPoints();
                            if (_mapController != null && collegeId != null) {
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

                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: (_isFetchingRoute || (_directionsResult != null && _routeScreenPoints.isEmpty))
                              ? const RoutePathSkeleton(
                                  key: ValueKey('route_skeleton'),
                                  height: double.infinity,
                                )
                              : _directionsResult != null
                                  ? AnimatedRouteOverlay(
                                      key: const ValueKey('route_overlay'),
                                      points: _routeScreenPoints,
                                      shader: _shader,
                                      routeColor: routeColorTheme,
                                      trafficDensity: 0.55,
                                      projectedCenter: _routeProjectedCenter,
                                      projectedZoom: _routeProjectedZoom,
                                    )
                                  : const SizedBox.shrink(key: ValueKey('route_empty')),
                        ),
                      ),
                    ),

                    // Projected Rive Markers Layer
                    Consumer(
                      builder: (context, ref, child) {
                        final navState = ref.watch(mapNavigationProvider);
                        final currentCenter = navState.centerLocation;
                        final currentZoom = navState.zoom;

                        return Stack(
                          children: [
                            for (final bus in widget.buses)
                              if (_screenPositions.containsKey(bus.id))
                                Builder(
                                  builder: (context) {
                                    Offset pos = _screenPositions[bus.id]!;
                                    if (_positionsProjectedCenter != null && currentCenter != null) {
                                      pos = _transformPoint(
                                        point: pos,
                                        size: mapSize,
                                        projectedCenter: _positionsProjectedCenter!,
                                        projectedZoom: _positionsProjectedZoom,
                                        currentCenter: currentCenter,
                                        currentZoom: currentZoom,
                                      );
                                    }
                                    return Positioned(
                                      left: pos.dx - 27,
                                      top: pos.dy - 27,
                                      child: BusTrackerMarker(
                                        bus: bus,
                                        rotation: _animatedRotations[bus.id] ?? _liveLocations[bus.id]?.heading ?? 0.0,
                                        onTap: () => widget.onBusTap?.call(bus),
                                      ),
                                    );
                                  },
                                ),
                          ],
                        );
                      },
                    ),

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

class BusTrackerMarker extends StatelessWidget {
  final BusModel bus;
  final double rotation;
  final VoidCallback onTap;

  const BusTrackerMarker({
    super.key,
    required this.bus,
    required this.rotation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Transform.rotate(
        angle: rotation * math.pi / 180,
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
            border: Border.all(
              color: primaryColor,
              width: 2,
            ),
          ),
          child: ClipOval(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Image.asset(
                'assets/bus_icon.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedRouteOverlay extends ConsumerStatefulWidget {
  final List<Offset> points;
  final ui.FragmentShader? shader;
  final Color routeColor;
  final double trafficDensity;
  final LatLng? projectedCenter;
  final double projectedZoom;

  const AnimatedRouteOverlay({
    super.key,
    required this.points,
    required this.shader,
    required this.routeColor,
    required this.trafficDensity,
    required this.projectedCenter,
    required this.projectedZoom,
  });

  @override
  ConsumerState<AnimatedRouteOverlay> createState() => _AnimatedRouteOverlayState();
}

class _AnimatedRouteOverlayState extends ConsumerState<AnimatedRouteOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navState = ref.watch(mapNavigationProvider);
    return CustomPaint(
      size: Size.infinite,
      painter: RoutePainter(
        points: widget.points,
        shader: widget.shader,
        routeColor: widget.routeColor,
        trafficDensity: widget.trafficDensity,
        time: _animationController.value,
        projectedCenter: widget.projectedCenter,
        projectedZoom: widget.projectedZoom,
        currentCenter: navState.centerLocation,
        currentZoom: navState.zoom,
      ),
    );
  }
}

class RoutePainter extends CustomPainter {
  final List<Offset> points;
  final ui.FragmentShader? shader;
  final Color routeColor;
  final double trafficDensity;
  final double time;
  final LatLng? projectedCenter;
  final double projectedZoom;
  final LatLng? currentCenter;
  final double currentZoom;

  RoutePainter({
    required this.points,
    required this.shader,
    required this.routeColor,
    required this.trafficDensity,
    required this.time,
    required this.projectedCenter,
    required this.projectedZoom,
    required this.currentCenter,
    required this.currentZoom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || size.width <= 0.0 || size.height <= 0.0) return;

    List<Offset> transformedPoints = points;
    if (projectedCenter != null && currentCenter != null) {
      transformedPoints = points.map((pt) {
        return _transformPoint(
          point: pt,
          size: size,
          projectedCenter: projectedCenter!,
          projectedZoom: projectedZoom,
          currentCenter: currentCenter!,
          currentZoom: currentZoom,
        );
      }).toList();
    }

    final path = Path();
    path.moveTo(transformedPoints.first.dx, transformedPoints.first.dy);
    for (int i = 1; i < transformedPoints.length; i++) {
      path.lineTo(transformedPoints[i].dx, transformedPoints[i].dy);
    }

    if (shader != null) {
      shader!.setFloat(0, size.width);
      shader!.setFloat(1, size.height);
      shader!.setFloat(2, time * 10.0);
      shader!.setFloat(3, trafficDensity);
      shader!.setFloat(4, routeColor.red / 255.0);
      shader!.setFloat(5, routeColor.green / 255.0);
      shader!.setFloat(6, routeColor.blue / 255.0);
      shader!.setFloat(7, routeColor.opacity);

      final paint = Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(path, paint);
    } else {
      // Fallback glow painter
      // 1. Outer Blur Glow
      final glowPaint = Paint()
        ..color = routeColor.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..imageFilter = ui.ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0);

      canvas.drawPath(path, glowPaint);

      // 2. Solid Core
      final corePaint = Paint()
        ..color = routeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(path, corePaint);

      // 3. Animated progress sweep pulse
      final sweepPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      for (final pathMetric in path.computeMetrics()) {
        final length = pathMetric.length;
        if (length == 0) continue;
        final dashLength = 30.0;
        final gapLength = 90.0;
        final totalPeriod = dashLength + gapLength;

        final offset = (time * length * 0.5) % totalPeriod;

        double distance = offset;
        while (distance < length) {
          final extract = pathMetric.extractPath(
            distance,
            math.min(distance + dashLength, length),
          );
          canvas.drawPath(extract, sweepPaint);
          distance += totalPeriod;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant RoutePainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.points != points ||
        oldDelegate.routeColor != routeColor ||
        oldDelegate.trafficDensity != trafficDensity ||
        oldDelegate.projectedCenter != projectedCenter ||
        oldDelegate.projectedZoom != projectedZoom ||
        oldDelegate.currentCenter != currentCenter ||
        oldDelegate.currentZoom != currentZoom;
  }
}

class DouglasPeucker {
  static List<LatLng> simplify(List<LatLng> points, double epsilon) {
    if (points.length < 3 || epsilon <= 0.0) return points;

    double dmax = 0.0;
    int index = 0;
    int end = points.length - 1;

    for (int i = 1; i < end; i++) {
      double d = _perpendicularDistance(points[i], points[0], points[end]);
      if (d > dmax) {
        index = i;
        dmax = d;
      }
    }

    if (dmax > epsilon) {
      final results1 = simplify(points.sublist(0, index + 1), epsilon);
      final results2 = simplify(points.sublist(index), epsilon);
      return [...results1.sublist(0, results1.length - 1), ...results2];
    } else {
      return [points.first, points.last];
    }
  }

  static List<LatLng> simplifyToMaxPoints(List<LatLng> points, int maxPoints) {
    if (points.length <= maxPoints) return points;

    double epsilon = 0.00002;
    List<LatLng> simplified = points;

    for (int iter = 0; iter < 8; iter++) {
      simplified = simplify(points, epsilon);
      if (simplified.length <= maxPoints) {
        break;
      }
      epsilon *= 2.0;
    }
    return simplified;
  }

  static double _perpendicularDistance(LatLng p, LatLng start, LatLng end) {
    double dx = end.longitude - start.longitude;
    double dy = end.latitude - start.latitude;

    double mag = math.sqrt(dx * dx + dy * dy);
    if (mag > 0.0) {
      dx /= mag;
      dy /= mag;
    }

    final pvalx = p.longitude - start.longitude;
    final pvaly = p.latitude - start.latitude;

    return (pvalx * dy - pvaly * dx).abs();
  }
}

double _lngToMercator(double lng) {
  return (lng + 180.0) / 360.0;
}

double _latToMercator(double lat) {
  final rad = lat * math.pi / 180.0;
  final sinLat = math.sin(rad);
  final clampedSin = sinLat.clamp(-0.9999, 0.9999);
  return 0.5 - math.log((1.0 + clampedSin) / (1.0 - clampedSin)) / (4.0 * math.pi);
}

Offset _transformPoint({
  required Offset point,
  required Size size,
  required LatLng projectedCenter,
  required double projectedZoom,
  required LatLng currentCenter,
  required double currentZoom,
}) {
  final double centerX = size.width / 2.0;
  final double centerY = size.height / 2.0;

  // 1. Translate relative to screen center
  final double xOff = point.dx - centerX;
  final double yOff = point.dy - centerY;

  // 2. Scale by zoom change
  final double zoomScale = math.pow(2.0, currentZoom - projectedZoom).toDouble();
  final double xScaled = xOff * zoomScale;
  final double yScaled = yOff * zoomScale;

  // 3. Translate by Mercator difference
  final double mxP = _lngToMercator(projectedCenter.longitude);
  final double myP = _latToMercator(projectedCenter.latitude);
  final double mxC = _lngToMercator(currentCenter.longitude);
  final double myC = _latToMercator(currentCenter.latitude);

  // Map size in pixels at current zoom level
  final double mapSize = 256.0 * math.pow(2.0, currentZoom);
  final double dx = (mxC - mxP) * mapSize;
  final double dy = (myC - myP) * mapSize;

  final double xTransformed = xScaled - dx;
  final double yTransformed = yScaled - dy;

  // 4. Translate back to widget coordinates
  return Offset(xTransformed + centerX, yTransformed + centerY);
}

