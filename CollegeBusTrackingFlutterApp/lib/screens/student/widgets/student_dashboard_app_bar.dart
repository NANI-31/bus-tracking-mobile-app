import 'package:flutter/material.dart';
import 'package:collegebus/models/user_model.dart';
import 'package:collegebus/services/auth_service.dart';

class StudentDashboardAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final UserModel? user;
  final TabController tabController;
  final AuthService authService;

  const StudentDashboardAppBar({
    super.key,
    required this.user,
    required this.tabController,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      actions: [
        // Actions moved to Sidebar (AppDrawer)
      ],
      bottom: TabBar(
        controller: tabController,
        labelColor: Theme.of(context).colorScheme.onPrimary,
        unselectedLabelColor: Theme.of(
          context,
        ).colorScheme.onPrimary.withValues(alpha: 0.7),
        indicatorColor: Theme.of(context).colorScheme.onPrimary,
        tabs: const [
          Tab(text: 'Track', icon: Icon(Icons.map)),
          Tab(text: 'Route', icon: Icon(Icons.show_chart)),
          Tab(text: 'Info', icon: Icon(Icons.info_outline)),
        ],
      ),
    );
  }

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight + kTextTabBarHeight);
}
