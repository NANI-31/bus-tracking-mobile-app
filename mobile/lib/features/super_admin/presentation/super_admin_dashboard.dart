import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/features/super_admin/application/super_admin_provider.dart';
// New Tab Imports
import 'package:collegebus/features/super_admin/presentation/tabs/system_overview_tab.dart';
import 'package:collegebus/features/super_admin/presentation/tabs/colleges_tab.dart';
import 'package:collegebus/features/super_admin/presentation/tabs/global_users_tab.dart';
import 'package:collegebus/features/super_admin/presentation/tabs/configuration_tab.dart';
import 'package:collegebus/features/super_admin/presentation/tabs/audit_tab.dart';
import 'package:collegebus/features/super_admin/presentation/tabs/sos_logs_tab.dart';
import 'package:collegebus/features/super_admin/presentation/tabs/safety_monitor_tab.dart';
import 'package:collegebus/features/super_admin/presentation/tabs/transactions_tab.dart';
import 'package:collegebus/features/super_admin/presentation/tabs/danger_zone_tab.dart';
import 'package:collegebus/shared/widgets/logout_confirmation_dialog.dart';
import 'package:collegebus/shared/widgets/logout_loading_dialog.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(superAdminServiceProvider.notifier).loadSystemDashboard(),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('System alerts coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirmed = await LogoutConfirmationDialog.show(context);
              if (confirmed) {
                if (context.mounted) {
                  LogoutLoadingDialog.show(context);
                }
                await authService.signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              }
            },
          ),
        ],
      ),
      drawer: NavigationDrawer(
        selectedIndex: _selectedDrawerIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedDrawerIndex = index);
          Navigator.pop(context);
        },
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white24,
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
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
                Text(
                  user?.email ?? 'admin@system.com',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: Text('System Overview'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: Text('Colleges'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people),
            label: Text('Global Users'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: Text('Configuration'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: Text('Audit Logs'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.emergency_outlined),
            selectedIcon: Icon(Icons.emergency),
            label: Text('SOS Logs'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.monitor_heart_outlined),
            selectedIcon: Icon(Icons.monitor_heart),
            label: Text('Safety Monitor'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: Text('Transactions'),
          ),
          const Divider(),
          const NavigationDrawerDestination(
            icon: Icon(Icons.warning_amber_outlined),
            selectedIcon: Icon(Icons.warning_amber),
            label: Text('Danger Zone'),
          ),
        ],
      ),
      body: asyncState.when(
        data: (state) {
          final allColleges = state.colleges;
          final allUsers = state.globalUsers;
          
          final totalColleges = allColleges.length;
          final verifiedColleges = allColleges.where((c) => c.verified).length;
          final pendingColleges = allColleges.where((c) => !c.verified).length;
          final totalUsers = allUsers.length;

          return _buildCurrentTab(
            totalColleges,
            verifiedColleges,
            pendingColleges,
            totalUsers,
            state,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, st) => Center(child: Text('Error: $error')),
      ),
    );
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
            // Note: Auto-filter to verify not passed here,
            // state is now local to CollegesTab.
          }),
        );
      case 1:
        return const CollegesTab();
      case 2:
        return const GlobalUsersTab();
      case 3:
        return const ConfigurationTab();
      case 4:
        return AuditTab(auditLogs: state.auditLogs);
      case 5:
        return SosLogsTab(
          sosLogs: state.sosLogs,
          colleges: state.colleges,
        );
      case 6:
        return const TransactionsTab();
      case 7:
        return SafetyMonitorTab(colleges: state.colleges);
      case 8:
        return const DangerZoneTab();
      default:
        return const Center(child: Text('Tab under construction'));
    }
  }
}
