import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/models/user_model.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/widgets/success_modal.dart';

class AppDrawer extends StatelessWidget {
  final UserModel? user;
  final AuthService authService;

  const AppDrawer({super.key, required this.user, required this.authService});

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.toString();
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor:
          theme.drawerTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: VStack([
        // 1. Custom Header
        VStack([
              HStack([
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white,
                  child: (user?.fullName ?? 'U')[0]
                      .toUpperCase()
                      .text
                      .size(32)
                      .bold
                      .color(AppColors.primary)
                      .make(),
                ),
                const Spacer(),
                if (user?.role != null)
                  user!.role.displayName
                      .toUpperCase()
                      .text
                      .color(Colors.white)
                      .size(10)
                      .bold
                      .letterSpacing(1.2)
                      .make()
                      .pSymmetric(h: 12, v: 6)
                      .box
                      .color(Colors.white.withAlpha(50))
                      .rounded
                      .border(color: Colors.white.withAlpha(100))
                      .make(),
              ]),
              20.heightBox,
              (user?.fullName ?? 'Guest').text
                  .color(Colors.white)
                  .size(22)
                  .bold
                  .letterSpacing(0.5)
                  .maxLines(1)
                  .ellipsis
                  .make(),
              4.heightBox,
              (user?.email ?? '').text
                  .color(Colors.white.withAlpha(200))
                  .size(14)
                  .maxLines(1)
                  .ellipsis
                  .make(),
            ])
            .pLTRB(24, 64, 24, 24)
            .box
            .linearGradient(
              [AppColors.primary, AppColors.primary.withAlpha(200)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
            .make(),

        // 2. Navigation Items
        VStack([
          _buildDrawerItem(
            context: context,
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            title: 'Home',
            isSelected: _isRouteActive(
              currentRoute,
              '/student/home',
              exact: true,
            ),
            onTap: () => _navigateTo(context, currentRoute, '/student/home'),
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            title: 'Dashboard',
            isSelected: _isRouteActive(currentRoute, '/student', exact: true),
            onTap: () => _navigateTo(context, currentRoute, '/student'),
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.notifications_outlined,
            activeIcon: Icons.notifications,
            title: 'Notifications',
            isSelected: _isRouteActive(currentRoute, '/notifications'),
            onTap: () => _navigateTo(context, currentRoute, '/notifications'),
          ),

          // Role Specific Logic
          if (user?.role == UserRole.student || user?.role == UserRole.parent)
            _buildDrawerItem(
              context: context,
              icon: Icons.calendar_month_outlined,
              activeIcon: Icons.calendar_month,
              title: 'Bus Schedule',
              isSelected: _isRouteActive(currentRoute, '/student/schedule'),
              onTap: () =>
                  _navigateTo(context, currentRoute, '/student/schedule'),
            ),

          if (user?.role == UserRole.busCoordinator)
            _buildDrawerItem(
              context: context,
              icon: Icons.edit_calendar_outlined,
              activeIcon: Icons.edit_calendar,
              title: 'Manage Schedule',
              isSelected: _isRouteActive(currentRoute, '/coordinator/schedule'),
              onTap: () =>
                  _navigateTo(context, currentRoute, '/coordinator/schedule'),
            ),

          // Profile Section (For everyone)
          _buildDrawerItem(
            context: context,
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            title: 'Profile',
            isSelected: _isRouteActive(currentRoute, '/student/profile'),
            onTap: () => _navigateTo(context, currentRoute, '/student/profile'),
          ),
        ]).pSymmetric(v: 16, h: 12).scrollVertical().expand(),

        // 3. Footer (Logout)
        _buildDrawerItem(
              context: context,
              icon: Icons.logout_rounded,
              activeIcon: Icons.logout_rounded,
              title: 'Logout',
              isSelected: false,
              isDestructive: true,
              onTap: () async {
                // Show Logout Dialog for 2 seconds
                // We do NOT pop the drawer here to ensure context remains valid
                await SuccessModal.show(
                  context: context,
                  title: 'Logging Out',
                  message: 'Securely signing you out...',
                  icon: Icons.logout_rounded,
                  autoCloseDurationSeconds: 2,
                );

                await authService.signOut();

                if (context.mounted) {
                  context.go('/login');
                }
              },
            )
            .safeArea()
            .p16()
            .box
            .withDecoration(
              BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.withAlpha(20), width: 1),
                ),
              ),
            )
            .make(),
      ]),
    );
  }

  bool _isRouteActive(String current, String target, {bool exact = false}) {
    if (target == '/') return current == '/';
    if (exact) return current == target;
    return current == target || current.startsWith('$target/');
  }

  void _navigateTo(BuildContext context, String current, String target) {
    Navigator.pop(context); // Close drawer first
    if (current != target) {
      if (target == _getHomeRoute(user?.role)) {
        context.go(target);
      } else {
        context.push(target);
      }
    }
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final color = isDestructive
        ? AppColors.error
        : (isSelected
              ? theme.primaryColor
              : theme.textTheme.bodyLarge?.color ?? AppColors.textPrimary);

    final backgroundColor = isDestructive
        ? AppColors.error.withAlpha(20)
        : (isSelected ? theme.primaryColor.withAlpha(25) : Colors.transparent);

    return ListTile(
          leading: Icon(isSelected ? activeIcon : icon, color: color, size: 24),
          title: title.text
              .color(color)
              .fontWeight(isSelected ? FontWeight.w600 : FontWeight.w500)
              .size(14)
              .make(),
          dense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          onTap: onTap,
        ).box
        .color(backgroundColor)
        .withRounded(value: 28)
        .margin(const EdgeInsets.only(bottom: 4))
        .make();
  }

  String _getHomeRoute(UserRole? role) {
    if (role == UserRole.student || role == UserRole.parent) {
      return '/student';
    } else if (role == UserRole.busCoordinator) {
      return '/coordinator';
    } else if (role == UserRole.driver) {
      return '/driver';
    } else if (role == UserRole.teacher) {
      return '/teacher';
    } else if (role == UserRole.admin) {
      return '/admin';
    }
    return '/login';
  }
}
