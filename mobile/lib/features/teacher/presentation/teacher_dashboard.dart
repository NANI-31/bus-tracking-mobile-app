import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/features/bus/application/bus_provider.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/features/user/domain/user_model.dart';
import 'package:collegebus/features/route/domain/route_model.dart';
import 'package:collegebus/features/route/application/route_provider.dart';
import 'package:collegebus/features/driver/application/driver_location_provider.dart';
import 'package:collegebus/features/driver/application/driver_map_provider.dart';
import 'package:collegebus/features/student/application/map_navigation_provider.dart';
import 'package:collegebus/core/providers/repository_providers.dart';
import 'package:collegebus/core/providers/socket_provider.dart';
import 'package:collegebus/core/providers/service_providers.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/core/utils/map_marker_helper.dart';
import 'package:collegebus/shared/widgets/success_modal.dart';
import 'package:collegebus/shared/widgets/api_error_modal.dart';
import 'package:collegebus/features/student/presentation/bus_schedule_screen.dart';
import 'package:collegebus/features/user/presentation/screens/profile_screen.dart';
import 'package:collegebus/shared/widgets/navigation/curved_bottom_nav_bar.dart';
import 'tabs/teacher_override_tab.dart';
import 'tabs/teacher_live_tracking_tab.dart';


class TeacherDashboard extends ConsumerStatefulWidget {
  const TeacherDashboard({super.key});

