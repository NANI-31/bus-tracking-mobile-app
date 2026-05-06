import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/user/domain/user_model.dart';
import 'package:collegebus/features/admin/application/admin_provider.dart';
import 'package:collegebus/core/constants/constants.dart';

class UserCard extends ConsumerWidget {
  final UserModel user;

  const UserCard({super.key, required this.user});

  void _confirmDeleteUser(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User?'),
        content: Text(
          'Are you sure you want to delete ${user.fullName}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final caService = ref.read(collegeAdminServiceProvider);
                await caService.deleteUser(user.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete user: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isApproved = user.approved;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isApproved
              ? Colors.green.shade100
              : Colors.orange.shade100,
          child: Icon(
            isApproved ? Icons.check : Icons.pending,
            color: isApproved ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(
          user.fullName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _confirmDeleteUser(context, ref),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    user.role.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isApproved
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isApproved ? 'Approved' : 'Pending',
                    style: TextStyle(
                      fontSize: 11,
                      color: isApproved ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
