import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConfigurationTab extends ConsumerWidget {
  const ConfigurationTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          title: const Text('System Settings'),
          leading: const Icon(Icons.settings),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        const Divider(),
        ListTile(
          title: const Text('Notification Templates'),
          leading: const Icon(Icons.notifications),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        const Divider(),
        ListTile(
          title: const Text('Role Permissions'),
          leading: const Icon(Icons.security),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        const Divider(),
        ListTile(
          title: const Text('Backup & Restore'),
          leading: const Icon(Icons.backup),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
      ],
    );
  }
}





