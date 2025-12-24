import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/widgets/app_drawer.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:go_router/go_router.dart';

// New standalone widgets
import 'widgets/home/welcome_section.dart';
import 'widgets/home/bus_status_card.dart';
import 'widgets/home/route_card.dart';
import 'widgets/home/track_button.dart';

class StudentHomeScreen extends StatelessWidget {
  final bool isTab;
  final VoidCallback? onTrackLive;

  const StudentHomeScreen({super.key, this.isTab = false, this.onTrackLive});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUserModel;
    final userName = user?.fullName.split(' ').first ?? 'Student';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: isTab ? null : AppDrawer(user: user, authService: authService),
      appBar: isTab
          ? null
          : AppBar(
              title: const Text('Home'),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              foregroundColor: Theme.of(context).colorScheme.onSecondary,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => context.push('/notifications'),
                ),
              ],
            ),
      body: VStack([
        16.heightBox,

        // 1. Welcome Section
        WelcomeSection(userName: userName),
        16.heightBox,

        // 2. Bus Status Card
        const BusStatusCard(),
        20.heightBox,

        // 3. Current Route Card
        const RouteCard(),
        16.heightBox,

        // 4. Action Button
        TrackBusButton(
          onTap: () {
            if (onTrackLive != null) {
              onTrackLive!();
            } else {
              context.go('/student');
            }
          },
        ),
        16.heightBox,

        // 5. Update Interval Text
        HStack([
          const Icon(Icons.circle, size: 8, color: Colors.greenAccent),
          8.widthBox,
          "Live location updates every 30 seconds".text
              .size(13)
              .color(
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              )
              .make(),
        ], alignment: MainAxisAlignment.center).centered(),

        20.heightBox,
      ]).pSymmetric(h: 20).scrollVertical(),
    );
  }
}
