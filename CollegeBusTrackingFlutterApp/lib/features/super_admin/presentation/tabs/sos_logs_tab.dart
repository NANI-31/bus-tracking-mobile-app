import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:collegebus/features/sos/domain/sos_model.dart';
import 'package:collegebus/features/college/domain/college_model.dart';
import 'package:collegebus/core/constants/constants.dart';

class SosLogsTab extends ConsumerWidget {
  final List<SosModel> sosLogs;
  final List<CollegeModel> colleges;

  const SosLogsTab({super.key, required this.sosLogs, required this.colleges});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          child: Row(
            children: [
              const Icon(Icons.emergency, color: Colors.red),
              const SizedBox(width: 8.0),
              Text(
                'System SOS Archives (${sosLogs.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: sosLogs.isEmpty
              ? const Center(child: Text('No emergency logs found'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingMedium,
                  ),
                  itemCount: sosLogs.length,
                  itemBuilder: (context, index) {
                    final sos = sosLogs[index];
                    final college = colleges.firstWhereOrNull(
                      (c) => c.id == sos.collegeId,
                    );
                    return Card(
                      child: ExpansionTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.redAccent,
                          child: Icon(
                            Icons.warning,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          'Bus ${sos.busNumber} - ${college?.name ?? 'Unknown College'}',
                        ),
                        subtitle: Text(
                          'Resolved ${DateFormat('MMM dd, HH:mm').format((sos.resolvedAt ?? sos.timestamp).toLocal())}',
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow(
                                  'Reported By',
                                  '${sos.userRole} (${DateFormat('HH:mm').format(sos.timestamp.toLocal())})',
                                ),
                                _buildDetailRow(
                                  'Resolved By',
                                  sos.resolvedBy ?? 'Admin',
                                ),
                                _buildDetailRow('Bus ID', sos.busId),
                                const Divider(),
                                const Text(
                                  'Resolution documentation:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  sos.resolutionNotes ?? 'No notes provided.',
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
