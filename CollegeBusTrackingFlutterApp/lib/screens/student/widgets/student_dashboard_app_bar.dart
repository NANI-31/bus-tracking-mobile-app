import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:collegebus/models/user_model.dart';
import 'package:collegebus/utils/constants.dart';
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
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      actions: [
        // Actions moved to Sidebar (AppDrawer)
      ],
      bottom: TabBar(
        controller: tabController,
        labelColor: AppColors.onPrimary,
        unselectedLabelColor: AppColors.onPrimary.withValues(alpha: 0.7),
        indicatorColor: AppColors.onPrimary,
        tabs: const [
          Tab(text: 'Track Buses', icon: Icon(Icons.map)),
          Tab(text: 'Bus List', icon: Icon(Icons.list)),
          Tab(text: 'Bus Info', icon: Icon(Icons.info)),
        ],
      ),
    );
  }

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight + kTextTabBarHeight);
}
