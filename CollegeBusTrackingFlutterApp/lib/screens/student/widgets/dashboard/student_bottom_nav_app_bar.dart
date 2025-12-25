import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import '../../../common/notifications/notifications_screen.dart';

class StudentBottomNavAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final int bottomNavIndex;

  const StudentBottomNavAppBar({super.key, required this.bottomNavIndex});

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        height: 70,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: HStack([
          // School Icon
          Icon(
            Icons.school_rounded,
            color: Theme.of(context).colorScheme.onSecondary,
            size: 30,
          ),

          // Dynamic Title
          _getTitle(bottomNavIndex).text.xl2.bold
              .color(Theme.of(context).colorScheme.onSecondary)
              .make(),

          // Notification Icon with Dot
          ZStack([
            Icon(
              Icons.notifications_rounded,
              color: Theme.of(context).colorScheme.onSecondary,
              size: 30,
            ),
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5252),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2.0,
                  ),
                ),
              ),
            ),
          ]).onTap(() {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            );
          }),
        ], alignment: MainAxisAlignment.spaceBetween),
      ),
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return "Student Home";
      case 1:
        return "Track Bus";
      case 2:
        return "Bus List";
      case 3:
        return "Schedule";
      default:
        return "Profile";
    }
  }
}
