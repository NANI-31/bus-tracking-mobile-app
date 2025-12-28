import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/services/data_service.dart';
import 'package:collegebus/services/location_service.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/models/route_model.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/utils/map_style_helper.dart';
import 'package:collegebus/services/theme_service.dart';
import 'package:collegebus/services/socket_service.dart';
import 'package:collegebus/services/persistence_service.dart';
import 'widgets/location_display.dart';
import 'widgets/bus_route_selectors.dart';
import 'widgets/bus_assignment_card.dart';
import 'widgets/live_tracking_control_panel.dart';
import 'package:collegebus/widgets/common/common_map_view.dart';
import 'dart:async';
import 'package:collegebus/widgets/success_modal.dart';
import 'package:collegebus/widgets/sos_button.dart';
import 'package:geolocator/geolocator.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  LatLng? _currentLocation;
  bool _isSharing = false;
  BusModel? _myBus;
  RouteModel? _selectedRoute;
  String? _selectedBusNumber;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  StreamSubscription<Position>? _positionSubscription;
  String? _mapStyle;

  List<RouteModel> _routes = [];
  List<String> _busNumbers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _getCurrentLocation();
    _loadRoutes();
    _loadBusNumbers();
    _loadMyBus().then((_) => _loadSavedSelections());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ThemeService>(
        context,
        listen: false,
      ).addListener(_handleThemeChange);
      Provider.of<DataService>(context, listen: false).addListener(_loadMyBus);
      _handleThemeChange();
    });
  }

  void _handleThemeChange() {
    if (!mounted) return;
    final themeService = Provider.of<ThemeService>(context, listen: false);
    MapStyleHelper.getStyle(themeService.isDarkMode).then((style) {
      if (mounted) setState(() => _mapStyle = style);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _positionSubscription?.cancel();
    final themeService = Provider.of<ThemeService>(context, listen: false);
    themeService.removeListener(_handleThemeChange);
    final dataService = Provider.of<DataService>(context, listen: false);
    dataService.removeListener(_loadMyBus);
    super.dispose();
  }

  Future<void> _loadSavedSelections() async {
    final busId = PersistenceService.getString('driver_bus_id');
    final routeId = PersistenceService.getString('driver_route_id');
    final busNumber = PersistenceService.getString('driver_bus_number');
    final isSharing = PersistenceService.getIsSharingLocation();

    if (mounted) {
      setState(() {
        if (busId != null && _myBus == null) {
          _myBus = BusModel(
            id: busId,
            busNumber: busNumber ?? '',
            driverId: '',
            routeId: routeId ?? '',
            collegeId: '',
            isActive: true,
            createdAt: DateTime.now(),
          );
        }
        if (busNumber != null) _selectedBusNumber = busNumber;
        if (routeId != null) {
          final existingRoute = _routes.firstWhere(
            (r) => r.id == routeId,
            orElse: () => _routes.isNotEmpty
                ? _routes.first
                : RouteModel(
                    id: routeId,
                    routeName: '',
                    routeType: '',
                    startPoint: RoutePoint(name: '', lat: 0, lng: 0),
                    endPoint: RoutePoint(name: '', lat: 0, lng: 0),
                    stopPoints: [],
                    collegeId: '',
                    createdBy: '',
                    isActive: true,
                    createdAt: DateTime.now(),
                  ),
          );
          _selectedRoute = existingRoute;
        }
        _isSharing = isSharing;
      });

      if (_isSharing && _myBus != null) {
        _startLocationSharing();
      }
      _updateMarkers();
    }
  }

  Future<void> _saveSelections() async {
    if (_myBus != null) {
      await PersistenceService.setString('driver_bus_id', _myBus!.id);
      await PersistenceService.setString(
        'driver_bus_number',
        _myBus!.busNumber,
      );
      if (_selectedRoute != null) {
        await PersistenceService.setString(
          'driver_route_id',
          _selectedRoute!.id,
        );
      }
    }
    await PersistenceService.setIsSharingLocation(_isSharing);
  }

  Future<void> _getCurrentLocation() async {
    final locationService = Provider.of<LocationService>(
      context,
      listen: false,
    );
    final location = await locationService.getCurrentLocation();
    if (location != null && mounted) {
      setState(() => _currentLocation = location);
      _updateMarkers();
    }
  }

  Future<void> _loadBusNumbers() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserModel;
    if (user == null) return;
    final dataService = Provider.of<DataService>(context, listen: false);
    final buses = await dataService.getBusesByCollege(user.collegeId).first;
    if (mounted)
      setState(() => _busNumbers = buses.map((b) => b.busNumber).toList());
  }

  Future<void> _loadRoutes() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserModel;
    if (user == null) return;
    final dataService = Provider.of<DataService>(context, listen: false);
    final routes = await dataService.getRoutesByCollege(user.collegeId).first;
    if (mounted) setState(() => _routes = routes);
  }

  Future<void> _loadMyBus() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserModel;
    if (user == null) return;
    final dataService = Provider.of<DataService>(context, listen: false);
    final bus = await dataService.getBusByDriver(user.id);
    if (bus != null && mounted) {
      setState(() {
        _myBus = bus;
        _selectedBusNumber = bus.busNumber;
        if (bus.routeId != null && _routes.isNotEmpty) {
          try {
            _selectedRoute = _routes.firstWhere((r) => r.id == bus.routeId);
            // ignore: empty_catches
          } catch (e) {}
        }
      });
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
        infoWindow: InfoWindow(title: 'Start: ${route.startPoint.name}'),
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
        infoWindow: InfoWindow(title: 'End: ${route.endPoint.name}'),
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
          infoWindow: InfoWindow(title: 'Stop ${i + 1}: ${stop.name}'),
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

  Future<void> _toggleLocationSharing() async {
    if (!_isSharing) {
      if (_myBus == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please assign a bus first')),
        );
        return;
      }
      _startLocationSharing();
    } else {
      _stopLocationSharing();
    }
  }

  void _startLocationSharing() {
    final locationService = Provider.of<LocationService>(
      context,
      listen: false,
    );
    final socketService = Provider.of<SocketService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final dataService = Provider.of<DataService>(context, listen: false);

    // Update bus status to live
    dataService.updateBusStatus(_myBus!.id, 'on-time').catchError((e) {
      if (kDebugMode) print('Failed to update bus status: $e');
    });

    locationService.startLocationTracking(
      onLocationUpdate: (position) {
        socketService.updateLocation({
          'busId': _myBus!.id,
          'collegeId': authService.currentUserModel?.collegeId,
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
          _checkRouteDeviation(position);
        }
      },
    );
    setState(() => _isSharing = true);
    _saveSelections();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Location sharing started'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  DateTime? _lastDeviationAlertTime;

  String? _nextStopETA;

  void _checkRouteDeviation(Position position) {
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
              '⚠️ You are off route! (${minDistance.toInt()}m away)',
            ),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    // ETA Calculation
    _calculateETA(position);
  }

  void _calculateETA(Position position) {
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
          _nextStopETA = '$timeMinutes min to ${nextStop!.name}';
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
    if (lenSq != 0) // in case of 0 length line
      param = dot / lenSq;

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

  void _stopLocationSharing() {
    final locationService = Provider.of<LocationService>(
      context,
      listen: false,
    );
    final dataService = Provider.of<DataService>(context, listen: false);

    locationService.stopLocationTracking();

    // Revert bus status to offline
    if (_myBus != null) {
      dataService.updateBusStatus(_myBus!.id, 'not-running').catchError((e) {
        if (kDebugMode) print('Failed to update bus status: $e');
      });
    }

    if (mounted) {
      setState(() {
        _isSharing = false;
        _nextStopETA = null;
      });
    }
    _saveSelections();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Location sharing stopped')));
  }

  Future<void> _handleAssignBus() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final dataService = Provider.of<DataService>(context, listen: false);
    final currentUser = authService.currentUserModel;
    if (currentUser == null) return;
    final newBus = BusModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      busNumber: _selectedBusNumber!,
      driverId: currentUser.id,
      routeId: _selectedRoute!.id,
      collegeId: currentUser.collegeId,
      createdAt: DateTime.now(),
    );
    try {
      await dataService.createBus(newBus);
      if (!mounted) return;
      setState(() => _myBus = newBus);
      await _saveSelections();
      _updateMarkers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bus assigned successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to assign bus: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleRemoveAssignment() async {
    final dataService = Provider.of<DataService>(context, listen: false);
    try {
      if (_myBus != null) await dataService.deleteBus(_myBus!.id);
      await PersistenceService.remove('driver_bus_id');
      await PersistenceService.remove('driver_bus_number');
      await PersistenceService.remove('driver_route_id');
      if (!mounted) return;
      setState(() {
        _myBus = null;
        _selectedBusNumber = null;
        _selectedRoute = null;
      });
      _updateMarkers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bus assignment removed'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove assignment: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleAcceptAssignment(String busId) async {
    final dataService = Provider.of<DataService>(context, listen: false);
    try {
      await dataService.acceptBusAssignment(busId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Assignment accepted!'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadMyBus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleRejectAssignment(String busId) async {
    final dataService = Provider.of<DataService>(context, listen: false);
    try {
      await dataService.rejectBusAssignment(busId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Assignment declined'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
        setState(() {
          _myBus = null;
          _selectedBusNumber = null;
        });
        _loadMyBus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUserModel;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: 'Welcome, ${user?.fullName ?? 'Driver'}'.text.ellipsis.make(),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.onPrimary,
          unselectedLabelColor: Theme.of(
            context,
          ).colorScheme.onPrimary.withValues(alpha: 0.7),
          indicatorColor: Theme.of(context).colorScheme.onPrimary,
          tabs: const [
            Tab(text: 'Bus Setup', icon: Icon(Icons.settings)),
            Tab(text: 'Live Tracking', icon: Icon(Icons.map)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildBusSetupTab(), _buildLiveTrackingTab()],
      ),
    );
  }

  Widget _buildBusSetupTab() {
    if (_myBus != null && _myBus!.assignmentStatus == 'pending') {
      return _buildPendingAssignmentUI(_myBus!).p(AppSizes.paddingMedium);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      child: VStack([
        LocationDisplay(currentLocation: _currentLocation),
        VStack([
          'Bus & Route Selection'.text.size(24).bold.make(),
          AppSizes.paddingLarge.heightBox,
          if (_myBus == null)
            BusRouteSelectors(
              selectedBusNumber: _selectedBusNumber,
              selectedRoute: _selectedRoute,
              busNumbers: _busNumbers,
              routes: _routes,
              onBusNumberChanged: (busNumber) =>
                  setState(() => _selectedBusNumber = busNumber),
              onRouteChanged: (route) {
                setState(() => _selectedRoute = route);
                _updateMarkers();
              },
              onAssign: _handleAssignBus,
            )
          else
            BusAssignmentCard(
              bus: _myBus!,
              route: _selectedRoute,
              onRemove: _handleRemoveAssignment,
            ),
        ]),
      ]),
    );
  }

  Widget _buildPendingAssignmentUI(BusModel bus) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Glossy Gradient Colors
    final gradientColors = isDark
        ? [
            const Color(0xFF2E3192),
            const Color(0xFF1BFFFF),
          ] // Deep Blue -> Cyan
        : [
            const Color(0xFF667EEA),
            const Color(0xFF764BA2),
          ]; // Soft Blue -> Purple

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

            'Bus Number'.text.white.white.make().opacity(value: 0.8),
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

  Future<void> _handleTripComplete() async {
    if (_myBus == null) return;

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
      final dataService = Provider.of<DataService>(context, listen: false);
      try {
        _stopLocationSharing(); // Stop tracking first
        await dataService.unassignDriverFromBus(_myBus!.id);

        await PersistenceService.remove('driver_bus_id');
        await PersistenceService.remove('driver_bus_number');
        await PersistenceService.remove('driver_route_id');

        if (mounted) {
          setState(() {
            _myBus = null;
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

  Widget _buildLiveTrackingTab() {
    return Stack(
      children: [
        Column(
          children: [
            CommonMapView(
              currentLocation: _currentLocation,
              mapStyle: _mapStyle,
              markers: _markers,
              polylines: _polylines,
              onMapCreated: (controller) {},
              initialZoom: 16.0,
            ).expand(),
            LiveTrackingControlPanel(
              bus: _myBus,
              route: _selectedRoute,
              isSharing: _isSharing,
              currentLocation: _currentLocation,
              onToggleSharing: _toggleLocationSharing,
            ),
          ],
        ),
        // Trip Complete Floating Button (Visible only when tracking is active or assignment is accepted)
        if (_myBus != null && _myBus!.assignmentStatus == 'accepted')
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: _handleTripComplete,
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
            busId: _myBus?.id,
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
