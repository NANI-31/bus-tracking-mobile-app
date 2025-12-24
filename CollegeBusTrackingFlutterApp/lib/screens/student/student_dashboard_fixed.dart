import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/services/firestore_service.dart';
import 'package:collegebus/services/location_service.dart';
import 'package:collegebus/services/api_service.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/models/route_model.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/services/theme_service.dart';

// Import the new modules
import 'tabs/student_map_tab.dart';
import 'tabs/student_bus_list_tab.dart';
import 'tabs/student_info_tab.dart';
import 'utils/student_map_helper.dart';
import 'widgets/student_dashboard_app_bar.dart';
import 'package:collegebus/widgets/app_drawer.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  List<BusModel> _allBuses = [];
  List<BusModel> _filteredBuses = [];
  BusModel? _selectedBus;
  LatLng? _currentLocation;
  Set<Polyline> _polylines = {};
  String? _selectedStop;
  String? _selectedBusNumber;
  String? _selectedRouteType;
  List<RouteModel> _routes = [];
  Map<String, StreamSubscription> _busLocationSubscriptions = {};

  // Stream subscriptions
  StreamSubscription? _busesListSubscription;
  StreamSubscription? _routesSubscription;

  // Cached lists for filters
  List<String> _cachedExposedStops = [];
  List<String> _cachedExposedBusNumbers = [];

  List<String> get _allStops => _cachedExposedStops;
  List<String> get _allBusNumbers => _cachedExposedBusNumbers;

  void _updateCachedFilterLists() {
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
    _cachedExposedStops = stops.toList()..sort();

    _cachedExposedBusNumbers =
        _allBuses.map((bus) => bus.busNumber).toSet().toList()..sort();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Listen to tab changes to update UI when using bottom nav
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _getCurrentLocation();
    _loadRoutes();
    _loadBuses();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // In case user model loaded after initState
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUserModel;
    if (user != null && _allBuses.isEmpty && _busesListSubscription == null) {
      _loadRoutes();
      _loadBuses();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Cancel all location subscriptions
    for (final subscription in _busLocationSubscriptions.values) {
      subscription.cancel();
    }
    _busLocationSubscriptions.clear();

    // Cancel main subscriptions
    _busesListSubscription?.cancel();
    _routesSubscription?.cancel();

    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    final locationService = Provider.of<LocationService>(
      context,
      listen: false,
    );

    // faster: try last known location first to show something immediately
    final lastKnown = await locationService.getLastKnownLocation();
    if (lastKnown != null && mounted) {
      setState(() {
        _currentLocation = lastKnown;
        _updateMarkers();
      });
    }

    // then get fresh high-accuracy location
    final location = await locationService.getCurrentLocation();
    if (location != null && mounted) {
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
      await _busesListSubscription?.cancel();
      _busesListSubscription = firestoreService
          .getBusesByCollege(collegeId)
          .listen((buses) {
            // Cancel existing subscriptions
            for (final subscription in _busLocationSubscriptions.values) {
              subscription.cancel();
            }
            _busLocationSubscriptions.clear();

            if (mounted) {
              setState(() {
                _allBuses = buses;
                if (_selectedStop == null &&
                    authService.currentUserModel?.preferredStop != null) {
                  _selectedStop = authService.currentUserModel!.preferredStop;
                }
                _updateCachedFilterLists();
                _applyFilters();
                _updateMarkers();
              });
            }

            // Set up location listeners (ONE stream for all buses)
            _setupBusLocationListeners(collegeId, firestoreService);
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
      await _routesSubscription?.cancel();
      _routesSubscription = firestoreService
          .getRoutesByCollege(collegeId)
          .listen((routes) {
            if (mounted) {
              setState(() {
                _routes = routes;
                _updateCachedFilterLists();
                _applyFilters();
                _updateMarkers();
              });
            }
          });
    }
  }

  void _setupBusLocationListeners(
    String collegeId,
    FirestoreService firestoreService,
  ) {
    // Cancel any existing subscription first
    // We only need ONE subscription now for ALL buses
    for (final subscription in _busLocationSubscriptions.values) {
      subscription.cancel();
    }
    _busLocationSubscriptions.clear();

    final subscription = firestoreService
        .getCollegeBusLocationsStream(collegeId)
        .listen((locations) {
          if (!mounted) return;

          // Update all markers
          for (final location in locations) {
            final bus = _allBuses.firstWhere(
              (b) => b.id == location.busId,
              orElse: () => BusModel(
                id: '',
                busNumber: '',
                driverId: '',
                routeId: '',
                collegeId: '',
                isActive: false,
                createdAt: DateTime.now(),
              ),
            );

            if (bus.id.isNotEmpty) {
              _updateBusMarker(bus, location);
            }
          }
        });

    // Store with a key 'all' since it covers everything
    _busLocationSubscriptions['all'] = subscription;
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

    final marker = StudentMapHelper.createBusMarker(
      bus: bus,
      route: route,
      location: location,
      currentLocation: _currentLocation,
      isSelected: _selectedBus?.id == bus.id,
      onTap: () => _selectBus(bus),
    );

    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'bus_${bus.id}');
      _markers.add(marker);
    });

    // Auto-follow selected bus
    if (_selectedBus?.id == bus.id &&
        location != null &&
        _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(location.currentLocation),
      );
    }
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
        final matches =
            route.startPoint == _selectedStop ||
            route.endPoint == _selectedStop ||
            route.stopPoints.contains(_selectedStop);
        return matches;
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
  }

  void _updateMarkers() {
    final newMarkers = <Marker>{};

    // Always show current location marker
    if (_currentLocation != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentLocation!,
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    // Show all filtered buses as markers
    for (final bus in _filteredBuses) {
      _addBusMarker(bus, newMarkers);
    }

    // If a bus is selected, show its route polyline and stops
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
    if (_selectedBus?.id == bus.id) {
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

      final polyline = StudentMapHelper.createRoutePolyline(
        bus: bus,
        route: route,
        currentLocation: _currentLocation,
      );

      setState(() {
        _polylines = {polyline};
      });

      // Add stop markers
      final stopMarkers = StudentMapHelper.createStopMarkers(
        bus: bus,
        route: route,
        currentLocation: _currentLocation,
      );

      _markers.addAll(stopMarkers);
    }
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

    final marker = StudentMapHelper.createBusMarker(
      bus: bus,
      route: route,
      location: null, // Initial add, no location yet
      currentLocation: _currentLocation,
      isSelected: _selectedBus?.id == bus.id,
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
    // Use first (one-shot) to move camera immediately without creating a persistent leaky listener
    firestoreService.getBusLocation(bus.id).first.then((location) {
      if (location != null && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(location.currentLocation, 16.0),
        );
      }
    });

    // Switch to Map tab (index 0) if not already there
    _tabController.animateTo(0);
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

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUserModel;

    return Consumer<ThemeService>(
      builder: (context, themeService, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          drawer: AppDrawer(user: user, authService: authService),
          appBar: themeService.useBottomNavigation
              ? AppBar(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  title: const Text('College Bus Tracking'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        _loadBuses();
                        _loadRoutes();
                      },
                    ),
                  ],
                )
              : StudentDashboardAppBar(
                  user: user,
                  tabController: _tabController,
                  authService: authService,
                ),
          body: TabBarView(
            controller: _tabController,
            physics: themeService.useBottomNavigation
                ? const NeverScrollableScrollPhysics() // Disable swipe on bottom nav usually? Or keep it?
                : const NeverScrollableScrollPhysics(), // Already disabled in original
            children: [
              // Map Tab
              StudentMapTab(
                currentLocation: _currentLocation,
                markers: _markers,
                polylines: _polylines,
                selectedBus: _selectedBus,
                selectedRouteType: _selectedRouteType,
                selectedBusNumber: _selectedBusNumber,
                allBusNumbers: _allBusNumbers,
                filteredBusesCount: _filteredBuses.length,
                onMapCreated: (controller) => _mapController = controller,
                onRouteTypeSelected: _onRouteTypeSelected,
                onBusNumberSelected: _onBusNumberSelected,
                onClearFilters: _clearFilters,
                onBusSelected: (bus) {
                  setState(() {
                    _selectedBus = bus;
                  });
                  if (bus == null) {
                    _updateMarkers();
                  }
                },
              ),

              // Bus List Tab
              StudentBusListTab(
                filteredBuses: _filteredBuses,
                routes: _routes,
                selectedBus: _selectedBus,
                onBusSelected: (bus) => _selectBus(bus),
                selectedStop: _selectedStop,
                onClearFilters: _clearFilters,
              ),

              // Bus Info Tab
              StudentInfoTab(
                allBusNumbers: _allBusNumbers,
                allStops: _allStops,
              ),
            ],
          ),
          bottomNavigationBar: themeService.useBottomNavigation
              ? NavigationBar(
                  selectedIndex: _tabController.index,
                  onDestinationSelected: (index) {
                    _tabController.animateTo(index);
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.map_outlined),
                      selectedIcon: Icon(Icons.map),
                      label: 'Track',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.list_alt_outlined),
                      selectedIcon: Icon(Icons.list_alt),
                      label: 'Buses',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.info_outline),
                      selectedIcon: Icon(Icons.info),
                      label: 'Info',
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }
}
