import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/services/data_service.dart';
import 'package:collegebus/models/user_model.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/models/route_model.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/widgets/app_drawer.dart';
import 'package:collegebus/services/theme_service.dart';
import 'package:collegebus/screens/notifications_screen.dart';
import 'package:collegebus/screens/coordinator/schedule_management_screen.dart';
import 'package:collegebus/screens/student/student_profile_screen.dart';
import 'package:velocity_x/velocity_x.dart';

// New Modules
import 'package:collegebus/screens/coordinator/modules/overview_tab.dart';
import 'package:collegebus/screens/coordinator/modules/driver_management_tab.dart';
import 'package:collegebus/screens/coordinator/modules/routes_tab.dart';
import 'package:collegebus/screens/coordinator/modules/bus_numbers_tab.dart';

class CoordinatorDashboard extends StatefulWidget {
  const CoordinatorDashboard({super.key});

  @override
  State<CoordinatorDashboard> createState() => _CoordinatorDashboardState();
}

class _CoordinatorDashboardState extends State<CoordinatorDashboard>
    with SingleTickerProviderStateMixin {
  bool _isDataLoaded = false;
  late TabController _tabController;
  List<UserModel> _pendingDrivers = [];
  List<UserModel> _allDrivers = [];
  List<BusModel> _buses = [];
  List<RouteModel> _routes = [];
  List<String> _busNumbers = [];
  int _bottomNavIndex = 0;

  // Stream subscriptions
  StreamSubscription? _pendingDriversSubscription;
  StreamSubscription? _allDriversSubscription;
  StreamSubscription? _busesSubscription;
  StreamSubscription? _routesSubscription;
  StreamSubscription? _busNumbersSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authService = Provider.of<AuthService>(context);
    final collegeId = authService.currentUserModel?.collegeId;

    if (collegeId != null && !_isDataLoaded) {
      _isDataLoaded = true;
      _loadData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pendingDriversSubscription?.cancel();
    _allDriversSubscription?.cancel();
    _busesSubscription?.cancel();
    _routesSubscription?.cancel();
    _busNumbersSubscription?.cancel();
    super.dispose();
  }

  void _loadData() {
    _loadPendingDrivers();
    _loadAllDrivers();
    _loadBuses();
    _loadRoutes();
    _loadRoutes();
    _loadBusNumbers();
  }

  Future<void> _loadPendingDrivers() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<DataService>(context, listen: false);
    final collegeId = authService.currentUserModel?.collegeId;

    if (collegeId != null) {
      await _pendingDriversSubscription?.cancel();
      _pendingDriversSubscription = firestoreService
          .getPendingApprovals(collegeId)
          .listen((users) {
            if (mounted) {
              setState(() {
                _pendingDrivers = users
                    .where((user) => user.role == UserRole.driver)
                    .toList();
              });
            }
          });
    }
  }

  Future<void> _loadAllDrivers() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<DataService>(context, listen: false);
    final collegeId = authService.currentUserModel?.collegeId;

    if (collegeId != null) {
      await _allDriversSubscription?.cancel();
      _allDriversSubscription = firestoreService
          .getUsersByRole(UserRole.driver, collegeId)
          .listen((users) {
            if (mounted) {
              setState(() {
                _allDrivers = users;
              });
            }
          });
    }
  }

  Future<void> _loadBuses() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<DataService>(context, listen: false);
    final collegeId = authService.currentUserModel?.collegeId;

    if (collegeId != null) {
      await _busesSubscription?.cancel();
      _busesSubscription = firestoreService.getBusesByCollege(collegeId).listen(
        (buses) {
          if (mounted) {
            setState(() {
              _buses = buses;
            });
          }
        },
      );
    }
  }

  Future<void> _loadRoutes() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<DataService>(context, listen: false);
    final collegeId = authService.currentUserModel?.collegeId;

    if (collegeId != null) {
      await _routesSubscription?.cancel();
      _routesSubscription = firestoreService
          .getRoutesByCollege(collegeId)
          .listen((routes) {
            if (mounted) {
              setState(() {
                _routes = routes;
              });
            }
          });
    }
  }

  Future<void> _loadBusNumbers() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<DataService>(context, listen: false);
    final collegeId = authService.currentUserModel?.collegeId;

    if (collegeId != null) {
      await _busNumbersSubscription?.cancel();
      _busNumbersSubscription = firestoreService
          .getBusNumbers(collegeId)
          .listen((busNumbers) {
            if (mounted) {
              setState(() {
                _busNumbers = busNumbers;
              });
            }
          });
    }
  }

  Future<void> _approveDriver(UserModel driver) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<DataService>(context, listen: false);

    final currentUser = authService.currentUserModel;
    if (currentUser != null) {
      await firestoreService.approveUser(driver.id, currentUser.id);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${driver.fullName} has been approved as a driver'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
    }
  }

  Future<void> _rejectDriver(UserModel driver) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<DataService>(context, listen: false);

    final currentUser = authService.currentUserModel;
    if (currentUser != null) {
      await firestoreService.rejectUser(driver.id, currentUser.id);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${driver.fullName} has been rejected'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUserModel;

    return Consumer<ThemeService>(
      builder: (context, themeService, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          drawer: themeService.useBottomNavigation
              ? null
              : AppDrawer(user: currentUser, authService: authService),
          appBar: themeService.useBottomNavigation
              ? (_bottomNavIndex == 0
                    ? AppBar(
                        title: 'Coordinator Dashboard'.text.make(),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        bottom: TabBar(
                          controller: _tabController,
                          labelColor: Theme.of(context).colorScheme.onPrimary,
                          unselectedLabelColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary.withValues(alpha: 0.7),
                          indicatorColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          isScrollable: true,
                          tabs: const [
                            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
                            Tab(text: 'Drivers', icon: Icon(Icons.approval)),
                            Tab(text: 'Routes', icon: Icon(Icons.route)),
                            Tab(
                              text: 'Buses',
                              icon: Icon(Icons.directions_bus),
                            ),
                          ],
                        ),
                      )
                    : null)
              : AppBar(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  actions: [
                    IconButton(
                      icon: Icon(
                        themeService.isDarkMode
                            ? Icons.dark_mode
                            : Icons.light_mode,
                      ),
                      onPressed: () {
                        themeService.toggleTheme(!themeService.isDarkMode);
                      },
                    ),
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
                    isScrollable: true,
                    tabs: const [
                      Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
                      Tab(text: 'Drivers', icon: Icon(Icons.approval)),
                      Tab(text: 'Routes', icon: Icon(Icons.route)),
                      Tab(text: 'Buses', icon: Icon(Icons.directions_bus)),
                    ],
                  ),
                ),
          body: themeService.useBottomNavigation
              ? IndexedStack(
                  index: _bottomNavIndex,
                  children: [
                    // 0: Dashboard (TabBarView)
                    TabBarView(
                      controller: _tabController,
                      children: [
                        OverviewTab(
                          routes: _routes,
                          buses: _buses,
                          pendingDrivers: _pendingDrivers,
                          busNumbers: _busNumbers,
                        ),
                        DriverManagementTab(
                          pendingApprovals: _pendingDrivers,
                          allDrivers: _allDrivers,
                          buses: _buses,
                          onApprove: _approveDriver,
                          onReject: _rejectDriver,
                        ),
                        RoutesTab(routes: _routes, onRefresh: _loadRoutes),
                        BusNumbersTab(
                          busNumbers: _busNumbers,
                          buses: _buses,
                          onRefresh: _loadBusNumbers,
                          allDrivers: _allDrivers,
                        ),
                      ],
                    ),
                    // 1: Notifications
                    const NotificationsScreen(),
                    // 2: Manage Schedule
                    const ScheduleManagementScreen(),
                    // 3: Profile
                    const StudentProfileScreen(),
                  ],
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    OverviewTab(
                      routes: _routes,
                      buses: _buses,
                      pendingDrivers: _pendingDrivers,
                      busNumbers: _busNumbers,
                    ),
                    DriverManagementTab(
                      pendingApprovals: _pendingDrivers,
                      allDrivers: _allDrivers,
                      buses: _buses,
                      onApprove: _approveDriver,
                      onReject: _rejectDriver,
                    ),
                    RoutesTab(routes: _routes, onRefresh: _loadRoutes),
                    BusNumbersTab(
                      busNumbers: _busNumbers,
                      buses: _buses,
                      onRefresh: _loadBusNumbers,
                      allDrivers: _allDrivers,
                    ),
                  ],
                ),
          bottomNavigationBar: themeService.useBottomNavigation
              ? NavigationBar(
                  selectedIndex: _bottomNavIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      _bottomNavIndex = index;
                    });
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: 'Dashboard',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.notifications_outlined),
                      selectedIcon: Icon(Icons.notifications),
                      label: 'Notifications',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.edit_calendar_outlined),
                      selectedIcon: Icon(Icons.edit_calendar),
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
