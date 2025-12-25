import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/widgets/app_drawer.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUserModel;

    return Scaffold(
      appBar: AppBar(
        title: 'Notifications'.text.make(),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      drawer: AppDrawer(user: user, authService: authService),
      body: VStack(
        [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          16.heightBox,
          'No new notifications'.text
              .size(18)
              .color(
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              )
              .medium
              .make(),
        ],
        alignment: MainAxisAlignment.center,
        crossAlignment: CrossAxisAlignment.center,
      ).centered(),
    );
  }
}
