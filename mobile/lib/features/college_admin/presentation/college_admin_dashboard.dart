import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/features/college_admin/application/college_admin_provider.dart';
import 'package:collegebus/features/college_admin/presentation/widgets/live_fleet_map.dart';
import 'package:collegebus/features/college_admin/presentation/widgets/sos_dashboard.dart';
import 'package:collegebus/features/notification/services/fcm_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:collegebus/features/settings/presentation/sos_sound_settings.dart';
import 'dart:async';

// New Tab Imports
import 'package:collegebus/features/college_admin/presentation/tabs/overview_tab.dart';
import 'package:collegebus/features/college_admin/presentation/tabs/users_tab.dart';
import 'package:collegebus/features/college_admin/presentation/tabs/transactions_tab.dart';
import 'package:collegebus/features/college_admin/presentation/tabs/settings_tab.dart';
import 'package:collegebus/shared/widgets/logout_confirmation_dialog.dart';
import 'package:collegebus/shared/widgets/logout_loading_dialog.dart';
import 'package:collegebus/shared/widgets/navigation/curved_bottom_nav_bar.dart';

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
      _currentIndex = 3; // Emergency tab (now 3)
      FCMService().consumeInitialMessage();
    }

    _fcmTapSubscription = FCMService().tapStream.listen((message) {
      if (message.data['type'] == 'SOS') {
        setState(() {
          _currentIndex = 3; // Emergency tab (now 3)
        });
      }
    });

    // Listen to provider for new SOS alerts from socket
    ref.listen(collegeAdminServiceProvider, (previous, next) {
      final prevCount = previous?.valueOrNull?.activeSos.length ?? 0;
      final nextCount = next.valueOrNull?.activeSos.length ?? 0;

      if (nextCount > prevCount) {
        // New alert
        _playSosSound();
        // If we are not already on Emergency tab, maybe show a snackbar or navigate?
        // User requested sound, and dashboard usually handles visual via badge/tab.
      } else if (nextCount == 0 && prevCount > 0) {
        // All resolved
        _stopSosSound();
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
    final asyncState = ref.watch(collegeAdminServiceProvider);
    final authService = ref.watch(authProvider.notifier);
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
      body: asyncState.when(
        data: (state) => _buildCurrentTab(state, authUser?.collegeId ?? ''),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, st) => Center(child: Text('Error: $error')),
      ),
      bottomNavigationBar: CurvedBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        activeColor: _getCollegeAdminActiveColor(context),
        backgroundColor: Theme.of(context).cardColor,
        items: [
          const CurvedBottomNavItem(
            icon: Icons.dashboard_outlined,
            label: 'Overview',
          ),
          const CurvedBottomNavItem(
            icon: Icons.people_outlined,
            label: 'Users',
          ),
          const CurvedBottomNavItem(
            icon: Icons.receipt_long_outlined,
            label: 'Transactions',
          ),
          CurvedBottomNavItem(
            icon: Icons.emergency_outlined,
            label: 'Emergency',
            badgeCount: asyncState.valueOrNull?.activeSos.length ?? 0,
          ),
          const CurvedBottomNavItem(
            icon: Icons.directions_bus_outlined,
            label: 'Fleet',
          ),
          const CurvedBottomNavItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
          ),
        ],
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
        return const TransactionsTab();
      case 3:
        return const SosDashboard();
      case 4:
        return LiveFleetMap(
          buses: state.collegeBuses,
          collegeId: collegeId,
        );
      case 5:
        return const SettingsTab();
      default:
        return const Center(child: Text('Tab under construction'));
    }
  }

  Color _getCollegeAdminActiveColor(BuildContext context) {
    switch (_currentIndex) {
      case 0:
        return Theme.of(context).primaryColor;
      case 1:
        return Colors.blue.shade600;
      case 2:
        return Colors.green.shade600;
      case 3:
        return Colors.red.shade600;
      case 4:
        return Colors.orange.shade600;
      case 5:
        return Colors.grey.shade600;
      default:
        return Theme.of(context).primaryColor;
    }
  }
}
