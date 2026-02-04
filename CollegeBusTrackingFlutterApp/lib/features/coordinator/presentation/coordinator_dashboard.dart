import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/core/providers/socket_provider.dart';
import 'package:collegebus/features/sos/application/sos_provider.dart';
import 'package:collegebus/core/providers/api_provider.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/features/sos/domain/sos_model.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/features/notification/presentation/screens/notifications_screen.dart';
import 'package:collegebus/features/notification/services/notification_service.dart';
import 'package:collegebus/features/coordinator/presentation/schedule_management_screen.dart';
import 'package:collegebus/features/user/presentation/screens/profile_screen.dart';
import 'package:collegebus/features/coordinator/presentation/modules/overview_tab.dart';
import 'package:collegebus/features/coordinator/presentation/modules/driver_management_tab.dart';
import 'package:collegebus/features/coordinator/presentation/modules/routes_tab.dart';
import 'package:collegebus/features/coordinator/presentation/modules/bus_numbers_tab.dart';
import 'package:collegebus/features/coordinator/presentation/modules/live_map_tab.dart';
import 'package:collegebus/l10n/coordinator/app_localizations.dart'
    as coord_l10n;

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
      _bottomNavIndex = 0; // Go to Dashboard
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
                      color: Colors.red.withOpacity(0.1),
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
                            const SizedBox(width: 8.0),
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final collegeId = user?.collegeId;
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
              // Trigger loud alarm notification
              NotificationService.showSOSAlert(
                busNumber: alert.busNumber,
                driverName: alert.userId, // Using userId as name placeholder
              );
            }
          }
        }
      });
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: null,
      appBar: _bottomNavIndex == 0
          ? AppBar(
              title: Text(l10n.dashboardTitle),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              bottom: TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).colorScheme.onPrimary,
                unselectedLabelColor: Theme.of(
                  context,
                ).colorScheme.onPrimary.withOpacity(0.7),
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
            )
          : null,

      body: IndexedStack(
        index: _bottomNavIndex,
        children: [
          // 0: Dashboard (TabBarView)
          TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
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
          // 1: Notifications
          const NotificationsScreen(),
          // 2: Manage Schedule
          const ScheduleManagementScreen(),
          // 3: Profile
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
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
      ),
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
              label: Text(
                activeSosAlerts.length > 1
                    ? '(${activeSosAlerts.length}) ACTIVE ALERTS'
                    : 'ACTIVE SOS',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }
}





