import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:collegebus/shared/widgets/logout_confirmation_dialog.dart';
import 'package:collegebus/l10n/driver/app_localizations.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:velocity_x/velocity_x.dart';
// import 'package:provider/provider.dart'; // Removed legacy provider
import 'package:collegebus/core/services/persistence_service.dart';
import 'package:collegebus/core/services/secure_storage_service.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/core/providers/service_providers.dart';
import 'package:collegebus/features/bus/application/bus_provider.dart';
import 'package:collegebus/features/route/application/route_provider.dart';
import 'package:collegebus/core/providers/api_provider.dart';
import 'package:collegebus/core/providers/socket_provider.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/features/route/domain/route_model.dart';
import 'package:collegebus/core/constants/constants.dart';

import 'package:collegebus/core/utils/app_logger.dart';
import 'widgets/location_display.dart';
import 'widgets/bus_route_selectors.dart';
import 'widgets/bus_assignment_card.dart';
import 'widgets/live_tracking_control_panel.dart';
import 'package:collegebus/widgets/common/common_map_view.dart';
import 'dart:async';
import 'package:collegebus/shared/widgets/success_modal.dart';
import 'package:collegebus/shared/widgets/sos_button.dart';
import 'package:geolocator/geolocator.dart';
import 'package:collegebus/features/user/presentation/screens/profile_screen.dart';

class DriverDashboard extends ConsumerStatefulWidget {
  const DriverDashboard({super.key});

