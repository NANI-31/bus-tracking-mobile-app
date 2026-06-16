import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:collegebus/features/route/domain/route_model.dart';
import 'package:collegebus/core/constants/constants.dart';

import 'package:collegebus/core/utils/app_logger.dart';
import 'widgets/location_display.dart';

import 'widgets/bus_assignment_card.dart';
import 'widgets/live_tracking_control_panel.dart';
import 'package:collegebus/widgets/common/common_map_view.dart';
import 'package:collegebus/shared/widgets/navigation/curved_bottom_nav_bar.dart';
import 'dart:async';
import 'package:collegebus/shared/widgets/success_modal.dart';
import 'package:collegebus/shared/widgets/sos_button.dart';
import 'package:geolocator/geolocator.dart';
import 'package:collegebus/features/user/presentation/screens/profile_screen.dart';

import 'package:collegebus/core/services/directions_result.dart';
import 'widgets/voice_message_button.dart';
import 'package:collegebus/features/driver/application/driver_location_provider.dart';
import 'package:collegebus/features/driver/application/driver_map_provider.dart';
import 'package:collegebus/features/driver/application/driver_ui_provider.dart';
import 'package:collegebus/core/utils/map_marker_helper.dart';
import 'package:collegebus/shared/widgets/shimmer_skeletons.dart';
import 'package:collegebus/shared/widgets/api_error_modal.dart';


class DriverDashboard extends ConsumerStatefulWidget {
  const DriverDashboard({super.key});

  @override
  ConsumerState<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends ConsumerState<DriverDashboard>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  bool _isSharing = false;
  bool _hasInitialized = false; // Prevent auto-resume during first build

