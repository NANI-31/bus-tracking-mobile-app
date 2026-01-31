import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/providers/auth_provider.dart';
import 'package:collegebus/widgets/app_drawer.dart';
import 'package:collegebus/l10n/notification/app_localizations.dart'
    as notif_l10n;

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    // Ensure delegate is provided in main.dart, accessed here
    final l10n = notif_l10n.NotificationLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: l10n.title.text.make(),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      drawer: AppDrawer(user: user),
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
          l10n.emptyState.text
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