  @override
  ConsumerState<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends ConsumerState<DriverDashboard>
    with SingleTickerProviderStateMixin {
  int _bottomNavIndex = 0;
  LatLng? _currentLocation;
  bool _isSharing = false;

  // Selection state
  RouteModel? _selectedRoute;
  String? _selectedBusNumber;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadSavedSelections();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final socketService = ref.read(socketServiceProvider);
      final user = ref.read(currentUserProvider);
      if (user != null) {
        socketService.joinCollege(user.collegeId);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadSavedSelections() async {
    final busNumber = await SecureStorageService.getDriverBusNumber();

    if (mounted) {
      setState(() {
        if (busNumber != null) _selectedBusNumber = busNumber;
      });
      _updateMarkers();
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
    final polylinePoints = [
      startCoord,
      ...route.stopPoints.map(
        (s) => s.lat != 0
            ? LatLng(s.lat, s.lng)
            : _getMockCoordinateForLocation(s.name),
      ),
      endCoord,
    ];
    setState(() {
      _markers = markers;
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: polylinePoints,
          color: AppColors.primary,
          width: 4,
        ),
      };
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

  Future<void> _startLocationSharing(BusModel myBus) async {
    final locationService = ref.read(locationServiceProvider);
    final socketService = ref.read(socketServiceProvider);
    final user = ref.read(currentUserProvider);
    final api = ref.read(apiServiceProvider);

    // SECURITY: Re-verify location permission before each trip start
    final hasPermission = await locationService.checkLocationPermission();
    if (!hasPermission) {
      final granted = await locationService.requestLocationPermission();
      if (!granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              DriverLocalizations.of(context)!.locationNotAvailable,
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }
    }

    // Update bus status to live
    api.updateBusStatus(myBus.id, 'on-time').catchError((e) {
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
    setState(() => _isSharing = true);
    _saveSelections(myBus);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(DriverLocalizations.of(context)!.locationSharingStarted),
        backgroundColor: AppColors.success,
      ),
    );
  }

  DateTime? _lastDeviationAlertTime;

  String? _nextStopETA;

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
    final api = ref.read(apiServiceProvider);

    locationService.stopLocationTracking();

    // Revert bus status to offline
    if (myBus != null) {
      api.updateBusStatus(myBus.id, 'not-running').catchError((e) {
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

  Future<void> _handleAssignBus() async {
    final user = ref.read(currentUserProvider);
    final api = ref.read(apiServiceProvider);
    if (user == null || _selectedBusNumber == null || _selectedRoute == null) {
      return;
    }
    final newBus = BusModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      busNumber: _selectedBusNumber!,
      driverId: user.id,
      routeId: _selectedRoute!.id,
      collegeId: user.collegeId,
      createdAt: DateTime.now(),
    );
    try {
      await api.createBus(newBus);
      if (!mounted) return;
      await _saveSelections(newBus);
      _updateMarkers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(DriverLocalizations.of(context)!.busAssignedSuccess),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            DriverLocalizations.of(context)!.assignBusError(e.toString()),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleRemoveAssignment(BusModel myBus) async {
    final api = ref.read(apiServiceProvider);
    try {
      await api.deleteBus(myBus.id);
      await PersistenceService.remove('driver_bus_id');
      await PersistenceService.remove('driver_bus_number');
      await PersistenceService.remove('driver_route_id');
      if (!mounted) return;
      setState(() {
        _selectedBusNumber = null;
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

  Future<void> _handleAcceptAssignment(String busId) async {
    final api = ref.read(apiServiceProvider);
    try {
      await api.acceptBusAssignment(busId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(DriverLocalizations.of(context)!.assignmentAccepted),
            backgroundColor: AppColors.success,
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
              )!.acceptAssignmentError(e.toString()),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleRejectAssignment(String busId) async {
    final api = ref.read(apiServiceProvider);
    try {
      await api.rejectBusAssignment(busId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(DriverLocalizations.of(context)!.assignmentDeclined),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
        setState(() {
          _selectedBusNumber = null;
        });
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

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserProvider.select((u) => u?.id));
    final collegeId = ref.watch(
      currentUserProvider.select((u) => u?.collegeId),
    );
    final fullName = ref.watch(
      currentUserProvider.select((u) => u?.fullName ?? 'Driver'),
    );

    if (userId == null || collegeId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final myBusAsync = ref.watch(driverBusProvider(userId));
    final routesAsync = ref.watch(collegeRoutesProvider(collegeId));
    final busNumbersAsync = ref.watch(busNumbersProvider(collegeId));

    return myBusAsync.when(
      data: (myBus) {
        // Match selection from saved preferences on first load
        if (_selectedRoute == null && myBus?.routeId != null) {
          routesAsync.whenData((routes) {
            try {
              final route = routes.firstWhere((r) => r.id == myBus!.routeId);
              if (mounted) {
                setState(() {
                  _selectedRoute = route;
                  _selectedBusNumber = myBus?.busNumber;
                });
                _updateMarkers();
              }
            } catch (e) {
              debugPrint('Error matching route selection: $e');
            }
          });
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: DriverLocalizations.of(
              context,
            )!.welcomeDriver(fullName).text.ellipsis.make(),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  final confirmed = await LogoutConfirmationDialog.show(
                    context,
                  );
                  if (confirmed) {
                    await ref.read(authProvider.notifier).signOut();
                    if (context.mounted) context.go('/login');
                  }
                },
              ),
            ],
          ),
          body: IndexedStack(
            index: _bottomNavIndex,
            children: [
              _buildBusSetupTab(myBus, routesAsync, busNumbersAsync),
              _buildLiveTrackingTab(myBus),
              const ProfileScreen(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _bottomNavIndex,
            onDestinationSelected: (index) {
              setState(() => _bottomNavIndex = index);
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: DriverLocalizations.of(context)!.busSetupTab,
              ),
              NavigationDestination(
                icon: const Icon(Icons.map_outlined),
                selectedIcon: const Icon(Icons.map),
                label: DriverLocalizations.of(context)!.liveTrackingTab,
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) =>
          Scaffold(body: Center(child: Text('Error loading dashboard: $e'))),
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
          DriverLocalizations.of(
            context,
          )!.busRouteSelection.text.size(24).bold.make(),
          AppSizes.paddingLarge.heightBox,
          if (myBus == null)
            busNumbersAsync.when(
              data: (busNumbers) => routesAsync.when(
                data: (routes) => BusRouteSelectors(
                  selectedBusNumber: _selectedBusNumber,
                  selectedRoute: _selectedRoute,
                  busNumbers: busNumbers,
                  routes: routes,
                  onBusNumberChanged: (busNumber) =>
                      setState(() => _selectedBusNumber = busNumber),
                  onRouteChanged: (route) {
                    setState(() => _selectedRoute = route);
                    _updateMarkers();
                  },
                  onAssign: _handleAssignBus,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text('Error: $e'),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text('Error: $e'),
            )
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
            color: gradientColors.last.withOpacity(0.5),
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
              backgroundColor: Colors.white.withOpacity(0.1),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: CircleAvatar(
              radius: 80,
              backgroundColor: Colors.white.withOpacity(0.1),
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
                onPressed: () => _handleAcceptAssignment(bus.id),
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
      final api = ref.read(apiServiceProvider);
      try {
        _stopLocationSharing(myBus); // Stop tracking first
        // unassignDriverFromBus logic: set driverId to null, etc.
        await api.updateBus(myBus.id, {
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
            _selectedBusNumber = null;
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
              polylines: _polylines,
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
          child: SOSButton(
            currentLocation: _currentLocation,
            busId: myBus?.id,
            routeId: _selectedRoute?.id,
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
}
