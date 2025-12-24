import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/services/data_service.dart';
import 'package:collegebus/models/user_model.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/models/college_model.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/models/route_model.dart';
import 'package:collegebus/widgets/app_drawer.dart';
import 'package:collegebus/services/theme_service.dart';
import 'package:collegebus/screens/notifications_screen.dart';
import 'package:collegebus/screens/coordinator/schedule_management_screen.dart';
import 'package:collegebus/screens/student/student_profile_screen.dart';
import 'package:velocity_x/velocity_x.dart';

class CoordinatorDashboard extends StatefulWidget {
  const CoordinatorDashboard({super.key});

  @override
  State<CoordinatorDashboard> createState() => _CoordinatorDashboardState();
}

class _CoordinatorDashboardState extends State<CoordinatorDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<UserModel> _pendingDrivers = [];
  List<BusModel> _buses = [];
  List<RouteModel> _routes = [];
  CollegeModel? _college;
  List<String> _busNumbers = [];
  int _bottomNavIndex = 0;

  // Stream subscriptions
  StreamSubscription? _pendingDriversSubscription;
  StreamSubscription? _busesSubscription;
  StreamSubscription? _routesSubscription;
  StreamSubscription? _busNumbersSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pendingDriversSubscription?.cancel();
    _busesSubscription?.cancel();
    _routesSubscription?.cancel();
    _busNumbersSubscription?.cancel();
    super.dispose();
  }

  void _loadData() {
    _loadPendingDrivers();
    _loadBuses();
    _loadRoutes();
    _loadCollege();
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

  Future<void> _loadCollege() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<DataService>(context, listen: false);
    final collegeId = authService.currentUserModel?.collegeId;
    if (collegeId != null && mounted) {
      final college = await firestoreService.getCollege(collegeId);
      if (mounted) {
        setState(() {
          _college = college;
        });
      }
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

  void _showCreateOrEditRouteDialog({RouteModel? route}) {
    final isEditing = route != null;
    final TextEditingController nameController = TextEditingController(
      text: route?.routeName ?? '',
    );
    final TextEditingController startController = TextEditingController(
      text: route?.startPoint ?? '',
    );
    final TextEditingController endController = TextEditingController(
      text: route?.endPoint ?? '',
    );
    String selectedType = route?.routeType ?? 'pickup';
    List<TextEditingController> stopControllers = (route?.stopPoints ?? [])
        .map((s) => TextEditingController(text: s))
        .toList();
    if (stopControllers.isEmpty) stopControllers.add(TextEditingController());

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Route' : 'Create Route'),
              content: SingleChildScrollView(
                child: VStack([
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Route Name'),
                  ),
                  8.heightBox,
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: 'Route Type'),
                    items: const [
                      DropdownMenuItem(value: 'pickup', child: Text('Pickup')),
                      DropdownMenuItem(value: 'drop', child: Text('Drop')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedType = value!;
                      });
                    },
                  ),
                  8.heightBox,
                  TextField(
                    controller: startController,
                    decoration: const InputDecoration(labelText: 'Start Point'),
                    enabled: !isEditing,
                  ),
                  8.heightBox,
                  ...stopControllers.asMap().entries.map((entry) {
                    int idx = entry.key;
                    TextEditingController controller = entry.value;
                    return HStack([
                      TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: 'Stop ${idx + 1}',
                        ),
                      ).expand(),
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle,
                          color: Colors.red,
                        ),
                        onPressed: stopControllers.length > 1
                            ? () {
                                setState(() {
                                  stopControllers.removeAt(idx);
                                });
                              }
                            : null,
                      ),
                    ]);
                  }),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Stop'),
                      onPressed: () {
                        setState(() {
                          stopControllers.add(TextEditingController());
                        });
                      },
                    ),
                  ),
                  TextField(
                    controller: endController,
                    decoration: const InputDecoration(labelText: 'End Point'),
                    enabled: !isEditing,
                  ),
                ]),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final firestoreService = Provider.of<DataService>(
                      context,
                      listen: false,
                    );
                    final authService = Provider.of<AuthService>(
                      context,
                      listen: false,
                    );
                    final collegeId = authService.currentUserModel?.collegeId;
                    if (collegeId == null) return;
                    final stops = stopControllers
                        .map((c) => c.text.trim())
                        .where((s) => s.isNotEmpty)
                        .toList();
                    if (startController.text.trim().isEmpty ||
                        endController.text.trim().isEmpty)
                      return;
                    if (isEditing) {
                      await firestoreService.updateRoute(route.id, {
                        'routeName': nameController.text.trim(),
                        'routeType': selectedType,
                        'stopPoints': stops,
                        'updatedAt': DateTime.now().toIso8601String(),
                      });
                      if (!mounted) return;
                    } else {
                      final newRoute = RouteModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        routeName: nameController.text.trim().isNotEmpty
                            ? nameController.text.trim()
                            : '${startController.text.trim()} - ${endController.text.trim()}',
                        routeType: selectedType,
                        startPoint: startController.text.trim(),
                        endPoint: endController.text.trim(),
                        stopPoints: stops,
                        collegeId: collegeId,
                        createdBy: authService.currentUserModel?.id ?? '',
                        isActive: true,
                        createdAt: DateTime.now(),
                        updatedAt: null,
                      );
                      await firestoreService.createRoute(newRoute);
                      if (!mounted) return;
                    }
                    if (!mounted) return;
                    Navigator.of(context).pop();
                  },
                  child: Text(isEditing ? 'Save' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCreateBusNumberDialog() {
    final TextEditingController busNumberController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Bus Number'),
          content: TextField(
            controller: busNumberController,
            decoration: const InputDecoration(
              labelText: 'Bus Number',
              hintText: 'e.g., KA-01-AB-1234',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final busNumber = busNumberController.text.trim();
                if (busNumber.isEmpty) return;

                final authService = Provider.of<AuthService>(
                  context,
                  listen: false,
                );
                final firestoreService = Provider.of<DataService>(
                  context,
                  listen: false,
                );
                final collegeId = authService.currentUserModel?.collegeId;

                if (collegeId != null) {
                  await firestoreService.addBusNumber(collegeId, busNumber);
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Bus number $busNumber added successfully'),
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
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
                            Tab(text: 'Details', icon: Icon(Icons.school)),
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
                      onPressed: () {
                        authService.signOut();
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
                      Tab(text: 'Details', icon: Icon(Icons.school)),
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
                        _buildOverviewTab(),
                        _buildDriverApprovalsTab(),
                        _buildRoutesTab(),
                        _buildBusNumbersTab(),
                        _buildCollegeInfoTab(),
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
                    _buildOverviewTab(),
                    _buildDriverApprovalsTab(),
                    _buildRoutesTab(),
                    _buildBusNumbersTab(),
                    _buildCollegeInfoTab(),
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

  Widget _buildOverviewTab() {
    return VStack([
      'System Overview'.text
          .size(24)
          .bold
          .color(Theme.of(context).colorScheme.onSurface)
          .make(),
      AppSizes.paddingLarge.heightBox,

      // Statistics Cards
      HStack([
        _buildStatCard(
          'Total Routes',
          _routes.length.toString(),
          Icons.route,
          Theme.of(context).primaryColor,
        ).expand(),
        AppSizes.paddingMedium.widthBox,
        _buildStatCard(
          'Active Buses',
          _buses.where((b) => b.isActive).length.toString(),
          Icons.directions_bus,
          Theme.of(context).colorScheme.secondary,
        ).expand(),
      ]),

      AppSizes.paddingMedium.heightBox,

      HStack([
        _buildStatCard(
          'Pending Drivers',
          _pendingDrivers.length.toString(),
          Icons.pending,
          Theme.of(context).colorScheme.error,
        ).expand(),
        AppSizes.paddingMedium.widthBox,
        _buildStatCard(
          'Bus Numbers',
          _busNumbers.length.toString(),
          Icons.confirmation_number,
          Theme.of(context).colorScheme.secondary,
        ).expand(),
      ]),
    ]).p(AppSizes.paddingMedium);
  }

  Widget _buildDriverApprovalsTab() {
    return _pendingDrivers.isEmpty
        ? VStack(
            [
              Icon(
                Icons.check_circle_outline,
                size: 64,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              AppSizes.paddingMedium.heightBox,
              'No pending driver approvals'.text
                  .size(18)
                  .color(
                    Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  )
                  .make(),
            ],
            alignment: MainAxisAlignment.center,
            crossAlignment: CrossAxisAlignment.center,
          ).centered()
        : ListView.builder(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            itemCount: _pendingDrivers.length,
            itemBuilder: (context, index) {
              final driver = _pendingDrivers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Icon(
                      Icons.drive_eta,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  title: driver.fullName.text.semiBold.make(),
                  subtitle: VStack([
                    driver.email.text.make(),
                    if (driver.phoneNumber != null &&
                        driver.phoneNumber!.isNotEmpty)
                      'Phone: ${driver.phoneNumber}'.text.make(),
                    'Applied: ${driver.createdAt.toString().substring(0, 10)}'
                        .text
                        .size(12)
                        .color(
                          Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        )
                        .make(),
                  ]),
                  trailing: HStack([
                    IconButton(
                      icon: Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      onPressed: () => _approveDriver(driver),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: () => _rejectDriver(driver),
                    ),
                  ]),
                  isThreeLine: true,
                ),
              );
            },
          );
  }

  Widget _buildRoutesTab() {
    return VStack([
      HStack(
        [
          'Routes'.text.size(20).bold.make(),
          ElevatedButton.icon(
            onPressed: () => _showCreateOrEditRouteDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Create Route'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
        alignment: MainAxisAlignment.spaceBetween,
        axisSize: MainAxisSize.max,
      ).p(AppSizes.paddingMedium),
      Expanded(
        child: _routes.isEmpty
            ? VStack(
                [
                  Icon(
                    Icons.route_outlined,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  AppSizes.paddingMedium.heightBox,
                  'No routes created yet'.text
                      .size(18)
                      .color(AppColors.textSecondary)
                      .make(),
                  AppSizes.paddingSmall.heightBox,
                  'Create routes for drivers to select'.text
                      .size(14)
                      .color(AppColors.textSecondary)
                      .center
                      .make(),
                ],
                alignment: MainAxisAlignment.center,
                crossAlignment: CrossAxisAlignment.center,
              ).centered()
            : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingMedium,
                ),
                itemCount: _routes.length,
                itemBuilder: (context, index) {
                  final route = _routes[index];
                  return Card(
                    margin: const EdgeInsets.only(
                      bottom: AppSizes.paddingMedium,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: route.routeType == 'pickup'
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).primaryColor,
                        child: Icon(
                          route.routeType == 'pickup'
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                      title: route.routeName.text.semiBold.make(),
                      subtitle: VStack([
                        'Type: ${route.routeType.toUpperCase()}'.text.make(),
                        '${route.startPoint} → ${route.endPoint}'.text.make(),
                        if (route.stopPoints.isNotEmpty)
                          'Stops: ${route.stopPoints.join(', ')}'.text
                              .size(12)
                              .make(),
                      ]),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                SizedBox(width: 8),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) async {
                          if (value == 'edit') {
                            _showCreateOrEditRouteDialog(route: route);
                          } else if (value == 'delete') {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Route'),
                                content: Text(
                                  'Are you sure you want to delete ${route.routeName}?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              final firestoreService = Provider.of<DataService>(
                                context,
                                listen: false,
                              );
                              await firestoreService.deleteRoute(route.id);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Route deleted successfully'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          }
                        },
                      ),
                      isThreeLine: route.stopPoints.isNotEmpty,
                    ),
                  );
                },
              ),
      ),
    ]);
  }

  Widget _buildBusNumbersTab() {
    return VStack([
      HStack(
        [
          'Bus Numbers'.text.size(20).bold.make(),
          ElevatedButton.icon(
            onPressed: _showCreateBusNumberDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Bus Number'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
          ),
        ],
        alignment: MainAxisAlignment.spaceBetween,
        axisSize: MainAxisSize.max,
      ).p(AppSizes.paddingMedium),
      Expanded(
        child: _busNumbers.isEmpty
            ? VStack(
                [
                  Icon(
                    Icons.directions_bus_outlined,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  AppSizes.paddingMedium.heightBox,
                  'No bus numbers added yet'.text
                      .size(18)
                      .color(AppColors.textSecondary)
                      .make(),
                  AppSizes.paddingSmall.heightBox,
                  'Add bus numbers for drivers to select'.text
                      .size(14)
                      .color(AppColors.textSecondary)
                      .center
                      .make(),
                ],
                alignment: MainAxisAlignment.center,
                crossAlignment: CrossAxisAlignment.center,
              ).centered()
            : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingMedium,
                ),
                itemCount: _busNumbers.length,
                itemBuilder: (context, index) {
                  final busNumber = _busNumbers[index];
                  final isAssigned = _buses.any(
                    (bus) => bus.busNumber == busNumber,
                  );

                  return Card(
                    margin: const EdgeInsets.only(
                      bottom: AppSizes.paddingMedium,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isAssigned
                            ? AppColors.success
                            : AppColors.warning,
                        child: Icon(
                          isAssigned ? Icons.check : Icons.directions_bus,
                          color: AppColors.onPrimary,
                        ),
                      ),
                      title: busNumber.text.semiBold.make(),
                      subtitle:
                          (isAssigned ? 'Assigned to driver' : 'Available').text
                              .color(
                                isAssigned
                                    ? AppColors.success
                                    : AppColors.warning,
                              )
                              .medium
                              .make(),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: AppColors.error),
                        onPressed: () async {
                          if (isAssigned) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Cannot delete assigned bus number',
                                ),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }

                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Bus Number'),
                              content: Text(
                                'Are you sure you want to delete $busNumber?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.error,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            final authService = Provider.of<AuthService>(
                              context,
                              listen: false,
                            );
                            final firestoreService = Provider.of<DataService>(
                              context,
                              listen: false,
                            );
                            final collegeId =
                                authService.currentUserModel?.collegeId;

                            if (collegeId != null) {
                              await firestoreService.removeBusNumber(
                                collegeId,
                                busNumber,
                              );
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Bus number $busNumber deleted',
                                  ),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
    ]);
  }

  Widget _buildCollegeInfoTab() {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUserModel;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      child: VStack([
        // Header with College Name and Icon
        HStack([
              VxBox(
                    child: const Icon(
                      Icons.school,
                      size: 40,
                      color: Colors.white,
                    ),
                  ).p16
                  .withDecoration(
                    BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                  )
                  .make(),
              AppSizes.paddingMedium.widthBox,
              VStack([
                (_college?.name ?? 'College Name').text
                    .size(24)
                    .bold
                    .white
                    .make(),
                4.heightBox,
                (user?.collegeId ?? 'College ID').text
                    .size(14)
                    .color(Colors.white.withValues(alpha: 0.9))
                    .make(),
              ]).expand(),
              VxBox(
                    child: (_college?.verified == true ? 'Verified' : 'Pending')
                        .text
                        .white
                        .bold
                        .size(12)
                        .make(),
                  )
                  .color(
                    _college?.verified == true
                        ? AppColors.success
                        : AppColors.warning,
                  )
                  .roundedFull
                  .padding(
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  )
                  .make()
                  .p(AppSizes.paddingSmall),
            ]).box
            .linearGradient(
              [AppColors.primary, AppColors.primary.withAlpha(204)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
            .roundedLg
            .shadow
            .make(),
        AppSizes.paddingLarge.heightBox,

        // College Details Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            side: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            ),
          ),
          child: VStack([
            'College Details'.text.size(18).bold.make(),
            AppSizes.paddingMedium.heightBox,
            _buildDetailRow(
              Icons.calendar_today,
              'Joined',
              _college?.createdAt.toString().substring(0, 10) ?? 'Not set',
            ),
          ]).p(AppSizes.paddingMedium),
        ),
        AppSizes.paddingLarge.heightBox,

        // Statistics Summary
        'Quick Stats'.text
            .size(18)
            .bold
            .color(Theme.of(context).colorScheme.onSurface)
            .make(),
        AppSizes.paddingMedium.heightBox,
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSizes.paddingMedium,
          crossAxisSpacing: AppSizes.paddingMedium,
          childAspectRatio: 1.5,
          children: [
            _buildSummaryCard(
              'Drivers',
              _pendingDrivers.length.toString(),
              Icons.people,
              Colors.blue,
            ),
            _buildSummaryCard(
              'Routes',
              _routes.length.toString(),
              Icons.route,
              Colors.orange,
            ),
            _buildSummaryCard(
              'Buses',
              _buses.length.toString(),
              Icons.directions_bus,
              Colors.green,
            ),
            _buildSummaryCard(
              'Status',
              _college?.verified == true ? 'Active' : 'Pending',
              Icons.verified_user,
              Colors.purple,
            ),
          ],
        ),
        AppSizes.paddingLarge.heightBox,

        'Account Details'.text
            .size(18)
            .bold
            .color(AppColors.textPrimary)
            .make(),
        AppSizes.paddingMedium.heightBox,

        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
          child: VStack([
            _buildDetailTile(Icons.email, 'Email', user?.email ?? 'N/A'),
            const Divider(height: 1),
            _buildDetailTile(
              Icons.admin_panel_settings,
              'Role',
              user?.role.displayName ?? 'N/A',
            ),
            const Divider(height: 1),
            _buildDetailTile(
              Icons.domain,
              'Allowed Domains',
              _college?.allowedDomains.join(', ') ?? 'N/A',
            ),
            const Divider(height: 1),
            _buildDetailTile(
              Icons.verified_user,
              'Account Status',
              user?.approved == true ? 'Approved' : 'Pending Verification',
            ),
          ]),
        ),
        100.heightBox, // Bottom padding
      ]),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return VxBox(
          child: VStack(
            [
              Icon(icon, color: color, size: 28),
              8.heightBox,
              value.text.size(20).bold.color(color).make(),
              title.text
                  .size(12)
                  .color(
                    Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  )
                  .make(),
            ],
            alignment: MainAxisAlignment.center,
            crossAlignment: CrossAxisAlignment.center,
          ),
        )
        .color(Theme.of(context).cardColor)
        .withRounded(value: AppSizes.radiusMedium)
        .withDecoration(
          BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
        )
        .make()
        .p(AppSizes.paddingMedium);
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return HStack(
      [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        AppSizes.paddingSmall.widthBox,
        VStack([
          title.text
              .size(12)
              .color(
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              )
              .make(),
          value.text.size(16).medium.make(),
        ]).expand(),
      ],
      crossAlignment: CrossAxisAlignment.start,
    ).pOnly(bottom: AppSizes.paddingMedium);
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: VStack([
        Icon(icon, size: 32, color: color),
        AppSizes.paddingSmall.heightBox,
        value.text.size(24).bold.color(color).make(),
        AppSizes.paddingSmall.heightBox,
        title.text
            .size(14)
            .color(
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            )
            .center
            .make(),
      ], crossAlignment: CrossAxisAlignment.center).p(AppSizes.paddingMedium),
    );
  }

  Widget _buildDetailTile(IconData icon, String title, String value) {
    return ListTile(
      leading:
          VxBox(
                child: Icon(
                  icon,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
              ).p8.rounded
              .color(Theme.of(context).primaryColor.withValues(alpha: 0.1))
              .make(),
      title: title.text
          .size(12)
          .color(Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))
          .make(),
      subtitle: value.text
          .size(16)
          .medium
          .color(Theme.of(context).colorScheme.onSurface)
          .make(),
    );
  }
}
