import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/features/college_admin/application/college_admin_provider.dart';
import 'package:collegebus/features/college_admin/presentation/widgets/sos_dashboard.dart';
import 'package:collegebus/features/notification/services/fcm_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:collegebus/features/settings/presentation/sos_sound_settings.dart';
import 'dart:async';
import 'package:collegebus/core/constants/constants.dart';

import 'package:collegebus/features/college_admin/presentation/tabs/overview_tab.dart';
import 'package:collegebus/features/college_admin/presentation/tabs/users_tab.dart';
import 'package:collegebus/features/college_admin/presentation/tabs/transactions_tab.dart';
import 'package:collegebus/features/college_admin/presentation/tabs/fleet_tab.dart';
import 'package:collegebus/features/college_admin/presentation/tabs/routes_tab.dart';
import 'package:collegebus/features/college_admin/presentation/tabs/live_tracking_tab.dart';
import 'package:collegebus/features/college_admin/presentation/tabs/audit_tab.dart';
import 'package:collegebus/features/college_admin/presentation/tabs/settings_tab.dart';
import 'package:collegebus/shared/widgets/logout_confirmation_dialog.dart';

class CollegeAdminDashboard extends ConsumerStatefulWidget {
  const CollegeAdminDashboard({super.key});

  @override
  ConsumerState<CollegeAdminDashboard> createState() =>
      _CollegeAdminDashboardState();
}

class _CollegeAdminDashboardState extends ConsumerState<CollegeAdminDashboard> {
  int _currentIndex = 0;
  StreamSubscription? _fcmTapSubscription;

