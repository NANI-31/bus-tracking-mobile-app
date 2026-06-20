import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/features/super_admin/application/super_admin_provider.dart';
import 'package:collegebus/core/constants/constants.dart';

// New Tab Imports
import 'package:collegebus/features/super_admin/presentation/tabs/system_overview_tab.dart';
import 'package:collegebus/features/super_admin/presentation/tabs/colleges_tab.dart';
import 'package:collegebus/features/super_admin/presentation/tabs/global_users_tab.dart';
import 'package:collegebus/features/super_admin/presentation/tabs/audit_tab.dart';

import 'package:collegebus/features/super_admin/presentation/tabs/system_analysis_tab.dart';
import 'package:collegebus/features/super_admin/presentation/tabs/sos_logs_tab.dart';
import 'package:collegebus/features/super_admin/presentation/tabs/safety_monitor_tab.dart';
import 'package:collegebus/features/super_admin/presentation/tabs/payments_tab.dart';
import 'package:collegebus/features/super_admin/presentation/tabs/danger_zone_tab.dart';
import 'package:collegebus/features/super_admin/presentation/tabs/live_tracking_tab.dart';
import 'package:collegebus/shared/widgets/logout_confirmation_dialog.dart';

class SuperAdminDashboard extends ConsumerStatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  ConsumerState<SuperAdminDashboard> createState() =>
      _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends ConsumerState<SuperAdminDashboard> {
  int _selectedDrawerIndex = 0;

  @override
  void initState() {
    super.initState();
    // Restore/Enable Status Bar
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSystemData();
    });
  }

  Future<void> _loadSystemData() async {
    final saNotifier = ref.read(superAdminServiceProvider.notifier);
    await saNotifier.loadSystemDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(authProvider.notifier);
    final user = ref.watch(currentUserProvider);
    final asyncState = ref.watch(superAdminServiceProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = context.isTabletLayout || context.isDesktopLayout;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF12181F) : const Color(0xFFF5F7FA),
      appBar: isWide
          ? null
          : AppBar(
              title: const Text('Super Admin', style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ref.read(superAdminServiceProvider.notifier).loadSystemDashboard(),
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
              child: _buildSidebarContent(context, user, true),
            ),
      body: asyncState.when(
        data: (state) {
          final allColleges = state.colleges;
          final allUsers = state.globalUsers;
          
          final totalColleges = allColleges.length;
          final verifiedColleges = allColleges.where((c) => c.verified).length;
          final pendingColleges = allColleges.where((c) => !c.verified).length;
          final totalUsers = allUsers.length;

          final tabContent = _buildCurrentTab(
            totalColleges,
            verifiedColleges,
            pendingColleges,
            totalUsers,
            state,
          );

          if (isWide) {
            return Row(
              children: [
                // Persistent Side Panel
                SizedBox(
                  width: 280,
                  child: _buildSidebarContent(context, user, false),
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
                        _getTabTitle(_selectedDrawerIndex),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: Colors.transparent,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      elevation: 0,
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () => ref.read(superAdminServiceProvider.notifier).loadSystemDashboard(),
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

  Widget _buildSidebarContent(BuildContext context, dynamic user, bool isDrawer) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final destinations = [
      {
        'icon': Icons.dashboard_outlined,
        'selectedIcon': Icons.dashboard,
        'label': 'System Overview',
        'isDanger': false
      },
      {
        'icon': Icons.school_outlined,
        'selectedIcon': Icons.school,
        'label': 'Colleges',
        'isDanger': false
      },
      {
        'icon': Icons.people_outlined,
        'selectedIcon': Icons.people,
        'label': 'Global Users',
        'isDanger': false
      },

      {
        'icon': Icons.history_outlined,
        'selectedIcon': Icons.history,
        'label': 'Audit Logs',
        'isDanger': false
      },
      {
        'icon': Icons.analytics_outlined,
        'selectedIcon': Icons.analytics,
        'label': 'System Analysis',
        'isDanger': false
      },
      {
        'icon': Icons.emergency_outlined,
        'selectedIcon': Icons.emergency,
        'label': 'SOS Logs',
        'isDanger': false
      },
      {
        'icon': Icons.credit_card_outlined,
        'selectedIcon': Icons.credit_card,
        'label': 'Payments',
        'isDanger': false
      },
      {
        'icon': Icons.monitor_heart_outlined,
        'selectedIcon': Icons.monitor_heart,
        'label': 'Safety Monitor',
        'isDanger': false
      },
      {
        'icon': Icons.map_outlined,
        'selectedIcon': Icons.map,
        'label': 'Live Tracking',
        'isDanger': false
      },
      {
        'icon': Icons.warning_amber_outlined,
        'selectedIcon': Icons.warning_amber,
        'label': 'Danger Zone',
        'isDanger': true
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
                    ? [const Color(0xFF3B0764), const Color(0xFF1A0B2E)]
                    : [Colors.deepPurple.shade800, Colors.purple.shade600],
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
                            color: Colors.deepPurple.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white12,
                        child: Icon(
                          Icons.admin_panel_settings_rounded,
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
                            user?.fullName ?? 'Super Admin',
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
                            user?.email ?? 'admin@system.com',
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
                  child: const Text(
                    "SYSTEM ROOT ACCESS",
                    style: TextStyle(
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
                final isDanger = dest['isDanger'] as bool;
                
                if (isDanger && index > 0 && !(destinations[index - 1]['isDanger'] as bool)) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Divider(
                          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
                          height: 1,
                        ),
                      ),
                      _buildSidebarTileForDest(context, index, dest),
                    ],
                  );
                }
                
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
    final isSelected = _selectedDrawerIndex == index;
    
    return _SidebarTile(
      icon: dest['icon'] as IconData,
      selectedIcon: dest['selectedIcon'] as IconData,
      label: dest['label'] as String,
      isSelected: isSelected,
      isDanger: isDanger,
      onTap: () {
        setState(() => _selectedDrawerIndex = index);
        if (Scaffold.of(context).isDrawerOpen) {
          Navigator.pop(context);
        }
      },
    );
  }

  String _getTabTitle(int index) {
    switch (index) {
      case 0:
        return 'System Overview';
      case 1:
        return 'Colleges';
      case 2:
        return 'Global Users';
      case 3:
        return 'Audit Logs';
      case 4:
        return 'System Analysis';
      case 5:
        return 'SOS Logs';
      case 6:
        return 'Payments';
      case 7:
        return 'Safety Monitor';
      case 8:
        return 'Live Fleet Tracking';
      case 9:
        return 'Danger Zone';
      default:
        return 'Super Admin';
    }
  }

  Widget _buildCurrentTab(
    int totalColleges,
    int verifiedColleges,
    int pendingColleges,
    int totalUsers,
    dynamic state,
  ) {
    switch (_selectedDrawerIndex) {
      case 0:
        return SystemOverviewTab(
          totalColleges: totalColleges,
          verifiedColleges: verifiedColleges,
          totalUsers: totalUsers,
          pendingColleges: pendingColleges,
          allUsers: state.globalUsers,
          auditLogs: state.auditLogs,
          onNavigate: (index) => setState(() => _selectedDrawerIndex = index),
          onVerifyColleges: () => setState(() {
            _selectedDrawerIndex = 1;
          }),
        );
      case 1:
        return const CollegesTab();
      case 2:
        return const GlobalUsersTab();
      case 3:
        return const AuditTab();
      case 4:
        return const SystemAnalysisTab();
      case 5:
        return SosLogsTab(
          sosLogs: state.sosLogs,
          colleges: state.colleges,
        );
      case 6:
        return const PaymentsTab();
      case 7:
        return SafetyMonitorTab(colleges: state.colleges);
      case 8:
        return const LiveTrackingTab();
      case 9:
        return const DangerZoneTab();
      default:
        return const Center(child: Text('Tab under construction'));
    }
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

    final Color activeColor = widget.isDanger ? Colors.red : Colors.deepPurple;
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
