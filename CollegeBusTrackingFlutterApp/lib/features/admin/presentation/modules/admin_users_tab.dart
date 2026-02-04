import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/features/user/application/user_provider.dart';

class AdminUsersTab extends ConsumerWidget {
  const AdminUsersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(userListProvider);

    return usersAsync.when(
      data: (users) => users.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: user.approved
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).colorScheme.error,
                      child: Icon(
                        user.approved ? Icons.check : Icons.pending,
                        color: Theme.of(context).colorScheme.onSecondary,
                      ),
                    ),
                    title: Text(
                      user.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: VStack([
                      user.email.text.make(),
                      if (user.phoneNumber != null &&
                          user.phoneNumber!.isNotEmpty)
                        'Phone: ${user.phoneNumber}'.text.make(),
                      'Role: ${user.role.displayName}'.text
                          .color(Theme.of(context).primaryColor)
                          .medium
                          .make(),
                      'Status: ${user.approved ? 'Approved' : 'Pending'}'.text
                          .color(
                            user.approved
                                ? Theme.of(context).colorScheme.secondary
                                : Theme.of(context).colorScheme.error,
                          )
                          .medium
                          .make(),
                    ]),
                    isThreeLine: true,
                  ),
                );
              },
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildEmptyState() {
    return VStack(
      [
        Icon(Icons.people_outlined, size: 64, color: AppColors.textSecondary),
        AppSizes.paddingMedium.heightBox,
        'No users found'.text.size(18).color(AppColors.textSecondary).make(),
      ],
      alignment: MainAxisAlignment.center,
      crossAlignment: CrossAxisAlignment.center,
    ).centered();
  }
}





