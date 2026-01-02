import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/services/data_service.dart';
import 'package:collegebus/services/socket_service.dart';
import 'package:collegebus/models/user_model.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/models/route_model.dart';
import 'package:collegebus/models/sos_model.dart';
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
  StreamSubscription? _sosSubscription;
  StreamSubscription? _sosResolvedSubscription;

  List<SosModel> _activeSosAlerts = [];

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
      socketService.addListener(_handleSocketConnectionChange);

      // Trigger once in case already connected
      if (socketService.isConnected) _handleSocketConnectionChange();

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

      // SOS Alerts
      _sosSubscription = socketService.sosAlertStream.listen((data) {
        if (mounted) {
          final sos = SosModel.fromMap(data);
          setState(() {
            _activeSosAlerts.insert(0, sos);
          });
          _showSOSAlert(sos);
        }
      });

      // DEBUG: Listen for room join confirmation
      // This is a dynamic listener not in the service stream yet, but we can access the raw socket if needed
      // Or better, just add a one-off here via the service helper if expose
      // Ideally, the service should expose a stream for 'joined'.
      // For now, let's just log vigorously in the service, but here we only have streams.

      // Let's add a quick debug snackbar on general socket connection
      if (socketService.isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Socket Connected! Listening for SOS...'),
            backgroundColor: Colors.green,
          ),
        );
      }

      _sosResolvedSubscription = socketService.sosResolvedStream.listen((data) {
        if (mounted) {
          final sosId = data['sos_id'];
          setState(() {
            _activeSosAlerts.removeWhere((s) => s.sosId == sosId);
          });
        }
      });

      // Load initial active SOS
      firestoreService.getActiveSos(collegeId).then((alerts) {
        if (mounted) {
          setState(() {
            _activeSosAlerts = alerts;
          });
          // Persistence: Show alert if there are any active SOS when logging in
          if (_activeSosAlerts.isNotEmpty) {
            _showSOSAlert(_activeSosAlerts.first);
          }
        }
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

  void _handleEditDriver(UserModel driver) {
    final TextEditingController nameController = TextEditingController(
      text: driver.fullName,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Driver Name'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Enter driver name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isEmpty || newName == driver.fullName) return;

                final firestoreService = Provider.of<DataService>(
                  context,
                  listen: false,
                );

                try {
                  await firestoreService.updateUser(driver.id, {
                    'fullName': newName,
                  });
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Driver name updated to $newName')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update name: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showSOSAlert(SosModel sos) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.red.shade900,
        title: const Row(
          children: [
            Icon(Icons.report_problem_rounded, color: Colors.white, size: 32),
            SizedBox(width: 12),
            Text(
              'EMERGENCY SOS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A driver has triggered an SOS alert!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Bus: ${sos.busNumber}',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              'Time: ${DateFormat('hh:mm a').format(sos.timestamp.toLocal())}',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'Immediate action is required.',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleTrackDriver(
                BusModel(
                  id: sos.busId,
                  busNumber: sos.busId,
                  driverId: sos.userId,
                  collegeId: sos.collegeId,
                  createdAt: DateTime.now(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red.shade900,
            ),
            child: const Text(
              'TRACK ON MAP',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resolveSos(sos.sosId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'RESOLVE',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('DISMISS', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showActiveSosList() {
    if (!mounted || _activeSosAlerts.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade900,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Center(
                child: Text(
                  'ACTIVE SOS ALERTS (${_activeSosAlerts.length})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _activeSosAlerts.length,
                separatorBuilder: (ctx, i) => const Divider(),
                itemBuilder: (ctx, index) {
                  final sos = _activeSosAlerts[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade900),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Bus: ${sos.busNumber}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              DateFormat(
                                'hh:mm a',
                              ).format(sos.timestamp.toLocal()),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.map, size: 18),
                                label: const Text('TRACK'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.red.shade900,
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _handleTrackDriver(
                                    BusModel(
                                      id: sos.busId,
                                      busNumber: sos.busId,
                                      driverId: sos.userId,
                                      collegeId: sos.collegeId,
                                      createdAt: DateTime.now(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.check, size: 18),
                                label: const Text('RESOLVE'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _resolveSos(sos.sosId);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resolveSos(String sosId) async {
    final dataService = Provider.of<DataService>(context, listen: false);
    try {
      await dataService.resolveSos(sosId);
      if (mounted) {
        setState(() {
          _activeSosAlerts.removeWhere((s) => s.sosId == sosId);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('SOS alert resolved.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to resolve SOS: $e')));
      }
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

  bool _hasShownConnectionSuccess = false;

  void _handleSocketConnectionChange() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    if (socketService.isConnected && !_hasShownConnectionSuccess && mounted) {
      _hasShownConnectionSuccess = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Socket Connected! Listening for SOS...'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _busesSubscription?.cancel();
    _routesSubscription?.cancel();
    _driversSubscription?.cancel();
    _busNumbersSubscription?.cancel();
    _driverStatusSubscription?.cancel();
    _sosSubscription?.cancel();
    _sosResolvedSubscription?.cancel();

    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.removeListener(_handleSocketConnectionChange);

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
                          activeSosCount: _activeSosAlerts.length,
                          onSosTap: _showActiveSosList,
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
                          onEditDriver: _handleEditDriver,
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
                      activeSosCount: _activeSosAlerts.length,
                      onSosTap: _showActiveSosList,
                    ),
                    LiveMapTab(buses: _buses, selectedBus: _currentTrackingBus),
                    DriverManagementTab(
                      pendingApprovals: _pendingDrivers,
                      allDrivers: _allDrivers,
                      buses: _buses,
                      onlineDriverIds: _onlineDriverIds,
                      onApprove: _approveDriver,
                      onReject: _rejectDriver,
                      onEditDriver: _handleEditDriver,
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
          floatingActionButton: _activeSosAlerts.isNotEmpty
              ? FloatingActionButton.extended(
                  onPressed: () {
                    if (_activeSosAlerts.length > 1) {
                      _showActiveSosList();
                    } else {
                      _showSOSAlert(_activeSosAlerts.first);
                    }
                  },
                  backgroundColor: AppColors.error,
                  icon: const Icon(Icons.warning, color: Colors.white),
                  label:
                      (_activeSosAlerts.length > 1
                              ? '(${_activeSosAlerts.length}) ACTIVE ALERTS'
                              : 'ACTIVE SOS')
                          .text
                          .white
                          .bold
                          .make(),
                )
              : null,
        );
      },
    );
  }
}
