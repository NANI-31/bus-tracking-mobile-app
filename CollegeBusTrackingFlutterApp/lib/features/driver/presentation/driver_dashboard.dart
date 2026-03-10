import 'package:flutter/material.dart';
import 'package:collegebus/shared/widgets/logout_confirmation_dialog.dart';
import 'package:collegebus/shared/widgets/logout_loading_dialog.dart';
import 'package:collegebus/l10n/driver/app_localizations.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
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
import 'widgets/voice_message_button.dart';

class DriverDashboard extends ConsumerStatefulWidget {
  const DriverDashboard({super.key});

  @override
  ConsumerState<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends ConsumerState<DriverDashboard>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int _bottomNavIndex = 0;
  LatLng? _currentLocation;
  bool _isSharing = false;
  bool _hasInitialized = false; // Prevent auto-resume during first build

  // Selection state
  RouteModel? _selectedRoute;

  Set<Marker> _markers = {};

  DateTime? _lastDeviationAlertTime;
  String? _nextStopETA;
  Timer? _bannerDelayTimer;
  bool _showDisconnectedBanner = false;

  @override
  void initState() {
    super.initState();
    debugPrint('[DriverDashboard] initState START');
    WidgetsBinding.instance.addObserver(this);
    _isSharing = PersistenceService.getIsSharingLocation();
    debugPrint('[DriverDashboard] _isSharing from persistence: $_isSharing');
    _getCurrentLocation();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('[DriverDashboard] postFrameCallback - marking initialized');
      _hasInitialized = true;
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
      if (mounted) {
        setState(() {
          _showDisconnectedBanner = false;
        });
      }
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                DriverLocalizations.of(context)!.locationNotAvailable,
              ),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        // If we can't share, update state to false
        setState(() => _isSharing = false);
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
        if (mounted) {
          setState(
            () => _currentLocation = LatLng(
              position.latitude,
              position.longitude,
            ),
          );
          _checkRouteDeviation(position, myBus);
        }
      },
    );

    if (mounted) {
      setState(() => _isSharing = true);
    }
    _saveSelections(myBus);

    if (!mounted) return;
    if (!silent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            DriverLocalizations.of(context)!.locationSharingStarted,
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _saveSelections(BusModel? myBus) async {
    if (myBus != null) {
      await SecureStorageService.setDriverBusId(myBus.id);
      await SecureStorageService.setDriverBusNumber(myBus.busNumber);
      if (_selectedRoute != null) {
        await SecureStorageService.setDriverRouteId(_selectedRoute!.id);
      }
    }
    await PersistenceService.setIsSharingLocation(_isSharing);
  }

  Future<void> _getCurrentLocation() async {
    final locationService = ref.read(locationServiceProvider);
    final location = await locationService.getCurrentLocation();
    if (location != null && mounted) {
      setState(() => _currentLocation = location);
      _updateMarkers();
    }
  }

  void _updateMarkers() {
    if (_selectedRoute == null) {
      setState(() => _markers = {});
      return;
    }
    final markers = <Marker>{};
    final route = _selectedRoute!;
    final startCoord = route.startPoint.lat != 0
        ? LatLng(route.startPoint.lat, route.startPoint.lng)
        : _getMockCoordinateForLocation(route.startPoint.name);
    markers.add(
      Marker(
        markerId: const MarkerId('start'),
        position: startCoord,
        infoWindow: InfoWindow(
          title: DriverLocalizations.of(
            context,
          )!.startPointMarker(route.startPoint.name),
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );
    final endCoord = route.endPoint.lat != 0
        ? LatLng(route.endPoint.lat, route.endPoint.lng)
        : _getMockCoordinateForLocation(route.endPoint.name);
    markers.add(
      Marker(
        markerId: const MarkerId('end'),
        position: endCoord,
        infoWindow: InfoWindow(
          title: DriverLocalizations.of(
            context,
          )!.endPointMarker(route.endPoint.name),
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );
    for (var i = 0; i < route.stopPoints.length; i++) {
      final stop = route.stopPoints[i];
      final coord = stop.lat != 0
          ? LatLng(stop.lat, stop.lng)
          : _getMockCoordinateForLocation(stop.name);
      markers.add(
        Marker(
          markerId: MarkerId('stop_$i'),
          position: coord,
          infoWindow: InfoWindow(
            title: DriverLocalizations.of(
              context,
            )!.stopPointMarker(i + 1, stop.name),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
        ),
      );
    }
    setState(() {
      _markers = markers;
    });
  }

  LatLng _getMockCoordinateForLocation(String location) {
    final base = _currentLocation ?? const LatLng(17.385, 78.4867);
    final hash = location.hashCode;
    return LatLng(
      base.latitude + (hash % 100) / 10000.0,
      base.longitude + ((hash ~/ 100) % 100) / 10000.0,
    );
  }

  Future<void> _toggleLocationSharing(BusModel? myBus) async {
    if (!_isSharing) {
      if (myBus == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              DriverLocalizations.of(context)!.pleaseAssignBusFirst,
            ),
          ),
        );
        return;
      }
      _startLocationSharing(myBus);
    } else {
      _stopLocationSharing(myBus);
    }
  }

  void _checkRouteDeviation(Position position, BusModel? myBus) {
    if (_selectedRoute == null) return;

    // Build ordered list of points: Start -> Stops -> End
    final points = [
      LatLng(_selectedRoute!.startPoint.lat, _selectedRoute!.startPoint.lng),
      ..._selectedRoute!.stopPoints.map((s) => LatLng(s.lat, s.lng)),
      LatLng(_selectedRoute!.endPoint.lat, _selectedRoute!.endPoint.lng),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              DriverLocalizations.of(
                context,
              )!.offRouteAlert(minDistance.toInt()),
            ),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    // ETA Calculation
    _calculateETA(position, myBus);
  }

  void _calculateETA(Position position, BusModel? myBus) {
    if (_selectedRoute == null) return;

    double minDistance = double.infinity;
    RoutePoint? nextStop;

    for (final stop in _selectedRoute!.stopPoints) {
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

      if (mounted) {
        setState(() {
          _nextStopETA = DriverLocalizations.of(
            context,
          )!.etaToNextStop(timeMinutes, nextStop?.name ?? '');
        });
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

    if (mounted) {
      setState(() {
        _isSharing = false;
        _nextStopETA = null;
      });
    }
    _saveSelections(myBus);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(DriverLocalizations.of(context)!.locationSharingStopped),
      ),
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
      setState(() {
        _selectedRoute = null;
      });
      _updateMarkers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(DriverLocalizations.of(context)!.busAssignmentRemoved),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            DriverLocalizations.of(
              context,
            )!.removeAssignmentError(e.toString()),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleAcceptAssignment(BusModel bus) async {
    final repo = ref.read(busRepositoryProvider);
    try {
      await repo.updateBus(bus.id, {'assignmentStatus': 'accepted'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(DriverLocalizations.of(context)!.assignmentAccepted),
            backgroundColor: AppColors.success,
          ),
        );
        // Auto-start location sharing
        await _startLocationSharing(bus);
        // Switch to Live Tracking tab
        setState(() {
          _bottomNavIndex = 1;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              DriverLocalizations.of(
                context,
              )!.acceptAssignmentError(e.toString()),
            ),
            backgroundColor: AppColors.error,
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(DriverLocalizations.of(context)!.assignmentDeclined),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              DriverLocalizations.of(
                context,
              )!.declineAssignmentError(e.toString()),
            ),
            backgroundColor: AppColors.error,
          ),
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

        // If connected, hide banner and cancel any pending timer
        if (isConnected && !isConnecting) {
          _bannerDelayTimer?.cancel();
          if (_showDisconnectedBanner) {
            _showDisconnectedBanner = false;
          }
          return const SizedBox.shrink();
        }

        // If just came back from background or briefly disconnected,
        // add a 3-second grace period before showing the banner
        if (!_showDisconnectedBanner && !isConnecting) {
          _bannerDelayTimer?.cancel();
          _bannerDelayTimer = Timer(const Duration(seconds: 3), () {
            if (mounted && !socketService.isConnected) {
              setState(() {
                _showDisconnectedBanner = true;
              });
            }
          });
          return const SizedBox.shrink();
        }

        // Show "Connecting..." immediately but "Disconnected" after grace period
        if (!isConnecting && !_showDisconnectedBanner) {
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
    final fullName = ref.watch(
      currentUserProvider.select((u) => u?.fullName ?? 'Driver'),
    );

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
          if (mounted) {
            setState(() {
              _bottomNavIndex = 0;
            });
          }
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

          // 1. Handle auto-resume location sharing (ONLY after init)
          if (_isSharing && _hasInitialized) {
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
          if (_selectedRoute == null && bus.routeId != null) {
            debugPrint(
              '[DriverDashboard] Matching route for routeId=${bus.routeId}',
            );
            final routesAsync = ref.read(collegeRoutesProvider(collegeId));
            final routes = routesAsync.valueOrNull;
            if (routes != null) {
              try {
                final route = routes.firstWhere((r) => r.id == bus.routeId);
                if (mounted) {
                  setState(() {
                    _selectedRoute = route;
                  });
                  _updateMarkers();
                }
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
        if (_selectedRoute == null) {
          final bus = ref.read(driverBusProvider(userId)).valueOrNull;
          if (bus != null && bus.routeId != null) {
            next.whenData((routes) {
              try {
                final route = routes.firstWhere((r) => r.id == bus.routeId);
                if (mounted) {
                  setState(() {
                    _selectedRoute = route;
                  });
                  _updateMarkers();
                }
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: DriverLocalizations.of(
          context,
        )!.welcomeDriver(fullName).text.ellipsis.make(),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirmed = await LogoutConfirmationDialog.show(context);
              if (confirmed) {
                if (context.mounted) {
                  LogoutLoadingDialog.show(context);
                }
                await ref.read(authProvider.notifier).signOut();
                if (context.mounted) context.go('/login');
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main Content
          if (myBusAsync.isLoading && !myBusAsync.hasValue)
            const Center(child: CircularProgressIndicator())
          else
            IndexedStack(
              index: _bottomNavIndex,
              children: [
                _buildBusSetupTab(myBus, routesAsync, busNumbersAsync),
                _buildLiveTrackingTab(myBus),
                const ProfileScreen(),
              ],
            ),

          // Connectivity Banner
          _buildConnectivityBanner(),
        ],
      ),
      bottomNavigationBar: CurvedBottomNavBar(
        currentIndex: _bottomNavIndex,
        onTap: (index) {
          setState(() => _bottomNavIndex = index);
        },
        activeColor: _getDriverActiveColor(context),
        backgroundColor: Theme.of(context).cardColor,
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
    );
  }

  Widget _buildBusSetupTab(
    BusModel? myBus,
    AsyncValue<List<RouteModel>> routesAsync,
    AsyncValue<List<String>> busNumbersAsync,
  ) {
    if (myBus != null && myBus.assignmentStatus == 'pending') {
      return _buildPendingAssignmentUI(myBus).p(AppSizes.paddingMedium);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      child: VStack([
        LocationDisplay(currentLocation: _currentLocation),
        VStack([
          if (myBus == null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_late_outlined,
                    size: 64,
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'There are no assignments.',
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).disabledColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please contact the coordinator.',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).disabledColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ).pOnly(top: 40)
          else
            BusAssignmentCard(
              bus: myBus,
              route: _selectedRoute,
              onRemove: () => _handleRemoveAssignment(myBus),
            ),
        ]),
      ]),
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
          setState(() {
            _selectedRoute = null;
          });
          _updateMarkers();

          SuccessModal.show(
            context: context,
            title: 'Trip Completed',
            message: 'Good job! You have been unassigned from the bus.',
            primaryActionText: 'OK',
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error completing trip: $e'),
              backgroundColor: AppColors.error,
            ),
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
            CommonMapView(
              currentLocation: _currentLocation,
              markers: _markers,
              polylines: const {},
              onMapCreated: (controller) {},
              initialZoom: 17.0,
            ).expand(),
            LiveTrackingControlPanel(
              bus: myBus,
              route: _selectedRoute,
              isSharing: _isSharing,
              currentLocation: _currentLocation,
              onToggleSharing: () => _toggleLocationSharing(myBus),
            ),
          ],
        ),
        // Trip Complete Floating Button
        if (myBus != null && myBus.assignmentStatus == 'accepted')
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: () => _handleTripComplete(myBus),
              backgroundColor: AppColors.success,
              icon: const Icon(Icons.check_circle_outline, color: Colors.white),
              label: const Text(
                'Trip Complete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        Positioned(
          top: 16,
          left: 16,
          child: Column(
            children: [
              SOSButton(
                currentLocation: _currentLocation,
                busId: myBus?.id,
                routeId: _selectedRoute?.id,
              ),
              if (myBus != null && myBus.assignmentStatus == 'accepted') ...[
                16.heightBox,
                const VoiceMessageButton(),
              ],
            ],
          ),
        ),
        if (_nextStopETA != null && _isSharing)
          Positioned(
            bottom: 240, // Above control panel
            left: 16,
            right: 16,
            child: Card(
              color: Colors.black87,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  'ETA: $_nextStopETA',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color _getDriverActiveColor(BuildContext context) {
    switch (_bottomNavIndex) {
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
