import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/services/data_service.dart';
import 'package:collegebus/services/socket_service.dart';
import 'package:collegebus/models/user_model.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/models/route_model.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/widgets/app_drawer.dart';
import 'package:collegebus/services/theme_service.dart';
import 'package:collegebus/screens/notifications_screen.dart';
import 'package:collegebus/screens/coordinator/schedule_management_screen.dart';
import 'package:collegebus/screens/common/profile_screen.dart';
import 'package:velocity_x/velocity_x.dart';

// New Modules
import 'package:collegebus/screens/coordinator/modules/overview_tab.dart';
import 'package:collegebus/screens/coordinator/modules/driver_management_tab.dart';
import 'package:collegebus/screens/coordinator/modules/routes_tab.dart';
import 'package:collegebus/screens/coordinator/modules/bus_numbers_tab.dart';
import 'package:collegebus/screens/coordinator/modules/live_map_tab.dart';
import 'package:collegebus/l10n/coordinator/app_localizations.dart'
    as coord_l10n;
import 'package:collegebus/services/export_service.dart';

class CoordinatorDashboard extends StatefulWidget {
  const CoordinatorDashboard({super.key});

  @override
  State<CoordinatorDashboard> createState() => _CoordinatorDashboardState();
}

class _CoordinatorDashboardState extends State<CoordinatorDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _bottomNavIndex = 0;

  // Data lists
  List<BusModel> _buses = [];
  List<RouteModel> _routes = [];
  List<UserModel> _allDrivers = [];
  List<UserModel> _pendingDrivers = [];
  List<String> _busNumbers = [];
  Set<String> _onlineDriverIds = {};
  BusModel? _currentTrackingBus;

  // Stream subscriptions
  StreamSubscription<List<BusModel>>? _busesSubscription;
  StreamSubscription<List<RouteModel>>? _routesSubscription;
  StreamSubscription<List<UserModel>>? _driversSubscription;
  StreamSubscription<List<String>>? _busNumbersSubscription;
  StreamSubscription<Map<String, dynamic>>? _driverStatusSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initData();
  }

  void _initData() {
    final firestoreService = Provider.of<DataService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final collegeId = authService.currentUserModel?.collegeId;

    if (collegeId != null) {
      final socketService = Provider.of<SocketService>(context, listen: false);
      socketService.joinCollege(collegeId);

      _driverStatusSubscription = socketService.driverStatusStream.listen((
        data,
      ) {
        if (mounted) {
          final driverId = data['driverId'];
          final status = data['status'];
          setState(() {
            if (status == 'online') {
              _onlineDriverIds.add(driverId);
            } else {
              _onlineDriverIds.remove(driverId);
            }
          });
        }
      });

      // Load initial data
      _loadRoutes();
      _loadBusNumbers();

      // Listen to streams - Use correct method names from DataService
      _busesSubscription = firestoreService.getBusesByCollege(collegeId).listen(
        (buses) {
          if (mounted) setState(() => _buses = buses);
        },
      );

      _routesSubscription = firestoreService
          .getRoutesByCollege(collegeId)
          .listen((routes) {
            if (mounted) setState(() => _routes = routes);
          });

      _driversSubscription = firestoreService
          .getUsersByRole(UserRole.driver, collegeId)
          .listen((drivers) {
            if (mounted) {
              setState(() {
                _allDrivers = drivers;
                _pendingDrivers = drivers.where((d) => !d.approved).toList();
              });
            }
          });

      // Listen to bus numbers stream instead of manual future await (since getBusNumbers returns Stream)
      _busNumbersSubscription = firestoreService
          .getBusNumbers(collegeId)
          .listen((busNumbers) {
            if (mounted) setState(() => _busNumbers = busNumbers);
          });
    }
  }

  Future<void> _loadRoutes() async {
    final firestoreService = Provider.of<DataService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final collegeId = authService.currentUserModel?.collegeId;
    if (collegeId != null) {
      // Force refresh
      firestoreService.getRoutesByCollege(collegeId, forceRefresh: true);
    }
  }

  Future<void> _loadBusNumbers() async {
    final firestoreService = Provider.of<DataService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final collegeId = authService.currentUserModel?.collegeId;
    if (collegeId != null) {
      // Force refresh stream
      firestoreService.getBusNumbers(collegeId, forceRefresh: true);
    }
  }

  void _handleTrackDriver(BusModel bus) {
    setState(() {
      _currentTrackingBus = bus;
      // Switch to Live Map tab (index 1)
      _tabController.animateTo(1);
    });
  }

  Future<void> _approveDriver(UserModel driver) async {
    final firestoreService = Provider.of<DataService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUserModel != null) {
      // approveUser(userId, approverId)
      await firestoreService.approveUser(
        driver.id,
        authService.currentUserModel!.id,
      );
    }
  }

  Future<void> _rejectDriver(UserModel driver) async {
    final firestoreService = Provider.of<DataService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUserModel != null) {
      // rejectUser(userId, approverId)
      await firestoreService.rejectUser(
        driver.id,
        authService.currentUserModel!.id,
      );
    }
  }

  Future<void> _showExportDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Export Reports'),
          children: [
            SimpleDialogOption(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await ExportService().exportBuses(_buses);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bus report exported')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Export failed: $e')),
                    );
                  }
                }
              },
              child: const Text('Export Bus List'),
            ),
            SimpleDialogOption(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await ExportService().exportDrivers(_allDrivers);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Driver report exported')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Export failed: $e')),
                    );
                  }
                }
              },
              child: const Text('Export Driver List'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _busesSubscription?.cancel();
    _routesSubscription?.cancel();
    _driversSubscription?.cancel();
    _busNumbersSubscription?.cancel();
    _driverStatusSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUserModel;
    final l10n = coord_l10n.CoordinatorLocalizations.of(context)!;

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
                        title: l10n.dashboardTitle.text.make(),
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
                          tabs: [
                            Tab(
                              text: l10n.overview,
                              icon: const Icon(Icons.dashboard),
                            ),
                            const Tab(text: 'Live Map', icon: Icon(Icons.map)),
                            Tab(
                              text: l10n.drivers,
                              icon: const Icon(Icons.approval),
                            ),
                            Tab(
                              text: l10n.routes,
                              icon: const Icon(Icons.route),
                            ),
                            Tab(
                              text: l10n.buses,
                              icon: const Icon(Icons.directions_bus),
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
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh Data',
                      onPressed: () {
                        final ds = Provider.of<DataService>(
                          context,
                          listen: false,
                        );
                        final auth = Provider.of<AuthService>(
                          context,
                          listen: false,
                        );
                        final cid = auth.currentUserModel?.collegeId;
                        if (cid != null) {
                          ds.getBusesByCollege(cid).first; // Trigger fetch
                          ds.getRoutesByCollege(cid, forceRefresh: true).first;
                          ds.getBusNumbers(cid, forceRefresh: true).first;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Refreshing data...'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.download),
                      tooltip: 'Export Reports',
                      onPressed: () => _showExportDialog(context),
                    ),
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
                    tabs: [
                      Tab(
                        text: l10n.overview,
                        icon: const Icon(Icons.dashboard),
                      ),
                      const Tab(text: 'Live Map', icon: Icon(Icons.map)),
                      Tab(text: l10n.drivers, icon: const Icon(Icons.approval)),
                      Tab(text: l10n.routes, icon: const Icon(Icons.route)),
                      Tab(
                        text: l10n.buses,
                        icon: const Icon(Icons.directions_bus),
                      ),
                    ],
                  ),
                ),

          // ...
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
                        LiveMapTab(
                          buses: _buses,
                          selectedBus: _currentTrackingBus,
                        ),
                        DriverManagementTab(
                          pendingApprovals: _pendingDrivers,
                          allDrivers: _allDrivers,
                          buses: _buses,
                          onlineDriverIds: _onlineDriverIds,
                          onApprove: _approveDriver,
                          onReject: _rejectDriver,
                          onTrack: _handleTrackDriver,
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
                    const ProfileScreen(),
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
                    LiveMapTab(buses: _buses, selectedBus: _currentTrackingBus),
                    DriverManagementTab(
                      pendingApprovals: _pendingDrivers,
                      allDrivers: _allDrivers,
                      buses: _buses,
                      onlineDriverIds: _onlineDriverIds,
                      onApprove: _approveDriver,
                      onReject: _rejectDriver,
                      onTrack: _handleTrackDriver,
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
