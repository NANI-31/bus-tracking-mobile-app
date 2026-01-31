import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:collegebus/providers/auth_provider.dart';
import 'package:collegebus/providers/service_providers.dart';
import 'package:collegebus/providers/socket_provider.dart';
import 'package:collegebus/providers/user_provider.dart';
import 'package:collegebus/providers/bus_provider.dart';
import 'package:collegebus/providers/route_provider.dart';
import 'package:collegebus/providers/sos_provider.dart';
import 'package:collegebus/providers/api_provider.dart';
import 'package:collegebus/models/user_model.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/models/sos_model.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/widgets/app_drawer.dart';
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
import 'package:collegebus/services/core/export_service.dart';

class CoordinatorDashboard extends ConsumerStatefulWidget {
  const CoordinatorDashboard({super.key});

  @override
  ConsumerState<CoordinatorDashboard> createState() =>
      _CoordinatorDashboardState();
}

class _CoordinatorDashboardState extends ConsumerState<CoordinatorDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _bottomNavIndex = 0;
  BusModel? _selectedBus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user?.collegeId != null) {
        ref.read(socketServiceProvider).joinCollege(user!.collegeId);
      }
    });
  }

  void _handleTrackBus(BusModel bus) {
    setState(() {
      _selectedBus = bus;
      _tabController.animateTo(1); // Switch to Live Map tab
    });
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
              _handleTrackBus(
                BusModel(
                  id: sos.busId,
                  busNumber: sos.busNumber,
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

  void _showActiveSosList(List<SosModel> activeSosAlerts) {
    if (!mounted || activeSosAlerts.isEmpty) return;

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
                  'ACTIVE SOS ALERTS (${activeSosAlerts.length})',
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
                itemCount: activeSosAlerts.length,
                separatorBuilder: (ctx, i) => const Divider(),
                itemBuilder: (ctx, index) {
                  final sos = activeSosAlerts[index];
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
                                  _handleTrackBus(
                                    BusModel(
                                      id: sos.busId,
                                      busNumber: sos.busNumber,
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
    final api = ref.read(apiServiceProvider);
    try {
      await api.resolveSos(sosId);
      if (mounted) {
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

  Future<void> _showExportDialog(
    BuildContext context,
    List<BusModel> buses,
    List<UserModel> allDrivers,
  ) async {
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
                  await ExportService().exportBuses(buses);
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
                  await ExportService().exportDrivers(allDrivers);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final collegeId = user?.collegeId;
    final themeService = ref.watch(themeServiceProvider);
    final l10n = coord_l10n.CoordinatorLocalizations.of(context)!;

    // We only need activeSosAlerts list for the FAB at dashboard level
    final activeSosAlerts = collegeId != null
        ? ref.watch(activeSosProvider(collegeId)).value ?? []
        : <SosModel>[];

    // Listen for new SOS alerts
    if (collegeId != null) {
      ref.listen<AsyncValue<List<SosModel>>>(activeSosProvider(collegeId), (
        previous,
        next,
      ) {
        if (next is AsyncData<List<SosModel>>) {
          final currentAlerts = next.value;
          final previousAlerts = previous?.value ?? [];

          for (final alert in currentAlerts) {
            if (!previousAlerts.any((s) => s.sosId == alert.sosId)) {
              _showSOSAlert(alert);
            }
          }
        }
      });
    }

    // Watch data needed for dashboard-level actions (export, refresh)
    final buses = collegeId != null
        ? ref.watch(collegeBusesStreamProvider(collegeId)).value ?? []
        : <BusModel>[];
    final allDrivers = collegeId != null
        ? ref
                  .watch(
                    usersByRoleProvider((
                      role: UserRole.driver,
                      collegeId: collegeId,
                    )),
                  )
                  .value ??
              []
        : <UserModel>[];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: themeService.useBottomNavigation ? null : AppDrawer(user: user),
      appBar: themeService.useBottomNavigation
          ? (_bottomNavIndex == 0
                ? AppBar(
                    title: l10n.dashboardTitle.text.make(),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
                        Tab(
                          text: l10n.drivers,
                          icon: const Icon(Icons.approval),
                        ),
                        Tab(text: l10n.routes, icon: const Icon(Icons.route)),
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
                    if (collegeId != null) {
                      ref.invalidate(collegeBusesStreamProvider(collegeId));
                      ref.invalidate(collegeRoutesProvider(collegeId));
                      ref.invalidate(busNumbersProvider(collegeId));
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
                  onPressed: () =>
                      _showExportDialog(context, buses, allDrivers),
                ),
                IconButton(
                  icon: Icon(
                    themeService.isDarkMode
                        ? Icons.dark_mode
                        : Icons.light_mode,
                  ),
                  onPressed: () {
                    ref
                        .read(themeServiceProvider.notifier)
                        .toggleTheme(!themeService.isDarkMode);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await ref.read(authProvider.notifier).signOut();
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
                  Tab(text: l10n.overview, icon: const Icon(Icons.dashboard)),
                  const Tab(text: 'Live Map', icon: Icon(Icons.map)),
                  Tab(text: l10n.drivers, icon: const Icon(Icons.approval)),
                  Tab(text: l10n.routes, icon: const Icon(Icons.route)),
                  Tab(text: l10n.buses, icon: const Icon(Icons.directions_bus)),
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
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    OverviewTab(
                      onSosTap: () =>
                          _tabController.animateTo(1), // Go to Live Map
                    ),
                    LiveMapTab(selectedBus: _selectedBus),
                    const DriverManagementTab(),
                    const RoutesTab(),
                    const BusNumbersTab(),
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
                  onSosTap: () => _tabController.animateTo(1), // Go to Live Map
                ),
                LiveMapTab(selectedBus: _selectedBus),
                const DriverManagementTab(),
                const RoutesTab(),
                const BusNumbersTab(),
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
      floatingActionButton: activeSosAlerts.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                if (activeSosAlerts.length > 1) {
                  _showActiveSosList(activeSosAlerts);
                } else {
                  _showSOSAlert(activeSosAlerts.first);
                }
              },
              backgroundColor: AppColors.error,
              icon: const Icon(Icons.warning, color: Colors.white),
              label:
                  (activeSosAlerts.length > 1
                          ? '(${activeSosAlerts.length}) ACTIVE ALERTS'
                          : 'ACTIVE SOS')
                      .text
                      .white
                      .bold
                      .make(),
            )
          : null,
    );
  }
}
