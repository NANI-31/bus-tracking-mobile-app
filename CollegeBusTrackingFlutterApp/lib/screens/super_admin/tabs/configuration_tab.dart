import 'package:flutter/material.dart';

class ConfigurationTab extends StatelessWidget {
  const ConfigurationTab({super.key});

  @override
  Widget build(BuildContext context) {
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
