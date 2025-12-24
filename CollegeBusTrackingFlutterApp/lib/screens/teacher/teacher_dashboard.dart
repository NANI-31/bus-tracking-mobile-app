import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/services/firestore_service.dart';
import 'package:collegebus/services/location_service.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/models/route_model.dart';
import 'package:collegebus/models/user_model.dart';
import 'package:collegebus/utils/constants.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  List<BusModel> _allBuses = [];
  List<BusModel> _filteredBuses = [];
  BusModel? _selectedBus;
  LatLng? _currentLocation;
  List<UserModel> _pendingStudents = [];
  String? _selectedStop;
  String? _selectedBusNumber;
  String? _selectedRouteType;
  List<RouteModel> _routes = [];
  Set<Polyline> _polylines = {};
  Map<String, StreamSubscription> _busLocationSubscriptions = {};

  // Get unique stops from all buses
  List<String> get _allStops {
    final stops = <String>{};
    for (final bus in _allBuses) {
      final route = _routes.firstWhere(
        (r) => r.id == bus.routeId,
        orElse: () => RouteModel(
          id: '',
          routeName: 'N/A',
          routeType: '',
          startPoint: '',
          endPoint: '',
          stopPoints: [],
          collegeId: '',
          createdBy: '',
          isActive: false,
          createdAt: DateTime.now(),
        ),
      );
      stops.add(route.startPoint);
      stops.add(route.endPoint);
      stops.addAll(route.stopPoints);
    }
    return stops.toList()..sort();
  }

  // Get unique bus numbers
  List<String> get _allBusNumbers {
    return _allBuses.map((bus) => bus.busNumber).toSet().toList()..sort();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _getCurrentLocation();
    _loadRoutes();
    _loadBuses();
    _loadPendingStudents();
    _loadSavedFilters();
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Cancel all location subscriptions
    for (final subscription in _busLocationSubscriptions.values) {
      subscription.cancel();
    }
    _busLocationSubscriptions.clear();
    super.dispose();
  }

  Future<void> _loadSavedFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUserModel?.id;

    if (userId != null) {
      final savedStop = prefs.getString('teacher_${userId}_selected_stop');
      final savedBusNumber = prefs.getString('teacher_${userId}_selected_bus');
      final savedRouteType = prefs.getString(
        'teacher_${userId}_selected_route_type',
      );

      setState(() {
        _selectedStop = savedStop;
        _selectedBusNumber = savedBusNumber;
        _selectedRouteType = savedRouteType;
      });

      _applyFilters();
    }
  }

  Future<void> _saveFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUserModel?.id;

    if (userId != null) {
      if (_selectedStop != null) {
        await prefs.setString(
          'teacher_${userId}_selected_stop',
          _selectedStop!,
        );
      } else {
        await prefs.remove('teacher_${userId}_selected_stop');
      }

      if (_selectedBusNumber != null) {
        await prefs.setString(
          'teacher_${userId}_selected_bus',
          _selectedBusNumber!,
        );
      } else {
        await prefs.remove('teacher_${userId}_selected_bus');
      }

      if (_selectedRouteType != null) {
        await prefs.setString(
          'teacher_${userId}_selected_route_type',
          _selectedRouteType!,
        );
      } else {
        await prefs.remove('teacher_${userId}_selected_route_type');
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    final locationService = Provider.of<LocationService>(
      context,
      listen: false,
    );
    final location = await locationService.getCurrentLocation();
    if (location != null) {
      setState(() {
        _currentLocation = location;
        _updateMarkers();
      });
    }
  }

  Future<void> _loadBuses() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(
      context,
      listen: false,
    );

    final collegeId = authService.currentUserModel?.collegeId;
    if (collegeId != null) {
      firestoreService.getBusesByCollege(collegeId).listen((buses) {
        // Cancel existing subscriptions
        for (final subscription in _busLocationSubscriptions.values) {
          subscription.cancel();
        }
        _busLocationSubscriptions.clear();

        setState(() {
          _allBuses = buses;
          _applyFilters();
          _updateMarkers();
        });

        // Set up location listeners for each bus
        _setupBusLocationListeners(buses, firestoreService);
      });
    }
  }

  Future<void> _loadPendingStudents() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(
      context,
      listen: false,
    );

    final collegeId = authService.currentUserModel?.collegeId;
    if (collegeId != null) {
      firestoreService.getPendingApprovals(collegeId).listen((students) {
        setState(() {
          _pendingStudents = students
              .where((user) => user.role == UserRole.student)
              .toList();
        });
      });
    }
  }

  Future<void> _loadRoutes() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(
      context,
      listen: false,
    );
    final collegeId = authService.currentUserModel?.collegeId;
    if (collegeId != null) {
      firestoreService.getRoutesByCollege(collegeId).listen((routes) {
        setState(() {
          _routes = routes;
        });
      });
    }
  }

  void _setupBusLocationListeners(
    List<BusModel> buses,
    FirestoreService firestoreService,
  ) {
    for (final bus in buses) {
      final subscription = firestoreService.getBusLocation(bus.id).listen((
        location,
      ) {
        if (mounted) {
          _updateBusMarker(bus, location);
        }
      });
      _busLocationSubscriptions[bus.id] = subscription;
    }
  }

  void _updateBusMarker(BusModel bus, BusLocationModel? location) {
    final route = _routes.firstWhere(
      (r) => r.id == bus.routeId,
      orElse: () => RouteModel(
        id: '',
        routeName: 'N/A',
        routeType: '',
        startPoint: '',
        endPoint: '',
        stopPoints: [],
        collegeId: '',
        createdBy: '',
        isActive: false,
        createdAt: DateTime.now(),
      ),
    );

    final marker = Marker(
      markerId: MarkerId('bus_${bus.id}'),
      position:
          location?.currentLocation ??
          _getMockCoordinateForLocation(route.startPoint),
      infoWindow: InfoWindow(
        title:
            'Bus ${bus.busNumber} ${location != null ? "(Live)" : "(Not Live)"}',
        snippet:
            '${route.startPoint} → ${route.endPoint}\n${location != null ? 'Last updated: ${location.timestamp.toString().substring(11, 16)}' : 'Status: Offline'}',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        _selectedBus?.id == bus.id
            ? BitmapDescriptor.hueRed
            : location != null
            ? BitmapDescriptor.hueGreen
            : BitmapDescriptor.hueOrange,
      ),
      onTap: () => _selectBus(bus),
    );

    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'bus_${bus.id}');
      _markers.add(marker);
    });
  }

  void _applyFilters() {
    List<BusModel> filtered = List.from(_allBuses);

    // Filter by route type
    if (_selectedRouteType != null) {
      filtered = filtered.where((bus) {
        final route = _routes.firstWhere(
          (r) => r.id == bus.routeId,
          orElse: () => RouteModel(
            id: '',
            routeName: 'N/A',
            routeType: '',
            startPoint: '',
            endPoint: '',
            stopPoints: [],
            collegeId: '',
            createdBy: '',
            isActive: false,
            createdAt: DateTime.now(),
          ),
        );
        return route.routeType == _selectedRouteType;
      }).toList();
    }

    // Filter by selected stop
    if (_selectedStop != null) {
      filtered = filtered.where((bus) {
        final route = _routes.firstWhere(
          (r) => r.id == bus.routeId,
          orElse: () => RouteModel(
            id: '',
            routeName: 'N/A',
            routeType: '',
            startPoint: '',
            endPoint: '',
            stopPoints: [],
            collegeId: '',
            createdBy: '',
            isActive: false,
            createdAt: DateTime.now(),
          ),
        );
        return route.startPoint == _selectedStop ||
            route.endPoint == _selectedStop ||
            route.stopPoints.contains(_selectedStop);
      }).toList();
    }

    // Filter by selected bus number
    if (_selectedBusNumber != null) {
      filtered = filtered
          .where((bus) => bus.busNumber == _selectedBusNumber)
          .toList();
    }

    setState(() {
      _filteredBuses = filtered;
    });

    _saveFilters();
  }

  void _updateMarkers() {
    final newMarkers = <Marker>{};

    // Add current location marker
    if (_currentLocation != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentLocation!,
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    // Add bus markers for filtered buses
    for (final bus in _filteredBuses) {
      _addBusMarker(bus, newMarkers);
    }

    // If a bus is selected, show its route
    if (_selectedBus != null) {
      _addBusRoutePolyline(_selectedBus!);
    } else {
      setState(() {
        _polylines = {};
      });
    }

    setState(() {
      _markers = newMarkers;
    });
  }

  void _addBusRoutePolyline(BusModel bus) {
    final route = _routes.firstWhere(
      (r) => r.id == bus.routeId,
      orElse: () => RouteModel(
        id: '',
        routeName: 'N/A',
        routeType: '',
        startPoint: '',
        endPoint: '',
        stopPoints: [],
        collegeId: '',
        createdBy: '',
        isActive: false,
        createdAt: DateTime.now(),
      ),
    );

    final routePoints = <LatLng>[];
    final startCoord = _getMockCoordinateForLocation(route.startPoint);
    routePoints.add(startCoord);

    for (final stop in route.stopPoints) {
      routePoints.add(_getMockCoordinateForLocation(stop));
    }

    final endCoord = _getMockCoordinateForLocation(route.endPoint);
    routePoints.add(endCoord);

    final polyline = Polyline(
      polylineId: PolylineId('route_${bus.id}'),
      points: routePoints,
      color: Colors.blue,
      width: 4,
    );

    setState(() {
      _polylines = {polyline};
    });

    // Add stop markers
    for (int i = 0; i < routePoints.length; i++) {
      final stopName = i == 0
          ? route.startPoint
          : i == routePoints.length - 1
          ? route.endPoint
          : route.stopPoints[i - 1];

      _markers.add(
        Marker(
          markerId: MarkerId('stop_${bus.id}_$i'),
          position: routePoints[i],
          infoWindow: InfoWindow(
            title: stopName,
            snippet: i == 0
                ? 'Start Point'
                : i == routePoints.length - 1
                ? 'End Point'
                : 'Stop',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            i == 0
                ? BitmapDescriptor.hueGreen
                : i == routePoints.length - 1
                ? BitmapDescriptor.hueRed
                : BitmapDescriptor.hueYellow,
          ),
        ),
      );
    }
  }

  LatLng _getMockCoordinateForLocation(String location) {
    final mockCoords = {
      'Central Station': const LatLng(12.9716, 77.5946),
      'City Center': const LatLng(12.9726, 77.5956),
      'Shopping Mall': const LatLng(12.9736, 77.5966),
      'Hospital': const LatLng(12.9746, 77.5976),
      'University Campus': const LatLng(12.9756, 77.5986),
      'Airport': const LatLng(12.9766, 77.5996),
      'Hotel District': const LatLng(12.9776, 77.6006),
      'Business Park': const LatLng(12.9786, 77.6016),
      'Suburban Area': const LatLng(12.9796, 77.6026),
      'Residential Area': const LatLng(12.9806, 77.6036),
      'Park': const LatLng(12.9816, 77.6046),
    };

    return mockCoords[location] ??
        _currentLocation ??
        const LatLng(12.9716, 77.5946);
  }

  void _addBusMarker(BusModel bus, Set<Marker> markers) {
    final route = _routes.firstWhere(
      (r) => r.id == bus.routeId,
      orElse: () => RouteModel(
        id: '',
        routeName: 'N/A',
        routeType: '',
        startPoint: '',
        endPoint: '',
        stopPoints: [],
        collegeId: '',
        createdBy: '',
        isActive: false,
        createdAt: DateTime.now(),
      ),
    );

    // Show bus at start point initially (will be updated by location listener)
    final startLocation = _getMockCoordinateForLocation(route.startPoint);
    final marker = Marker(
      markerId: MarkerId('bus_${bus.id}'),
      position: startLocation,
      infoWindow: InfoWindow(
        title: 'Bus ${bus.busNumber} (Loading...)',
        snippet: '${route.startPoint} → ${route.endPoint}\nStatus: Loading...',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      onTap: () => _selectBus(bus),
    );

    markers.add(marker);
  }

  void _selectBus(BusModel bus) {
    setState(() {
      _selectedBus = bus;
    });

    // Move camera to bus location if available
    final firestoreService = Provider.of<FirestoreService>(
      context,
      listen: false,
    );
    firestoreService.getBusLocation(bus.id).listen((location) {
      if (location != null && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(location.currentLocation, 16.0),
        );
      }
    });
  }

  void _onStopSelected(String? stop) {
    setState(() {
      _selectedStop = stop;
    });
    _applyFilters();
    _updateMarkers();
  }

  void _onBusNumberSelected(String? busNumber) {
    setState(() {
      _selectedBusNumber = busNumber;
    });
    _applyFilters();
    _updateMarkers();
  }

  void _onRouteTypeSelected(String? routeType) {
    setState(() {
      _selectedRouteType = routeType;
    });
    _applyFilters();
    _updateMarkers();
  }

  void _clearFilters() {
    setState(() {
      _selectedStop = null;
      _selectedBusNumber = null;
      _selectedRouteType = null;
      _selectedBus = null;
      _polylines.clear();
    });
    _applyFilters();
    _updateMarkers();
  }

  Future<void> _approveStudent(UserModel student) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(
      context,
      listen: false,
    );

    final currentUser = authService.currentUserModel;
    if (currentUser != null) {
      await firestoreService.approveUser(student.id, currentUser.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${student.fullName} has been approved'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _rejectStudent(UserModel student) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(
      context,
      listen: false,
    );

    final currentUser = authService.currentUserModel;
    if (currentUser != null) {
      await firestoreService.rejectUser(student.id, currentUser.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${student.fullName} has been rejected'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUserModel;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: 'Welcome, ${user?.fullName ?? 'Teacher'}'.text.make(),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Notifications will be implemented in future updates
            },
          ),
          IconButton(
            icon: const Icon(Icons.schedule),
            onPressed: () => context.go('/teacher/schedule'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                context.go('/login');
              }
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
            Tab(text: 'Track Buses', icon: Icon(Icons.map)),
            Tab(text: 'Bus List', icon: Icon(Icons.list)),
            Tab(text: 'Approvals', icon: Icon(Icons.approval)),
            Tab(text: 'Bus Info', icon: Icon(Icons.info)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Bus Tracking Tab
          VStack([
            // Location display
            HStack([
                  Icon(
                    Icons.location_on,
                    color: _currentLocation != null
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).colorScheme.error,
                  ),
                  AppSizes.paddingSmall.widthBox,
                  (_currentLocation != null
                          ? 'Your Location: ${_currentLocation!.latitude.toStringAsFixed(4)}, ${_currentLocation!.longitude.toStringAsFixed(4)}'
                          : 'Location not available. Please enable location services.')
                      .text
                      .color(
                        _currentLocation != null
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).colorScheme.error,
                      )
                      .medium
                      .make()
                      .expand(),
                ])
                .p(AppSizes.paddingMedium)
                .box
                .color(
                  _currentLocation != null
                      ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                      : Theme.of(
                          context,
                        ).colorScheme.error.withValues(alpha: 0.1),
                )
                .make(),

            // Filter Controls
            VStack([
                  HStack([
                    DropdownButtonFormField<String>(
                      value: _selectedRouteType,
                      decoration: const InputDecoration(
                        labelText: 'Route Type',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Types'),
                        ),
                        DropdownMenuItem(
                          value: 'pickup',
                          child: Text('Pickup'),
                        ),
                        DropdownMenuItem(value: 'drop', child: Text('Drop')),
                      ],
                      onChanged: _onRouteTypeSelected,
                    ).expand(),
                    AppSizes.paddingSmall.widthBox,
                    DropdownButtonFormField<String>(
                      value: _selectedStop,
                      decoration: const InputDecoration(
                        labelText: 'Bus Stop',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Stops'),
                        ),
                        ..._allStops.map(
                          (stop) =>
                              DropdownMenuItem(value: stop, child: Text(stop)),
                        ),
                      ],
                      onChanged: _onStopSelected,
                    ).expand(),
                  ]),
                  AppSizes.paddingSmall.heightBox,
                  HStack([
                    DropdownButtonFormField<String>(
                      value: _selectedBusNumber,
                      decoration: const InputDecoration(
                        labelText: 'Bus Number',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Buses'),
                        ),
                        ..._allBusNumbers.map(
                          (busNumber) => DropdownMenuItem(
                            value: busNumber,
                            child: Text(busNumber),
                          ),
                        ),
                      ],
                      onChanged: _onBusNumberSelected,
                    ).expand(),
                    AppSizes.paddingSmall.widthBox,
                    if (_selectedStop != null ||
                        _selectedBusNumber != null ||
                        _selectedRouteType != null)
                      ElevatedButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.secondary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onSecondary,
                        ),
                      ),
                  ]),
                  if (_selectedStop != null ||
                      _selectedBusNumber != null ||
                      _selectedRouteType != null)
                    VStack([
                      AppSizes.paddingSmall.heightBox,
                      '${_filteredBuses.length} bus(es) found'.text
                          .color(
                            Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                          )
                          .size(12)
                          .make(),
                    ]),
                ])
                .p(AppSizes.paddingMedium)
                .box
                .color(Theme.of(context).colorScheme.surface)
                .make(),

            // Map
            (_currentLocation != null
                    ? GoogleMap(
                        onMapCreated: (GoogleMapController controller) {
                          _mapController = controller;
                          print(
                            'DEBUG: Teacher GoogleMap created successfully',
                          );
                        },
                        initialCameraPosition: CameraPosition(
                          target: _currentLocation!,
                          zoom: 14.0,
                        ),
                        markers: _markers,
                        polylines: _polylines,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        mapType: MapType.normal,
                      )
                    : const CircularProgressIndicator().centered())
                .expand(),

            // Selected bus info
            if (_selectedBus != null)
              VStack([
                    HStack([
                      CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Icon(
                          Icons.directions_bus,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                      AppSizes.paddingMedium.widthBox,
                      VStack([
                        'Bus ${_selectedBus!.busNumber}'.text
                            .size(20)
                            .bold
                            .color(Theme.of(context).colorScheme.onSurface)
                            .make(),
                        'Route: ${_routes.firstWhere(
                              (r) => r.id == _selectedBus!.routeId,
                              orElse: () => RouteModel(id: '', routeName: 'N/A', routeType: '', startPoint: '', endPoint: '', stopPoints: [], collegeId: '', createdBy: '', isActive: false, createdAt: DateTime.now()),
                            ).startPoint} → ${_routes.firstWhere(
                              (r) => r.id == _selectedBus!.routeId,
                              orElse: () => RouteModel(id: '', routeName: 'N/A', routeType: '', startPoint: '', endPoint: '', stopPoints: [], collegeId: '', createdBy: '', isActive: false, createdAt: DateTime.now()),
                            ).endPoint}'
                            .text
                            .size(16)
                            .color(
                              Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                            )
                            .make(),
                      ]).expand(),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _selectedBus = null;
                            _polylines.clear();
                          });
                          _updateMarkers();
                        },
                        icon: const Icon(Icons.close),
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ]),
                    AppSizes.paddingMedium.heightBox,
                    HStack([
                          Icon(
                            Icons.info_outline,
                            color: AppColors.primary,
                            size: 16,
                          ),
                          AppSizes.paddingSmall.widthBox,
                          'Tap on the map to see live bus location. The bus marker will update in real-time as the driver moves.'
                              .text
                              .size(12)
                              .color(Theme.of(context).primaryColor)
                              .make()
                              .expand(),
                        ])
                        .p(AppSizes.paddingSmall)
                        .box
                        .color(AppColors.primary.withValues(alpha: 0.1))
                        .roundedExpected(AppSizes.radiusSmall)
                        .make(),
                    if ((_routes
                        .firstWhere(
                          (r) => r.id == _selectedBus!.routeId,
                          orElse: () => RouteModel(
                            id: '',
                            routeName: 'N/A',
                            routeType: '',
                            startPoint: '',
                            endPoint: '',
                            stopPoints: [],
                            collegeId: '',
                            createdBy: '',
                            isActive: false,
                            createdAt: DateTime.now(),
                          ),
                        )
                        .stopPoints
                        .isNotEmpty))
                      VStack([
                        AppSizes.paddingMedium.heightBox,
                        'Stops: ${_routes.firstWhere(
                              (r) => r.id == _selectedBus!.routeId,
                              orElse: () => RouteModel(id: '', routeName: 'N/A', routeType: '', startPoint: '', endPoint: '', stopPoints: [], collegeId: '', createdBy: '', isActive: false, createdAt: DateTime.now()),
                            ).stopPoints.join(' → ')}'
                            .text
                            .size(14)
                            .color(
                              Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                            )
                            .make(),
                      ]),
                  ])
                  .p(AppSizes.paddingMedium)
                  .box
                  .color(Theme.of(context).colorScheme.surface)
                  .topRounded(value: AppSizes.radiusLarge)
                  .make(),
          ]),

          // Bus List Tab
          _filteredBuses.isEmpty
              ? VStack(
                  [
                    Icon(
                      Icons.directions_bus_outlined,
                      size: 64,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    AppSizes.paddingMedium.heightBox,
                    (_selectedStop != null ||
                                _selectedBusNumber != null ||
                                _selectedRouteType != null
                            ? 'No buses found for selected filters'
                            : 'No buses available')
                        .text
                        .size(18)
                        .color(
                          Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        )
                        .make(),
                  ],
                  alignment: MainAxisAlignment.center,
                  crossAlignment: CrossAxisAlignment.center,
                ).centered()
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSizes.paddingMedium),
                  itemCount: _filteredBuses.length,
                  itemBuilder: (context, index) {
                    final bus = _filteredBuses[index];
                    final isSelected = _selectedBus?.id == bus.id;
                    final route = _routes.firstWhere(
                      (r) => r.id == bus.routeId,
                      orElse: () => RouteModel(
                        id: '',
                        routeName: 'N/A',
                        routeType: '',
                        startPoint: '',
                        endPoint: '',
                        stopPoints: [],
                        collegeId: '',
                        createdBy: '',
                        isActive: false,
                        createdAt: DateTime.now(),
                      ),
                    );

                    return Card(
                      margin: const EdgeInsets.only(
                        bottom: AppSizes.paddingMedium,
                      ),
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? AppColors.primary
                              : Theme.of(context).colorScheme.secondary,
                          child: Icon(
                            Icons.directions_bus,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        title: 'Bus ${bus.busNumber}'.text.semiBold
                            .color(
                              isSelected
                                  ? Theme.of(context).primaryColor
                                  : null,
                            )
                            .make(),
                        subtitle: VStack([
                          '${route.startPoint} → ${route.endPoint}'.text.make(),
                          'Type: ${route.routeType.toUpperCase()}'.text.make(),
                          if (route.stopPoints.isNotEmpty)
                            'Stops: ${route.stopPoints.join(', ')}'.text
                                .size(12)
                                .make(),
                        ]),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: Theme.of(context).primaryColor,
                              )
                            : const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          _selectBus(bus);
                          _tabController.animateTo(0); // Switch to map tab
                        },
                        isThreeLine: route.stopPoints.isNotEmpty,
                      ),
                    );
                  },
                ),

          // Approvals Tab
          _pendingStudents.isEmpty
              ? VStack(
                  [
                    Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    AppSizes.paddingMedium.heightBox,
                    'No pending student approvals'.text
                        .size(18)
                        .color(
                          Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        )
                        .make(),
                  ],
                  alignment: MainAxisAlignment.center,
                  crossAlignment: CrossAxisAlignment.center,
                ).centered()
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSizes.paddingMedium),
                  itemCount: _pendingStudents.length,
                  itemBuilder: (context, index) {
                    final student = _pendingStudents[index];
                    return Card(
                      margin: const EdgeInsets.only(
                        bottom: AppSizes.paddingMedium,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Icon(
                            Icons.person,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        title: student.fullName.text.semiBold.make(),
                        subtitle: VStack([
                          student.email.text.make(),
                          if (student.phoneNumber != null &&
                              student.phoneNumber!.isNotEmpty)
                            'Phone: ${student.phoneNumber}'.text.make(),
                          if (student.rollNumber != null &&
                              student.rollNumber!.isNotEmpty)
                            'Roll: ${student.rollNumber}'.text.make(),
                          'Role: ${student.role.displayName}'.text
                              .color(Theme.of(context).primaryColor)
                              .medium
                              .make(),
                        ]),
                        trailing: HStack([
                          IconButton(
                            icon: Icon(
                              Icons.check,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            onPressed: () => _approveStudent(student),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            onPressed: () => _rejectStudent(student),
                          ),
                        ]),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),

          // Bus Info Tab
          VStack([
            'Available Bus Numbers'.text
                .size(20)
                .bold
                .color(Theme.of(context).colorScheme.onSurface)
                .make(),
            AppSizes.paddingMedium.heightBox,
            (_allBusNumbers.isEmpty
                    ? 'No bus numbers available'.text
                          .color(
                            Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                          )
                          .make()
                          .centered()
                    : ListView.builder(
                        itemCount: _allBusNumbers.length,
                        itemBuilder: (context, index) {
                          final busNumber = _allBusNumbers[index];
                          final isAssigned = _allBuses.any(
                            (bus) => bus.busNumber == busNumber,
                          );

                          return Card(
                            margin: const EdgeInsets.only(
                              bottom: AppSizes.paddingSmall,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isAssigned
                                    ? Theme.of(context).colorScheme.secondary
                                    : Theme.of(context).colorScheme.error,
                                child: Icon(
                                  isAssigned
                                      ? Icons.check
                                      : Icons.directions_bus,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                ),
                              ),
                              title: busNumber.text.semiBold.make(),
                              subtitle:
                                  (isAssigned
                                          ? 'Assigned to driver'
                                          : 'Available')
                                      .text
                                      .color(
                                        isAssigned
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.secondary
                                            : Theme.of(
                                                context,
                                              ).colorScheme.error,
                                      )
                                      .medium
                                      .make(),
                            ),
                          );
                        },
                      ))
                .expand(),
            AppSizes.paddingMedium.heightBox,
            'All Stops'.text
                .size(20)
                .bold
                .color(Theme.of(context).colorScheme.onSurface)
                .make(),
            AppSizes.paddingMedium.heightBox,
            (_allStops.isEmpty
                    ? 'No stops available'.text
                          .color(
                            Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                          )
                          .make()
                          .centered()
                    : ListView.builder(
                        itemCount: _allStops.length,
                        itemBuilder: (context, index) {
                          final stop = _allStops[index];
                          return Card(
                            margin: const EdgeInsets.only(
                              bottom: AppSizes.paddingSmall,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).primaryColor,
                                child: Icon(
                                  Icons.location_on,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                ),
                              ),
                              title: stop.text.semiBold.make(),
                              subtitle: 'Bus stop location'.text
                                  .size(12)
                                  .color(
                                    Theme.of(context).colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  )
                                  .make(),
                            ),
                          );
                        },
                      ))
                .expand(),
          ]).p(AppSizes.paddingMedium),
        ],
      ),
    );
  }
}

extension on VxBox {
  VxBox roundedExpected(double radius) {
    return rounded.customRounded(BorderRadius.circular(radius));
  }
}
