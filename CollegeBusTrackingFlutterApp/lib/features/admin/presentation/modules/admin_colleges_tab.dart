import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/features/college/application/college_provider.dart';

class AdminCollegesTab extends ConsumerWidget {
  const AdminCollegesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collegesAsync = ref.watch(collegeServiceProvider);

    return collegesAsync.when(
      data: (colleges) => colleges.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              itemCount: colleges.length,
              itemBuilder: (context, index) {
                final college = colleges[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: college.verified
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).colorScheme.error,
                      child: Icon(
                        college.verified ? Icons.verified : Icons.pending,
                        color: Theme.of(context).colorScheme.onSecondary,
                      ),
                    ),
                    title: Text(
                      college.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: VStack([
                      'Domains: ${college.allowedDomains.join(', ')}'.text
                          .make(),
                      'Status: ${college.verified ? 'Verified' : 'Pending Verification'}'
                          .text
                          .color(
                            college.verified
                                ? Theme.of(context).colorScheme.secondary
                                : Theme.of(context).colorScheme.error,
                          )
                          .medium
                          .make(),
                    ]),
                    trailing: !college.verified
                        ? IconButton(
                            icon: Icon(
                              Icons.check,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            onPressed: () {
                              // College verification implementation
                            },
                          )
                        : null,
                    isThreeLine: true,
                  ),
                );
              },
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return VStack(
      [
        Icon(
          Icons.school_outlined,
          size: 64,
          color: context.colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        AppSizes.paddingMedium.heightBox,
        'No colleges registered yet'.text
            .size(18)
            .color(context.colorScheme.onSurface.withValues(alpha: 0.6))
            .make(),
      ],
      alignment: MainAxisAlignment.center,
      crossAlignment: CrossAxisAlignment.center,
    ).centered();
  }
}
