import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
      child: Column(
        children: [
          // 1. Custom Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withAlpha(200)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white,
                      child: Text(
                        (user?.fullName ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (user?.role != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(50),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withAlpha(100),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          user!.role.displayName.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  user?.fullName ?? 'Guest',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    color: Colors.white.withAlpha(200),
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // 2. Navigation Items
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard,
                    title: 'Dashboard',
                    isSelected: _isRouteActive(
                      currentRoute,
                      _getHomeRoute(user?.role),
                      exact: true,
                    ),
                    onTap: () => _navigateTo(
                      context,
                      currentRoute,
                      _getHomeRoute(user?.role),
                    ),
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.notifications_outlined,
                    activeIcon: Icons.notifications,
                    title: 'Notifications',
                    isSelected: _isRouteActive(currentRoute, '/notifications'),
                    onTap: () =>
                        _navigateTo(context, currentRoute, '/notifications'),
                  ),

                  // Role Specific Logic
                  if (user?.role == UserRole.student ||
                      user?.role == UserRole.parent) ...[
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.calendar_month_outlined,
                      activeIcon: Icons.calendar_month,
                      title: 'Bus Schedule',
                      isSelected: _isRouteActive(
                        currentRoute,
                        '/student/schedule',
                      ),
                      onTap: () => _navigateTo(
                        context,
                        currentRoute,
                        '/student/schedule',
                      ),
                    ),
                  ],

                  if (user?.role == UserRole.busCoordinator) ...[
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.edit_calendar_outlined,
                      activeIcon: Icons.edit_calendar,
                      title: 'Manage Schedule',
                      isSelected: _isRouteActive(
                        currentRoute,
                        '/coordinator/schedule',
                      ),
                      onTap: () => _navigateTo(
                        context,
                        currentRoute,
                        '/coordinator/schedule',
                      ),
                    ),
                  ],

                  // Profile Section (For everyone)
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    title: 'Profile',
                    isSelected: _isRouteActive(
                      currentRoute,
                      '/student/profile',
                    ), // Adjust path based on role if needed
                    onTap: () =>
                        _navigateTo(context, currentRoute, '/student/profile'),
                  ),
                ],
              ),
            ),
          ),

          // 3. Footer (Logout)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.withAlpha(20))),
            ),
            child: SafeArea(
              // Ensure it respects bottom notch/safe area
              child: _buildDrawerItem(
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
              ),
            ),
          ),
        ],
      ),
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
      context.push(
        target,
      ); // Using push usually better for drawers to keep history, or go() for top-level
      // For main tabs, maybe go() is better, but context.push works generally.
      // Based on previous code: context.go for home, push for others.
      // Let's stick to the previous logic logic if possible, or just use context.go for main sections.
      // Actually previous code used context.go for home and context.push for others.

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

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(28), // Pill shape
      ),
      child: ListTile(
        leading: Icon(isSelected ? activeIcon : icon, color: color, size: 24),
        title: Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        onTap: onTap,
      ),
    );
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
