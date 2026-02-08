import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/features/admin/application/admin_provider.dart';
import 'package:collegebus/features/college_admin/services/college_admin_service.dart';
import 'package:collegebus/features/college_admin/presentation/widgets/live_fleet_map.dart';
import 'package:collegebus/features/college_admin/presentation/widgets/sos_dashboard.dart';
import 'package:collegebus/features/notification/services/fcm_service.dart';
import 'dart:async';

// New Tab Imports
import 'package:collegebus/features/college_admin/presentation/tabs/overview_tab.dart';
import 'package:collegebus/features/college_admin/presentation/tabs/users_tab.dart';
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
      _currentIndex = 3;
      FCMService().consumeInitialMessage();
    }

    _fcmTapSubscription = FCMService().tapStream.listen((message) {
      if (message.data['type'] == 'SOS') {
        setState(() {
          _currentIndex = 3; // Emergency tab
        });
      }
    });
  }

  @override
  void dispose() {
    _fcmTapSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadCollegeData() async {
    final user = ref.read(currentUserProvider);
    final collegeId = user?.collegeId ?? '';
    debugPrint(
      'DASHBOARD: Loading data for user=${user?.email}, collegeId=$collegeId',
    );

    if (collegeId.isNotEmpty) {
      final collegeAdminService = ref.read(collegeAdminServiceProvider);
      await collegeAdminService.loadCollegeDashboard(collegeId);
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
    final collegeAdminService = ref.watch(collegeAdminServiceProvider);
    final authService = ref.watch(authProvider.notifier);
    final isLoading = collegeAdminService.isLoading;
    final authUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('College Admin'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
                if (context.mounted) {
                  context.go('/login');
                }
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildCurrentTab(collegeAdminService, authUser?.collegeId ?? ''),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          const NavigationDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('${collegeAdminService.activeSos.length}'),
              isLabelVisible: collegeAdminService.activeSos.isNotEmpty,
              child: const Icon(Icons.emergency_outlined),
            ),
            selectedIcon: const Icon(Icons.emergency),
            label: 'Emergency',
          ),
          const NavigationDestination(
            icon: Icon(Icons.directions_bus_outlined),
            selectedIcon: Icon(Icons.directions_bus),
            label: 'Fleet',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTab(
    CollegeAdminService collegeAdminService,
    String collegeId,
  ) {
    switch (_currentIndex) {
      case 0:
        return OverviewTab(onNavigate: _onNavigate);
      case 1:
        return const UsersTab();
      case 2:
        return const SosDashboard();
      case 3:
        return LiveFleetMap(
          buses: collegeAdminService.collegeBuses,
          collegeId: collegeId,
        );
      case 4:
        return const SettingsTab();
      default:
        return const Center(child: Text('Tab under construction'));
    }
  }
}
