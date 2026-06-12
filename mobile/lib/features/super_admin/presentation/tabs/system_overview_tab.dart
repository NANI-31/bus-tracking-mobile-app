import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:collegebus/features/super_admin/application/super_admin_provider.dart';
import 'package:collegebus/features/user/domain/user_model.dart';
import 'package:collegebus/features/audit/domain/audit_log_model.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/widgets/analytics/analytics_charts.dart';
import 'package:collegebus/features/super_admin/presentation/widgets/super_admin_stat_card.dart';
import 'package:collegebus/features/super_admin/presentation/widgets/system_health_card.dart';

class SystemOverviewTab extends ConsumerWidget {
  final int totalColleges;
  final int verifiedColleges;
  final int totalUsers;
  final int pendingColleges;
  final List<UserModel> allUsers;
  final List<AuditLogModel> auditLogs;
  final Function(int) onNavigate;
  final Function() onVerifyColleges;

  const SystemOverviewTab({
    super.key,
    required this.totalColleges,
    required this.verifiedColleges,
    required this.totalUsers,
    required this.pendingColleges,
    required this.allUsers,
    required this.auditLogs,
    required this.onNavigate,
    required this.onVerifyColleges,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(superAdminServiceProvider);
    final activeSosCount = asyncState.valueOrNull?.globalActiveSos.length ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SystemHealthCard(
            activeSosCount: activeSosCount,
            onViewMonitor: () => onNavigate(6), // Safety Monitor index
          ),

          const SizedBox(height: AppSizes.paddingLarge),

          Text(
            'System Statistics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSizes.paddingMedium),

          // Stats Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSizes.paddingMedium,
            mainAxisSpacing: AppSizes.paddingMedium,
            childAspectRatio: 1.4,
            children: [
              SuperAdminStatCard(
                title: 'Total Colleges',
                value: totalColleges.toString(),
                icon: Icons.school,
                color: Colors.deepPurple,
              ),
              SuperAdminStatCard(
                title: 'Verified',
                value: verifiedColleges.toString(),
                icon: Icons.verified,
                color: Colors.green,
              ),
              SuperAdminStatCard(
                title: 'Total Users',
                value: totalUsers.toString(),
                icon: Icons.people,
                color: Colors.blue,
              ),
              SuperAdminStatCard(
                title: 'Active Alerts',
                value: activeSosCount.toString(),
                icon: Icons.emergency,
                color: activeSosCount > 0 ? Colors.red : Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingLarge),

          // Visual Analytics Section
          Text(
            'Visual Analytics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSizes.paddingMedium),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppPieChart(
                          title: 'User Roles',
                          data: {
                            'Students': totalUsers > 0
                                ? allUsers
                                      .where((u) => u.role == UserRole.student)
                                      .length
                                      .toDouble()
                                : 0,
                            'Drivers': totalUsers > 0
                                ? allUsers
                                      .where((u) => u.role == UserRole.driver)
                                      .length
                                      .toDouble()
                                : 0,
                            'Admins': totalUsers > 0
                                ? allUsers
                                      .where(
                                        (u) =>
                                            u.role == UserRole.collegeAdmin ||
                                            u.role == UserRole.superAdmin,
                                      )
                                      .length
                                      .toDouble()
                                : 0,
                          },
                          colors: const [
                            Colors.blue,
                            Colors.green,
                            Colors.orange,
                          ],
                          height: 140,
                        ),
                      ),
                      const VerticalDivider(),
                      Expanded(
                        child: AppPieChart(
                          title: 'Colleges',
                          data: {
                            'Verified': verifiedColleges.toDouble(),
                            'Pending': pendingColleges.toDouble(),
                          },
                          colors: const [Colors.green, Colors.orange],
                          height: 140,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  // Simple Activity trend from Audit Logs (last 7 logs as mock points)
                  AppLineChart(
                    title: 'System Activity (Mock Trend)',
                    spots: auditLogs.length > 5
                        ? List.generate(
                            auditLogs.length.clamp(0, 10),
                            (i) => FlSpot(
                              i.toDouble(),
                              (10 + (i % 3) * 5 + (i % 2) * 2).toDouble(),
                            ),
                          )
                        : const [
                            FlSpot(0, 1),
                            FlSpot(1, 3),
                            FlSpot(2, 2),
                            FlSpot(3, 5),
                            FlSpot(4, 4),
                          ],
                    height: 120,
                    lineColor: Colors.deepPurple,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSizes.paddingLarge),

          // Quick Actions
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSizes.paddingMedium),

          Wrap(
            spacing: AppSizes.paddingSmall,
            runSpacing: AppSizes.paddingSmall,
            children: [
              ActionChip(
                avatar: const Icon(
                  Icons.verified,
                  size: 18,
                  color: Colors.green,
                ),
                label: const Text('Verify Colleges'),
                onPressed: onVerifyColleges,
              ),
              ActionChip(
                avatar: const Icon(Icons.search, size: 18, color: Colors.blue),
                label: const Text('Search Users'),
                onPressed: () => onNavigate(2),
              ),
              ActionChip(
                avatar: const Icon(
                  Icons.settings,
                  size: 18,
                  color: Colors.grey,
                ),
                label: const Text('Configuration'),
                onPressed: () => onNavigate(3),
              ),
            ],
          ),
        ],
      ),
    );
  }
}





