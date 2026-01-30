import 'package:flutter/material.dart';
import 'package:collegebus/utils/constants.dart';

class DangerZoneTab extends StatelessWidget {
  const DangerZoneTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Danger Zone',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sensitive system operations',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: AppSizes.paddingLarge),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              // TODO: Implement system wipe or sensitive ops
            },
            child: const Text('Clear All System Logs'),
          ),
        ],
      ),
    );
  }
}
