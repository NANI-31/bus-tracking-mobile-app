import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // defaultTargetPlatform
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:collegebus/l10n/driver/app_localizations.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/core/services/persistence_service.dart';
import 'package:collegebus/core/services/secure_storage_service.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/core/providers/service_providers.dart';
import 'package:collegebus/features/bus/application/bus_provider.dart';
import 'package:collegebus/features/route/application/route_provider.dart';
import 'package:collegebus/core/providers/repository_providers.dart';
import 'package:collegebus/core/providers/socket_provider.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/features/notification/services/notification_service.dart';
import 'package:collegebus/features/route/domain/route_model.dart';
import 'package:collegebus/core/constants/constants.dart';

import 'package:collegebus/core/utils/app_logger.dart';

import 'widgets/live_tracking_control_panel.dart';
import 'package:collegebus/shared/widgets/navigation/curved_bottom_nav_bar.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:collegebus/features/user/presentation/screens/profile_screen.dart';

import 'package:collegebus/features/driver/application/driver_location_provider.dart';
import 'package:collegebus/features/driver/application/driver_map_provider.dart';
import 'package:collegebus/features/driver/application/driver_ui_provider.dart';
import 'package:collegebus/core/utils/map_marker_cache.dart';
import 'package:collegebus/shared/widgets/shimmer_skeletons.dart';
import 'package:collegebus/shared/widgets/api_error_modal.dart';
import 'package:collegebus/shared/widgets/global_connectivity_banner.dart';
import 'widgets/driver_bus_setup_tab.dart';
import 'widgets/driver_live_tracking_tab.dart';

class DriverDashboard extends ConsumerStatefulWidget {
  const DriverDashboard({super.key});

  @override
  ConsumerState<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends ConsumerState<DriverDashboard>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  bool _isSharing = false;
  bool _hasInitialized = false; // Prevent auto-resume during first build
  String? _storedTripType;

  DateTime? _lastDeviationAlertTime;


  /// Tracks which stop points have already fired a `stop_reached` event during
  /// the current sharing session. Key = "${stop.name}_${stop.lat}_${stop.lng}".
  /// Cleared when location sharing stops so stops can fire again next trip.
  final Set<String> _arrivedStopIds = {};

  /// Active overlay entry for the top toast notification.
  OverlayEntry? _activeOverlayEntry;

  /// Subscription to socket override events for cleanup in dispose().
  StreamSubscription<Map<String, dynamic>>? _overrideApprovedSubscription;
  StreamSubscription<Map<String, dynamic>>? _overrideEndedSubscription;

  BitmapDescriptor? _busIcon;
  BitmapDescriptor? _startStopIcon;
  BitmapDescriptor? _intermediateStopIcon;
  BitmapDescriptor? _endStopIcon;
  Color? _lastStartColor;
  Color? _lastStopColor;
  Color? _lastEndColor;

  /// Key for the [RepaintBoundary] that wraps the mobile content body.
  /// Passed to [CurvedBottomNavBar] so the liquid-glass lens shader can
  /// sample the real pixels rendered behind the navigation bar.
  final GlobalKey _backgroundKey = GlobalKey();

  Future<void> _loadBusIcon() async {
    try {
      // MapMarkerCache deduplicates the async canvas-draw so subsequent calls
      // during active tracking sessions return instantly from memory.
      final icon = await MapMarkerCache.getBusMarker();
      if (mounted) {
        setState(() {
          _busIcon = icon;
        });
      }
    } catch (e) {
      debugPrint('[DriverDashboard] Error loading bus icon: $e');
    }
  }

