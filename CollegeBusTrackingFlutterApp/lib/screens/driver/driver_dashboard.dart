import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'widgets/location_display.dart';
import 'widgets/bus_route_selectors.dart';
import 'widgets/bus_assignment_card.dart';
import 'widgets/live_tracking_control_panel.dart';
import 'widgets/driver_map_view.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  LatLng? _currentLocation;
  BusModel? _myBus;
  bool _isSharing = false;
  String? _mapStyle;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  List<RouteModel> _routes = [];
  RouteModel? _selectedRoute;
  List<String> _busNumbers = [];
  String? _selectedBusNumber;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _getCurrentLocation();
    _loadRoutes();
    _loadBusNumbers();
    _loadMyBus();
    _loadSavedSelections();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ThemeService>(
        context,
        listen: false,
      ).addListener(_handleThemeChange);
      _handleThemeChange();
    });
  }

  void _handleThemeChange() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    MapStyleHelper.getStyle(themeService.isDarkMode).then((style) {
      if (mounted) {
        setState(() => _mapStyle = style);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    Provider.of<ThemeService>(
      context,
      listen: false,
    ).removeListener(_handleThemeChange);
    super.dispose();
  }

  Future<void> _loadSavedSelections() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    if (!context.mounted) return;
    final userId = authService.currentUserModel?.id;

    if (userId != null) {
      final savedBusNumber = prefs.getString('driver_${userId}_bus_number');
      final savedRouteId = prefs.getString('driver_${userId}_route_id');

      if (savedBusNumber != null) {
        setState(() => _selectedBusNumber = savedBusNumber);
      }

      if (savedRouteId != null && _routes.isNotEmpty) {
        final route = _routes.firstWhere(
          (r) => r.id == savedRouteId,
          orElse: () => _routes.first,
        );
        setState(() => _selectedRoute = route);
      }
    }
  }

  Future<void> _saveSelections() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    if (!context.mounted) return;
    final userId = authService.currentUserModel?.id;

    if (userId != null) {
      if (_selectedBusNumber != null) {
        await prefs.setString(
          'driver_${userId}_bus_number',
          _selectedBusNumber!,
        );
      }
      if (_selectedRoute != null) {
        await prefs.setString('driver_${userId}_route_id', _selectedRoute!.id);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    final locationService = Provider.of<LocationService>(
      context,
      listen: false,
    );
    final location = await locationService.getCurrentLocation();
    if (!context.mounted) return;
    if (location != null) {
      setState(() {
        _currentLocation = location;
      });
      _updateMarkers();
    }
  }

  Future<void> _loadBusNumbers() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserModel;
    if (user == null) return;

    final dataService = Provider.of<DataService>(context, listen: false);
    final buses = await dataService.getBusesByCollege(user.collegeId).first;
    if (!context.mounted) return;
    setState(() {
      _busNumbers = buses.map((b) => b.busNumber).toList();
    });
  }

  Future<void> _loadRoutes() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserModel;
    if (user == null) return;

    final dataService = Provider.of<DataService>(context, listen: false);
    final routes = await dataService.getRoutesByCollege(user.collegeId).first;
    if (!context.mounted) return;
    setState(() => _routes = routes);
    _loadSavedSelections();
  }

  Future<void> _loadMyBus() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserModel;
    if (user == null) return;

    final dataService = Provider.of<DataService>(context, listen: false);
    final buses = await dataService.getBusesByCollege(user.collegeId).first;
    if (!context.mounted) return;

    final myBuses = buses.where((b) => b.driverId == user.id).toList();
    if (myBuses.isNotEmpty) {
      setState(() => _myBus = myBuses.first);
      if (_myBus!.routeId != null && _routes.isNotEmpty) {
        final route = _routes.firstWhere(
          (r) => r.id == _myBus!.routeId,
          orElse: () => _routes.first,
        );
        setState(() => _selectedRoute = route);
        _updateMarkers();
      }
    }
  }

  void _updateMarkers() {
    if (_selectedRoute == null) {
      setState(() => _markers = {});
      return;
    }

    final markers = <Marker>{};
    final route = _selectedRoute!;

    // Start marker
    final startCoord = _getMockCoordinateForLocation(route.startPoint.name);
    markers.add(
      Marker(
        markerId: const MarkerId('start'),
        position: startCoord,
        infoWindow: InfoWindow(title: 'Start: ${route.startPoint.name}'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );

    // End marker
    final endCoord = _getMockCoordinateForLocation(route.endPoint.name);
    markers.add(
      Marker(
        markerId: const MarkerId('end'),
        position: endCoord,
        infoWindow: InfoWindow(title: 'End: ${route.endPoint.name}'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    // Stop markers
    for (var i = 0; i < route.stopPoints.length; i++) {
      final stop = route.stopPoints[i];
      final coord = _getMockCoordinateForLocation(stop.name);
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

    // Create polyline
    final polylinePoints = [startCoord];
    for (var stop in route.stopPoints) {
      polylinePoints.add(_getMockCoordinateForLocation(stop.name));
    }
    polylinePoints.add(endCoord);

    final polylines = <Polyline>{
      Polyline(
        polylineId: const PolylineId('route'),
        points: polylinePoints,
        color: AppColors.primary,
        width: 4,
      ),
    };

    setState(() {
      _markers = markers;
      _polylines = polylines;
    });
  }

  LatLng _getMockCoordinateForLocation(String location) {
    final base = _currentLocation ?? const LatLng(17.385, 78.4867);
    final hash = location.hashCode;
    final latOffset = (hash % 100) / 10000.0;
    final lngOffset = ((hash ~/ 100) % 100) / 10000.0;
    return LatLng(base.latitude + latOffset, base.longitude + lngOffset);
  }

  Future<void> _toggleLocationSharing() async {
    if (!_isSharing) {
      if (_myBus == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please assign a bus first')),
        );
        return;
      }

      final locationService = Provider.of<LocationService>(
        context,
        listen: false,
      );
      final socketService = Provider.of<SocketService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final messenger = ScaffoldMessenger.of(context);
      if (!context.mounted) return;

      await locationService.startLocationTracking(
        onLocationUpdate: (location) async {
          socketService.updateLocation({
            'busId': _myBus!.id,
            'collegeId': authService.currentUserModel?.collegeId,
            'location': {'lat': location.latitude, 'lng': location.longitude},
          });
        },
      );

      if (!context.mounted) return;
      setState(() => _isSharing = true);
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Location sharing started'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      final locationService = Provider.of<LocationService>(
        context,
        listen: false,
      );
      locationService.stopLocationTracking();
      setState(() => _isSharing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Location sharing stopped')));
    }
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

    await dataService.createBus(newBus);
    await _saveSelections();
    if (!context.mounted) return;
    setState(() => _myBus = newBus);
    _updateMarkers();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Bus assigned successfully!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _handleRemoveAssignment() async {
    final dataService = Provider.of<DataService>(context, listen: false);
    await dataService.deleteBus(_myBus!.id);

    final prefs = await SharedPreferences.getInstance();
    if (!context.mounted) return;
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUserModel?.id;
    if (userId != null) {
      await prefs.remove('driver_${userId}_bus_number');
      await prefs.remove('driver_${userId}_route_id');
    }

    if (!context.mounted) return;
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
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUserModel;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: 'Welcome, ${user?.fullName ?? 'Driver'}'.text.make(),
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
        children: [
          // Bus Setup Tab
          _buildBusSetupTab(),
          // Live Tracking Tab
          _buildLiveTrackingTab(),
        ],
      ),
    );
  }

  Widget _buildBusSetupTab() {
    return VStack([
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
            onBusNumberChanged: (busNumber) {
              setState(() => _selectedBusNumber = busNumber);
            },
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
      ]).p(AppSizes.paddingMedium).expand(),
    ]);
  }

  Widget _buildLiveTrackingTab() {
    return VStack([
      DriverMapView(
        currentLocation: _currentLocation,
        mapStyle: _mapStyle,
        markers: _markers,
        polylines: _polylines,
        onMapCreated: (controller) {
          debugPrint('DEBUG: Driver GoogleMap created successfully');
        },
      ).expand(),
      LiveTrackingControlPanel(
        bus: _myBus,
        route: _selectedRoute,
        isSharing: _isSharing,
        currentLocation: _currentLocation,
        onToggleSharing: _toggleLocationSharing,
      ),
    ]);
  }
}
