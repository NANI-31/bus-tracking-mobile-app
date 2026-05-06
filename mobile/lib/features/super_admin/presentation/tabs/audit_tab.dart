import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:collegebus/features/audit/domain/audit_log_model.dart';
import 'package:collegebus/core/constants/constants.dart';

class AuditTab extends ConsumerWidget {
  final List<AuditLogModel> auditLogs;

  const AuditTab({super.key, required this.auditLogs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (auditLogs.isEmpty) {
      return const Center(child: Text('No audit logs available'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      itemCount: auditLogs.length,
      itemBuilder: (context, index) {
        final log = auditLogs[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey.shade200,
              child: const Icon(Icons.history, color: Colors.grey),
            ),
            title: Text(log.action),
            subtitle: Text(
              '${log.actionDescription}\n${DateFormat('yyyy-MM-dd HH:mm').format(log.createdAt.toLocal())}',
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