  Future<void> _loadCustomStopMarkers(
    Color startColor,
    Color stopColor,
    Color endColor,
  ) async {
    // Color-change guard: skip the async work when nothing changed.
    if (_lastStartColor == startColor &&
        _lastStopColor == stopColor &&
        _lastEndColor == endColor) {
      return;
    }
    _lastStartColor = startColor;
    _lastStopColor = stopColor;
    _lastEndColor = endColor;

    try {
      // MapMarkerCache returns cached descriptors on repeated calls so the
      // canvas-draw / image-decode path is only hit once per unique color.
      final startIcon = await MapMarkerCache.getStartMarker(color: startColor);
      final stopIcon  = await MapMarkerCache.getStopMarker(color: stopColor);
      final endIcon   = await MapMarkerCache.getEndMarker(color: endColor);
      if (mounted) {
        setState(() {
          _startStopIcon = startIcon;
          _intermediateStopIcon = stopIcon;
          _endStopIcon = endIcon;
        });
      }
    } catch (e) {
      debugPrint('[DriverDashboard] Error loading custom stop markers: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    // Restore/Enable Status Bar (timer, battery, signals, etc.)
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    debugPrint('[DriverDashboard] initState START');
    WidgetsBinding.instance.addObserver(this);
    _isSharing = PersistenceService.getIsSharingLocation();
    debugPrint('[DriverDashboard] _isSharing from persistence: $_isSharing');
    _loadStoredTripType();
    _loadBusIcon();

    _loadCustomStopMarkers(
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFFE53935),
    );
    _getCurrentLocation();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      debugPrint('[DriverDashboard] postFrameCallback - marking initialized');
      _hasInitialized = true;
      ref.read(driverLocationProvider.notifier).updateSharing(_isSharing);
      final socketService = ref.read(socketServiceProvider);
      final user = ref.read(currentUserProvider);
      if (user != null) {
        socketService.joinCollege(user.collegeId);
      }

      // Wire socket-level override streams as a redundant fast path alongside
      // the bus_updated → driverBusProvider ref.listen in build().
      _setupOverrideListeners();

      // Request permissions sequentially:
      // First Notification and Foreground GPS, then Background GPS, Battery Opt, and Mic.
      if (mounted) {
        await _requestDriverPermissions();
      }
    });
    debugPrint('[DriverDashboard] initState END');
  }

  @override
  void dispose() {
    _activeOverlayEntry?.remove();
    _activeOverlayEntry = null;
    _overrideApprovedSubscription?.cancel();
    _overrideEndedSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AppLogger.i('[DriverDashboard] App resumed â€” reconnecting socket.');
      // Suppress the red offline banner for 5 s â€” the socket typically
      // reconnects within 1-3 s after screen wake. Without this, drivers
      // see a misleading red flash every time they unlock their phone.
      GlobalConnectivityBanner.suppress(const Duration(seconds: 5));
      final socketService = ref.read(socketServiceProvider);
      socketService.ensureConnected();
      // Re-join college room in case the socket reconnected without it
      final user = ref.read(currentUserProvider);
      if (user != null) {
        socketService.joinCollege(user.collegeId);
      }
      // If sharing was active, ensure the GPS stream is still live.
      // On some devices the OS may have killed the stream subscription while
      // the app was in the background; we recover silently here.
      final isSharing = ref.read(driverLocationProvider).isSharing;
      final locationService = ref.read(locationServiceProvider);
      if (isSharing && !locationService.isTracking) {
        AppLogger.w(
          '[DriverDashboard] Location stream stopped in background â€” restarting.',
        );
        // Re-start the GPS stream silently using the already-loaded provider.
        // driverBusProvider is keyed by userId, so we read it via currentUser.
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          final userId = ref.read(currentUserProvider)?.id;
          if (userId != null) {
            final bus = ref.read(driverBusProvider(userId)).valueOrNull;
            if (bus != null) {
              await _startLocationSharing(bus, silent: true);
            }
          }
        });
      }
    } else if (state == AppLifecycleState.paused) {
      // The screen turned off or the app went to background.
      // The foreground service notification keeps the GPS stream alive on
      // Android â€” we intentionally do NOT stop tracking here.
      AppLogger.i(
        '[DriverDashboard] App paused (screen off / backgrounded). GPS stream continues via foreground service.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Teacher override — pause / resume GPS emission
  // ---------------------------------------------------------------------------

  /// Subscribes to socket-level override events as a redundant fast path.
  /// The primary detection is via [driverBusProvider] ref.listen below, which
  /// detects [trackingTeacherId] changes even when the dedicated socket events
  /// are not yet emitted by the server.
  void _setupOverrideListeners() {
    final socketService = ref.read(socketServiceProvider);

    _overrideApprovedSubscription?.cancel();
    _overrideApprovedSubscription = socketService.locationOverrideApprovedStream.listen(
      (data) {
        final busId = data['busId'] as String?;
        final userId = ref.read(currentUserProvider)?.id;
        final myBus = userId != null
            ? ref.read(driverBusProvider(userId)).valueOrNull
            : null;
        // Only react if this event is for our bus
        if (myBus != null && busId == myBus.id) {
          AppLogger.i('[DriverDashboard] location_override_approved received — pausing GPS');
          _handleOverrideActivated();
        }
      },
    );

    _overrideEndedSubscription?.cancel();
    _overrideEndedSubscription = socketService.locationOverrideEndedStream.listen(
      (data) {
        final busId = data['busId'] as String?;
        final userId = ref.read(currentUserProvider)?.id;
        final myBus = userId != null
            ? ref.read(driverBusProvider(userId)).valueOrNull
            : null;
        if (myBus != null && busId == myBus.id) {
          AppLogger.i('[DriverDashboard] location_override_ended received — resuming GPS');
          _handleOverrideEnded(myBus);
        }
      },
    );
  }

  /// Called when the coordinator approves a teacher override request while
  /// the driver is actively sharing GPS. Pauses emission without ending the
  /// session ([isSharing] stays true so auto-resume works).
  void _handleOverrideActivated() {
    // Guard: only react if we were actually sharing
    if (!ref.read(driverLocationProvider).isSharing) return;
    // Stop GPS emission loop (does NOT clear bus state or stop socket)
    ref.read(locationServiceProvider).stopLocationTracking();
    ref.read(driverLocationProvider.notifier).updateOverridePaused(true);
    _showToast(
      '⚠️ Location sharing paused — teacher override is active.',
      isError: false,
    );
    AppLogger.i('[DriverDashboard] GPS emission paused due to teacher override.');
  }

  /// Called when the teacher override ends (teacher cancelled OR the bus
  /// provider detects [trackingTeacherId] cleared). Auto-resumes GPS sharing
  /// if the driver was sharing before the override.
  void _handleOverrideEnded(BusModel bus) {
    final state = ref.read(driverLocationProvider);
    // Only resume if we were sharing before the override
    if (!state.isSharing) return;
    ref.read(driverLocationProvider.notifier).updateOverridePaused(false);
    // Auto-resume GPS emission silently (no confirmation dialog needed)
    if (!ref.read(locationServiceProvider).isTracking) {
      _startLocationSharing(bus, silent: true);
    }
    _showToast('✅ Location sharing resumed.');
    AppLogger.i('[DriverDashboard] GPS emission resumed after teacher override ended.');
  }

  // ---------------------------------------------------------------------------

  Future<void> _startLocationSharing(
    BusModel myBus, {
    bool silent = false,
  }) async {
    final locationService = ref.read(locationServiceProvider);
    final socketService = ref.read(socketServiceProvider);
    final user = ref.read(currentUserProvider);
    final repo = ref.read(busRepositoryProvider);

    // SECURITY: Re-verify location permission before each trip start
    final hasPermission = await locationService.checkLocationPermission();
    if (!hasPermission) {
      final granted = await locationService.requestLocationPermission();
      if (!granted) {
        if (!mounted) return;
        if (!silent) {
          ApiErrorModal.show(
            context: context,
            error: DriverLocalizations.of(context)!.locationNotAvailable,
          );
        }
        // If we can't share, update state to false
        ref.read(driverLocationProvider.notifier).updateSharing(false);
        await PersistenceService.setIsSharingLocation(false);
        return;
      }
    }

    // Android 10+ requires a SEPARATE request for background location
    // ('Allow all the time'). This is necessary so the foreground service
    // can deliver GPS updates when the screen is off.
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _requestBackgroundLocationPermission(silent: silent);
    }

    // Update bus status to live
    repo.updateBus(myBus.id, {'status': 'on-time'}).then((_) {
      ref.read(socketServiceProvider).sendBusListUpdate();
    }).catchError((e) {
      AppLogger.e('Failed to update bus status: $e');
    });

    locationService.startLocationTracking(
      onLocationUpdate: (position) {
        // Compute ETA before emitting so it can be included in the payload.
        // _checkRouteDeviation() calls _calculateETA() internally and returns
        // Compute ETA to nearest stop. Prefer actual GPS speed when the bus is
        // moving (> 1 m/s â‰ˆ 3.6 km/h) to give students real-time accuracy.
        // Falls back to 30 km/h (8.33 m/s) when stationary or speed is unreliable.
        final etaMinutes = _computeEtaMinutes(
          position,
          speedMs: position.speed > 1.0 ? position.speed : null,
        );

        socketService.updateLocation({
          'busId': myBus.id,
          'collegeId': user!.collegeId,
          'location': {'lat': position.latitude, 'lng': position.longitude},
          'speed': position.speed,
          'heading': position.heading,
          if (myBus.tripType != null) 'tripType': myBus.tripType,
          if (etaMinutes != null) 'etaMinutes': etaMinutes,
        });


        final latLng = LatLng(position.latitude, position.longitude);
        ref
            .read(driverLocationProvider.notifier)
            .updateLocation(
              latLng,
              heading: position.heading,
              speed: position.speed,
            );
        _checkRouteDeviation(position, myBus);
        _checkStopArrival(position, myBus);
      },
    );

    ref.read(driverLocationProvider.notifier).updateSharing(true);
    _saveSelections(myBus);

    if (!mounted) return;
  }

  /// Requests ACCESS_BACKGROUND_LOCATION on Android 10+.
  ///
  /// Android requires a two-step permission flow: the user must first grant
  /// 'While in Use' (already done before this call), and then they can be asked
  /// to upgrade to 'Allow all the time' via a separate system prompt. Without
  /// 'Allow all the time', the foreground service still runs but GPS delivery
  /// is throttled / blocked when the screen turns off on some OEM devices.
  Future<void> _requestBackgroundLocationPermission({
    bool silent = false,
  }) async {
    // Only relevant on Android 10 (API 29)+
    final status = await Permission.locationAlways.status;
    if (status.isGranted) return; // Already has 'Allow all the time'

    if (status.isPermanentlyDenied) {
      // User tapped 'Don't allow' too many times â€” guide them to settings
      if (!silent && mounted) {
        final shouldOpen = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Background Location Required'),
            content: const Text(
              'To share your location when the screen is off, please open app Settings '
              'and set Location to "Allow all the time".',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Not now'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
        if (shouldOpen == true) openAppSettings();
      }
      return;
    }

    // Show rationale before requesting
    if (!silent && mounted) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Background Location'),
          content: const Text(
            'Select "Allow all the time" on the next screen so students '
            'can track the bus even when your phone screen is off.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Skip'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    await Permission.locationAlways.request();
  }

  /// Sequential permission flow that requests basic permissions first,
  /// followed by high-level background/battery/audio permissions.
  ///
  /// Delegates to [AppPermissionsService] so all roles share a centralized
  /// permission orchestrator — avoids regression when new roles are added.
  Future<void> _requestDriverPermissions() async {
    if (!mounted) return;
    await ref.read(appPermissionsServiceProvider).requestDriverPermissions(
          context: context,
        );
  }

  Future<void> _loadStoredTripType() async {
    final stored = await SecureStorageService.getDriverTripType();
    if (mounted && stored != null) {
      setState(() {
        _storedTripType = stored;
      });
    }
  }

  Future<void> _saveSelections(BusModel? myBus) async {
    if (myBus != null) {
      await SecureStorageService.setDriverBusId(myBus.id);
      await SecureStorageService.setDriverBusNumber(myBus.busNumber);
      if (myBus.tripType != null) {
        await SecureStorageService.setDriverTripType(myBus.tripType!);
      }
      final selectedRoute = ref.read(driverMapStateProvider).selectedRoute;
      if (selectedRoute != null) {
        await SecureStorageService.setDriverRouteId(selectedRoute.id);
      }
    }
    final isSharing = ref.read(driverLocationProvider).isSharing;
    await PersistenceService.setIsSharingLocation(isSharing);
  }


  Future<void> _getCurrentLocation() async {
    final locationService = ref.read(locationServiceProvider);
    try {
      final location = await locationService.getCurrentLocation();
      if (location != null) {
        ref.read(driverLocationProvider.notifier).updateLocation(location);
      }
    } catch (e) {
      debugPrint('[DriverDashboard] ❌ GPS threw: $e');
    }
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;

    // Dismiss any active top toast immediately to prevent stacking/overlaps
    _activeOverlayEntry?.remove();
    _activeOverlayEntry = null;

    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isError ? Colors.red.shade800 : const Color(0xFF0097B2),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  isError ? Icons.error_outline : Icons.check_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
                12.widthBox,
                Expanded(
                  child: Text(
                    message,
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
        ),
      ),
    );

    _activeOverlayEntry = entry;
    Overlay.of(context).insert(entry);

    // Auto-dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (_activeOverlayEntry == entry) {
        entry.remove();
        _activeOverlayEntry = null;
      }
    });
  }




  Future<void> _toggleLocationSharing(BusModel? myBus) async {
    final isSharing = ref.read(driverLocationProvider).isSharing;
    if (!isSharing) {
      if (myBus == null) {
        ApiErrorModal.show(
          context: context,
          error: DriverLocalizations.of(context)!.pleaseAssignBusFirst,
        );
        return;
      }
      _startLocationSharing(myBus);
    } else {
      _stopLocationSharing(myBus);
    }
  }

  void _checkRouteDeviation(Position position, BusModel? myBus) {
    final mapState = ref.read(driverMapStateProvider);
    final selectedRoute = mapState.selectedRoute;
    if (selectedRoute == null) return;

    final busPoint = LatLng(position.latitude, position.longitude);
    double minDistance;

    // Prefer the dense Google Directions polyline for off-route checks.
    // This prevents false alerts on winding roads where the straight-line
    // between two sparse stop waypoints diverges far from the actual road.
    final directionsPolyline = mapState.directionsResult?.polylinePoints;
    if (directionsPolyline != null && directionsPolyline.length >= 2) {
      // For 'drop' trips the bus travels the reverse of the encoded polyline.
      final polyline = myBus?.tripType == 'drop'
          ? directionsPolyline.reversed.toList()
          : directionsPolyline;
      minDistance = _minDistanceToPolyline(busPoint, polyline);
    } else {
      // Fallback: check against segments between ordered stop waypoints.
      // Used before directionsResult arrives or when the fetch failed.
      final orderedStops = selectedRoute.getOrderedStops(myBus?.tripType);
      final points = orderedStops.map((s) => LatLng(s.lat, s.lng)).toList();
      minDistance = double.infinity;
      for (int i = 0; i < points.length - 1; i++) {
        final dist = _distanceToSegment(busPoint, points[i], points[i + 1]);
        if (dist < minDistance) minDistance = dist;
      }
    }

    // Threshold: 200 meters from nearest road segment
    if (minDistance > 200) {
      final now = DateTime.now();
      if (_lastDeviationAlertTime == null ||
          now.difference(_lastDeviationAlertTime!) >
              const Duration(minutes: 1)) {
        _lastDeviationAlertTime = now;
      }
      ref
          .read(driverLocationProvider.notifier)
          .updateOffRouteDistance(minDistance.toInt());
    } else {
      ref
          .read(driverLocationProvider.notifier)
          .updateOffRouteDistance(null);
    }

    // ETA Calculation
    _calculateETA(position, myBus);
  }

  /// Finds the minimum perpendicular distance (metres) from [point] to any
  /// segment of [polyline]. Delegates to the shared route_math_utils helper
  /// via a private wrapper to avoid re-importing in this file.
  double _minDistanceToPolyline(LatLng point, List<LatLng> polyline) {
    if (polyline.isEmpty) return double.infinity;
    double minDist = double.infinity;
    for (int i = 0; i < polyline.length - 1; i++) {
      final d = _distanceToSegment(point, polyline[i], polyline[i + 1]);
      if (d < minDist) minDist = d;
    }
    return minDist;
  }

  void _calculateETA(Position position, BusModel? myBus) {
    final etaMinutes = _computeEtaMinutes(position);
    if (etaMinutes == null) return;

    // Build the localised display string for the driver's own ETA card.
    final selectedRoute = ref.read(driverMapStateProvider).selectedRoute;
    if (selectedRoute == null) return;

    // Find the nearest stop again for its name (already done inside _computeEtaMinutes)
    double minDistance = double.infinity;
    RoutePoint? nextStop;
    for (final stop in selectedRoute.stopPoints) {
      final dist = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        stop.lat,
        stop.lng,
      );
      if (dist < minDistance) {
        minDistance = dist;
        nextStop = stop;
      }
    }
    if (nextStop == null) return;

    final etaStr = DriverLocalizations.of(
      context,
    )!.etaToNextStop(etaMinutes, nextStop.name);
    ref.read(driverLocationProvider.notifier).updateETA(etaStr);
  }

  /// Computes ETA in whole minutes to the nearest stop.
  /// Returns null if no route is selected or no stops exist.
  /// This is the single source of truth used by both the driver's UI card
  /// and the socket payload sent to students.
  ///
  /// [speedMs] â€” optional GPS speed in m/s from [Position.speed].
  /// Used when speed > 1.0 m/s (> 3.6 km/h) to avoid GPS jitter on stationary
  /// fixes. Falls back to 8.33 m/s (30 km/h) when null or too low.
  int? _computeEtaMinutes(Position position, {double? speedMs}) {
    final selectedRoute = ref.read(driverMapStateProvider).selectedRoute;
    if (selectedRoute == null) return null;

    double minDistance = double.infinity;

    for (final stop in selectedRoute.stopPoints) {
      final dist = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        stop.lat,
        stop.lng,
      );
      if (dist < minDistance) minDistance = dist;
    }

    if (minDistance == double.infinity) return null;

    // Use real GPS speed when reliable (> 1 m/s); otherwise default to 30 km/h.
    // Threshold: 1 m/s â‰ˆ 3.6 km/h â€” below this the reading is GPS noise.
    final effectiveSpeedMs = (speedMs != null && speedMs > 1.0)
        ? speedMs
        : 8.33;
    final timeSeconds = minDistance / effectiveSpeedMs;
    return (timeSeconds / 60).ceil();
  }

  /// Checks whether the driver is within 25 m of any RoutePoint (start, stops, or end)
  /// that has not yet been announced this session, and emits `stop_reached` via the socket.
  ///
  /// Each stop is tracked with a composite key to avoid needing an `id` field
  /// on [RoutePoint]. The set is cleared in [_stopLocationSharing] so that
  /// stops fire again on the next trip.
  void _checkStopArrival(Position position, BusModel myBus) {
    final selectedRoute = ref.read(driverMapStateProvider).selectedRoute;
    if (selectedRoute == null) return;

    // Collect all RoutePoints: Start -> Stops -> End
    final List<RoutePoint> allRoutePoints = [];
    if (selectedRoute.startPoint.lat != 0 &&
        selectedRoute.startPoint.lng != 0) {
      allRoutePoints.add(selectedRoute.startPoint);
    }
    allRoutePoints.addAll(selectedRoute.stopPoints);
    if (selectedRoute.endPoint.lat != 0 && selectedRoute.endPoint.lng != 0) {
      allRoutePoints.add(selectedRoute.endPoint);
    }

    // Stop arrival threshold: 25 meters
    const double arrivalThresholdMeters = 25.0;

    for (final stop in allRoutePoints) {
      final stopKey = '${stop.name}_${stop.lat}_${stop.lng}';

      // Skip if this stop was already announced this session
      if (_arrivedStopIds.contains(stopKey)) continue;

      final dist = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        stop.lat,
        stop.lng,
      );

      if (dist <= arrivalThresholdMeters) {
        _arrivedStopIds.add(stopKey);

        final socketService = ref.read(socketServiceProvider);
        final user = ref.read(currentUserProvider);

        socketService.emitStopReached({
          'busId': myBus.id,
          'collegeId': user?.collegeId ?? myBus.collegeId,
          // Composite key so students can match to their own stop
          'stopId': stopKey,
          'stopName': stop.name,
          'distanceMeters': dist.toStringAsFixed(1),
          'timestamp': DateTime.now().toIso8601String(),
        });

        AppLogger.i(
          '[DriverDashboard] stop_reached emitted for "${stop.name}" '
          '(${dist.toStringAsFixed(0)} m)',
        );
      }
    }
  }

  double _distanceToSegment(LatLng p, LatLng start, LatLng end) {
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
      // in case of 0 length line
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

  void _stopLocationSharing(BusModel? myBus, {bool showFeedback = true}) {
    final locationService = ref.read(locationServiceProvider);
    final repo = ref.read(busRepositoryProvider);

    locationService.stopLocationTracking();

    // Reset arrived stops so they can fire again on the next trip.
    _arrivedStopIds.clear();

    // Revert bus status to offline
    if (myBus != null) {
      repo.updateBus(myBus.id, {'status': 'not-running'}).then((_) {
        ref.read(socketServiceProvider).sendBusListUpdate();
      }).catchError((e) {
        AppLogger.e('Failed to update bus status: $e');
      });
    }

    ref.read(driverLocationProvider.notifier).updateSharing(false);
    ref.read(driverLocationProvider.notifier).updateETA(null);
    _saveSelections(myBus);
    if (showFeedback) {
      _showToast(DriverLocalizations.of(context)!.locationSharingStopped);
    }
  }

  Future<void> _handleRemoveAssignment(BusModel myBus) async {
    final repo = ref.read(busRepositoryProvider);
    try {
      await repo.deleteBus(myBus.id);
      ref.read(socketServiceProvider).sendBusListUpdate();
      await PersistenceService.remove('driver_bus_id');
      await PersistenceService.remove('driver_bus_number');
      await PersistenceService.remove('driver_route_id');
      if (!mounted) return;
      ref.read(driverMapStateProvider.notifier).setSelectedRoute(null);
      _showToast(DriverLocalizations.of(context)!.busAssignmentRemoved);
    } catch (e) {
      if (!mounted) return;
      _showToast(
        DriverLocalizations.of(context)!.removeAssignmentError(e.toString()),
        isError: true,
      );
    }
  }

  Future<void> _handleAcceptAssignment(BusModel bus) async {
    final repo = ref.read(busRepositoryProvider);
    try {
      final updateData = <String, dynamic>{
        'assignmentStatus': 'accepted',
        'status': 'on-time',
      };
      if (bus.tripType != null) {
        updateData['tripType'] = bus.tripType;
        await SecureStorageService.setDriverTripType(bus.tripType!);
      }
      await repo.updateBus(bus.id, updateData);
      ref.read(socketServiceProvider).sendBusListUpdate();
      if (mounted) {
        _showToast(DriverLocalizations.of(context)!.assignmentAccepted);
        // Auto-start location sharing
        await _startLocationSharing(bus);
        // Switch to Live Tracking tab
        ref.read(driverUiStateProvider.notifier).setBottomNavIndex(1);
      }
    } catch (e) {

      if (mounted) {
        _showToast(
          DriverLocalizations.of(context)!.acceptAssignmentError(e.toString()),
          isError: true,
        );
      }
    }
  }

  Future<void> _handleRejectAssignment(String busId) async {
    final repo = ref.read(busRepositoryProvider);
    try {
      await repo.updateBus(busId, {
        'driverId': null,
        'assignmentStatus': 'unassigned',
        'status': 'not-running',
      });
      ref.read(socketServiceProvider).sendBusListUpdate();
      if (mounted) {
        _showToast(DriverLocalizations.of(context)!.assignmentDeclined);
      }
    } catch (e) {
      if (mounted) {
        _showToast(
          DriverLocalizations.of(context)!.declineAssignmentError(e.toString()),
          isError: true,
        );
      }
    }
  }

  // Global Connectivity Banner is now handled globally in MaterialApp.router builder

  @override
  Widget build(BuildContext context) {
    debugPrint('[DriverDashboard] build() START');
    final userId = ref.watch(currentUserProvider.select((u) => u?.id));
    final collegeId = ref.watch(
      currentUserProvider.select((u) => u?.collegeId),
    );

    final mapTheme = Theme.of(context).extension<MapThemeExtension>();
    final startColor = mapTheme?.startStopColor ?? const Color(0xFF4CAF50);
    final stopColor =
        mapTheme?.intermediateStopColor ?? const Color(0xFFFF9800);
    final endColor = mapTheme?.endStopColor ?? const Color(0xFFE53935);

    _loadCustomStopMarkers(startColor, stopColor, endColor);

    if (userId == null || collegeId == null) {
      debugPrint(
        '[DriverDashboard] userId or collegeId is null, showing loader',
      );
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    debugPrint('[DriverDashboard] userId=$userId, collegeId=$collegeId');
    // Listen for bus changes to handle unassignment, reassignment, and teacher override
    ref.listen<AsyncValue<BusModel?>>(driverBusProvider(userId), (
      previous,
      next,
    ) {
      final oldBus = previous?.value;
      final newBus = next.value;

      // If bus ID changed (or bus was removed)
      if (oldBus?.id != newBus?.id) {
        // 1. Stop location sharing if it was active for the old bus
        if (_isSharing) {
          _stopLocationSharing(oldBus);
        }

        // 2. If new bus is pending or unassigned, force back to setup tab
        if (newBus == null || newBus.assignmentStatus == 'pending') {
          ref.read(driverUiStateProvider.notifier).setBottomNavIndex(0);
        }
      }

      // ── Teacher override detection (bus_updated fallback) ─────────────────
      // When the server emits 'bus_updated', driverBusProvider fires with the
      // updated BusModel. We compare trackingTeacherId to detect override
      // activation/deactivation even if the dedicated socket events are absent.
      final oldTeacherId = oldBus?.trackingTeacherId;
      final newTeacherId = newBus?.trackingTeacherId;

      if (oldTeacherId != newTeacherId) {
        if (newTeacherId != null && oldTeacherId == null) {
          // Override just activated
          _handleOverrideActivated();
        } else if (newTeacherId == null && oldTeacherId != null) {
          // Override just ended
          if (newBus != null) {
            _handleOverrideEnded(newBus);
          }
        }
      }

      // ── Assignment notification ──────────────────────────────────
      // Fire a local notification whenever the bus status transitions TO
      // 'pending' (coordinator just made an assignment). This covers:
      //   - First-time assignment (oldBus was null / unassigned)
      //   - Reassignment to a different bus
      // The stable notification ID (42) means the OS replaces the previous
      // assignment notification rather than stacking them.
      final wasAlreadyPending = oldBus?.assignmentStatus == 'pending';
      if (!wasAlreadyPending &&
          newBus != null &&
          newBus.assignmentStatus == 'pending') {
        final tripType = newBus.tripType ?? 'pickup';
        NotificationService.showAssignmentAlert(
          busNumber: newBus.busNumber,
          tripType: tripType,
        ).catchError((e) {
          AppLogger.e('[DriverDashboard] Assignment notification failed: $e');
        });
      }
    });


    final myBusAsync = ref.watch(driverBusProvider(userId));
    debugPrint(
      '[DriverDashboard] myBusAsync state: isLoading=${myBusAsync.isLoading}, hasValue=${myBusAsync.hasValue}, hasError=${myBusAsync.hasError}',
    );

    // Auto-resume location sharing if state was persisted
    // CRITICAL: Only auto-resume AFTER initialization is complete to prevent
    // Android from killing the process when foreground service starts too early
    ref.listen<AsyncValue<BusModel?>>(driverBusProvider(userId), (
      previous,
      next,
    ) {
      try {
        final bus = next.value;
        if (bus != null) {
          if (bus.tripType != null && bus.tripType != _storedTripType) {
            _storedTripType = bus.tripType;
            SecureStorageService.setDriverTripType(bus.tripType!);
          }
          debugPrint(
            '[DriverDashboard] Bus data received: ${bus.busNumber}, assignmentStatus=${bus.assignmentStatus}, tripType=${bus.tripType}',
          );


          // 2. Handle auto-resume location sharing (ONLY after init and status is accepted)
          if (_isSharing &&
              _hasInitialized &&
              bus.assignmentStatus == 'accepted') {
            final locationService = ref.read(locationServiceProvider);
            if (!locationService.isTracking) {
              debugPrint('[DriverDashboard] Auto-resuming location sharing...');
              // Delay slightly to ensure app is fully ready
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  _startLocationSharing(bus, silent: true);
                }
              });
            }
          }

          // Handle route selection / mid-trip coordinator route change.
          //
          // We fire in two cases:
          //   a) No route selected yet (initial assignment or app restart).
          //   b) The bus.routeId changed to a different route than what the
          //      driver currently has selected — i.e. a coordinator changed
          //      the active trip route from EditBusScreen while the trip was
          //      already in progress.
          //
          // Case (b) is the fix: the old guard `currentRoute == null` caused
          // coordinator-initiated route changes to be silently dropped when
          // the driver was already tracking.
          final currentRoute = ref.read(driverMapStateProvider).selectedRoute;
          final routeChanged =
              bus.routeId != null && currentRoute?.id != bus.routeId;
          if (routeChanged) {
            debugPrint(
              '[DriverDashboard] Route ${currentRoute == null ? "initial selection" : "changed by coordinator"}: routeId=${bus.routeId}',
            );
            final routesAsync = ref.read(collegeRoutesProvider(collegeId));
            final routes = routesAsync.valueOrNull;
            if (routes != null) {
              try {
                final route = routes.firstWhere((r) => r.id == bus.routeId);
                ref
                    .read(driverMapStateProvider.notifier)
                    .setSelectedRoute(route);
                // Persist the coordinator-assigned route so it survives restart.
                // Fire-and-forget: the listener callback is synchronous, so we
                // intentionally do not await here.
                // ignore: unawaited_futures
                SecureStorageService.setDriverRouteId(route.id);
              } catch (e) {
                AppLogger.e('Error matching route selection: $e');
              }
            }
          }
        } else {
          debugPrint('[DriverDashboard] Bus data is null (no assignment)');
        }
      } catch (e, stack) {
        debugPrint('[DriverDashboard] ERROR in driverBus listener: $e');
        debugPrint('[DriverDashboard] Stack: $stack');
      }
    });

    // Match selection if routes load after bus
    ref.listen(collegeRoutesProvider(collegeId), (previous, next) {
      try {
        final currentRoute = ref.read(driverMapStateProvider).selectedRoute;
        if (currentRoute == null) {
          final bus = ref.read(driverBusProvider(userId)).valueOrNull;
          if (bus != null && bus.routeId != null) {
            next.whenData((routes) {
              try {
                final route = routes.firstWhere((r) => r.id == bus.routeId);
                ref
                    .read(driverMapStateProvider.notifier)
                    .setSelectedRoute(route);
              } catch (e) {
                AppLogger.e('Error matching route from route listener: $e');
              }
            });
          }
        }
      } catch (e, stack) {
        debugPrint('[DriverDashboard] ERROR in routes listener: $e');
        debugPrint('[DriverDashboard] Stack: $stack');
      }
    });

    final routesAsync = ref.watch(collegeRoutesProvider(collegeId));
    final busNumbersAsync = ref.watch(busNumbersProvider(collegeId));

    final rawBus = myBusAsync.valueOrNull;
    final myBus = (rawBus != null && rawBus.tripType == null && _storedTripType != null)
        ? rawBus.copyWith(tripType: _storedTripType)
        : rawBus;
    debugPrint(
      '[DriverDashboard] myBus=${myBus?.busNumber}, assignmentStatus=${myBus?.assignmentStatus}, tripType=${myBus?.tripType}',
    );


    final bottomNavIndex = ref.watch(
      driverUiStateProvider.select((s) => s.bottomNavIndex),
    );
    final isTabletOrDesktop = context.isTabletLayout || context.isDesktopLayout;

    if (isTabletOrDesktop) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            Row(
              children: [
                // Left navigation rail
                NavigationRail(
                  selectedIndex: bottomNavIndex,
                  onDestinationSelected: (index) {
                    ref
                        .read(driverUiStateProvider.notifier)
                        .setBottomNavIndex(index);
                  },
                  backgroundColor: Theme.of(context).cardColor,
                  labelType: NavigationRailLabelType.all,
                  selectedIconTheme: IconThemeData(
                    color: _getDriverActiveColor(context),
                  ),
                  destinations: [
                    NavigationRailDestination(
                      icon: const Icon(Icons.settings_outlined),
                      selectedIcon: const Icon(Icons.settings),
                      label: Text(DriverLocalizations.of(context)!.busSetupTab),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.map_outlined),
                      selectedIcon: const Icon(Icons.map),
                      label: Text(
                        DriverLocalizations.of(context)!.liveTrackingTab,
                      ),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: Text('Profile'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1, thickness: 1),

                // Content pane
                if (bottomNavIndex == 0)
                  Expanded(
                    flex: 4,
                    child: SafeArea(
                      child: _buildBusSetupTab(
                        myBus,
                        routesAsync,
                        busNumbersAsync,
                      ),
                    ),
                  )
                else if (bottomNavIndex == 2)
                  const Expanded(
                    flex: 4,
                    child: SafeArea(child: ProfileScreen()),
                  )
                else
                  Expanded(
                    flex: 4,
                    child: SafeArea(
                      child: myBusAsync.isLoading && !myBusAsync.hasValue
                          ? const BusAssignmentSkeleton()
                          : Consumer(
                              builder: (context, ref, child) {
                                final currentLocation = ref.watch(
                                  driverLocationProvider.select(
                                    (s) => s.currentLocation,
                                  ),
                                );
                                final isSharing = ref.watch(
                                  driverLocationProvider.select(
                                    (s) => s.isSharing,
                                  ),
                                );
                                final selectedRoute = ref.watch(
                                  driverMapStateProvider.select(
                                    (s) => s.selectedRoute,
                                  ),
                                );
                                return LiveTrackingControlPanel(
                                  bus: myBus,
                                  route: selectedRoute,
                                  isSharing: isSharing,
                                  currentLocation: currentLocation,
                                  onToggleSharing: () =>
                                      _toggleLocationSharing(myBus),
                                  onCompleteTrip: () =>
                                      _handleTripComplete(myBus),
                                );
                              },
                            ),
                    ),
                  ),

                // Right Pane: Active Map View (always visible on tablet/desktop)
                Expanded(
                  flex: 6,
                  child: Container(
                    color: Theme.of(context).cardColor,
                    child: _buildLiveTrackingTab(myBus),
                  ),
                ),
              ],
            ),
            const SizedBox.shrink(),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Main Content â€” always inside RepaintBoundary so the nav bar's
          // glass shader key is always attached regardless of loading state.
          RepaintBoundary(
            key: _backgroundKey,
            child: ColoredBox(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: (myBusAsync.isLoading && !myBusAsync.hasValue)
                  ? const SafeArea(
                      bottom: false,
                      child: BusAssignmentSkeleton(),
                    )
                  : IndexedStack(
                      index: bottomNavIndex,
                      children: [
                        SafeArea(
                          bottom: false,
                          child: _buildBusSetupTab(
                            myBus,
                            routesAsync,
                            busNumbersAsync,
                          ),
                        ),
                        SafeArea(
                          bottom: false,
                          child: _buildLiveTrackingTab(myBus),
                        ),
                        const ProfileScreen(),
                      ],
                    ),
            ),
          ),

          const SizedBox.shrink(),

          // Floating bottom navigation bar placed directly in Stack overlay
          Align(
            alignment: Alignment.bottomCenter,
            child: CurvedBottomNavBar(
              currentIndex: bottomNavIndex,
              onTap: (index) {
                ref
                    .read(driverUiStateProvider.notifier)
                    .setBottomNavIndex(index);
              },
              activeColor: _getDriverActiveColor(context),
              activeColors: [
                AppColors.turkishBlue,
                AppColors.success,
                Colors.purple.shade400,
              ],
              backgroundColor: Theme.of(context).cardColor,
              backgroundKey: _backgroundKey,
              items: [
                CurvedBottomNavItem(
                  icon: Icons.settings_outlined,
                  label: DriverLocalizations.of(context)!.busSetupTab,
                ),
                CurvedBottomNavItem(
                  icon: Icons.map_outlined,
                  label: DriverLocalizations.of(context)!.liveTrackingTab,
                ),
                const CurvedBottomNavItem(
                  icon: Icons.person_outline,
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusSetupTab(
    BusModel? myBus,
    AsyncValue<List<RouteModel>> routesAsync,
    AsyncValue<List<String>> busNumbersAsync,
  ) {
    return DriverBusSetupTab(
      myBus: myBus,
      routesAsync: routesAsync,
      busNumbersAsync: busNumbersAsync,
      onRemoveAssignment: () => _handleRemoveAssignment(myBus!),
      onRejectAssignment: (busId) => _handleRejectAssignment(busId),
      onAcceptAssignment: (bus) => _handleAcceptAssignment(bus),
    );
  }

  // _buildPendingAssignmentUI is now inside DriverBusSetupTab.
  // Keeping this comment as a tombstone so git history is clear.



  Future<void> _handleTripComplete(BusModel? myBus) async {
    if (myBus == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Trip?'),
        content: const Text(
          'This will mark your trip as finished and unassign you from this bus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text(
              'Complete Trip',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final repo = ref.read(busRepositoryProvider);
      try {
        _stopLocationSharing(myBus, showFeedback: false); // Stop tracking first
        // unassignDriverFromBus logic: set driverId to null, etc.
        await repo.updateBus(myBus.id, {
          'driverId': null,
          'assignmentStatus': 'unassigned',
          'status': 'not-running',
          'routeId': null,
        });

        ref.read(socketServiceProvider).sendBusListUpdate();

        await PersistenceService.remove('driver_bus_id');
        await PersistenceService.remove('driver_bus_number');
        await PersistenceService.remove('driver_route_id');

        if (mounted) {
          ref.read(driverMapStateProvider.notifier).setSelectedRoute(null);

          _showToast(
            'Trip Completed: Good job! You have been unassigned from the bus.',
          );
        }
      } catch (e) {
        if (mounted) {
          _showToast('Error completing trip: $e', isError: true);
        }
      }
    }
  }

  Widget _buildLiveTrackingTab(BusModel? myBus) {
    return DriverLiveTrackingTab(
      myBus: myBus,
      busIcon: _busIcon,
      startStopIcon: _startStopIcon,
      intermediateStopIcon: _intermediateStopIcon,
      endStopIcon: _endStopIcon,
      onToggleSharing: () => _toggleLocationSharing(myBus),
      onCompleteTrip: () => _handleTripComplete(myBus),
    );
  }


  Color _getDriverActiveColor(BuildContext context) {
    final bottomNavIndex = ref.read(driverUiStateProvider).bottomNavIndex;
    switch (bottomNavIndex) {
      case 0:
        return AppColors.turkishBlue;
      case 1:
        return AppColors.success;
      case 2:
        return Colors.purple.shade400;
      default:
        return AppColors.turkishBlue;
    }
  }

  // _findClosestPointIndex is now in route_math_utils.dart.
  // The _getDriverActiveColor method below is kept as it's used by the nav bar.
}

// PulsatingDot class removed
