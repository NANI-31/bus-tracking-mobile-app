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
          ? _buildEmptyState(context)
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
      error: (e, s) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load users',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                e.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(userListProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return VStack(
      [
        Icon(
          Icons.people_outlined,
          size: 64,
          color: context.colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        AppSizes.paddingMedium.heightBox,
        'No users found'.text
            .size(18)
            .color(context.colorScheme.onSurface.withValues(alpha: 0.6))
            .make(),
      ],
      alignment: MainAxisAlignment.center,
      crossAlignment: CrossAxisAlignment.center,
    ).centered();
  }
}
