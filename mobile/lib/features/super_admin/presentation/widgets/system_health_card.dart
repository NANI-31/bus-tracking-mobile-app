import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SystemHealthCard extends ConsumerWidget {
  final int activeSosCount;
  final VoidCallback onViewMonitor;

  const SystemHealthCard({
    super.key,
    required this.activeSosCount,
    required this.onViewMonitor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: activeSosCount > 0 ? Colors.red.shade50 : Colors.green.shade50,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: activeSosCount > 0 ? Colors.red : Colors.green,
          child: Icon(
            activeSosCount > 0 ? Icons.warning : Icons.check,
            color: Colors.white,
          ),
        ),
        title: Text(
          activeSosCount > 0
              ? 'System Warning: Emergency Active'
              : 'System Status: Healthy',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          activeSosCount > 0
              ? '$activeSosCount active alerts require investigation'
              : 'All services running normally',
        ),
        trailing: TextButton(
          onPressed: onViewMonitor,
          child: const Text('View Monitor'),
        ),
      ),
    );
  }
}





