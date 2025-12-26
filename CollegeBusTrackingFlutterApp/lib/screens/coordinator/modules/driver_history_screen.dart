import 'package:flutter/material.dart';
import 'package:collegebus/models/user_model.dart';

class DriverHistoryScreen extends StatelessWidget {
  final UserModel driver;

  const DriverHistoryScreen({super.key, required this.driver});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Driver History',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).iconTheme.color,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildDriverHeader(context),
          const Divider(),
          Expanded(child: _buildTimeline(context)),
        ],
      ),
    );
  }

  Widget _buildDriverHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: colorScheme.primary,
            child: Text(
              driver.fullName.isNotEmpty ? driver.fullName[0] : '?',
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                driver.fullName,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                driver.email,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Mock Data for History
    final List<Map<String, dynamic>> historyLogs = [
      {
        'date': 'Today, 2:30 PM',
        'title': 'Shift Ended',
        'description': 'Completed afternoon shift for Route KKR-01.',
        'type': 'info',
      },
      {
        'date': 'Today, 8:15 AM',
        'title': 'Trip Completed',
        'description': 'Successfully reached college campus with 45 students.',
        'type': 'success',
      },
      {
        'date': 'Today, 7:30 AM',
        'title': 'Trip Started',
        'description': 'Started route KKR-01 from SVN Colony.',
        'type': 'info',
      },
      {
        'date': 'Yesterday, 5:00 PM',
        'title': 'Bus Assigned',
        'description': 'Assigned to Bus KKR-01 by Coordinator.',
        'type': 'warning',
      },
      {
        'date': 'Dec 24, 10:00 AM',
        'title': 'Account Approved',
        'description': 'Driver account verified and approved.',
        'type': 'success',
      },
    ];

    if (historyLogs.isEmpty) {
      return Center(
        child: Text(
          'No history available',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: historyLogs.length,
      itemBuilder: (context, index) {
        final log = historyLogs[index];
        final isLast = index == historyLogs.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timeline Line
              Column(
                children: [
                  _buildTimelineDot(context, log['type']),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: colorScheme.outlineVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log['date'].toString(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      log['title'].toString(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      log['description'].toString(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimelineDot(BuildContext context, String type) {
    Color color;
    IconData icon;

    switch (type) {
      case 'success':
        color = Colors.green;
        icon = Icons.check;
        break;
      case 'warning':
        color = Colors.orange;
        icon = Icons.assignment_ind;
        break;
      case 'error':
        color = Colors.red;
        icon = Icons.warning;
        break;
      default:
        color = Theme.of(context).primaryColor;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Icon(icon, size: 14, color: color),
    );
  }
}
