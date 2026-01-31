import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:collegebus/providers/auth_provider.dart';
import 'package:collegebus/providers/bus_provider.dart';
import 'package:collegebus/providers/route_provider.dart';
import 'package:collegebus/providers/socket_provider.dart';
import 'package:collegebus/providers/api_provider.dart';
import 'package:collegebus/providers/service_providers.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/models/route_model.dart';
import 'package:collegebus/services/core/persistence_service.dart';

// Import the new modules
import 'tabs/student_map_tab.dart';
import 'tabs/student_bus_list_tab.dart';
import 'tabs/student_info_tab.dart';

// Re-adding widget imports
import 'widgets/student_dashboard_app_bar.dart';
import 'widgets/dashboard/student_bottom_nav_app_bar.dart';
import 'package:collegebus/widgets/app_drawer.dart';
import 'package:collegebus/screens/common/profile_screen.dart';
import 'student_home_screen.dart';
import 'bus_schedule_screen.dart';

class StudentDashboard extends ConsumerStatefulWidget {
  const StudentDashboard({super.key});

  @override
  ConsumerState<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends ConsumerState<StudentDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  GoogleMapController? _mapController;
  String? _mapStyle;

  BusModel? _selectedBus;
  LatLng? _currentLocation;
  String? _selectedStop;
  String? _selectedBusNumber;
  String? _selectedRouteType;
  int _bottomNavIndex = 0;

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

    // Join socket room
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user?.collegeId != null) {
        ref.read(socketServiceProvider).joinCollege(user!.collegeId);
      }
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

  Future<void> _getCurrentLocation() async {
    final locationService = ref.read(locationServiceProvider);
    final location = await locationService.getCurrentLocation();
    if (location != null && mounted) {
      setState(() => _currentLocation = location);
    }
  }

  void _selectBus(BusModel bus) {
    if (mounted) setState(() => _selectedBus = bus);
    final api = ref.read(apiServiceProvider);
    api.getBusLocation(bus.id).then((location) {
      if (location != null && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(location.currentLocation, 16.0),
        );
      }
    });

    _onBottomNavChanged(1);
    _tabController.animateTo(0);
  }

  void _onBusNumberSelected(String? busNumber) {
    if (mounted) {
      setState(() {
        _selectedBusNumber = busNumber;
      });
    }
  }

  void _onRouteTypeSelected(String? routeType) {
    if (mounted) {
      setState(() {
        _selectedRouteType = routeType;
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
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final collegeId = user?.collegeId;
    final themeService = ref.watch(themeServiceProvider);

    // Watch providers
    final busesAsync = collegeId != null
        ? ref.watch(collegeBusesStreamProvider(collegeId))
        : const AsyncValue<List<BusModel>>.data([]);
    final routesAsync = collegeId != null
        ? ref.watch(collegeRoutesProvider(collegeId))
        : const AsyncValue<List<RouteModel>>.data([]);

    final allBusesRaw = busesAsync.value ?? [];
    final routes = routesAsync.value ?? [];

    // Set default stop from preference if not set
    if (_selectedStop == null && user?.preferredStop != null) {
      _selectedStop = user!.preferredStop;
    }

    // Compute filter options
    final stopsSet = <String>{};
    for (final bus in allBusesRaw) {
      final route = routes.firstWhere(
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
      stopsSet.add(route.startPoint.name);
      stopsSet.add(route.endPoint.name);
      stopsSet.addAll(route.stopPoints.map((s) => s.name));
    }
    final allStops = stopsSet.toList()..sort();
    final allBusNumbers = allBusesRaw.map((b) => b.busNumber).toSet().toList()
      ..sort();

    // Apply filters
    var filteredBuses = allBusesRaw.where((bus) {
      return bus.status != 'not-running' && bus.assignmentStatus == 'accepted';
    }).toList();

    if (_selectedRouteType != null) {
      filteredBuses = filteredBuses.where((bus) {
        final route = routes.firstWhere(
          (r) => r.id == bus.routeId,
          orElse: () => RouteModel(
            id: '',
            routeName: '',
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
      filteredBuses = filteredBuses.where((bus) {
        final route = routes.firstWhere(
          (r) => r.id == bus.routeId,
          orElse: () => RouteModel(
            id: '',
            routeName: '',
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
      filteredBuses = filteredBuses
          .where((bus) => bus.busNumber == _selectedBusNumber)
          .toList();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: themeService.useBottomNavigation ? null : AppDrawer(user: user),
      appBar: themeService.useBottomNavigation
          ? ([3, 4].contains(_bottomNavIndex)
                ? null
                : StudentBottomNavAppBar(bottomNavIndex: _bottomNavIndex))
          : StudentDashboardAppBar(user: user, tabController: _tabController),
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
                  allBusNumbers: allBusNumbers,
                  filteredBusesCount: filteredBuses.length,
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
                  filteredBuses: filteredBuses,
                  routes: routes,
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
                  allBusNumbers: allBusNumbers,
                  filteredBusesCount: filteredBuses.length,
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
                  filteredBuses: filteredBuses,
                  routes: routes,
                  selectedBus: _selectedBus,
                  onBusSelected: (bus) => _selectBus(bus),
                  selectedStop: _selectedStop,
                  onClearFilters: _clearFilters,
                ),
                StudentInfoTab(
                  allBusNumbers: allBusNumbers,
                  allStops: allStops,
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
  }
}
