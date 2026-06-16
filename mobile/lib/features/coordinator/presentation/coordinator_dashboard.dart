import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animations/animations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:collegebus/core/utils/app_logger.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/core/providers/socket_provider.dart';
import 'package:collegebus/features/sos/application/sos_provider.dart';
import 'package:collegebus/core/providers/repository_providers.dart';
import 'package:collegebus/core/providers/service_providers.dart'; // Added for locationServiceProvider
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/features/bus/application/bus_provider.dart';
import 'package:collegebus/features/user/domain/user_model.dart';
import 'package:collegebus/features/sos/domain/sos_model.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:go_router/go_router.dart';
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
import 'package:collegebus/shared/widgets/api_error_modal.dart';
import 'package:collegebus/shared/widgets/success_modal.dart';

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
  int _previousBottomNavIndex = 0;
  int _previousSubTabIndex = 0;
  BusModel? _selectedBus;

  /// Key for the [RepaintBoundary] that wraps the mobile content body.
  /// Passed to [CurvedBottomNavBar] so the liquid-glass lens shader can
  /// sample the real pixels rendered behind the navigation bar.
  final GlobalKey _backgroundKey = GlobalKey();
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
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

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
      _previousBottomNavIndex = _bottomNavIndex;
      _bottomNavIndex = 0; // Go to Dashboard
      _previousSubTabIndex = _tabController.index;
      _tabController.animateTo(1); // Switch to Live Map tab
    });
  }

  void _handleEditDriver(UserModel driver) {
    final user = ref.read(currentUserProvider);
    final collegeId = user?.collegeId;
    if (collegeId == null) return;

    // We use read here because this is an event handler
    final buses =
        ref.read(allCollegeBusesStreamProvider(collegeId)).value ?? [];

    try {
      final bus = buses.firstWhere((b) => b.driverId == driver.id);
      context.push(
        '/coordinator/edit-bus/${bus.busNumber}?editable=false',
        extra: bus,
      );
    } catch (_) {
      context.push('/coordinator/edit-driver/${driver.id}', extra: driver);
    }
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
    final repo = ref.read(incidentRepositoryProvider);
    try {
      await repo.resolveSos(sosId);
      final user = ref.read(currentUserProvider);
      if (user?.collegeId != null) {
        ref.invalidate(activeSosProvider(user!.collegeId));
      }
      if (mounted) {
        SuccessModal.show(
          context: context,
          title: 'SOS Resolved',
          message: 'SOS alert resolved.',
          primaryActionText: 'OK',
        );
      }
    } catch (e) {
      if (mounted) {
        ApiErrorModal.show(
          context: context,
          error: 'Failed to resolve SOS: $e',
        );
      }
    }
  }

  Widget _buildCapsuleTabBar(BuildContext context) {
    final l10n = coord_l10n.CoordinatorLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tabs = [
      {'text': l10n.overview, 'icon': Icons.dashboard},
      {'text': 'Live Map', 'icon': Icons.map},
      {'text': l10n.drivers, 'icon': Icons.approval},
      {'text': l10n.buses, 'icon': Icons.directions_bus},
      {'text': l10n.routes, 'icon': Icons.route},
    ];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final isSelected = _tabController.index == index;
          final icon = tab['icon'] as IconData;
          final text = tab['text'] as String;

          return GestureDetector(
            onTap: () {
              if (_tabController.index != index) {
                setState(() {
                  _previousSubTabIndex = _tabController.index;
                  _tabController.animateTo(index);
                });
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF0097B2), Color(0xFF00C6E6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected
                    ? null
                    : (isDark
                        ? const Color(0xFF23303B)
                        : const Color(0xFFE0F7FA)),
                borderRadius: BorderRadius.circular(30),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00C6E6).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.05)),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : const Color(0xFF004D40)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    text,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : const Color(0xFF004D40)),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Gradient _getAmbientGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final hour = now.hour;
    
    Color color1;
    Color color2;
    
    if (isDark) {
      if (hour >= 6 && hour < 12) {
        color1 = const Color(0xFF0F172A);
        color2 = const Color(0xFF1E1B4B);
      } else if (hour >= 12 && hour < 18) {
        color1 = const Color(0xFF0F172A);
        color2 = const Color(0xFF0F374A);
      } else {
        color1 = const Color(0xFF0B0F19);
        color2 = const Color(0xFF180E29);
      }
      
      if (_bottomNavIndex == 0) {
        if (_tabController.index == 1) {
          color2 = Color.lerp(color2, const Color(0xFF003B46), 0.5) ?? color2;
        } else if (_tabController.index == 2) {
          color2 = Color.lerp(color2, const Color(0xFF2E1A47), 0.5) ?? color2;
        }
      } else if (_bottomNavIndex == 1) {
        color2 = Color.lerp(color2, const Color(0xFF45220A), 0.5) ?? color2;
      } else if (_bottomNavIndex == 2) {
        color2 = Color.lerp(color2, const Color(0xFF064E3B), 0.5) ?? color2;
      }
    } else {
      if (hour >= 6 && hour < 12) {
        color1 = const Color(0xFFF8FAFC);
        color2 = const Color(0xFFECFDF5);
      } else if (hour >= 12 && hour < 18) {
        color1 = const Color(0xFFF8FAFC);
        color2 = const Color(0xFFE0F2FE);
      } else {
        color1 = const Color(0xFFF8FAFC);
        color2 = const Color(0xFFF5F3FF);
      }
      
      if (_bottomNavIndex == 0) {
        if (_tabController.index == 1) {
          color2 = Color.lerp(color2, const Color(0xFFE0F7FA), 0.5) ?? color2;
        } else if (_tabController.index == 2) {
          color2 = Color.lerp(color2, const Color(0xFFF3E5F5), 0.5) ?? color2;
        }
      } else if (_bottomNavIndex == 1) {
        color2 = Color.lerp(color2, const Color(0xFFFFF8E1), 0.5) ?? color2;
      } else if (_bottomNavIndex == 2) {
        color2 = Color.lerp(color2, const Color(0xFFE0F2F1), 0.5) ?? color2;
      }
    }
    
    return LinearGradient(
      colors: [color1, color2],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  Widget _getMainPage(int index) {
    switch (index) {
      case 0:
        return Column(
          children: [
            _buildCapsuleTabBar(context),
            Expanded(
              child: PageTransitionSwitcher(
                duration: const Duration(milliseconds: 300),
                reverse: _tabController.index < _previousSubTabIndex,
                transitionBuilder: (child, animation, secondaryAnimation) {
                  return SharedAxisTransition(
                    animation: animation,
                    secondaryAnimation: secondaryAnimation,
                    transitionType: SharedAxisTransitionType.horizontal,
                    fillColor: Colors.transparent,
                    child: child,
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(_tabController.index),
                  child: _getSubTabPage(_tabController.index),
                ),
              ),
            ),
          ],
        );
      case 1:
        return const NotificationsScreen();
      case 2:
        return const ScheduleManagementScreen();
      case 3:
        return const ProfileScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _getSubTabPage(int index) {
    switch (index) {
      case 0:
        return OverviewTab(
          onSosTap: () {
            setState(() {
              _previousSubTabIndex = _tabController.index;
              _tabController.animateTo(1);
            });
          },
        );
      case 1:
        return LiveMapTab(selectedBus: _selectedBus);
      case 2:
        return DriverManagementTab(
          onTrack: _handleTrackBus,
          onEditDriver: _handleEditDriver,
        );
      case 3:
        return const BusNumbersTab();
      case 4:
        return const RoutesTab();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final collegeId = user?.collegeId;
    final l10n = coord_l10n.CoordinatorLocalizations.of(context)!;
    final isWide = context.isTabletLayout || context.isDesktopLayout;

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

    final mainBody = PageTransitionSwitcher(
      duration: const Duration(milliseconds: 300),
      reverse: _bottomNavIndex < _previousBottomNavIndex,
      transitionBuilder: (child, animation, secondaryAnimation) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.horizontal,
          fillColor: Colors.transparent,
          child: child,
        );
      },
      child: KeyedSubtree(
        key: ValueKey<int>(_bottomNavIndex),
        child: _getMainPage(_bottomNavIndex),
      ),
    );

    final Widget dashboardContent;

    if (isWide) {
      dashboardContent = Scaffold(
        backgroundColor: Colors.transparent,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _bottomNavIndex,
              onDestinationSelected: (index) {
                if (_bottomNavIndex != index) {
                  _stopSosSound(); // Stop sound when switching tabs
                }
                setState(() {
                  _previousBottomNavIndex = _bottomNavIndex;
                  _bottomNavIndex = index;
                });
              },
              labelType: NavigationRailLabelType.all,
              backgroundColor: Theme.of(context).cardColor,
              selectedIconTheme: IconThemeData(color: _getCoordinatorActiveColor(context)),
              selectedLabelTextStyle: TextStyle(
                color: _getCoordinatorActiveColor(context),
                fontWeight: FontWeight.bold,
              ),
              unselectedIconTheme: const IconThemeData(color: Colors.grey),
              unselectedLabelTextStyle: const TextStyle(color: Colors.grey),
              indicatorColor: _getCoordinatorActiveColor(context).withValues(alpha: 0.12),
              destinations: [
                const NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Badge(
                    label: Text(ref.watch(unreadNotificationsCountProvider).toString()),
                    isLabelVisible: ref.watch(unreadNotificationsCountProvider) > 0,
                    child: const Icon(Icons.notifications_none_outlined),
                  ),
                  selectedIcon: Badge(
                    label: Text(ref.watch(unreadNotificationsCountProvider).toString()),
                    isLabelVisible: ref.watch(unreadNotificationsCountProvider) > 0,
                    child: const Icon(Icons.notifications),
                  ),
                  label: const Text('Notifications'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.edit_calendar_outlined),
                  selectedIcon: Icon(Icons.edit_calendar),
                  label: Text('Schedule'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: Text('Profile'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: Scaffold(
                backgroundColor: Colors.transparent,
                appBar: _bottomNavIndex == 0
                    ? AppBar(
                        title: Text(l10n.dashboardTitle),
                        backgroundColor: Colors.transparent,
                        foregroundColor: isDark ? Colors.white : Colors.black,
                        elevation: 0,
                      )
                    : null,
                body: mainBody,
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
              ),
            ),
          ],
        ),
      );
    } else {
      dashboardContent = Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _bottomNavIndex == 0
            ? AppBar(
                title: Text(l10n.dashboardTitle),
                backgroundColor: Colors.transparent,
                foregroundColor: isDark ? Colors.white : Colors.black,
                elevation: 0,
              )
            : null,
        body: Stack(
          children: [
            RepaintBoundary(
              key: _backgroundKey,
              child: ColoredBox(
                // The inner Scaffold is transparent; without this the captured
                // image has alpha=0 pixels which the GPU composites as black.
                color: Theme.of(context).scaffoldBackgroundColor,
                child: mainBody,
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: CurvedBottomNavBar(
                currentIndex: _bottomNavIndex,
                onTap: (index) {
                  if (_bottomNavIndex != index) {
                    _stopSosSound(); // Stop sound when switching tabs
                  }
                  setState(() {
                    _previousBottomNavIndex = _bottomNavIndex;
                    _bottomNavIndex = index;
                  });
                },
                activeColor: _getCoordinatorActiveColor(context),
                backgroundColor: Theme.of(context).cardColor,
                backgroundKey: _backgroundKey,
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        gradient: _getAmbientGradient(context),
      ),
      child: dashboardContent,
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
