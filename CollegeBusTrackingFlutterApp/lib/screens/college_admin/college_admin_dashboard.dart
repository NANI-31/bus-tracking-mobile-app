import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:collegebus/services/auth/auth_service.dart';
import 'package:collegebus/services/admin/college_admin_service.dart';
import 'package:collegebus/screens/college_admin/widgets/live_fleet_map.dart';
import 'package:collegebus/screens/college_admin/widgets/sos_dashboard.dart';
import 'package:collegebus/services/notification/fcm_service.dart';
import 'dart:async';

// New Tab Imports
import 'package:collegebus/screens/college_admin/tabs/overview_tab.dart';
import 'package:collegebus/screens/college_admin/tabs/users_tab.dart';
import 'package:collegebus/screens/college_admin/tabs/settings_tab.dart';

class CollegeAdminDashboard extends StatefulWidget {
  const CollegeAdminDashboard({super.key});

  @override
  State<CollegeAdminDashboard> createState() => _CollegeAdminDashboardState();
}

class _CollegeAdminDashboardState extends State<CollegeAdminDashboard> {
  int _currentIndex = 0;
  StreamSubscription? _fcmTapSubscription;

  @override
  void initState() {
    super.initState();
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
    final authService = Provider.of<AuthService>(context, listen: false);
    final collegeAdminService = Provider.of<CollegeAdminService>(
      context,
      listen: false,
    );
    final collegeId = authService.currentUserModel?.collegeId ?? '';

    if (collegeId.isNotEmpty) {
      await collegeAdminService.loadCollegeDashboard(collegeId);
    }
  }

  void _onNavigate(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final collegeAdminService = Provider.of<CollegeAdminService>(context);
    final authService = Provider.of<AuthService>(context);
    final isLoading = collegeAdminService.isLoading;
    final authUser = authService.currentUserModel;

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
              await authService.signOut();
              if (context.mounted) {
                context.go('/login');
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
