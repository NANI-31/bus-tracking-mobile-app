import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/services/data_service.dart';
import 'package:collegebus/services/location_service.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/models/route_model.dart';
import 'package:collegebus/services/theme_service.dart';
import 'package:collegebus/services/socket_service.dart';
import 'package:collegebus/services/persistence_service.dart';

// Import the new modules
import 'tabs/student_map_tab.dart';
import 'tabs/student_bus_list_tab.dart';
import 'tabs/student_info_tab.dart';
import 'package:collegebus/utils/map_style_helper.dart';
import 'widgets/student_dashboard_app_bar.dart';
import 'widgets/dashboard/student_bottom_nav_app_bar.dart';
import 'package:collegebus/widgets/app_drawer.dart';
import 'package:collegebus/screens/common/profile_screen.dart';
import 'student_home_screen.dart';
import 'bus_schedule_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  GoogleMapController? _mapController;
  String? _mapStyle;
  List<BusModel> _allBuses = [];
  List<BusModel> _filteredBuses = [];
  BusModel? _selectedBus;
  LatLng? _currentLocation;
  String? _selectedStop;
  String? _selectedBusNumber;
  String? _selectedRouteType;
  List<RouteModel> _routes = [];
  int _bottomNavIndex = 0;

  StreamSubscription<List<BusModel>>? _busesListSubscription;

  StreamSubscription<List<RouteModel>>? _routesSubscription;

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
          startPoint: RoutePoint(name: '', lat: 0, lng: 0),
          endPoint: RoutePoint(name: '', lat: 0, lng: 0),
          stopPoints: [],
          collegeId: '',
          createdBy: '',
          isActive: false,
          createdAt: DateTime.now(),
        ),
      );
      stops.add(route.startPoint.name);
      stops.add(route.endPoint.name);
      stops.addAll(route.stopPoints.map((s) => s.name));
    }
    _cachedExposedStops = stops.toList()..sort();

    _cachedExposedBusNumbers =
        _allBuses.map((bus) => bus.busNumber).toSet().toList()..sort();
  }

  @override
  void initState() {
    super.initState();
    _bottomNavIndex = PersistenceService.getBottomNavIndex();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: _bottomNavIndex < 3 ? _bottomNavIndex : 0,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) {
        setState(() {});
      }
    });

    _getCurrentLocation();
    _loadRoutes();
    _loadBuses();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ThemeService>(
        context,
        listen: false,
      ).addListener(_handleThemeChange);
      _handleThemeChange();
    });
  }

  void _onBottomNavChanged(int index) {
    if (mounted) {
      setState(() {
        _bottomNavIndex = index;
      });
      PersistenceService.setBottomNavIndex(index);
    }
  }

  void _handleThemeChange() {
    if (!mounted) return;
    final themeService = Provider.of<ThemeService>(context, listen: false);
    MapStyleHelper.getStyle(themeService.isDarkMode).then((style) {
      if (mounted) {
        setState(() {
          _mapStyle = style;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUserModel;
    if (user != null && _allBuses.isEmpty && _busesListSubscription == null) {
      // Moved joinCollege to _loadBuses to ensure listeners are ready before initial push
      _loadRoutes();
      _loadBuses();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _busesListSubscription?.cancel();
    _routesSubscription?.cancel();
    Provider.of<ThemeService>(
      context,
      listen: false,
    ).removeListener(_handleThemeChange);
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    final locationService = Provider.of<LocationService>(
      context,
      listen: false,
    );
    final lastKnown = await locationService.getLastKnownLocation();
    if (lastKnown != null && mounted) {
      setState(() {
        _currentLocation = lastKnown;
      });
    }
    final location = await locationService.getCurrentLocation();
    if (location != null && mounted) {
      setState(() {
        _currentLocation = location;
      });
    }
  }

  Future<void> _loadBuses() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final dataService = Provider.of<DataService>(context, listen: false);
    final collegeId = authService.currentUserModel?.collegeId;
    if (collegeId != null) {
      await _busesListSubscription?.cancel();
      _busesListSubscription = dataService.getBusesByCollege(collegeId).listen((
        buses,
      ) {
        if (mounted) {
          setState(() {
            _allBuses = buses;
            if (_selectedStop == null &&
                authService.currentUserModel?.preferredStop != null) {
              _selectedStop = authService.currentUserModel!.preferredStop;
            }
            _updateCachedFilterLists();
            _applyFilters();
          });
        }
        // Trigger initial location push
        Provider.of<SocketService>(
          context,
          listen: false,
        ).joinCollege(collegeId);
      });
    }
  }

  Future<void> _loadRoutes() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final dataService = Provider.of<DataService>(context, listen: false);
    final collegeId = authService.currentUserModel?.collegeId;
    if (collegeId != null) {
      await _routesSubscription?.cancel();
      _routesSubscription = dataService.getRoutesByCollege(collegeId).listen((
        routes,
      ) {
        if (mounted) {
          setState(() {
            _routes = routes;
            _updateCachedFilterLists();
            _applyFilters();
          });
        }
      });
    }
  }

  void _applyFilters() {
    // 1. Initial filter: Only show active, assigned, accepted buses
    List<BusModel> filtered = _allBuses.where((bus) {
      return bus.status != 'not-running' && bus.assignmentStatus == 'accepted';
    }).toList();

    if (_selectedRouteType != null) {
      filtered = filtered.where((bus) {
        final route = _routes.firstWhere(
          (r) => r.id == bus.routeId,
          orElse: () => RouteModel(
            id: '',
            routeName: 'N/A',
            routeType: '',
            startPoint: RoutePoint(name: '', lat: 0, lng: 0),
            endPoint: RoutePoint(name: '', lat: 0, lng: 0),
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
    if (_selectedStop != null) {
      filtered = filtered.where((bus) {
        final route = _routes.firstWhere(
          (r) => r.id == bus.routeId,
          orElse: () => RouteModel(
            id: '',
            routeName: 'N/A',
            routeType: '',
            startPoint: RoutePoint(name: '', lat: 0, lng: 0),
            endPoint: RoutePoint(name: '', lat: 0, lng: 0),
            stopPoints: [],
            collegeId: '',
            createdBy: '',
            isActive: false,
            createdAt: DateTime.now(),
          ),
        );
        return route.startPoint.name == _selectedStop ||
            route.endPoint.name == _selectedStop ||
            route.stopPoints.any((s) => s.name == _selectedStop);
      }).toList();
    }
    if (_selectedBusNumber != null) {
      filtered = filtered
          .where((bus) => bus.busNumber == _selectedBusNumber)
          .toList();
    }
    _filteredBuses = filtered;
  }

  void _selectBus(BusModel bus) {
    if (mounted) setState(() => _selectedBus = bus);
    final dataService = Provider.of<DataService>(context, listen: false);
    dataService.getBusLocation(bus.id).first.then((location) {
      if (location != null && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(location.currentLocation, 16.0),
        );
      }
    });
    if (mounted) setState(() => _selectedBus = bus);
    _onBottomNavChanged(1);
    _tabController.animateTo(0);
  }

  void _onBusNumberSelected(String? busNumber) {
    if (mounted) {
      setState(() {
        _selectedBusNumber = busNumber;
        _applyFilters();
      });
    }
  }

  void _onRouteTypeSelected(String? routeType) {
    if (mounted) {
      setState(() {
        _selectedRouteType = routeType;
        _applyFilters();
      });
    }
  }

  void _clearFilters() {
    if (mounted) {
      setState(() {
        _selectedStop = null;
        _selectedBusNumber = null;
        _selectedRouteType = null;
        _selectedBus = null;
        _applyFilters();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUserModel;
    return Consumer<ThemeService>(
      builder: (context, themeService, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          drawer: themeService.useBottomNavigation
              ? null
              : AppDrawer(user: user, authService: authService),
          appBar: themeService.useBottomNavigation
              ? ([3, 4].contains(_bottomNavIndex)
                    ? null
                    : StudentBottomNavAppBar(bottomNavIndex: _bottomNavIndex))
              : StudentDashboardAppBar(
                  user: user,
                  tabController: _tabController,
                  authService: authService,
                ),
          body: themeService.useBottomNavigation
              ? IndexedStack(
                  index: _bottomNavIndex,
                  children: [
                    StudentHomeScreen(
                      isTab: true,
                      onTrackLive: () => _onBottomNavChanged(1),
                    ),
                    StudentMapTab(
                      currentLocation: _currentLocation,
                      buses: _selectedBus != null ? [_selectedBus!] : [],
                      selectedBus: _selectedBus,
                      selectedRouteType: _selectedRouteType,
                      selectedBusNumber: _selectedBusNumber,
                      allBusNumbers: _allBusNumbers,
                      filteredBusesCount: _filteredBuses.length,
                      mapStyle: _mapStyle,
                      onMapCreated: (controller) => _mapController = controller,
                      onRouteTypeSelected: _onRouteTypeSelected,
                      onBusNumberSelected: _onBusNumberSelected,
                      onClearFilters: _clearFilters,
                      onBusSelected: (bus) {
                        if (mounted) setState(() => _selectedBus = bus);
                      },
                    ),
                    StudentBusListTab(
                      filteredBuses: _filteredBuses,
                      routes: _routes,
                      selectedBus: _selectedBus,
                      onBusSelected: (bus) => _selectBus(bus),
                      selectedStop: _selectedStop,
                      onClearFilters: _clearFilters,
                    ),
                    const BusScheduleScreen(isTab: true),
                    const ProfileScreen(),
                  ],
                )
              : TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    StudentMapTab(
                      currentLocation: _currentLocation,
                      buses: _selectedBus != null ? [_selectedBus!] : [],
                      selectedBus: _selectedBus,
                      selectedRouteType: _selectedRouteType,
                      selectedBusNumber: _selectedBusNumber,
                      allBusNumbers: _allBusNumbers,
                      filteredBusesCount: _filteredBuses.length,
                      mapStyle: _mapStyle,
                      onMapCreated: (controller) => _mapController = controller,
                      onRouteTypeSelected: _onRouteTypeSelected,
                      onBusNumberSelected: _onBusNumberSelected,
                      onClearFilters: _clearFilters,
                      onBusSelected: (bus) {
                        setState(() => _selectedBus = bus);
                      },
                    ),
                    StudentBusListTab(
                      filteredBuses: _filteredBuses,
                      routes: _routes,
                      selectedBus: _selectedBus,
                      onBusSelected: (bus) => _selectBus(bus),
                      selectedStop: _selectedStop,
                      onClearFilters: _clearFilters,
                    ),
                    StudentInfoTab(
                      allBusNumbers: _allBusNumbers,
                      allStops: _allStops,
                    ),
                  ],
                ),
          bottomNavigationBar: themeService.useBottomNavigation
              ? NavigationBar(
                  selectedIndex: _bottomNavIndex,
                  onDestinationSelected: _onBottomNavChanged,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.map_outlined),
                      selectedIcon: Icon(Icons.map),
                      label: 'Live Map',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.show_chart_rounded),
                      selectedIcon: Icon(Icons.show_chart_rounded),
                      label: 'Route',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.calendar_month_outlined),
                      selectedIcon: Icon(Icons.calendar_month),
                      label: 'Schedule',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: 'Profile',
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }
}
