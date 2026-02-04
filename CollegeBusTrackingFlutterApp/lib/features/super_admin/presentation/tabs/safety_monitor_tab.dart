import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:collegebus/features/admin/application/admin_provider.dart';
import 'package:collegebus/features/college/domain/college_model.dart';
import 'package:collegebus/features/sos/domain/sos_model.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/features/super_admin/presentation/widgets/super_admin_stat_card.dart';

class SafetyMonitorTab extends ConsumerWidget {
  final List<CollegeModel> colleges;

  const SafetyMonitorTab({super.key, required this.colleges});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saService = ref.watch(superAdminServiceProvider);
    final activeSos = saService.globalActiveSos;
    final resolvedSos = saService.sosLogs;

    // Calculate incidents per college for trends
    final incidentsByCollege = groupBy(
      resolvedSos,
      (SosModel s) => s.collegeId,
    );
    final sortedColleges = incidentsByCollege.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SuperAdminStatCard(
                  title: 'Active SOS',
                  value: activeSos.length.toString(),
                  icon: Icons.emergency,
                  color: activeSos.isNotEmpty ? Colors.red : Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SuperAdminStatCard(
                  title: 'Resolved',
                  value: resolvedSos.length.toString(),
                  icon: Icons.task_alt,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          const Text(
            'Live Global Alerts',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (activeSos.isEmpty)
            const Card(
              child: ListTile(
                title: Text('No active emergencies globally'),
                leading: Icon(Icons.check_circle, color: Colors.green),
              ),
            )
          else
            ...activeSos.map((sos) {
              final college = colleges.firstWhereOrNull(
                (c) => c.id == sos.collegeId,
              );
              return Card(
                color: Colors.red.shade50,
                child: ListTile(
                  leading: const Icon(Icons.emergency, color: Colors.red),
                  title: Text(
                    'Bus ${sos.busNumber} - ${college?.name ?? 'Unknown'}',
                  ),
                  subtitle: Text(
                    'Reported ${DateFormat('HH:mm').format(sos.timestamp)} • ${sos.userRole}',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                ),
              );
            }),

          const SizedBox(height: 32),
          const Text(
            'Regional Safety Trends',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Total incidents reported per institution',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),

          if (sortedColleges.isEmpty)
            const Center(child: Text('No historical data available'))
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: sortedColleges.take(5).map((entry) {
                    final college = colleges.firstWhereOrNull(
                      (c) => c.id == entry.key,
                    );
                    final count = entry.value.length;
                    final maxCount = sortedColleges.first.value.length;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                college?.name ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '$count incidents',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: count / maxCount,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              count > 10 ? Colors.red : Colors.orange,
                            ),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}





