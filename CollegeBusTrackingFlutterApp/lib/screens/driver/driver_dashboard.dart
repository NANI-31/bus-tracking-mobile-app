import 'package:flutter/material.dart';
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
import 'widgets/driver_map_view.dart';
import 'dart:async';
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
    locationService.startLocationTracking(
      onLocationUpdate: (position) {
        socketService.updateLocation({
          'busId': _myBus!.id,
          'collegeId': authService.currentUserModel?.collegeId,
          'location': {'lat': position.latitude, 'lng': position.longitude},
          'speed': position.speed,
          'heading': position.heading,
        });
        if (mounted)
          setState(
            () => _currentLocation = LatLng(
              position.latitude,
              position.longitude,
            ),
          );
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

  void _stopLocationSharing() {
    final locationService = Provider.of<LocationService>(
      context,
      listen: false,
    );
    locationService.stopLocationTracking();
    setState(() => _isSharing = false);
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
  }

  Future<void> _handleRemoveAssignment() async {
    final dataService = Provider.of<DataService>(context, listen: false);
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
  }

  Future<void> _handleAcceptAssignment(String busId) async {
    final dataService = Provider.of<DataService>(context, listen: false);
    await dataService.acceptBusAssignment(busId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Assignment accepted!'),
        backgroundColor: AppColors.success,
      ),
    );
    _loadMyBus();
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
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning, width: 2),
      ),
      child: VStack([
        HStack([
          Icon(Icons.notification_important, color: AppColors.warning).shimmer(
            primaryColor: AppColors.warning,
            secondaryColor: Colors.white,
          ),
          12.widthBox,
          'Incoming Assignment'.text.xl.bold.color(AppColors.warning).make(),
        ]).pOnly(bottom: 12),
        'You have been assigned to Bus Number:'.text.make(),
        bus.busNumber.text.xl2.bold.make().pOnly(top: 4, bottom: 16),
        HStack(
          [
            ElevatedButton(
              onPressed: () => _handleAcceptAssignment(bus.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.onPrimary,
                minimumSize: const Size(120, 45),
              ),
              child: 'Accept'.text.make(),
            ).shimmer(
              primaryColor: AppColors.success,
              secondaryColor: Colors.white.withOpacity(0.5),
            ),
            16.widthBox,
            OutlinedButton(
              onPressed: () {
                // TODO: Implement reject assignment
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error),
                minimumSize: const Size(120, 45),
              ),
              child: 'Reject'.text.make(),
            ),
          ],
          axisSize: MainAxisSize.max,
          alignment: MainAxisAlignment.center,
        ),
      ]),
    );
  }

  Widget _buildLiveTrackingTab() {
    return VStack([
      DriverMapView(
        currentLocation: _currentLocation,
        mapStyle: _mapStyle,
        markers: _markers,
        polylines: _polylines,
        onMapCreated: (controller) {},
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
