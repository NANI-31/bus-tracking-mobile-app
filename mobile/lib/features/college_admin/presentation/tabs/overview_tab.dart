import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:collegebus/features/college_admin/application/college_admin_provider.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/widgets/analytics/analytics_charts.dart';
import 'package:collegebus/features/college_admin/presentation/widgets/stat_card.dart';

class OverviewTab extends ConsumerWidget {
  final Function(int) onNavigate;

  const OverviewTab({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(collegeAdminServiceProvider);
    final collegeUsers = asyncState.valueOrNull?.collegeUsers ?? [];

    debugPrint('OVERVIEW TAB: collegeUsers length: ${collegeUsers.length}');
    if (collegeUsers.isNotEmpty) {
      debugPrint('OVERVIEW TAB: Sample user role: ${collegeUsers.first.role}');
    }

    final totalStudents = collegeUsers
        .where((u) => u.role == UserRole.student)
        .length;
    final totalDrivers = collegeUsers
        .where((u) => u.role == UserRole.driver)
        .length;
    final buses = asyncState.valueOrNull?.collegeBuses ?? [];
    final totalBuses = buses.length;
    final pendingApprovals = collegeUsers.where((u) => !u.approved).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'College Statistics',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSizes.paddingMedium),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSizes.paddingMedium,
            mainAxisSpacing: AppSizes.paddingMedium,
            childAspectRatio: 1.4,
            children: [
              StatCard(
                title: 'Total Students',
                value: totalStudents.toString(),
                icon: Icons.person,
                color: Colors.blue,
              ),
              StatCard(
                title: 'Total Drivers',
                value: totalDrivers.toString(),
                icon: Icons.drive_eta,
                color: Colors.green,
              ),
              StatCard(
                title: 'Total Buses',
                value: totalBuses.toString(),
                icon: Icons.directions_bus,
                color: Colors.orange,
              ),
              StatCard(
                title: 'Pending Approvals',
                value: pendingApprovals.toString(),
                icon: Icons.pending_actions,
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingLarge),

          Text(
            'Visual Analytics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSizes.paddingMedium),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppPieChart(
                      title: 'Fleet Status',
                      data: {
                        'On-time': buses
                            .where((b) => b.status == 'on-time')
                            .length
                            .toDouble(),
                        'Delayed': buses
                            .where((b) => b.status == 'delayed')
                            .length
                            .toDouble(),
                        'Idle': buses
                            .where(
                              (b) =>
                                  b.status != 'on-time' &&
                                  b.status != 'delayed',
                            )
                            .length
                            .toDouble(),
                      },
                      colors: const [Colors.green, Colors.orange, Colors.grey],
                      height: 120,
                    ),
                  ),
                  const VerticalDivider(),
                  Expanded(
                    child: AppPieChart(
                      title: 'User Mix',
                      data: {
                        'Students': totalStudents.toDouble(),
                        'Drivers': totalDrivers.toDouble(),
                      },
                      colors: const [Colors.blue, Colors.teal],
                      height: 120,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSizes.paddingLarge),

          // Quick Actions
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600, // semiBold
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSizes.paddingMedium),

          Wrap(
            spacing: AppSizes.paddingSmall,
            runSpacing: AppSizes.paddingSmall,
            children: [
              ActionChip(
                avatar: Icon(Icons.people, size: 18, color: AppColors.primary),
                label: const Text('View Users'),
                onPressed: () => onNavigate(1),
              ),
              ActionChip(
                avatar: Icon(
                  Icons.add_circle,
                  size: 18,
                  color: AppColors.secondary,
                ),
                label: const Text('View Coordinators'),
                onPressed: () => onNavigate(1),
              ),
              ActionChip(
                avatar: Icon(Icons.route, size: 18, color: AppColors.success),
                label: const Text('Manage Fleet'),
                onPressed: () => onNavigate(2), // Fleet Tab index
              ),
              ActionChip(
                avatar: const Icon(Icons.map, size: 18, color: Colors.blue),
                label: const Text('Live Map'),
                onPressed: () => onNavigate(3), // Live Tracking Tab index
              ),
            ],
          ),
        ],
      ),
    );
  }
}





