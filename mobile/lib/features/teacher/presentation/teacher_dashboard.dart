import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velocity_x/velocity_x.dart';
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
import 'package:collegebus/widgets/common/common_map_view.dart';
import 'package:collegebus/shared/widgets/sos_button.dart';
import 'package:collegebus/features/driver/presentation/widgets/voice_message_button.dart';
import 'package:collegebus/shared/widgets/success_modal.dart';
import 'package:collegebus/shared/widgets/api_error_modal.dart';
import 'package:collegebus/features/student/presentation/bus_schedule_screen.dart';
import 'package:collegebus/features/student/presentation/tabs/student_map_tab.dart';
import 'package:collegebus/shared/widgets/maps/map_skeleton_loader.dart';
import 'package:collegebus/features/user/presentation/screens/profile_screen.dart';
import 'package:collegebus/shared/widgets/navigation/curved_bottom_nav_bar.dart';
import 'package:collegebus/features/driver/presentation/widgets/live_tracking_control_panel.dart';
import 'package:collegebus/core/services/directions_result.dart';

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

    // Fetch and cache the route for the map overlays
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

  Future<void> _handleTripComplete(BusModel? bus) async {
    if (bus == null) return;
    await _cancelOverride();
  }

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

    final driverIdx = findClosestIndex(currentLocation);

    int nextStopIndex = -1;
    for (int i = 0; i < allStops.length; i++) {
      final stop = allStops[i];
      if (stop.lat == 0 && stop.lng == 0) continue;
      
      final stopIdx = findClosestIndex(LatLng(stop.lat, stop.lng));
      if (stopIdx > driverIdx) {
        nextStopIndex = i;
        break;
      }
    }

    if (nextStopIndex < 0) return null;

    final nextStop = allStops[nextStopIndex];
    
    final remainingDistanceKm = Geolocator.distanceBetween(
      currentLocation.latitude,
      currentLocation.longitude,
      nextStop.lat,
      nextStop.lng,
    ) / 1000.0;

    int etaMin = 1;

    if (directionsResult.legs.isNotEmpty) {
      final legIndex = (nextStopIndex - 1).clamp(0, directionsResult.legs.length - 1);
      final leg = directionsResult.legs[legIndex];
      
      if (leg.distanceKm > 0) {
        final proportion = (remainingDistanceKm / leg.distanceKm).clamp(0.0, 1.0);
        etaMin = (proportion * leg.durationMin).round().clamp(1, leg.durationMin);
      } else {
        etaMin = leg.durationMin;
      }
    } else {
      etaMin = (remainingDistanceKm / 0.5).ceil().clamp(1, 120);
    }

    return 'Next: ${nextStop.name} · $etaMin min';
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
        ApiErrorModal.show(
          context: context,
          error: 'Route Deviation Alert! You are ${minDistance.toInt()} meters away from the active route path.',
        );
      }
    }

    _calculateETA(position, selectedBus);
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

    final etaStr = 'Next: ${nextStop.name} · $etaMinutes min';
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

  int _findClosestPointIndex(LatLng target, List<LatLng> points) {
    if (points.isEmpty) return 0;
    int closestIdx = 0;
    double minDistance = double.infinity;
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final dist = Geolocator.distanceBetween(
        target.latitude,
        target.longitude,
        p.latitude,
        p.longitude,
      );
      if (dist < minDistance) {
        minDistance = dist;
        closestIdx = i;
      }
    }
    return closestIdx;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
    final busesAsync = ref.watch(collegeBusesStreamProvider(user.collegeId));
    final pendingRequestsAsync = ref.watch(teacherOverrideRequestsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: 'Driver Keypad Override'.text.bold.make(),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: busesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            err.toString().text.color(AppColors.error).make().centered(),
        data: (buses) {
          BusModel? activeOverriddenBus;
          for (final b in buses) {
            if (b.trackingTeacherId == user.id) {
              activeOverriddenBus = b;
              break;
            }
          }

          if (activeOverriddenBus != null && _selectedBusId == null) {
            _selectedBusId = activeOverriddenBus.id;
          }

          BusModel? selectedBus;
          if (_selectedBusId != null) {
            for (final b in buses) {
              if (b.id == _selectedBusId) {
                selectedBus = b;
                break;
              }
            }
          }

          final pendingRequests = pendingRequestsAsync.valueOrNull ?? [];
          final hasPendingRequest = _selectedBusId != null &&
              pendingRequests.any((r) =>
                  r['busId'] == _selectedBusId ||
                  (r['busId'] is Map && r['busId']['_id'] == _selectedBusId));

          final isApproved =
              selectedBus != null && selectedBus.trackingTeacherId == user.id;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: VStack([
              'Select Bus to Override'.text.lg.bold.make().pOnly(bottom: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedBusId,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                hint: 'Choose a vehicle'.text.make(),
                items: buses.map((bus) {
                  return DropdownMenuItem<String>(
                    value: bus.id,
                    child: 'Bus ${bus.busNumber}'.text.make(),
                  );
                }).toList(),
                onChanged: _isTracking
                    ? null
                    : (busId) {
                        setState(() {
                          _selectedBusId = busId;
                        });
                      },
              ),
              const SizedBox(height: 24),

              if (selectedBus != null) ...[
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: VStack([
                    HStack([
                      const Icon(Icons.info_outline, color: Colors.blueGrey),
                      const SizedBox(width: 12),
                      'Status'.text.bold.lg.make(),
                    ]).pOnly(bottom: 8),

                    if (isApproved)
                      'Approved & Authorized'.text.green600.bold.make()
                    else if (hasPendingRequest)
                      'Request Pending Coordinator Approval'
                          .text
                          .amber500
                          .bold
                          .make()
                    else
                      'No active override authorization'.text.gray500.make(),
                  ]).p(16),
                ),
                const SizedBox(height: 24),

                if (isApproved) ...[
                  if (_isTracking) ...[
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => setState(() => _bottomNavIndex = 1),
                      child: 'Open Live Tracking'.text.bold.make(),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _stopLocationTracking,
                      child: 'Pause Tracking'.text.bold.make(),
                    ),
                  ] else ...[
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _startLocationTracking,
                      child: 'Start Override Tracking'.text.bold.make(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.shade300),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isTracking ? null : _cancelOverride,
                    child: 'End Override Session'.text.bold.make(),
                  ),
                ] else ...[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: (_isRequesting || hasPendingRequest)
                        ? null
                        : _submitRequest,
                    child: _isRequesting
                        ? const CircularProgressIndicator(color: Colors.white)
                            .centered()
                        : 'Request Override Authorization'.text.bold.make(),
                  ),
                ],
              ],

              const SizedBox(height: 32),
              'College Fleet Live Status'.text.lg.bold.make().pOnly(bottom: 12),
              if (buses.isEmpty)
                'No buses registered in this college.'.text.gray500.make().centered()
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: buses.length,
                  itemBuilder: (context, index) {
                    final bus = buses[index];
                    final isLive = ref.watch(studentLiveBusIdsProvider(user.collegeId)).contains(bus.id);
                    final isAssigned = bus.driverId.isNotEmpty;
                    final isCurrentOverride = bus.trackingTeacherId == user.id;

                    Color statusColor = Colors.grey;
                    String statusLabel = 'Offline';
                    String statusSubtitle = 'Unassigned & Offline';

                    if (isCurrentOverride) {
                      statusColor = Colors.green;
                      statusLabel = 'Override Active';
                      statusSubtitle = 'You are broadcasting location';
                    } else if (isLive) {
                      statusColor = Colors.green;
                      statusLabel = 'Live';
                      statusSubtitle = 'Currently broadcasting live';
                    } else if (isAssigned) {
                      statusColor = Colors.amber.shade700;
                      statusLabel = 'Assigned';
                      statusSubtitle = 'Assigned (Driver Offline)';
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isCurrentOverride 
                              ? Colors.green.shade400 
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.directions_bus,
                            color: statusColor,
                            size: 20,
                          ),
                        ),
                        title: 'Bus ${bus.busNumber}'.text.bold.make(),
                        subtitle: statusSubtitle.text.size(12).gray500.make(),
                        trailing: HStack([
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          statusLabel.text
                              .color(statusColor)
                              .bold
                              .size(12)
                              .make(),
                        ]),
                        onTap: _isTracking ? null : () {
                          setState(() {
                            _selectedBusId = bus.id;
                          });
                        },
                      ),
                    );
                  },
                ),
              const SizedBox(height: 80), // spacer for bottom nav bar clearance
            ]),
          );
        },
      ),
    );
  }

  Widget _buildLiveTrackingMapUI(UserModel user, bool isDark) {
    final mapState = ref.watch(driverMapStateProvider);
    final route = mapState.selectedRoute;
    final result = mapState.directionsResult;

    final locationState = ref.watch(driverLocationProvider);
    final currentLocation = locationState.currentLocation ?? _currentLocation;
    final heading = locationState.heading;
    final nextStopETA = locationState.nextStopETA;
    final isSharing = locationState.isSharing;

    // 1. Build stop markers dynamically
    final stopMarkers = <Marker>{};
    if (route != null) {
      if (route.startPoint.lat != 0 && route.startPoint.lng != 0) {
        stopMarkers.add(Marker(
          markerId: const MarkerId('tstop_start'),
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

        final isAtStart = (stop.lat - route.startPoint.lat).abs() < 0.00001 &&
            (stop.lng - route.startPoint.lng).abs() < 0.00001;
        final isAtEnd = (stop.lat - route.endPoint.lat).abs() < 0.00001 &&
            (stop.lng - route.endPoint.lng).abs() < 0.00001;
        final isSameNameStart = route.startPoint.name.isNotEmpty &&
            stop.name.trim().toLowerCase() == route.startPoint.name.trim().toLowerCase();
        final isSameNameEnd = route.endPoint.name.isNotEmpty &&
            stop.name.trim().toLowerCase() == route.endPoint.name.trim().toLowerCase();

        if (isAtStart || isAtEnd || isSameNameStart || isSameNameEnd) continue;

        stopMarkers.add(Marker(
          markerId: MarkerId('tstop_$i'),
          position: LatLng(stop.lat, stop.lng),
          icon: _intermediateStopIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(title: 'Stop ${i + 1}: ${stop.name}'),
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 1,
        ));
      }
      if (route.endPoint.lat != 0 && route.endPoint.lng != 0) {
        stopMarkers.add(Marker(
          markerId: const MarkerId('tstop_end'),
          position: LatLng(route.endPoint.lat, route.endPoint.lng),
          icon: _endStopIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: 'End: ${route.endPoint.name}'),
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 1,
        ));
      }
    }

    // 2. Build route polylines dynamically
    final polylines = <Polyline>{};
    if (result != null && result.hasRoute) {
      List<LatLng> points = List<LatLng>.from(result.polylinePoints);
      if (currentLocation != null && points.isNotEmpty) {
        final closestIdx = _findClosestPointIndex(currentLocation, points);
        points = [currentLocation, ...points.sublist(closestIdx)];
      }

      final routeColor = route != null
          ? Color(int.parse(route.color.replaceAll('#', '0xFF')))
          : const Color(0xFF1565C0);

      polylines.addAll({
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
      });
    }

    final mapMarkers = {...stopMarkers};
    if (currentLocation != null) {
      mapMarkers.add(
        Marker(
          markerId: const MarkerId('teacher_bus'),
          position: currentLocation,
          icon: _busIcon ?? BitmapDescriptor.defaultMarker,
          rotation: heading,
          anchor: const Offset(0.5, 0.2),
          flat: true,
          zIndexInt: 2,
        ),
      );
    }

    final buses = ref.watch(collegeBusesStreamProvider(user.collegeId)).valueOrNull ?? [];
    final matchingBuses = buses.where((b) => b.id == _selectedBusId);
    final bus = matchingBuses.isNotEmpty ? matchingBuses.first : null;

    // Compute next stop ETA from directions
    String? directionsETA;
    if (result != null && currentLocation != null && route != null) {
      directionsETA = _computeNextStopETAFromDirections(
        currentLocation,
        route,
        result,
      );
    }
    final displayETA = directionsETA ?? (nextStopETA != null ? 'ETA: $nextStopETA' : null);

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: CommonMapView(
                currentLocation: currentLocation,
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
              currentLocation: currentLocation,
              onToggleSharing: () => _toggleLocationSharing(bus),
              onCompleteTrip: () => _handleTripComplete(bus),
            ),
            SizedBox(height: CurvedBottomNavBar.clearance(context)),
          ],
        ),

        // ETA Card (Top Positioned)
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

        // SOS & Voice Message Buttons (Positioned Left)
        Positioned(
          top: MediaQuery.of(context).padding.top + (isSharing && route != null && displayETA != null ? 80 : 16),
          left: 16,
          child: Column(
            children: [
              SOSButton(
                currentLocation: currentLocation,
                busId: _selectedBusId,
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

  Widget _buildLiveTrackingTab(UserModel user) {
    if (_isTracking && _selectedBusId != null) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return _buildLiveTrackingMapUI(user, isDark);
    }

    final mapNavState = ref.watch(mapNavigationProvider);
    final selectedBus = mapNavState.selectedBus;
    final activeRoute = mapNavState.activeRoute;
    final selectedRouteType = mapNavState.selectedRouteType;

    final busesAsync = ref.watch(collegeBusesStreamProvider(user.collegeId));
    final liveBusIds = ref.watch(studentLiveBusIdsProvider(user.collegeId));
    final routesAsync = ref.watch(collegeRoutesProvider(user.collegeId));

    return busesAsync.when(
      loading: () => const MapSkeletonLoader().p(16),
      error: (err, stack) => Center(child: Text('Error loading fleet map: $err')),
      data: (buses) {
        final routes = routesAsync.valueOrNull ?? [];

        return StudentMapTab(
          currentLocation: _currentLocation,
          buses: selectedBus != null &&
                  selectedBus.assignmentStatus == 'accepted' &&
                  liveBusIds.contains(selectedBus.id)
              ? [selectedBus]
              : const [],
          selectedBus: selectedBus != null && selectedBus.assignmentStatus == 'accepted'
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
          onRouteTypeSelected: (type) {
            ref.read(mapNavigationProvider.notifier).updateFilters(selectedRouteType: () => type);
          },
          onBusNumberSelected: (busNum) {
            ref.read(mapNavigationProvider.notifier).updateFilters(selectedBusNumber: () => busNum);
          },
          onClearFilters: () {
            ref.read(mapNavigationProvider.notifier).clearFilters();
          },
          onBusSelected: (bus) {
            if (bus != null && bus.assignmentStatus != 'accepted') {
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
            RouteModel? activeRoute;
            if (bus != null) {
              final targetRouteId = bus.routeId ?? bus.defaultRouteId;
              activeRoute = routes.cast<RouteModel?>().firstWhere(
                (r) => r!.id == targetRouteId,
                orElse: () => null,
              );
            }
            ref.read(mapNavigationProvider.notifier).selectBus(bus, activeRoute);
          },
          activeRoute: selectedBus != null && selectedBus.assignmentStatus == 'accepted'
              ? activeRoute
              : null,
        );
      },
    );
  }
}
