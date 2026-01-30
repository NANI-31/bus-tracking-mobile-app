import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:collegebus/models/audit_log_model.dart';
import 'package:collegebus/utils/constants.dart';

class AuditTab extends StatelessWidget {
  final List<AuditLogModel> auditLogs;

  const AuditTab({super.key, required this.auditLogs});

  @override
  Widget build(BuildContext context) {
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
              '${log.actionDescription}\n${DateFormat('yyyy-MM-dd HH:mm').format(log.createdAt)}',
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