  DateTime? _lastDeviationAlertTime;
  Timer? _bannerDelayTimer;
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
      final icon = await MapMarkerHelper.createBusMarker();
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
    _loadBusIcon();
    _loadCustomStopMarkers(
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFFE53935),
    );
    _getCurrentLocation();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('[DriverDashboard] postFrameCallback - marking initialized');
      _hasInitialized = true;
      ref.read(driverLocationProvider.notifier).updateSharing(_isSharing);
      final socketService = ref.read(socketServiceProvider);
      final user = ref.read(currentUserProvider);
      if (user != null) {
        socketService.joinCollege(user.collegeId);
      }
    });
    debugPrint('[DriverDashboard] initState END');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bannerDelayTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AppLogger.i(
        '[DriverDashboard] App resumed. Ensuring socket connection...',
      );
      ref.read(socketServiceProvider).ensureConnected();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Cancel any pending banner timer when going to background
      _bannerDelayTimer?.cancel();
      ref.read(driverUiStateProvider.notifier).setShowDisconnectedBanner(false);
    }
  }

  // ... existing code ...

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

    // Update bus status to live
    repo.updateBus(myBus.id, {'status': 'on-time'}).catchError((e) {
      AppLogger.e('Failed to update bus status: $e');
    });

    locationService.startLocationTracking(
      onLocationUpdate: (position) {
        socketService.updateLocation({
          'busId': myBus.id,
          'collegeId': user!.collegeId,
          'location': {'lat': position.latitude, 'lng': position.longitude},
          'speed': position.speed,
          'heading': position.heading,
        });
        
        final latLng = LatLng(position.latitude, position.longitude);
        ref.read(driverLocationProvider.notifier).updateLocation(
          latLng,
          heading: position.heading,
          speed: position.speed,
        );
        _checkRouteDeviation(position, myBus);
      },
    );

    ref.read(driverLocationProvider.notifier).updateSharing(true);
    _saveSelections(myBus);

    if (!mounted) return;
  }

  Future<void> _saveSelections(BusModel? myBus) async {
    if (myBus != null) {
      await SecureStorageService.setDriverBusId(myBus.id);
      await SecureStorageService.setDriverBusNumber(myBus.busNumber);
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
    final location = await locationService.getCurrentLocation();
    if (location != null) {
      ref.read(driverLocationProvider.notifier).updateLocation(location);
    }
  }

  LatLng _getMockCoordinateForLocation(String location) {
    final currentLoc = ref.read(driverLocationProvider).currentLocation;
    final base = currentLoc ?? const LatLng(17.385, 78.4867);
    final hash = location.hashCode;
    return LatLng(
      base.latitude + (hash % 100) / 10000.0,
      base.longitude + ((hash ~/ 100) % 100) / 10000.0,
    );
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
    final selectedRoute = ref.read(driverMapStateProvider).selectedRoute;
    if (selectedRoute == null) return;

    // Build ordered list of points: Start -> Stops -> End
    final points = [
      LatLng(selectedRoute.startPoint.lat, selectedRoute.startPoint.lng),
      ...selectedRoute.stopPoints.map((s) => LatLng(s.lat, s.lng)),
      LatLng(selectedRoute.endPoint.lat, selectedRoute.endPoint.lng),
    ];

    double minDistance = double.infinity;

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final dist = _distanceToSegment(
        LatLng(position.latitude, position.longitude),
        p1,
        p2,
      );
      if (dist < minDistance) minDistance = dist;
    }

    // Threshold: 200 meters
    if (minDistance > 200) {
      final now = DateTime.now();
      if (_lastDeviationAlertTime == null ||
          now.difference(_lastDeviationAlertTime!) >
              const Duration(minutes: 1)) {
        _lastDeviationAlertTime = now;
        ApiErrorModal.show(
          context: context,
          error: DriverLocalizations.of(context)!.offRouteAlert(minDistance.toInt()),
        );
      }
    }

    // ETA Calculation
    _calculateETA(position, myBus);
  }

  void _calculateETA(Position position, BusModel? myBus) {
    final selectedRoute = ref.read(driverMapStateProvider).selectedRoute;
    if (selectedRoute == null) return;

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

    if (nextStop != null) {
      // average speed 30km/h = ~8.33 m/s
      final timeSeconds = minDistance / 8.33;
      final timeMinutes = (timeSeconds / 60).ceil();

      final etaStr = DriverLocalizations.of(
        context,
      )!.etaToNextStop(timeMinutes, nextStop.name);
      ref.read(driverLocationProvider.notifier).updateETA(etaStr);
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

  void _stopLocationSharing(BusModel? myBus) {
    final locationService = ref.read(locationServiceProvider);
    final repo = ref.read(busRepositoryProvider);

    locationService.stopLocationTracking();

    // Revert bus status to offline
    if (myBus != null) {
      repo.updateBus(myBus.id, {'status': 'not-running'}).catchError((e) {
        AppLogger.e('Failed to update bus status: $e');
      });
    }

    ref.read(driverLocationProvider.notifier).updateSharing(false);
    ref.read(driverLocationProvider.notifier).updateETA(null);
    _saveSelections(myBus);
    SuccessModal.show(
      context: context,
      title: 'Location Sharing',
      message: DriverLocalizations.of(context)!.locationSharingStopped,
      primaryActionText: 'OK',
    );
  }

  Future<void> _handleRemoveAssignment(BusModel myBus) async {
    final repo = ref.read(busRepositoryProvider);
    try {
      await repo.deleteBus(myBus.id);
      await PersistenceService.remove('driver_bus_id');
      await PersistenceService.remove('driver_bus_number');
      await PersistenceService.remove('driver_route_id');
      if (!mounted) return;
      ref.read(driverMapStateProvider.notifier).setSelectedRoute(null);
      SuccessModal.show(
        context: context,
        title: 'Assignment Removed',
        message: DriverLocalizations.of(context)!.busAssignmentRemoved,
        primaryActionText: 'OK',
      );
    } catch (e) {
      if (!mounted) return;
      ApiErrorModal.show(
        context: context,
        error: DriverLocalizations.of(context)!.removeAssignmentError(e.toString()),
      );
    }
  }

  Future<void> _handleAcceptAssignment(BusModel bus) async {
    final repo = ref.read(busRepositoryProvider);
    try {
      await repo.updateBus(bus.id, {'assignmentStatus': 'accepted'});
      if (mounted) {
        SuccessModal.show(
          context: context,
          title: 'Assignment Accepted',
          message: DriverLocalizations.of(context)!.assignmentAccepted,
          primaryActionText: 'OK',
        );
        // Auto-start location sharing
        await _startLocationSharing(bus);
        // Switch to Live Tracking tab
        ref.read(driverUiStateProvider.notifier).setBottomNavIndex(1);
      }
    } catch (e) {
      if (mounted) {
        ApiErrorModal.show(
          context: context,
          error: DriverLocalizations.of(context)!.acceptAssignmentError(e.toString()),
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
      if (mounted) {
        SuccessModal.show(
          context: context,
          title: 'Assignment Declined',
          message: DriverLocalizations.of(context)!.assignmentDeclined,
          primaryActionText: 'OK',
        );
      }
    } catch (e) {
      if (mounted) {
        ApiErrorModal.show(
          context: context,
          error: DriverLocalizations.of(context)!.declineAssignmentError(e.toString()),
        );
      }
    }
  }

  Widget _buildConnectivityBanner() {
    return Consumer(
      builder: (context, ref, child) {
        final socketService = ref.watch(socketServiceProvider);
        final isConnected = socketService.isConnected;
        final isConnecting = socketService.isConnecting;
        final showDisconnectedBanner = ref.watch(driverUiStateProvider.select((s) => s.showDisconnectedBanner));

        // If connected, hide banner and cancel any pending timer
        if (isConnected && !isConnecting) {
          _bannerDelayTimer?.cancel();
          if (showDisconnectedBanner) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(driverUiStateProvider.notifier).setShowDisconnectedBanner(false);
            });
          }
          return const SizedBox.shrink();
        }

        // If just came back from background or briefly disconnected,
        // add a 3-second grace period before showing the banner
        if (!showDisconnectedBanner && !isConnecting) {
          _bannerDelayTimer?.cancel();
          _bannerDelayTimer = Timer(const Duration(seconds: 3), () {
            if (mounted && !socketService.isConnected) {
              ref.read(driverUiStateProvider.notifier).setShowDisconnectedBanner(true);
            }
          });
          return const SizedBox.shrink();
        }

        // Show "Connecting..." immediately but "Disconnected" after grace period
        if (!isConnecting && !showDisconnectedBanner) {
          return const SizedBox.shrink();
        }

        return Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 20,
          right: 20,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * -20),
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: isConnecting ? Colors.amber : Colors.red,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: (isConnecting ? Colors.amber : Colors.red)
                        .withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                isConnecting ? "Connecting..." : "Server Disconnected",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isConnecting ? Colors.black87 : Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    debugPrint('[DriverDashboard] build() START');
    final userId = ref.watch(currentUserProvider.select((u) => u?.id));
    final collegeId = ref.watch(
      currentUserProvider.select((u) => u?.collegeId),
    );


    final mapTheme = Theme.of(context).extension<MapThemeExtension>();
    final startColor = mapTheme?.startStopColor ?? const Color(0xFF4CAF50);
    final stopColor = mapTheme?.intermediateStopColor ?? const Color(0xFFFF9800);
    final endColor = mapTheme?.endStopColor ?? const Color(0xFFE53935);

    _loadCustomStopMarkers(startColor, stopColor, endColor);




    if (userId == null || collegeId == null) {
      debugPrint(
        '[DriverDashboard] userId or collegeId is null, showing loader',
      );
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    debugPrint('[DriverDashboard] userId=$userId, collegeId=$collegeId');
    // Listen for bus changes to handle unassignment or reassignment
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
          debugPrint(
            '[DriverDashboard] Bus data received: ${bus.busNumber}, assignmentStatus=${bus.assignmentStatus}',
          );

          // 2. Handle auto-resume location sharing (ONLY after init and status is accepted)
          if (_isSharing && _hasInitialized && bus.assignmentStatus == 'accepted') {
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

          // 2. Handle initial route selection if matching preference
          final currentRoute = ref.read(driverMapStateProvider).selectedRoute;
          if (currentRoute == null && bus.routeId != null) {
            debugPrint(
              '[DriverDashboard] Matching route for routeId=${bus.routeId}',
            );
            final routesAsync = ref.read(collegeRoutesProvider(collegeId));
            final routes = routesAsync.valueOrNull;
            if (routes != null) {
              try {
                final route = routes.firstWhere((r) => r.id == bus.routeId);
                ref.read(driverMapStateProvider.notifier).setSelectedRoute(route);
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
                ref.read(driverMapStateProvider.notifier).setSelectedRoute(route);
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

    final myBus = myBusAsync.valueOrNull;
    debugPrint(
      '[DriverDashboard] myBus=${myBus?.busNumber}, assignmentStatus=${myBus?.assignmentStatus}',
    );

    final bottomNavIndex = ref.watch(driverUiStateProvider.select((s) => s.bottomNavIndex));
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
                    ref.read(driverUiStateProvider.notifier).setBottomNavIndex(index);
                  },
                  backgroundColor: Theme.of(context).cardColor,
                  labelType: NavigationRailLabelType.all,
                  selectedIconTheme: IconThemeData(color: _getDriverActiveColor(context)),
                  destinations: [
                    NavigationRailDestination(
                      icon: const Icon(Icons.settings_outlined),
                      selectedIcon: const Icon(Icons.settings),
                      label: Text(DriverLocalizations.of(context)!.busSetupTab),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.map_outlined),
                      selectedIcon: const Icon(Icons.map),
                      label: Text(DriverLocalizations.of(context)!.liveTrackingTab),
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
                      child: _buildBusSetupTab(myBus, routesAsync, busNumbersAsync),
                    ),
                  )
                else if (bottomNavIndex == 2)
                  const Expanded(
                    flex: 4,
                    child: SafeArea(
                      child: ProfileScreen(),
                    ),
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
                                  onToggleSharing: () => _toggleLocationSharing(myBus),
                                  onCompleteTrip: () => _handleTripComplete(myBus),
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
            SafeArea(child: _buildConnectivityBanner()),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Main Content — always inside RepaintBoundary so the nav bar's
          // glass shader key is always attached regardless of loading state.
          RepaintBoundary(
            key: _backgroundKey,
            child: ColoredBox(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: (myBusAsync.isLoading && !myBusAsync.hasValue)
                  ? const SafeArea(bottom: false, child: BusAssignmentSkeleton())
                  : IndexedStack(
                      index: bottomNavIndex,
                      children: [
                        SafeArea(bottom: false, child: _buildBusSetupTab(myBus, routesAsync, busNumbersAsync)),
                        SafeArea(bottom: false, child: _buildLiveTrackingTab(myBus)),
                        const ProfileScreen(),
                      ],
                    ),
            ),
          ),

          // Connectivity Banner
          SafeArea(child: _buildConnectivityBanner()),

          // Floating bottom navigation bar placed directly in Stack overlay
          Align(
            alignment: Alignment.bottomCenter,
            child: CurvedBottomNavBar(
              currentIndex: bottomNavIndex,
              onTap: (index) {
                ref.read(driverUiStateProvider.notifier).setBottomNavIndex(index);
              },
              activeColor: _getDriverActiveColor(context),
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
    if (myBus != null && myBus.assignmentStatus == 'pending') {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          children: [
            _buildPendingAssignmentUI(myBus),
            const BottomNavSpacer(),
          ],
        ),
      );
    }

    final designTheme = Theme.of(context).extension<DesignSystemThemeExtension>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      child: Column(
        children: [
          const LocationDisplay(),
          if (myBus == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.paddingLarge),
              decoration: designTheme?.cardDecoration ?? BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).disabledColor.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.assignment_ind_outlined,
                      size: 56,
                      color: Theme.of(context).disabledColor.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Assignments Yet',
                    style: designTheme?.cardHeaderStyle ?? TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You are not currently assigned to any bus or route. Please contact your administrator or bus coordinator to receive an assignment.',
                    textAlign: TextAlign.center,
                    style: designTheme?.cardBodyStyle ?? TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            )
          else
            BusAssignmentCard(
              bus: myBus,
              route: ref.watch(driverMapStateProvider.select((s) => s.selectedRoute)),
              onRemove: () => _handleRemoveAssignment(myBus),
            ),
          const BottomNavSpacer(),
        ],
      ),
    );
  }


  Widget _buildPendingAssignmentUI(BusModel bus) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Glossy Gradient Colors
    final gradientColors = isDark
        ? [const Color(0xFF2E3192), const Color(0xFF1BFFFF)]
        : [const Color(0xFF667EEA), const Color(0xFF764BA2)];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Glassy Overlay / Decoration
          Positioned(
            top: -20,
            right: -20,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: CircleAvatar(
              radius: 80,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
            ),
          ),

          VStack([
            HStack([
              const Icon(
                Icons.directions_bus_filled_rounded,
                color: Colors.white,
                size: 28,
              ),
              12.widthBox,
              'New Trip Assignment'.text.white.xl.bold.make(),
            ]).pOnly(bottom: 24),

            'Bus Number'.text.white.make().opacity(value: 0.8),
            bus.busNumber.text.xl6.white.bold.make().pOnly(bottom: 32),

            HStack([
              // Reject Button (Glassy Outlined)
              OutlinedButton(
                onPressed: () => _handleRejectAssignment(bus.id),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: 'Decline'.text.make(),
              ).expand(),

              16.widthBox,

              // Accept Button (Solid White)
              ElevatedButton(
                onPressed: () => _handleAcceptAssignment(bus),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: gradientColors.first,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: 'START TRIP'.text.bold.make(),
              ).expand(),
            ]),
          ]).p(24),
        ],
      ),
    );
  }

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
        _stopLocationSharing(myBus); // Stop tracking first
        // unassignDriverFromBus logic: set driverId to null, etc.
        await repo.updateBus(myBus.id, {
          'driverId': null,
          'assignmentStatus': 'unassigned',
          'status': 'not-running',
          'routeId': null,
        });

        await PersistenceService.remove('driver_bus_id');
        await PersistenceService.remove('driver_bus_number');
        await PersistenceService.remove('driver_route_id');

        if (mounted) {
          ref.read(driverMapStateProvider.notifier).setSelectedRoute(null);

          SuccessModal.show(
            context: context,
            title: 'Trip Completed',
            message: 'Good job! You have been unassigned from the bus.',
            primaryActionText: 'OK',
          );
        }
      } catch (e) {
        if (mounted) {
          ApiErrorModal.show(
            context: context,
            error: 'Error completing trip: $e',
          );
        }
      }
    }
  }

  Widget _buildLiveTrackingTab(BusModel? myBus) {
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

                final mapTheme = Theme.of(context).extension<MapThemeExtension>();
                final routeColorTheme = mapTheme?.routeColor ?? const Color(0xFF1565C0);

                // 1. Build stop markers dynamically
                final stopMarkers = <Marker>{};
                if (route != null) {
                  if (route.startPoint.lat != 0 && route.startPoint.lng != 0) {
                    stopMarkers.add(Marker(
                      markerId: const MarkerId('dstop_start'),
                      position: LatLng(route.startPoint.lat, route.startPoint.lng),
                      icon: _startStopIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                      infoWindow: InfoWindow(title: 'Start: ${route.startPoint.name}'),
                      anchor: const Offset(0.5, 0.5),
                      zIndexInt: 1,
                    ));
                  }
                  for (int i = 0; i < route.stopPoints.length; i++) {
                    final stop = route.stopPoints[i];
                    if (stop.lat == 0 && stop.lng == 0) continue;
                    stopMarkers.add(Marker(
                      markerId: MarkerId('dstop_$i'),
                      position: LatLng(stop.lat, stop.lng),
                      icon: _intermediateStopIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                      infoWindow: InfoWindow(title: 'Stop ${i + 1}: ${stop.name}'),
                      anchor: const Offset(0.5, 0.5),
                      zIndexInt: 1,
                    ));
                  }
                  if (route.endPoint.lat != 0 && route.endPoint.lng != 0) {
                    stopMarkers.add(Marker(
                      markerId: const MarkerId('dstop_end'),
                      position: LatLng(route.endPoint.lat, route.endPoint.lng),
                      icon: _endStopIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                      infoWindow: InfoWindow(title: 'End: ${route.endPoint.name}'),
                      anchor: const Offset(0.5, 0.5),
                      zIndexInt: 1,
                    ));
                  }
                }

                // 2. Build polylines dynamically
                final polylines = <Polyline>{};
                if (result != null && result.hasRoute) {
                  polylines.addAll({
                    Polyline(
                      polylineId: const PolylineId('driver_route_glow'),
                      points: result.polylinePoints,
                      color: routeColorTheme.withValues(alpha: 0.3),
                      width: 10,
                      startCap: Cap.roundCap,
                      endCap: Cap.roundCap,
                      geodesic: true,
                    ),
                    Polyline(
                      polylineId: const PolylineId('driver_route'),
                      points: result.polylinePoints,
                      color: routeColorTheme,
                      width: 6,
                      startCap: Cap.roundCap,
                      endCap: Cap.roundCap,
                      geodesic: true,
                    ),
                  });
                }

                final mapMarkers = {...stopMarkers};
                if (mapMarkers.isEmpty && route != null) {
                  // Fallback: draw basic markers if stopMarkers are empty
                  final startCoord = route.startPoint.lat != 0
                      ? LatLng(route.startPoint.lat, route.startPoint.lng)
                      : _getMockCoordinateForLocation(route.startPoint.name);
                  mapMarkers.add(Marker(
                    markerId: const MarkerId('start'),
                    position: startCoord,
                    infoWindow: InfoWindow(
                      title: DriverLocalizations.of(context)!.startPointMarker(route.startPoint.name),
                    ),
                    icon: _startStopIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                    anchor: const Offset(0.5, 0.5),
                  ));
                  
                  final endCoord = route.endPoint.lat != 0
                      ? LatLng(route.endPoint.lat, route.endPoint.lng)
                      : _getMockCoordinateForLocation(route.endPoint.name);
                  mapMarkers.add(Marker(
                    markerId: const MarkerId('end'),
                    position: endCoord,
                    infoWindow: InfoWindow(
                      title: DriverLocalizations.of(context)!.endPointMarker(route.endPoint.name),
                    ),
                    icon: _endStopIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                    anchor: const Offset(0.5, 0.5),
                  ));

                  for (var i = 0; i < route.stopPoints.length; i++) {
                    final stop = route.stopPoints[i];
                    final coord = stop.lat != 0
                        ? LatLng(stop.lat, stop.lng)
                        : _getMockCoordinateForLocation(stop.name);
                    mapMarkers.add(Marker(
                      markerId: MarkerId('stop_$i'),
                      position: coord,
                      infoWindow: InfoWindow(
                        title: DriverLocalizations.of(context)!.stopPointMarker(i + 1, stop.name),
                      ),
                      icon: _intermediateStopIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                      anchor: const Offset(0.5, 0.5),
                    ));
                  }
                }

                if (currentLocation != null) {
                  mapMarkers.add(
                    Marker(
                      markerId: const MarkerId('driver_bus'),
                      position: currentLocation,
                      icon: _busIcon ?? BitmapDescriptor.defaultMarker,
                      rotation: heading,
                      anchor: const Offset(0.5, 0.5),
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
                  onToggleSharing: () => _toggleLocationSharing(myBus),
                  onCompleteTrip: () => _handleTripComplete(myBus),
                );
              },
            ),
          ],
        ),
        // Next Stop ETA Card (navigation style)
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

            // Compute next stop ETA from directions
            String? directionsETA;
            if (result != null && currentLocation != null) {
              directionsETA = _computeNextStopETAFromDirections(
                currentLocation,
                selectedRoute,
                result,
              );
            }

            final displayETA = directionsETA ?? (nextStopETA != null ? 'ETA: $nextStopETA' : null);
            if (displayETA == null) {
              return const SizedBox.shrink();
            }

            return Positioned(
              bottom: 240, // Above control panel
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
              if (myBus != null && myBus.assignmentStatus == 'accepted') ...[
                16.heightBox,
                const VoiceMessageButton(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Compute next stop ETA using Directions API leg data and driver progress.
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

    // Helper to find the closest index in the polyline points to a given target coordinate
    int findClosestIndex(LatLng target) {
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

    // Find the driver's current index along the polyline path
    final driverIdx = findClosestIndex(currentLocation);

    // Find the next upcoming stop
    int nextStopIndex = -1;
    for (int i = 0; i < allStops.length; i++) {
      final stop = allStops[i];
      if (stop.lat == 0 && stop.lng == 0) continue;
      
      final stopIdx = findClosestIndex(LatLng(stop.lat, stop.lng));
      // Stop is ahead of the driver's path index
      if (stopIdx > driverIdx) {
        nextStopIndex = i;
        break;
      }
    }

    if (nextStopIndex < 0) return null;

    final nextStop = allStops[nextStopIndex];
    
    // Distance remaining to the next stop in kilometers
    final remainingDistanceKm = Geolocator.distanceBetween(
      currentLocation.latitude,
      currentLocation.longitude,
      nextStop.lat,
      nextStop.lng,
    ) / 1000.0;

    int etaMin = 1;

    if (directionsResult.legs.isNotEmpty) {
      // The leg leading to the next stop
      final legIndex = (nextStopIndex - 1).clamp(0, directionsResult.legs.length - 1);
      final leg = directionsResult.legs[legIndex];
      
      if (leg.distanceKm > 0) {
        // Calculate proportion of the remaining leg
        final proportion = (remainingDistanceKm / leg.distanceKm).clamp(0.0, 1.0);
        etaMin = (proportion * leg.durationMin).round().clamp(1, leg.durationMin);
      } else {
        etaMin = leg.durationMin;
      }
    } else {
      // Fallback if no leg details are present (average speed 30km/h = 0.5km/min)
      etaMin = (remainingDistanceKm / 0.5).ceil().clamp(1, 120);
    }

    return 'Next: ${nextStop.name} · $etaMin min';
  }

  Color _getDriverActiveColor(BuildContext context) {
    final bottomNavIndex = ref.read(driverUiStateProvider).bottomNavIndex;
    switch (bottomNavIndex) {
      case 0:
        return Theme.of(context).primaryColor;
      case 1:
        return AppColors.success;
      case 2:
        return Colors.purple.shade400;
      default:
        return Theme.of(context).primaryColor;
    }
  }
}

// PulsatingDot class removed
