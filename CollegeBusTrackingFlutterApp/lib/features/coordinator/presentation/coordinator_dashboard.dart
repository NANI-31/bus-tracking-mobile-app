import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:collegebus/core/utils/app_logger.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/core/providers/socket_provider.dart';
import 'package:collegebus/features/sos/application/sos_provider.dart';
import 'package:collegebus/core/providers/api_provider.dart';
import 'package:collegebus/core/providers/service_providers.dart'; // Added for locationServiceProvider
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/features/sos/domain/sos_model.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/features/notification/presentation/screens/notifications_screen.dart';
import 'package:collegebus/features/notification/services/notification_service.dart';
import 'package:collegebus/features/notification/services/fcm_service.dart'; // Added

import 'package:collegebus/features/coordinator/presentation/schedule_management_screen.dart';
import 'package:collegebus/features/user/presentation/screens/profile_screen.dart';
import 'package:collegebus/features/coordinator/presentation/modules/overview_tab.dart';
import 'package:collegebus/features/coordinator/presentation/modules/driver_management_tab.dart';
import 'package:collegebus/features/coordinator/presentation/modules/routes_tab.dart';
import 'package:collegebus/features/coordinator/presentation/modules/bus_numbers_tab.dart';
import 'package:collegebus/shared/widgets/navigation/curved_bottom_nav_bar.dart';
import 'package:collegebus/features/notification/application/notification_provider.dart';

import 'package:collegebus/features/coordinator/presentation/modules/live_map_tab.dart';
import 'package:collegebus/features/settings/presentation/sos_sound_settings.dart';
import 'package:collegebus/features/sos/application/sos_sound_provider.dart';
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
  StreamSubscription? _fcmTapSubscription;

  @override
  void initState() {
    super.initState();
    // Restore/Enable Status Bar
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    _tabController = TabController(length: 5, vsync: this);

    // Listen for user data to join socket room
    // This handles both initial load and re-auth scenarios
    ref.listenManual(currentUserProvider, (previous, next) {
      if (next?.collegeId != null && (previous?.collegeId != next?.collegeId)) {
        ref.read(socketServiceProvider).joinCollege(next!.collegeId);
      }
    });

    // Also check initial state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user?.collegeId != null) {
        ref.read(socketServiceProvider).joinCollege(user!.collegeId);
      }
      _checkPermissions();
      _setupSosListener();
    });
  }

  StreamSubscription? _sosAlertSubscription;

  void _setupSosListener() {
    final socket = ref.read(socketServiceProvider);
    final user = ref.read(currentUserProvider);
    final collegeId = user?.collegeId;

    _sosAlertSubscription?.cancel();
    _sosAlertSubscription = socket.sosAlertStream.listen((data) {
      AppLogger.i('[CoordinatorDashboard] Direct SOS stream received: $data');
      final sos = SosModel.fromMap(data);
      if (collegeId == null || sos.collegeId == collegeId) {
        _showSOSAlert(sos);
      }
    });
  }

  Future<void> _checkPermissions() async {
    // 1. Request Notification Permission
    await FCMService().requestPermission();

    // 2. Request Location Permission
    final locationService = ref.read(locationServiceProvider);
    await locationService.requestLocationPermission();

    // 3. Refresh FCM Token
    final user = ref.read(currentUserProvider);
    if (user != null) {
      debugPrint('Refreshing FCM token after permissions...');
    }
  }

  void _handleTrackBus(BusModel bus) {
    setState(() {
      _selectedBus = bus;
      if (_bottomNavIndex != 0) {
        _stopSosSound(); // Stop preview if switching from profile
      }
      _bottomNavIndex = 0; // Go to Dashboard
      _tabController.animateTo(1); // Switch to Live Map tab
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fcmTapSubscription?.cancel();
    _sosAlertSubscription?.cancel();
    super.dispose();
  }

  Future<void> _playSosSound() async {
    final enabled = await SosSettingsService.isSoundEnabled();
    if (!enabled) return;

    final soundFile = await SosSettingsService.getSoundFile();
    final volume = await SosSettingsService.getVolume();
    final player = ref.read(sosSoundPlayerProvider);

    await player.setVolume(volume);
    await player.play('sounds/$soundFile', loop: true);
  }

  Future<void> _stopSosSound() async {
    await ref.read(sosSoundPlayerProvider).stop();
  }

  void _showSOSAlert(SosModel sos) {
    if (!mounted) return;

    _playSosSound();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.isDarkMode
            ? Color(0xFF420000)
            : Colors.red.shade900,
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
              _stopSosSound();
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
              _stopSosSound();
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
            onPressed: () {
              _stopSosSound();
              Navigator.pop(ctx);
            },
            child: const Text('DISMISS', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showActiveSosList() {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final user = ref.watch(currentUserProvider);
          final collegeId = user?.collegeId;
          if (collegeId == null) return const SizedBox.shrink();

          final activeSosAsync = ref.watch(activeSosProvider(collegeId));

          return activeSosAsync.when(
            data: (activeSosAlerts) {
              if (activeSosAlerts.isEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                });
                return const SizedBox.shrink();
              }
              return Container(
                height: MediaQuery.of(context).size.height * 0.7,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: context.colorScheme.onSurface
                                            .withValues(alpha: 0.5),
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
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
          );
        },
      ),
    );
  }

  Future<void> _resolveSos(String sosId) async {
    final api = ref.read(apiServiceProvider);
    try {
      await api.resolveSos(sosId);
      final user = ref.read(currentUserProvider);
      if (user?.collegeId != null) {
        ref.invalidate(activeSosProvider(user!.collegeId));
      }
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
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final collegeId = user?.collegeId;
    final l10n = coord_l10n.CoordinatorLocalizations.of(context)!;

    // We only need activeSosAlerts list for the FAB at dashboard level
    final activeSosAlerts = collegeId != null
        ? ref.watch(activeSosProvider(collegeId)).value ?? []
        : <SosModel>[];

    // Listen for new SOS alerts from provider (for notification only, UI handled by direct stream)
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
              // Note: SOS UI dialog is shown via direct socket stream in _setupSosListener
              // Only trigger system notification here
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
              foregroundColor: Colors.white,
              bottom: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
                indicatorColor: Colors.white,
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
              DriverManagementTab(onTrack: _handleTrackBus),
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
      bottomNavigationBar: CurvedBottomNavBar(
        currentIndex: _bottomNavIndex,
        onTap: (index) {
          if (_bottomNavIndex != index) {
            _stopSosSound(); // Stop sound when switching tabs
          }
          setState(() {
            _bottomNavIndex = index;
          });
        },
        activeColor: _getCoordinatorActiveColor(context),
        backgroundColor: Theme.of(context).cardColor,
        items: [
          const CurvedBottomNavItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
          ),
          CurvedBottomNavItem(
            icon: Icons.notifications_none_outlined,
            label: 'Notifications',
            badgeCount: ref.watch(unreadNotificationsCountProvider),
          ),
          const CurvedBottomNavItem(
            icon: Icons.edit_calendar_outlined,
            label: 'Schedule',
          ),
          const CurvedBottomNavItem(
            icon: Icons.person_outline,
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: activeSosAlerts.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                if (activeSosAlerts.length > 1) {
                  _showActiveSosList();
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

  Color _getCoordinatorActiveColor(BuildContext context) {
    switch (_bottomNavIndex) {
      case 0:
        return Theme.of(context).primaryColor;
      case 1:
        return Colors.amber.shade700;
      case 2:
        return Colors.teal.shade600;
      case 3:
        return Colors.indigo.shade600;
      default:
        return Theme.of(context).primaryColor;
    }
  }
}