  @override
  void initState() {
    super.initState();
    // Restore/Enable Status Bar
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCollegeData();
    });
    _setupNotificationListeners();
  }

  void _setupNotificationListeners() {
    // Check for initial message that opened the app
    final initialMessage = FCMService().initialMessage;
    if (initialMessage != null && initialMessage.data['type'] == 'SOS') {
      _currentIndex = 6; // Emergency tab (now 6)
      FCMService().consumeInitialMessage();
    }

    _fcmTapSubscription = FCMService().tapStream.listen((message) {
      if (message.data['type'] == 'SOS') {
        setState(() {
          _currentIndex = 6; // Emergency tab (now 6)
        });
      }
    });

  }

  final AudioPlayer _sosAudioPlayer = AudioPlayer();

  Future<void> _playSosSound() async {
    final enabled = await SosSettingsService.isSoundEnabled();
    if (!enabled) return;

    final soundFile = await SosSettingsService.getSoundFile();
    try {
      await _sosAudioPlayer.setReleaseMode(ReleaseMode.loop);
      await _sosAudioPlayer.play(AssetSource('sounds/$soundFile'));
    } catch (e) {
      debugPrint('Error playing SOS sound: $e');
    }
  }

  Future<void> _stopSosSound() async {
    try {
      await _sosAudioPlayer.stop();
    } catch (e) {
      debugPrint('Error stopping SOS sound: $e');
    }
  }

  @override
  void dispose() {
    _fcmTapSubscription?.cancel();
    _sosAudioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadCollegeData() async {
    final user = ref.read(currentUserProvider);
    final collegeId = user?.collegeId ?? '';
    debugPrint(
      'DASHBOARD: Loading data for user=${user?.email}, collegeId=$collegeId',
    );

    if (collegeId.isNotEmpty) {
      final caNotifier = ref.read(collegeAdminServiceProvider.notifier);
      await caNotifier.loadCollegeDashboard(collegeId);
    } else {
      debugPrint('DASHBOARD: Skipping load because collegeId is empty');
    }
  }

  void _onNavigate(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to provider for new SOS alerts from socket
    ref.listen(collegeAdminServiceProvider, (previous, next) {
      final prevCount = previous?.valueOrNull?.activeSos.length ?? 0;
      final nextCount = next.valueOrNull?.activeSos.length ?? 0;

      if (nextCount > prevCount) {
        _playSosSound();
      } else if (nextCount == 0 && prevCount > 0) {
        _stopSosSound();
      }
    });

    final asyncState = ref.watch(collegeAdminServiceProvider);
    final authService = ref.watch(authProvider.notifier);
    final authUser = ref.watch(currentUserProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = context.isTabletLayout || context.isDesktopLayout;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF12181F) : const Color(0xFFF5F7FA),
      appBar: isWide
          ? null
          : AppBar(
              title: Text(_getTabTitle(_currentIndex), style: const TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => _loadCollegeData(),
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    final confirmed = await LogoutConfirmationDialog.show(context);
                    if (confirmed) {
                      await authService.signOut();
                    }
                  },
                ),
              ],
            ),
      drawer: isWide
          ? null
          : Drawer(
              width: 290,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
              ),
              child: _buildSidebarContent(context, authUser, asyncState.valueOrNull, true),
            ),
      body: asyncState.when(
        data: (state) {
          final tabContent = _buildCurrentTab(state, authUser?.collegeId ?? '');

          if (isWide) {
            return Row(
              children: [
                // Persistent Side Panel
                SizedBox(
                  width: 280,
                  child: _buildSidebarContent(context, authUser, state, false),
                ),
                Container(
                  width: 1.5,
                  height: double.infinity,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                ),
                // Tab Pane Area
                Expanded(
                  child: Scaffold(
                    backgroundColor: Colors.transparent,
                    appBar: AppBar(
                      title: Text(
                        _getTabTitle(_currentIndex),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: Colors.transparent,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      elevation: 0,
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () => _loadCollegeData(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout),
                          onPressed: () async {
                            final confirmed = await LogoutConfirmationDialog.show(context);
                            if (confirmed) {
                              await authService.signOut();
                            }
                          },
                        ),
                      ],
                    ),
                    body: tabContent,
                  ),
                ),
              ],
            );
          }

          return tabContent;
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, st) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildCurrentTab(
    dynamic state,
    String collegeId,
  ) {
    switch (_currentIndex) {
      case 0:
        return OverviewTab(onNavigate: _onNavigate);
      case 1:
        return const UsersTab();
      case 2:
        return const FleetTab();
      case 3:
        return const LiveTrackingTab();
      case 4:
        return const RoutesTab();
      case 5:
        return const TransactionsTab();
      case 6:
        return const SosDashboard();
      case 7:
        return const AuditTab();
      case 8:
        return const SettingsTab();
      default:
        return const Center(child: Text('Tab under construction'));
    }
  }


  String _getTabTitle(int index) {
    switch (index) {
      case 0:
        return 'Overview';
      case 1:
        return 'Users';
      case 2:
        return 'Fleet';
      case 3:
        return 'Live Tracking';
      case 4:
        return 'Routes';
      case 5:
        return 'Transactions';
      case 6:
        return 'Emergency Alerts';
      case 7:
        return 'Audit Logs';
      case 8:
        return 'Settings';
      default:
        return 'College Admin';
    }
  }

  Widget _buildSidebarContent(BuildContext context, dynamic user, dynamic state, bool isDrawer) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final destinations = [
      {
        'icon': Icons.dashboard_outlined,
        'selectedIcon': Icons.dashboard,
        'label': 'Overview',
        'isDanger': false
      },
      {
        'icon': Icons.people_outlined,
        'selectedIcon': Icons.people,
        'label': 'Users',
        'isDanger': false
      },
      {
        'icon': Icons.directions_bus_outlined,
        'selectedIcon': Icons.directions_bus,
        'label': 'Fleet',
        'isDanger': false
      },
      {
        'icon': Icons.map_outlined,
        'selectedIcon': Icons.map,
        'label': 'Live Tracking',
        'isDanger': false
      },
      {
        'icon': Icons.route_outlined,
        'selectedIcon': Icons.route,
        'label': 'Routes',
        'isDanger': false
      },
      {
        'icon': Icons.receipt_long_outlined,
        'selectedIcon': Icons.receipt_long,
        'label': 'Transactions',
        'isDanger': false
      },
      {
        'icon': Icons.emergency_outlined,
        'selectedIcon': Icons.emergency,
        'label': 'Emergency',
        'isDanger': false
      },
      {
        'icon': Icons.list_alt_rounded,
        'selectedIcon': Icons.list_alt_rounded,
        'label': 'Audit',
        'isDanger': false
      },
      {
        'icon': Icons.settings_outlined,
        'selectedIcon': Icons.settings,
        'label': 'Settings',
        'isDanger': false
      },
    ];

    return Container(
      color: isDark ? const Color(0xFF161F28) : Colors.white,
      child: Column(
        children: [
          // Header Cover
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              bottom: 24,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF004D5A), const Color(0xFF002228)]
                    : [const Color(0xFF0097B2), const Color(0xFF00C6E6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(isDrawer ? 32 : 0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0097B2).withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white12,
                        child: Icon(
                          Icons.school_rounded,
                          size: 26,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'College Admin',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? 'admin@college.com',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    state.college?.name.toUpperCase() ?? "COLLEGE ADMIN ACCESS",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Destinations
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: destinations.length,
              itemBuilder: (context, index) {
                final dest = destinations[index];
                return _buildSidebarTileForDest(context, index, dest);
              },
            ),
          ),
          
          // Logout Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _SidebarTile(
              icon: Icons.logout_rounded,
              selectedIcon: Icons.logout_rounded,
              label: 'Logout System',
              isSelected: false,
              isDanger: true,
              onTap: () async {
                if (isDrawer) Navigator.pop(context);
                
                final confirmed = await LogoutConfirmationDialog.show(context);
                if (confirmed) {
                  await ref.read(authProvider.notifier).signOut();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarTileForDest(BuildContext context, int index, Map<String, dynamic> dest) {
    final isDanger = dest['isDanger'] as bool;
    final isSelected = _currentIndex == index;
    
    return _SidebarTile(
      icon: dest['icon'] as IconData,
      selectedIcon: dest['selectedIcon'] as IconData,
      label: dest['label'] as String,
      isSelected: isSelected,
      isDanger: isDanger,
      onTap: () {
        setState(() => _currentIndex = index);
        if (Scaffold.of(context).isDrawerOpen) {
          Navigator.pop(context);
        }
      },
    );
  }
}

class _SidebarTile extends StatefulWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDanger;

  const _SidebarTile({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  State<_SidebarTile> createState() => _SidebarTileState();
}

class _SidebarTileState extends State<_SidebarTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.04,
    )..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _scale = 1.0 - _controller.value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color activeColor = widget.isDanger ? Colors.red : const Color(0xFF0097B2);
    final Color inactiveColor = isDark ? Colors.white60 : Colors.black54;

    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
        HapticFeedback.selectionClick();
      },
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: Transform.scale(
        scale: _scale,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? activeColor.withValues(alpha: isDark ? 0.12 : 0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected
                  ? activeColor.withValues(alpha: isDark ? 0.2 : 0.12)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Selection Indicator Bar
              if (widget.isSelected)
                Positioned(
                  left: 0,
                  top: 12,
                  bottom: 12,
                  width: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ListTile(
                contentPadding: const EdgeInsets.only(left: 20, right: 16),
                leading: Icon(
                  widget.isSelected ? widget.selectedIcon : widget.icon,
                  color: widget.isSelected ? activeColor : inactiveColor,
                  size: 22,
                ),
                title: Text(
                  widget.label,
                  style: TextStyle(
                    fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.normal,
                    color: widget.isSelected ? activeColor : inactiveColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

