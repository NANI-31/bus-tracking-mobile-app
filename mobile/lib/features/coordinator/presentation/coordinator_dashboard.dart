import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velocity_x/velocity_x.dart';

import 'package:collegebus/core/utils/app_logger.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/core/providers/socket_provider.dart';
import 'package:collegebus/features/sos/application/sos_provider.dart';
import 'package:collegebus/core/providers/repository_providers.dart';
import 'package:collegebus/core/providers/service_providers.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/features/bus/application/bus_provider.dart';
import 'package:collegebus/features/user/domain/user_model.dart';
import 'package:collegebus/features/user/application/user_provider.dart';
import 'package:collegebus/features/sos/domain/sos_model.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:go_router/go_router.dart';
import 'package:collegebus/features/notification/presentation/screens/notifications_screen.dart';
import 'package:collegebus/features/notification/services/notification_service.dart';


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
import 'package:collegebus/core/utils/map_marker_helper.dart';

class CoordinatorDashboard extends ConsumerStatefulWidget {
  const CoordinatorDashboard({super.key});

  @override
  ConsumerState<CoordinatorDashboard> createState() =>
      _CoordinatorDashboardState();
}

class _CoordinatorDashboardState extends ConsumerState<CoordinatorDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  int _bottomNavIndex = 0;
  BusModel? _selectedBus;

  // Cached sub-tab widgets — never recreated after initState.
  // Creating them inside build() or _getSubTabPage() caused full remount
  // on every build triggered by the TabController animation listener.
  late final List<Widget> _subTabPages;

  // Tracks which bottom-nav pages have been mounted at least once.
  // Unvisited pages render SizedBox.shrink() to avoid mounting
  // GoogleMaps / socket streams that are not yet needed.
  final Set<int> _visitedBottomNavPages = {0};

  final Set<String> _resolvedMockIds = {};

  void _resolveMockAlert(String sosId) {
    setState(() {
      _resolvedMockIds.add(sosId);
    });
  }

  /// Key for the [RepaintBoundary] that wraps the mobile content body.
  /// Passed to [CurvedBottomNavBar] so the liquid-glass lens shader can
  /// sample the real pixels rendered behind the navigation bar.
  final GlobalKey _backgroundKey = GlobalKey();
  StreamSubscription? _fcmTapSubscription;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
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

    // Build sub-tab widgets once and cache them.
    // Previously _getSubTabPage() was called inside build() which caused
    // fresh widget instances on every rebuild → full remount on every tab change.
    _initSubTabs();

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
      _prefetchAssets();
      _setupSosListener();
    });
  }

  StreamSubscription? _sosAlertSubscription;

  /// Build all sub-tab widgets once so they are stable across rebuilds.
  /// Calling setState on the TabController listener previously caused all
  /// 5 tabs to be recreated (new widget instances = full remount = jank).
  void _initSubTabs() {
    _subTabPages = [
      OverviewTab(
        onSosTap: () => setState(() => _tabController.animateTo(1)),
        onActiveBusesTap: () => setState(() => _tabController.animateTo(1)),
      ),
      LiveMapTab(selectedBus: _selectedBus),
      DriverManagementTab(
        onTrack: _handleTrackBus,
        onEditDriver: _handleEditDriver,
      ),
      const BusNumbersTab(),
      const RoutesTab(),
    ];
  }

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
    // Delegate to the centralized permission service so all roles use
    // a single permission flow — avoids regression when new roles are added.
    await ref.read(appPermissionsServiceProvider).requestBasicPermissions();
  }

  Future<void> _prefetchAssets() async {
    // 1. Prefetch map custom marker icons to memory cache
    try {
      await MapMarkerHelper.createBusMarker();
      await MapMarkerHelper.getStartMarker(color: const Color(0xFF4CAF50));
      await MapMarkerHelper.getStopMarker(color: const Color(0xFFFF9800));
      await MapMarkerHelper.getEndMarker(color: const Color(0xFFE53935));
      debugPrint('[CoordinatorDashboard] Map markers prefetched successfully.');
    } catch (e) {
      debugPrint('[CoordinatorDashboard] Error prefetching map markers: $e');
    }

    // 2. Precache background assets — check mounted after every await since
    //    this is an async method and the widget may have been disposed.
    if (!mounted) return;
    try {
      await precacheImage(const AssetImage('assets/images/login.png'), context);
      if (!mounted) return;
      await precacheImage(
        const AssetImage('assets/images/registration.png'),
        context,
      );
      if (!mounted) return;
      await precacheImage(
        const AssetImage('assets/images/upashtit-logo-new.png'),
        context,
      );
      debugPrint(
        '[CoordinatorDashboard] Background images precached successfully.',
      );
    } catch (e) {
      debugPrint(
        '[CoordinatorDashboard] Error precaching background images: $e',
      );
    }
  }

  void _handleTrackBus(BusModel bus) {
    setState(() {
      _selectedBus = bus;
      if (_bottomNavIndex != 0) {
        _stopSosSound();
      }
      _bottomNavIndex = 0;
      _tabController.animateTo(1);
      // Update the cached LiveMapTab with the new selected bus.
      _subTabPages[1] = LiveMapTab(selectedBus: _selectedBus);
    });
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
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
    _scrollController.dispose();
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

    final usersList = ref.read(userListProvider).value ?? [];
    final driver = usersList.firstWhere(
      (u) => u.id == sos.userId,
      orElse: () => UserModel(
        id: sos.userId,
        fullName: 'Active Bus Driver',
        email: '',
        role: UserRole.driver,
        collegeId: sos.collegeId,
        createdAt: DateTime.now(),
      ),
    );

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'SOS Alert',
      barrierColor: Colors.black.withValues(alpha: 0.75),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (ctx, anim1, anim2) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      isDark
                          ? const Color(0xFF3A0A0A).withValues(alpha: 0.85)
                          : const Color(0xFF901A1A).withValues(alpha: 0.95),
                      isDark
                          ? const Color(0xFF1F0303).withValues(alpha: 0.95)
                          : const Color(0xFF5F0C0C).withValues(alpha: 0.95),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.35),
                      blurRadius: 30,
                      spreadRadius: 5,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Hero(
                            tag: 'sos-marker-${sos.busId}',
                            child: const AnimatedSosBeacon(),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'CRITICAL ALERT',
                                  style: TextStyle(
                                    color: Colors.redAccent.shade100,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                                const Text(
                                  'EMERGENCY SOS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'A driver has triggered an active distress signal. Immediate intervention is required.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSosInfoCard(
                        icon: Icons.person_rounded,
                        label: 'Driver',
                        value: driver.fullName,
                        trailing:
                            driver.phoneNumber != null &&
                                driver.phoneNumber!.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 18),
                                color: Colors.white.withValues(alpha: 0.6),
                                tooltip: 'Copy Phone Number',
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: driver.phoneNumber!),
                                  );
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Phone number copied to clipboard!',
                                      ),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _buildSosInfoCard(
                        icon: Icons.directions_bus_rounded,
                        label: 'Bus Details',
                        value: 'Bus ${sos.busNumber}',
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.redAccent.withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Text(
                            'SOS ACTIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSosInfoCard(
                        icon: Icons.access_time_filled_rounded,
                        label: 'Time Triggered',
                        value: DateFormat(
                          'hh:mm:ss a',
                        ).format(sos.timestamp.toLocal()),
                      ),
                      const SizedBox(height: 12),
                      _buildSosInfoCard(
                        icon: Icons.location_on_rounded,
                        label: 'Coordinates',
                        value:
                            '${sos.latitude.toStringAsFixed(6)}, ${sos.longitude.toStringAsFixed(6)}',
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.content_copy_rounded,
                            size: 18,
                          ),
                          color: Colors.white.withValues(alpha: 0.6),
                          tooltip: 'Copy Coordinates',
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(
                                text: '${sos.latitude}, ${sos.longitude}',
                              ),
                            );
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Coordinates copied to clipboard!',
                                ),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 28),
                      ElevatedButton.icon(
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
                        icon: const Icon(Icons.map_rounded),
                        label: const Text(
                          'TRACK BUS ON MAP',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFB71C1C),
                          elevation: 4,
                          shadowColor: Colors.redAccent.withValues(alpha: 0.4),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _stopSosSound();
                                Navigator.pop(ctx);
                                _resolveSos(sos.sosId);
                              },
                              icon: const Icon(Icons.check_circle_rounded),
                              label: const Text(
                                'RESOLVE',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B5E20),
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shadowColor: Colors.greenAccent.withValues(
                                  alpha: 0.2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: () {
                              _stopSosSound();
                              Navigator.pop(ctx);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white.withValues(
                                alpha: 0.8,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                            ),
                            child: const Text(
                              'DISMISS',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curve = CurvedAnimation(
          parent: anim1,
          curve: const Cubic(0.34, 1.56, 0.64, 1.0),
        );
        return Transform.scale(
          scale: curve.value,
          child: Opacity(opacity: anim1.value, child: child),
        );
      },
    );
  }

  Widget _buildSosInfoCard({
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.redAccent.shade100, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  void _showActiveSosList() {
    if (!mounted) return;

    final user = ref.read(currentUserProvider);
    final collegeId = user?.collegeId;
    if (collegeId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SosListSheetContent(
        collegeId: collegeId,
        onTrack: _handleTrackBus,
        onResolve: _resolveSos,
        onShowAlert: _showSOSAlert,
        resolvedMockIds: _resolvedMockIds,
        onResolveMock: _resolveMockAlert,
      ),
    );
  }

  Future<void> _resolveSos(String sosId) async {
    if (sosId.startsWith('MOCK-SOS-')) {
      _resolveMockAlert(sosId);
      return;
    }
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

  Widget _buildCapsuleTabBar(BuildContext context, {bool isCompact = false}) {
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
      height: isCompact ? 66 : 80,
      padding: EdgeInsets.symmetric(vertical: isCompact ? 4 : 6),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: List.generate(tabs.length, (index) {
              final isSelected = _tabController.index == index;

              return _TabItem(
                index: index,
                tab: tabs[index],
                isSelected: isSelected,
                isDark: isDark,
                isCompact: isCompact,
                onTap: () {
                  if (_tabController.index != index) {
                    setState(() {
                      _tabController.animateTo(index);
                    });
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        0.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                      );
                    }
                  }
                },
              );
            }),
          ),
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (index) {
      case 0:
        return Column(
          children: [
            // P0 fix: BackdropFilter here ran on every animation frame during
            // tab switches — 60 expensive GPU blur readback passes per second.
            // Replaced with a solid semi-opaque container (visually equivalent).
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.45)
                    : Colors.white.withValues(alpha: 0.75),
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                        : const Color(0xFF0097B2).withValues(alpha: 0.10),
                    width: 1.5,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isDark ? 0.30 : 0.08,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _buildCapsuleTabBar(context, isCompact: false),
            ),
            Expanded(
              // P0 fix: TabTransitionView ran AnimatedBuilder on EVERY tab-controller
              // animation frame, building a Stack with all 5 heavyweight tabs + Opacity
              // transitions. Replaced with a lazy IndexedStack:
              // - Only the active tab is painted (GPU)
              // - Unvisited tabs are SizedBox.shrink() until first visit
              // - Once visited, tabs stay mounted (state preserved, no flash)
              child: _LazyCoordSubTabStack(
                controller: _tabController,
                pages: _subTabPages,
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final collegeId = user?.collegeId;
    final isWide = context.isTabletLayout || context.isDesktopLayout;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Headerless Status Bar Icon Color Sync
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
    );

    // We only need activeSosAlerts list for the FAB at dashboard level
    final realActiveSosAlerts = collegeId != null
        ? ref.watch(activeSosProvider(collegeId)).value ?? []
        : <SosModel>[];

    final activeSosAlerts = realActiveSosAlerts
        .where((s) => !_resolvedMockIds.contains(s.sosId))
        .toList();

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

    // P0 fix: SpatialTabTransition used Opacity + Transform.scale for the
    // bottom-nav page switch — Opacity with non-0/1 values forces a GPU
    // save-layer. Combined with the inner tab animation this doubled GPU load.
    // Replaced with a lazy IndexedStack: instant switch, state preserved.
    final mainBody = _LazyCoordBottomNavStack(
      currentIndex: _bottomNavIndex,
      visitedPages: _visitedBottomNavPages,
      pageBuilder: _getMainPage,
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
                  _bottomNavIndex = index;
                  _visitedBottomNavPages.add(index);
                });
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    0.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                  );
                }
              },
              labelType: NavigationRailLabelType.all,
              backgroundColor: Theme.of(context).cardColor,
              selectedIconTheme: IconThemeData(
                color: _getCoordinatorActiveColor(context),
              ),
              selectedLabelTextStyle: TextStyle(
                color: _getCoordinatorActiveColor(context),
                fontWeight: FontWeight.bold,
              ),
              unselectedIconTheme: const IconThemeData(color: Colors.grey),
              unselectedLabelTextStyle: const TextStyle(color: Colors.grey),
              indicatorColor: _getCoordinatorActiveColor(
                context,
              ).withValues(alpha: 0.12),
              destinations: [
                const NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Badge(
                    label: Text(
                      ref.watch(unreadNotificationsCountProvider).toString(),
                    ),
                    isLabelVisible:
                        ref.watch(unreadNotificationsCountProvider) > 0,
                    child: const Icon(Icons.notifications_none_outlined),
                  ),
                  selectedIcon: Badge(
                    label: Text(
                      ref.watch(unreadNotificationsCountProvider).toString(),
                    ),
                    isLabelVisible:
                        ref.watch(unreadNotificationsCountProvider) > 0,
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
                appBar: null,
                body: SafeArea(
                  top: _bottomNavIndex == 0,
                  bottom: false,
                  child: mainBody,
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
              ),
            ),
          ],
        ),
      );
    } else {
      dashboardContent = Scaffold(
        backgroundColor: Colors.transparent,
        appBar: null,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            RepaintBoundary(
              key: _backgroundKey,
              child: ColoredBox(
                // The inner Scaffold is transparent; without this the captured
                // image has alpha=0 pixels which the GPU composites as black.
                color: Theme.of(context).scaffoldBackgroundColor,
                child: SafeArea(
                  top: _bottomNavIndex == 0,
                  bottom: false,
                  child: mainBody,
                ),
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
                    _bottomNavIndex = index;
                    _visitedBottomNavPages.add(index);
                  });
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      0.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                    );
                  }
                },
                activeColor: _getCoordinatorActiveColor(context),
                activeColors: [
                  const Color(0xFF00C6E6), // Turkish Blue / Turquoise
                  Colors.amber.shade700,
                  Colors.teal.shade600,
                  Colors.indigo.shade600,
                ],
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

    // P2 fix: AnimatedContainer animates the background gradient on every
    // tab switch — smooth gradient on a full-screen container every frame.
    // Replaced with a plain Container. The gradient still updates correctly
    // on tab changes, just without the interpolation overhead.
    return Container(
      decoration: BoxDecoration(gradient: _getAmbientGradient(context)),
      child: dashboardContent,
    );
  }

  Color _getCoordinatorActiveColor(BuildContext context) {
    switch (_bottomNavIndex) {
      case 0:
        return const Color(0xFF00C6E6); // Turkish Blue / Turquoise
      case 1:
        return Colors.amber.shade700;
      case 2:
        return Colors.teal.shade600;
      case 3:
        return Colors.indigo.shade600;
      default:
        return const Color(0xFF00C6E6);
    }
  }
}

class CapsuleTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget Function(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  )
  builder;
  final double maxHeight;
  final double minHeight;
  final int selectedIndex;

  CapsuleTabBarDelegate({
    required this.builder,
    required this.maxHeight,
    required this.minHeight,
    required this.selectedIndex,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(
      child: builder(context, shrinkOffset, overlapsContent),
    );
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(covariant CapsuleTabBarDelegate oldDelegate) {
    return oldDelegate.maxHeight != maxHeight ||
        oldDelegate.minHeight != minHeight ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dynamic Sub Tab Item & HSL Interpolation
// ─────────────────────────────────────────────────────────────────────────────

Color interpolateColorHSL(Color colorA, Color colorB, double t) {
  final hslA = HSLColor.fromColor(colorA);
  final hslB = HSLColor.fromColor(colorB);

  double hA = hslA.hue;
  double hB = hslB.hue;
  if ((hB - hA).abs() > 180.0) {
    if (hB > hA) {
      hA += 360.0;
    } else {
      hB += 360.0;
    }
  }
  double h = hA + (hB - hA) * t;
  if (h > 360.0) h -= 360.0;
  if (h < 0.0) h += 360.0;

  final s = hslA.saturation + (hslB.saturation - hslA.saturation) * t;
  final l = hslA.lightness + (hslB.lightness - hslA.lightness) * t;
  final alpha = hslA.alpha + (hslB.alpha - hslA.alpha) * t;
  return HSLColor.fromAHSL(
    alpha.clamp(0.0, 1.0),
    h.clamp(0.0, 360.0),
    s.clamp(0.0, 1.0),
    l.clamp(0.0, 1.0),
  ).toColor();
}

class _TabItem extends StatefulWidget {
  final int index;
  final Map<String, dynamic> tab;
  final bool isSelected;
  final bool isDark;
  final bool isCompact;
  final VoidCallback onTap;

  const _TabItem({
    required this.index,
    required this.tab,
    required this.isSelected,
    required this.isDark,
    required this.isCompact,
    required this.onTap,
  });

  @override
  State<_TabItem> createState() => _TabItemState();
}

class _TabItemState extends State<_TabItem> with TickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _pressScaleAnimation;
  late AnimationController _splatterController;
  late AnimationController _selectController;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _pressScaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );

    _splatterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _selectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    if (widget.isSelected) {
      _splatterController.value = 1.0;
      _selectController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_TabItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _splatterController.forward(from: 0.0);
    }
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _selectController.forward();
      } else {
        _selectController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    _splatterController.dispose();
    _selectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = widget.tab['icon'] as IconData;
    final text = widget.tab['text'] as String;

    final inactiveBgColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.03);

    const activeColorStart = Color(0xFF0097B2);
    const activeColorEnd = Color(0xFF00C6E6);

    final borderActiveColor = const Color(0xFF00E5FF).withValues(alpha: 0.5);
    final borderInactiveColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.06);

    final contentActiveColor = Colors.white;
    final contentInactiveColor = widget.isDark
        ? Colors.white70
        : const Color(0xFF004D40);

    return Expanded(
      child: GestureDetector(
        onTapDown: (_) {
          _pressController.forward();
          HapticFeedback.selectionClick();
        },
        onTapUp: (_) {
          _pressController.reverse();
        },
        onTapCancel: () {
          _pressController.reverse();
        },
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([_selectController, _pressScaleAnimation]),
          builder: (context, child) {
            final selectedRatio = _selectController.value;
            final double baseScale = 0.96 + 0.08 * selectedRatio;

            final startColor = interpolateColorHSL(
              inactiveBgColor,
              activeColorStart,
              selectedRatio,
            );
            final endColor = interpolateColorHSL(
              inactiveBgColor,
              activeColorEnd,
              selectedRatio,
            );

            final borderColor = interpolateColorHSL(
              borderInactiveColor,
              borderActiveColor,
              selectedRatio,
            );

            final contentColor = interpolateColorHSL(
              contentInactiveColor,
              contentActiveColor,
              selectedRatio,
            );

            return Transform.scale(
              scale: baseScale * _pressScaleAnimation.value,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: EdgeInsets.symmetric(
                  horizontal: widget.isCompact ? 2 : 4,
                  vertical: widget.isCompact ? 6 : 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [startColor, endColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: selectedRatio > 0.01
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF00C6E6,
                            ).withValues(alpha: 0.35 * selectedRatio),
                            blurRadius: 10,
                            spreadRadius: -2,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                  border: Border.all(color: borderColor, width: 1.2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _splatterController,
                          builder: (context, child) {
                            return CustomPaint(
                              size: const Size(32, 32),
                              painter: SplatterPainter(
                                progress: _splatterController.value,
                                color: const Color(0xFF00E5FF),
                              ),
                            );
                          },
                        ),
                        Icon(
                          icon,
                          size: 15 + 3 * selectedRatio,
                          color: contentColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: selectedRatio > 0.5
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: contentColor,
                        fontSize: 9.5,
                        letterSpacing: 0.2 * selectedRatio,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Splatter Painter, Shader and Transition Overlay
// ─────────────────────────────────────────────────────────────────────────────

class SplatterPainter extends CustomPainter {
  final double progress;
  final Color color;

  SplatterPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1.0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.45;

    final centralPaint = Paint()
      ..color = color.withValues(
        alpha: (0.45 * (1.0 - progress)).clamp(0.0, 1.0),
      )
      ..style = PaintingStyle.fill;

    final path = Path();
    final int points = 8;
    for (int i = 0; i < points; i++) {
      final angle = (i * 2 * math.pi) / points;
      final wiggle =
          math.sin(angle * 3 + progress * math.pi) * 3.0 * (1.0 - progress);
      final currentRadius = (baseRadius * progress * 0.9) + wiggle;
      final x = center.dx + math.cos(angle) * currentRadius;
      final y = center.dy + math.sin(angle) * currentRadius;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, centralPaint);

    final particlePaint = Paint()
      ..color = color.withValues(
        alpha: (0.65 * (1.0 - progress)).clamp(0.0, 1.0),
      )
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 6; i++) {
      final angle = (i * 2 * math.pi) / 6 + 0.2;
      final distance = baseRadius * 0.6 + (baseRadius * 0.9 * progress);
      final particleCenter = Offset(
        center.dx + math.cos(angle) * distance,
        center.dy + math.sin(angle) * distance,
      );
      final particleRadius = 2.5 * (1.0 - progress);
      if (particleRadius > 0.1) {
        canvas.drawCircle(particleCenter, particleRadius, particlePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SplatterPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class RedShimmerSkeleton extends StatefulWidget {
  const RedShimmerSkeleton({super.key});

  @override
  State<RedShimmerSkeleton> createState() => _RedShimmerSkeletonState();
}

class _RedShimmerSkeletonState extends State<RedShimmerSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _opacityAnim = Tween<double>(
      begin: 0.35,
      end: 0.75,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacityAnim,
      builder: (context, child) {
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: 3,
          separatorBuilder: (ctx, i) => const SizedBox(height: 12),
          itemBuilder: (ctx, index) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(
                  0xFF2A0808,
                ).withValues(alpha: _opacityAnim.value),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.shade900.withValues(
                    alpha: _opacityAnim.value + 0.1,
                  ),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 100,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.red.shade900.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        width: 60,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.red.shade900.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.red.shade900.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.red.shade900.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SosListSheetContent extends StatefulWidget {
  final String collegeId;
  final Function(BusModel) onTrack;
  final Function(String) onResolve;
  final Function(SosModel) onShowAlert;
  final Set<String> resolvedMockIds;
  final Function(String) onResolveMock;

  const _SosListSheetContent({
    required this.collegeId,
    required this.onTrack,
    required this.onResolve,
    required this.onShowAlert,
    required this.resolvedMockIds,
    required this.onResolveMock,
  });

  @override
  State<_SosListSheetContent> createState() => _SosListSheetContentState();
}

class _SosListSheetContentState extends State<_SosListSheetContent> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer(
      builder: (context, ref, _) {
        final realActiveSosAsync = ref.watch(
          activeSosProvider(widget.collegeId),
        );
        final activeSosAlerts = (realActiveSosAsync.valueOrNull ?? <SosModel>[])
            .where((s) => !widget.resolvedMockIds.contains(s.sosId))
            .toList();

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    isDark
                        ? const Color(0xFF241212).withValues(alpha: 0.92)
                        : const Color(0xFFFFF3F3).withValues(alpha: 0.92),
                    isDark
                        ? const Color(0xFF140505).withValues(alpha: 0.96)
                        : const Color(0xFFFEE8E8).withValues(alpha: 0.96),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                border: Border.all(
                  color: Colors.redAccent.withValues(
                    alpha: isDark ? 0.2 : 0.35,
                  ),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.15),
                    blurRadius: 25,
                    spreadRadius: 2,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drag handle
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),

                  // Header Section
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'ACTIVE SOS ALERTS',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF901A1A),
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD32F2F),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.redAccent.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Text(
                                _isLoading
                                    ? '...'
                                    : '${activeSosAlerts.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onShowAlert(
                              SosModel(
                                sosId: 'MOCK-SOS-999',
                                collegeId: widget.collegeId,
                                userId: 'driver_mock_id',
                                userRole: 'DRIVER',
                                busId: 'bus_mock_id',
                                busNumber: '108-A',
                                routeId: 'route_mock_id',
                                latitude: 16.2345,
                                longitude: 80.4567,
                                timestamp: DateTime.now().subtract(
                                  const Duration(minutes: 5),
                                ),
                                status: SosStatus.active,
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.add_alert_rounded,
                            size: 16,
                            color: Colors.redAccent,
                          ),
                          label: const Text(
                            'TEST MOCK',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.redAccent.withValues(
                              alpha: 0.08,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Divider
                  Container(
                    height: 1,
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.08,
                    ),
                  ),

                  // Content Area
                  Expanded(
                    child: _isLoading
                        ? const RedShimmerSkeleton()
                        : realActiveSosAsync.when(
                            data: (realList) {
                              if (activeSosAlerts.isEmpty) {
                                return const EmptySosListIllustration();
                              }
                              return ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: activeSosAlerts.length,
                                separatorBuilder: (ctx, i) =>
                                    const SizedBox(height: 14),
                                itemBuilder: (ctx, index) {
                                  final sos = activeSosAlerts[index];
                                  final usersList =
                                      ref.read(userListProvider).value ?? [];
                                  final driver = usersList.firstWhere(
                                    (u) => u.id == sos.userId,
                                    orElse: () => UserModel(
                                      id: sos.userId,
                                      fullName: 'Active Bus Driver',
                                      email: '',
                                      role: UserRole.driver,
                                      collegeId: sos.collegeId,
                                      createdAt: DateTime.now(),
                                    ),
                                  );

                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          isDark
                                              ? const Color(
                                                  0xFF381515,
                                                ).withValues(alpha: 0.3)
                                              : const Color(
                                                  0xFFFFEEEE,
                                                ).withValues(alpha: 0.5),
                                          isDark
                                              ? const Color(
                                                  0xFF281010,
                                                ).withValues(alpha: 0.5)
                                              : const Color(
                                                  0xFFFFFAFA,
                                                ).withValues(alpha: 0.6),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: Colors.redAccent.withValues(
                                          alpha: 0.2,
                                        ),
                                        width: 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.03,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Hero(
                                              tag: 'sos-marker-${sos.busId}',
                                              child: Container(
                                                width: 42,
                                                height: 42,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.red.shade900,
                                                      Colors.redAccent.shade400,
                                                    ],
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.redAccent
                                                          .withValues(
                                                            alpha: 0.3,
                                                          ),
                                                      blurRadius: 8,
                                                      offset: const Offset(
                                                        0,
                                                        2,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: const Center(
                                                  child: Icon(
                                                    Icons
                                                        .report_problem_rounded,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    driver.fullName,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15,
                                                      color: isDark
                                                          ? Colors.white
                                                          : Colors.black87,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors
                                                              .redAccent
                                                              .withValues(
                                                                alpha: 0.15,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          'Bus ${sos.busNumber}',
                                                          style: TextStyle(
                                                            color: isDark
                                                                ? Colors
                                                                      .redAccent
                                                                      .shade100
                                                                : const Color(
                                                                    0xFFB71C1C,
                                                                  ),
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        '•  Active Emergency',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: Colors
                                                              .redAccent
                                                              .shade200,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  DateFormat('hh:mm a').format(
                                                    sos.timestamp.toLocal(),
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        (isDark
                                                                ? Colors.white
                                                                : Colors.black)
                                                            .withValues(
                                                              alpha: 0.6,
                                                            ),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Triggered',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color:
                                                        (isDark
                                                                ? Colors.white
                                                                : Colors.black)
                                                            .withValues(
                                                              alpha: 0.4,
                                                            ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                icon: const Icon(
                                                  Icons.map_rounded,
                                                  size: 16,
                                                ),
                                                label: const Text(
                                                  'TRACK BUS',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: isDark
                                                      ? Colors.white.withValues(
                                                          alpha: 0.08,
                                                        )
                                                      : Colors.white,
                                                  foregroundColor: const Color(
                                                    0xFFB71C1C,
                                                  ),
                                                  elevation: 0,
                                                  side: BorderSide(
                                                    color: Colors.redAccent
                                                        .withValues(alpha: 0.2),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 12,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                ),
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  widget.onTrack(
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
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                icon: const Icon(
                                                  Icons.check_circle_rounded,
                                                  size: 16,
                                                ),
                                                label: const Text(
                                                  'RESOLVE',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(
                                                    0xFF2E7D32,
                                                  ),
                                                  foregroundColor: Colors.white,
                                                  elevation: 2,
                                                  shadowColor: Colors
                                                      .greenAccent
                                                      .withValues(alpha: 0.2),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 12,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                ),
                                                onPressed: () {
                                                  if (sos.sosId.startsWith(
                                                    'MOCK-SOS-',
                                                  )) {
                                                    setState(() {
                                                      widget.onResolveMock(
                                                        sos.sosId,
                                                      );
                                                    });
                                                    SuccessModal.show(
                                                      context: context,
                                                      title: 'SOS Resolved',
                                                      message:
                                                          'Mock SOS alert resolved.',
                                                      primaryActionText: 'OK',
                                                    );
                                                  } else {
                                                    Navigator.pop(context);
                                                    widget.onResolve(sos.sosId);
                                                  }
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            loading: () => const RedShimmerSkeleton(),
                            error: (e, st) => Center(
                              child: Text(
                                'Error loading alerts: $e',
                                style: const TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rich Status Empty SOS Radar Illustration & Painter
// ─────────────────────────────────────────────────────────────────────────────

class EmptySosListIllustration extends StatefulWidget {
  const EmptySosListIllustration({super.key});

  @override
  State<EmptySosListIllustration> createState() =>
      _EmptySosListIllustrationState();
}

class _EmptySosListIllustrationState extends State<EmptySosListIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(200, 200),
                painter: SweepingRadarPainter(
                  animationValue: _controller.value,
                  isDark: isDark,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          'All Clear & Secure'.text.bold.xl2.center
              .color(isDark ? Colors.white : Colors.red.shade900)
              .make(),
          const SizedBox(height: 8),
          'Sweeping for SOS distress signals...'.text.medium.center
              .color(isDark ? Colors.white60 : Colors.black54)
              .make(),
          const SizedBox(height: 4),
          'No emergency alerts currently active.'.text
              .size(12)
              .center
              .color(isDark ? Colors.white38 : Colors.black38)
              .make(),
        ],
      ),
    );
  }
}

class SweepingRadarPainter extends CustomPainter {
  final double animationValue;
  final bool isDark;

  SweepingRadarPainter({required this.animationValue, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2 - 10;

    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF1E0808) : const Color(0xFFFFF1F2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, maxRadius, bgPaint);

    final borderPaint = Paint()
      ..color = Colors.red.shade900.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, maxRadius, borderPaint);

    final gridPaint = Paint()
      ..color = Colors.red.shade900.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, maxRadius * 0.75, gridPaint);
    canvas.drawCircle(center, maxRadius * 0.50, gridPaint);
    canvas.drawCircle(center, maxRadius * 0.25, gridPaint);

    canvas.drawLine(
      Offset(center.dx - maxRadius, center.dy),
      Offset(center.dx + maxRadius, center.dy),
      gridPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - maxRadius),
      Offset(center.dx, center.dy + maxRadius),
      gridPaint,
    );

    final double sweepAngle = animationValue * 2 * math.pi;
    final sweepLinePaint = Paint()
      ..color = Colors.red.shade500
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final endPoint = Offset(
      center.dx + math.cos(sweepAngle) * maxRadius,
      center.dy + math.sin(sweepAngle) * maxRadius,
    );
    canvas.drawLine(center, endPoint, sweepLinePaint);

    final sweepRect = Rect.fromCircle(center: center, radius: maxRadius);
    final sweepGradientPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.red.shade500.withValues(alpha: 0.4),
          Colors.red.shade500.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.25],
        transform: GradientRotation(sweepAngle - 0.25 * 2 * math.pi),
      ).createShader(sweepRect)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, maxRadius, sweepGradientPaint);

    final dots = [
      Offset(
        center.dx + maxRadius * 0.45 * math.cos(0.5),
        center.dy + maxRadius * 0.45 * math.sin(0.5),
      ),
      Offset(
        center.dx + maxRadius * 0.65 * math.cos(2.2),
        center.dy + maxRadius * 0.65 * math.sin(2.2),
      ),
      Offset(
        center.dx + maxRadius * 0.35 * math.cos(4.5),
        center.dy + maxRadius * 0.35 * math.sin(4.5),
      ),
    ];
    final dotAngles = [0.5, 2.2, 4.5];

    for (int i = 0; i < dots.length; i++) {
      double diff = (sweepAngle - dotAngles[i]) % (2 * math.pi);
      double dotOpacity = 0.0;
      if (diff < math.pi / 2) {
        dotOpacity = 1.0 - (diff / (math.pi / 2));
      }

      if (dotOpacity > 0.01) {
        final dotPaint = Paint()
          ..color = Colors.green.withValues(alpha: dotOpacity * 0.9)
          ..style = PaintingStyle.fill;
        final glowPaint = Paint()
          ..color = Colors.green.withValues(alpha: dotOpacity * 0.3)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

        canvas.drawCircle(dots[i], 6, glowPaint);
        canvas.drawCircle(dots[i], 4, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SweepingRadarPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isDark != isDark;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lazy IndexedStack for coordinator sub-tabs (replaces TabTransitionView).
// Only the active tab is in the render tree. Tabs are mounted on first visit
// and remain mounted thereafter to preserve state (map, scroll positions).
// ─────────────────────────────────────────────────────────────────────────────

class _LazyCoordSubTabStack extends StatefulWidget {
  final TabController controller;
  final List<Widget> pages;

  const _LazyCoordSubTabStack({
    required this.controller,
    required this.pages,
  });

  @override
  State<_LazyCoordSubTabStack> createState() => _LazyCoordSubTabStackState();
}

class _LazyCoordSubTabStackState extends State<_LazyCoordSubTabStack> {
  late int _currentIndex;
  final Set<int> _visited = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.controller.index;
    _visited.add(_currentIndex);
    widget.controller.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    final newIndex = widget.controller.index;
    if (newIndex != _currentIndex) {
      setState(() {
        _currentIndex = newIndex;
        _visited.add(_currentIndex);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _currentIndex,
      children: List.generate(widget.pages.length, (i) {
        if (!_visited.contains(i)) return const SizedBox.shrink();
        return widget.pages[i];
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lazy IndexedStack for coordinator bottom nav pages (replaces SpatialTabTransition).
// Mounts each page only on first visit to avoid loading Google Maps + socket
// streams for pages the user hasn't opened yet.
// ─────────────────────────────────────────────────────────────────────────────

class _LazyCoordBottomNavStack extends StatelessWidget {
  final int currentIndex;
  final Set<int> visitedPages;
  final Widget Function(int) pageBuilder;

  const _LazyCoordBottomNavStack({
    required this.currentIndex,
    required this.visitedPages,
    required this.pageBuilder,
  });

  @override
  Widget build(BuildContext context) {
    // 4 bottom nav pages: Dashboard(0), Notifications(1), Schedule(2), Profile(3)
    return IndexedStack(
      index: currentIndex,
      children: List.generate(4, (i) {
        if (!visitedPages.contains(i)) return const SizedBox.shrink();
        return pageBuilder(i);
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Spatial Page Route Transition system with custom Cubic curves
// ─────────────────────────────────────────────────────────────────────────────

class SpatialTabTransition extends StatefulWidget {
  final Widget child;
  final int currentIndex;
  final Duration duration;

  const SpatialTabTransition({
    super.key,
    required this.child,
    required this.currentIndex,
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  State<SpatialTabTransition> createState() => _SpatialTabTransitionState();
}

class _SpatialTabTransitionState extends State<SpatialTabTransition>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  Widget? _oldChild;
  int _oldIndex = 0;
  bool _isReversed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _oldIndex = widget.currentIndex;
  }

  @override
  void didUpdateWidget(SpatialTabTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _oldIndex = oldWidget.currentIndex;
      _oldChild = oldWidget.child;
      _isReversed = widget.currentIndex < _oldIndex;
      _controller.reset();
      _controller.forward().then((_) {
        if (mounted) {
          setState(() {
            _oldChild = null;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;
        if (value == 0.0 && _oldChild == null) {
          return widget.child;
        }

        final exitCurve = const Cubic(0.4, 0.0, 0.2, 1.0).transform(value);
        final enterCurve = const Cubic(0.34, 1.35, 0.64, 1.0).transform(value);

        final List<Widget> stackChildren = [];

        if (_oldChild != null) {
          final slideDirection = _isReversed ? 1.0 : -1.0;
          final double slideX =
              slideDirection * exitCurve * MediaQuery.of(context).size.width;
          final double slideY = math.sin(exitCurve * math.pi) * 25.0;
          final double scale = 1.0 - (exitCurve * 0.12);
          final double opacity = (1.0 - exitCurve).clamp(0.0, 1.0);

          stackChildren.add(
            Transform.translate(
              offset: Offset(slideX, slideY),
              child: Transform.scale(
                scale: scale,
                child: Opacity(opacity: opacity, child: _oldChild),
              ),
            ),
          );
        }

        final slideDirection = _isReversed ? -1.0 : 1.0;
        final double slideX =
            slideDirection *
            (1.0 - enterCurve) *
            MediaQuery.of(context).size.width;
        final double slideY = math.sin((1.0 - enterCurve) * math.pi) * 25.0;
        final double scale = 0.88 + (enterCurve * 0.12);
        final double opacity = enterCurve.clamp(0.0, 1.0);

        stackChildren.add(
          Transform.translate(
            offset: Offset(slideX, slideY),
            child: Transform.scale(
              scale: scale,
              child: Opacity(opacity: opacity, child: widget.child),
            ),
          ),
        );

        return Stack(children: stackChildren);
      },
    );
  }
}

class AnimatedSosBeacon extends StatefulWidget {
  const AnimatedSosBeacon({super.key});

  @override
  State<AnimatedSosBeacon> createState() => _AnimatedSosBeaconState();
}

class _AnimatedSosBeaconState extends State<AnimatedSosBeacon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer ripple 2
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.redAccent.withValues(
                  alpha: (1.0 - _controller.value) * 0.15,
                ),
              ),
            ),
            // Outer ripple 1
            Transform.scale(
              scale: 0.5 + (_controller.value * 0.5),
              child: Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.redAccent.withValues(
                    alpha: (1.0 - _controller.value) * 0.3,
                  ),
                ),
              ),
            ),
            // Glowing center ring
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.shade900,
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withValues(alpha: 0.6),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        );
      },
    );
  }
}