  @override
  ConsumerState<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends ConsumerState<TeacherDashboard> {
  int _bottomNavIndex = 0;
  final Set<int> _visitedTabs = {0};

  String? _selectedBusId;
  bool _isRequesting = false;
  bool _isTracking = false;
  LatLng? _currentLocation;

  // Map Markers & Assets
  BitmapDescriptor? _busIcon;
  BitmapDescriptor? _startStopIcon;
  BitmapDescriptor? _intermediateStopIcon;
  BitmapDescriptor? _endStopIcon;

  // GPS Tracking State Helpers
  DateTime? _lastDeviationAlertTime;
  final Set<String> _arrivedStopIds = {};

  /// Persistent deviation toast Ã¢â‚¬â€ updates distance in-place, never stacks.
  OverlayEntry? _deviationOverlayEntry;
  final ValueNotifier<int> _deviationDistanceNotifier = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    // Join socket room
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      final collegeId = user?.collegeId;
      if (collegeId != null) {
        ref.read(socketServiceProvider).joinCollege(collegeId);
      }
      _loadMapIcons();
      _getCurrentLocation();
    });
  }

  @override
  void dispose() {
    _stopLocationTracking();
    _deviationOverlayEntry?.remove();
    _deviationOverlayEntry = null;
    _deviationDistanceNotifier.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    final locationService = ref.read(locationServiceProvider);
    final location = await locationService.getCurrentLocation();
    if (location != null && mounted) {
      setState(() => _currentLocation = location);
      ref.read(mapNavigationProvider.notifier).updateUserLocation(location);
    }
  }

  Future<void> _loadMapIcons() async {
    try {
      final icon = await MapMarkerHelper.createBusMarker();
      if (mounted) setState(() => _busIcon = icon);
    } catch (_) {}
    if (!mounted) return;
    try {
      final mapTheme = Theme.of(context).extension<MapThemeExtension>();
      final startColor = mapTheme?.startStopColor ?? const Color(0xFF4CAF50);
      final stopColor = mapTheme?.intermediateStopColor ?? const Color(0xFFFF9800);
      final endColor = mapTheme?.endStopColor ?? const Color(0xFFE53935);

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
    } catch (_) {}
  }

  void _onBottomNavChanged(int index) {
    setState(() {
      _bottomNavIndex = index;
      _visitedTabs.add(index);
    });
  }

  Future<void> _submitRequest() async {
    if (_selectedBusId == null) return;
    setState(() => _isRequesting = true);
    try {
      final repo = ref.read(busRepositoryProvider);
      await repo.requestTeacherOverride(_selectedBusId!);
      ref.invalidate(teacherOverrideRequestsProvider);
      final user = ref.read(currentUserProvider);
      if (user != null) {
        ref.invalidate(collegeBusesStreamProvider(user.collegeId));
      }
      if (mounted) {
        SuccessModal.show(
          context: context,
          title: 'Request Sent',
          message: 'Override authorization request has been sent to coordinator approval.',
          primaryActionText: 'OK',
        );
      }
    } catch (e) {
      if (mounted) {
        ApiErrorModal.show(
          context: context,
          error: e.toString().contains('already exists')
              ? 'An override request is already pending for this bus.'
              : 'Failed to send request: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }

  Future<void> _startLocationTracking() async {
    if (_selectedBusId == null) return;
    final locationService = ref.read(locationServiceProvider);
    final socketService = ref.read(socketServiceProvider);
    final user = ref.read(currentUserProvider);

    final hasPermission = await locationService.checkLocationPermission();
    if (!hasPermission) {
      final granted = await locationService.requestLocationPermission();
      if (!granted) {
        if (mounted) {
          ApiErrorModal.show(
            context: context,
            error: 'Location permissions are required to broadcast coordinates.',
          );
        }
        return;
      }
    }

    // Fetch and cache the route for the map overlays.
    // Uses ref.read (sync) — if routes haven't loaded yet, we schedule a
    // one-shot retry so the map overlay appears as soon as data arrives.
    RouteModel? assignedRoute;
    if (user != null) {
      final buses = ref.read(collegeBusesStreamProvider(user.collegeId)).valueOrNull ?? [];
      final matchingBuses = buses.where((b) => b.id == _selectedBusId);
      if (matchingBuses.isNotEmpty) {
        final selectedBus = matchingBuses.first;
        final targetRouteId = selectedBus.routeId ?? selectedBus.defaultRouteId;
        if (targetRouteId != null) {
          final routes = ref.read(collegeRoutesProvider(user.collegeId)).valueOrNull ?? [];
          final matchingRoutes = routes.where((r) => r.id == targetRouteId);
          if (matchingRoutes.isNotEmpty) {
            assignedRoute = matchingRoutes.first;
          } else {
            // Routes not ready yet — schedule a retry after the first frame.
            _scheduleRouteLookup(targetRouteId, user.collegeId);
          }
        }
      }
    }

    if (assignedRoute != null) {
      ref.read(driverMapStateProvider.notifier).setSelectedRoute(assignedRoute);
    }

    setState(() {
      _isTracking = true;
      _bottomNavIndex = 1; // Switch to Live Tracking tab
      _visitedTabs.add(1);
    });
    if (_currentLocation != null) {
      ref.read(driverLocationProvider.notifier).updateLocation(_currentLocation!);
    }
    ref.read(driverLocationProvider.notifier).updateSharing(true);

    ref.read(busRepositoryProvider).updateBus(_selectedBusId!, {'status': 'on-time'}).catchError((e) {
      debugPrint('Failed to update bus status: $e');
    });

    locationService.startLocationTracking(
      onLocationUpdate: (position) {
        // 1. Update Riverpod provider for driver location parameters
        ref.read(driverLocationProvider.notifier).updateLocation(
          LatLng(position.latitude, position.longitude),
          heading: position.heading,
          speed: position.speed,
        );

        // 2. Perform route adherence and stop arrival checks
        final buses = ref.read(collegeBusesStreamProvider(user!.collegeId)).valueOrNull ?? [];
        final matchingBuses = buses.where((b) => b.id == _selectedBusId);
        if (matchingBuses.isNotEmpty) {
          final selectedBus = matchingBuses.first;
          _checkRouteDeviation(position, selectedBus);
          _checkStopArrival(position, selectedBus);
        }

        // 3. Emit position and path-aware ETA payload via socket stream
        socketService.updateLocation({
          'busId': _selectedBusId!,
          'collegeId': user.collegeId,
          'location': {'lat': position.latitude, 'lng': position.longitude},
          'speed': position.speed,
          'heading': position.heading,
          'etaMinutes': _computeEtaMinutes(position, speedMs: position.speed),
        });
      },
    );
  }

  void _stopLocationTracking() {
    ref.read(locationServiceProvider).stopLocationTracking();
    ref.read(driverLocationProvider.notifier).clear();
    ref.read(driverMapStateProvider.notifier).clear();
    _arrivedStopIds.clear();
    _lastDeviationAlertTime = null;
    if (mounted) {
      setState(() => _isTracking = false);
    } else {
      _isTracking = false;
    }
    if (_selectedBusId != null) {
      ref.read(busRepositoryProvider).updateBus(_selectedBusId!, {'status': 'not-running'}).catchError((e) {
        debugPrint('Failed to update bus status: $e');
      });
    }
  }

  /// Called when routes provider returned empty at tracking-start time.
  /// Retries every 500 ms (up to 5 attempts) and sets the route in
  /// driverMapStateProvider as soon as it is available.
  void _scheduleRouteLookup(String targetRouteId, String collegeId) {
    var attempts = 0;
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      attempts++;
      if (!mounted || attempts > 5) {
        timer.cancel();
        return;
      }
      final routes =
          ref.read(collegeRoutesProvider(collegeId)).valueOrNull ?? [];
      final match = routes.cast<RouteModel?>().firstWhere(
            (r) => r!.id == targetRouteId,
            orElse: () => null,
          );
      if (match != null) {
        timer.cancel();
        ref.read(driverMapStateProvider.notifier).setSelectedRoute(match);
      }
    });
  }

  Future<void> _toggleLocationSharing(BusModel? bus) async {
    if (bus == null) return;
    final isSharing = ref.read(driverLocationProvider).isSharing;
    if (isSharing) {
      ref.read(locationServiceProvider).stopLocationTracking();
      ref.read(driverLocationProvider.notifier).updateSharing(false);
      ref.read(busRepositoryProvider).updateBus(bus.id, {'status': 'not-running'}).catchError((e) {
        debugPrint('Failed to update bus status: $e');
      });
    } else {
      await _startLocationTracking();
    }
  }



  Future<void> _cancelOverride() async {
    if (_selectedBusId == null) return;
    _stopLocationTracking();
    try {
      final repo = ref.read(busRepositoryProvider);
      await repo.cancelTeacherOverride(_selectedBusId!);
      ref.invalidate(busListProvider);
      ref.invalidate(teacherOverrideRequestsProvider);
      final user = ref.read(currentUserProvider);
      if (user != null) {
        ref.invalidate(collegeBusesStreamProvider(user.collegeId));
      }
      if (mounted) {
        SuccessModal.show(
          context: context,
          title: 'Override Ended',
          message: 'You have stopped broadcasting coordinates for this bus.',
          primaryActionText: 'OK',
        );
      }
    } catch (e) {
      if (mounted) {
        ApiErrorModal.show(
          context: context,
          error: 'Failed to end override: $e',
        );
      }
    }
  }

  void _selectBus(BusModel bus) {
    if (bus.assignmentStatus != 'accepted') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bus ${bus.busNumber} is not active yet (pending driver acceptance).',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final user = ref.read(currentUserProvider);
    final collegeId = user?.collegeId;
    RouteModel? activeRoute;
    if (collegeId != null) {
      final routes = ref.read(collegeRoutesProvider(collegeId)).valueOrNull ?? [];
      final targetRouteId = bus.routeId ?? bus.defaultRouteId;
      activeRoute = routes.cast<RouteModel?>().firstWhere(
        (r) => r!.id == targetRouteId,
        orElse: () => null,
      );
    }
    ref.read(mapNavigationProvider.notifier).selectBus(bus, activeRoute);
    _onBottomNavChanged(1); // Switch to Live Tracking/Map Tab
  }

  // --- Location Deviation, Proximity & ETA Calculations ---

  void _checkRouteDeviation(Position position, BusModel selectedBus) {
    final selectedRoute = ref.read(driverMapStateProvider).selectedRoute;
    if (selectedRoute == null) return;

    final points = [
      LatLng(selectedRoute.startPoint.lat, selectedRoute.startPoint.lng),
      ...selectedRoute.stopPoints.map((s) => LatLng(s.lat, s.lng)),
      LatLng(selectedRoute.endPoint.lat, selectedRoute.endPoint.lng),
    ];

    double minDistance = double.infinity;
    for (int i = 0; i < points.length - 1; i++) {
      final dist = _distanceToSegment(
        LatLng(position.latitude, position.longitude),
        points[i],
        points[i + 1],
      );
      if (dist < minDistance) minDistance = dist;
    }

    if (minDistance > 200) {
      final now = DateTime.now();
      if (_lastDeviationAlertTime == null ||
          now.difference(_lastDeviationAlertTime!) > const Duration(minutes: 1)) {
        _lastDeviationAlertTime = now;
      }
      _deviationDistanceNotifier.value = minDistance.toInt();
      _showDeviationToast();
    } else {
      _hideDeviationToast();
    }

    _calculateETA(position, selectedBus);
  }

  /// Shows (or keeps) a persistent deviation toast, updating distance in-place.
  void _showDeviationToast() {
    if (!mounted) return;
    if (_deviationOverlayEntry != null) return;

    final entry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: MediaQuery.of(ctx).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: ValueListenableBuilder<int>(
            valueListenable: _deviationDistanceNotifier,
            builder: (_, dist, __) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.orange.shade800,
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
                      'Off route Ã¢â‚¬â€ ${dist}m from path',
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
      ),
    );

    _deviationOverlayEntry = entry;
    Overlay.of(context).insert(entry);
  }

  /// Dismisses the deviation toast when the teacher is back on route.
  void _hideDeviationToast() {
    _deviationOverlayEntry?.remove();
    _deviationOverlayEntry = null;
  }

  void _calculateETA(Position position, BusModel selectedBus) {
    final etaMinutes = _computeEtaMinutes(position, speedMs: position.speed);
    if (etaMinutes == null) return;

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
    if (nextStop == null) return;

    final etaStr = 'Next: ${nextStop.name} Ã‚Â· $etaMinutes min';
    ref.read(driverLocationProvider.notifier).updateETA(etaStr);
  }

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

    final effectiveSpeedMs = (speedMs != null && speedMs > 1.0) ? speedMs : 8.33;
    final timeSeconds = minDistance / effectiveSpeedMs;
    return (timeSeconds / 60).ceil();
  }

  void _checkStopArrival(Position position, BusModel selectedBus) {
    final selectedRoute = ref.read(driverMapStateProvider).selectedRoute;
    if (selectedRoute == null) return;

    final List<RoutePoint> allRoutePoints = [];
    if (selectedRoute.startPoint.lat != 0 && selectedRoute.startPoint.lng != 0) {
      allRoutePoints.add(selectedRoute.startPoint);
    }
    allRoutePoints.addAll(selectedRoute.stopPoints);
    if (selectedRoute.endPoint.lat != 0 && selectedRoute.endPoint.lng != 0) {
      allRoutePoints.add(selectedRoute.endPoint);
    }

    const double arrivalThresholdMeters = 25.0;

    for (final stop in allRoutePoints) {
      final stopKey = '${stop.name}_${stop.lat}_${stop.lng}';
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
          'busId': selectedBus.id,
          'collegeId': user?.collegeId ?? selectedBus.collegeId,
          'stopId': stopKey,
          'stopName': stop.name,
          'distanceMeters': dist.toStringAsFixed(1),
          'timestamp': DateTime.now().toIso8601String(),
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


  String _fingerprintRoute(RouteModel route) {
    final buffer = StringBuffer(route.id);
    buffer.write('|${route.startPoint.lat},${route.startPoint.lng}');
    for (final s in route.stopPoints) {
      buffer.write('|${s.lat},${s.lng}');
    }
    buffer.write('|${route.endPoint.lat},${route.endPoint.lng}');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final busesAsync = ref.watch(collegeBusesStreamProvider(user.collegeId));
    final routesAsync = ref.watch(collegeRoutesProvider(user.collegeId));

    // 1. Auto-select active override bus if not explicitly selected
    final buses = busesAsync.valueOrNull ?? [];
    if (_selectedBusId == null) {
      for (final b in buses) {
        if (b.trackingTeacherId == user.id) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedBusId = b.id);
          });
          break;
        }
      }
    }

    // 2. Auto-load route overlay into driverMapStateProvider
    if (_selectedBusId != null) {
      final selectedBus = buses.cast<BusModel?>().firstWhere(
            (b) => b?.id == _selectedBusId,
            orElse: () => null,
          );
      if (selectedBus != null) {
        final targetRouteId = selectedBus.routeId ?? selectedBus.defaultRouteId;
        if (targetRouteId != null) {
          final routes = routesAsync.valueOrNull ?? [];
          final matchingRoute = routes.cast<RouteModel?>().firstWhere(
                (r) => r?.id == targetRouteId,
                orElse: () => null,
              );
          if (matchingRoute != null) {
            final currentLoaded = ref.read(driverMapStateProvider).selectedRoute;
            if (currentLoaded == null ||
                currentLoaded.id != matchingRoute.id ||
                _fingerprintRoute(currentLoaded) != _fingerprintRoute(matchingRoute)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  ref.read(driverMapStateProvider.notifier).setSelectedRoute(matchingRoute);
                }
              });
            }
          }
        }
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassColor = isDark
        ? Colors.black.withValues(alpha: 0.25)
        : Colors.white.withValues(alpha: 0.25);

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _bottomNavIndex,
            children: [
              // Tab 0: Override Control Panel
              _visitedTabs.contains(0)
                  ? _buildOverrideTab(user, isDark, glassColor)
                  : const SizedBox.shrink(),

              // Tab 1: Live Tracking
              _visitedTabs.contains(1)
                  ? _buildLiveTrackingTab(user)
                  : const SizedBox.shrink(),

              // Tab 2: Schedules
              _visitedTabs.contains(2)
                  ? BusScheduleScreen(
                      isTab: true,
                      onBusSelected: _selectBus,
                    )
                  : const SizedBox.shrink(),

              // Tab 3: Profile
              _visitedTabs.contains(3)
                  ? const ProfileScreen()
                  : const SizedBox.shrink(),
            ],
          ),

          Align(
            alignment: Alignment.bottomCenter,
              child: CurvedBottomNavBar(
                activeColor: AppColors.primary,
                activeColors: [
                  AppColors.primary,
                  Colors.blue.shade600,
                  Colors.teal.shade500,
                  Colors.blueGrey.shade600,
                ],
                inactiveColor: Theme.of(context).colorScheme.secondary,
                backgroundColor: Theme.of(context).brightness == Brightness.light
                    ? Theme.of(context).cardColor
                    : Theme.of(context).colorScheme.primaryContainer,
                currentIndex: _bottomNavIndex,
                onTap: _onBottomNavChanged,
                items: [
                  CurvedBottomNavItem(
                    icon: _bottomNavIndex == 0
                        ? Icons.dashboard_customize
                        : Icons.dashboard_customize_outlined,
                    label: 'Override',
                  ),
                  CurvedBottomNavItem(
                    icon: _bottomNavIndex == 1
                        ? Icons.navigation
                        : Icons.navigation_outlined,
                    label: 'Live Tracking',
                  ),
                  CurvedBottomNavItem(
                    icon: _bottomNavIndex == 2
                        ? Icons.calendar_month
                        : Icons.calendar_month_outlined,
                    label: 'Schedule',
                  ),
                  CurvedBottomNavItem(
                    icon: _bottomNavIndex == 3
                        ? Icons.person
                        : Icons.person_outline,
                    label: 'Profile',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverrideTab(UserModel user, bool isDark, Color glassColor) {
    return TeacherOverrideTab(
      user: user,
      selectedBusId: _selectedBusId,
      isTracking: _isTracking,
      isRequesting: _isRequesting,
      isDark: isDark,
      onSelectBus: (busId) => setState(() => _selectedBusId = busId),
      onStartTracking: _startLocationTracking,
      onStopTracking: _stopLocationTracking,
      onSubmitRequest: _submitRequest,

      onCancelOverride: _cancelOverride,
      onOpenLiveTracking: () => setState(() => _bottomNavIndex = 1),
    );
  }

  Widget _buildLiveTrackingTab(UserModel user) {
    return TeacherLiveTrackingTab(
      user: user,
      selectedBusId: _selectedBusId,
      isTracking: _isTracking,
      currentLocation: _currentLocation,
      busIcon: _busIcon,
      startStopIcon: _startStopIcon,
      intermediateStopIcon: _intermediateStopIcon,
      endStopIcon: _endStopIcon,
      onToggleSharing: _toggleLocationSharing,
      onCompleteTrip: _cancelOverride,
      onBusSelected: (bus, route) {
        ref.read(mapNavigationProvider.notifier).selectBus(bus, route);
      },
      onRouteTypeSelected: (_) {
        // Route type filtering is handled internally by StudentMapTab.
      },
      onBusNumberSelected: (busNumber, buses, routes) {
        if (busNumber == null || buses.isEmpty) return;
        BusModel? bus;
        for (final b in buses) {
          if (b.busNumber == busNumber) {
            bus = b;
            break;
          }
        }
        if (bus == null) return;
        RouteModel? activeRoute;
        if (bus.routeId != null) {
          for (final r in routes) {
            if (r.id == bus.routeId) {
              activeRoute = r;
              break;
            }
          }
        }
        ref.read(mapNavigationProvider.notifier).selectBus(bus, activeRoute);
      },
      onClearFilters: () {
        ref.read(mapNavigationProvider.notifier).selectBus(null, null);
      },
    );
  }
}
