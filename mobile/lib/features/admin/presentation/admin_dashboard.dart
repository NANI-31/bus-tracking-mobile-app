import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/shared/widgets/logout_confirmation_dialog.dart';
import 'package:collegebus/shared/widgets/logout_loading_dialog.dart';

// New Modules
import 'modules/admin_overview_tab.dart';
import 'modules/admin_colleges_tab.dart';
import 'modules/admin_users_tab.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Restore/Enable Status Bar
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Granular selection: only rebuild when name changes
    final adminName = ref.watch(
      currentUserProvider.select((u) => u?.fullName ?? 'Admin'),
    );
    final authService = ref.read(authProvider.notifier);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: 'Admin Panel - $adminName'.text.make(),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: context.colorScheme.onPrimary,
          unselectedLabelColor: context.colorScheme.onPrimary.withValues(
            alpha: 0.7,
          ),
          indicatorColor: context.colorScheme.onPrimary,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Colleges', icon: Icon(Icons.school)),
            Tab(text: 'Users', icon: Icon(Icons.people)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AdminOverviewTab(),
          AdminCollegesTab(),
          AdminUsersTab(),
        ],
      ),
    );
  }
}
