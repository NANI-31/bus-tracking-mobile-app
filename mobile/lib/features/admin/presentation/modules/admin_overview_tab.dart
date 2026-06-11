import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/features/user/application/user_provider.dart';
import 'package:collegebus/features/college/application/college_provider.dart';

class AdminOverviewTab extends ConsumerWidget {
  const AdminOverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collegesAsync = ref.watch(collegeServiceProvider);
    final usersAsync = ref.watch(userListProvider);

    return collegesAsync.when(
      data: (colleges) => usersAsync.when(
        data: (users) => _buildContent(context, colleges, users),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => _buildErrorState(context, ref, e, isUsersError: true),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => _buildErrorState(context, ref, e, isUsersError: false),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<dynamic> colleges,
    List<dynamic> users,
  ) {
    return VStack([
      'System Overview'.text
          .size(24)
          .bold
          .color(Theme.of(context).colorScheme.onSurface)
          .make(),
      AppSizes.paddingLarge.heightBox,

      // Statistics Cards
      HStack([
        _buildStatCard(
          context,
          'Total Colleges',
          colleges.length.toString(),
          Icons.school,
          Theme.of(context).primaryColor,
        ).expand(),
        AppSizes.paddingMedium.widthBox,
        _buildStatCard(
          context,
          'Verified Colleges',
          colleges.where((c) => c.verified).length.toString(),
          Icons.verified,
          Theme.of(context).colorScheme.secondary,
        ).expand(),
      ]),

      AppSizes.paddingMedium.heightBox,

      HStack([
        _buildStatCard(
          context,
          'Total Users',
          users.length.toString(),
          Icons.people,
          Theme.of(context).colorScheme.secondary,
        ).expand(),
        AppSizes.paddingMedium.widthBox,
        _buildStatCard(
          context,
          'Pending Approvals',
          users.where((u) => u.needsManualApproval).length.toString(),
          Icons.pending,
          Theme.of(context).colorScheme.error,
        ).expand(),
      ]),
    ]).p(AppSizes.paddingMedium);
  }

  Widget _buildErrorState(
    BuildContext context,
    WidgetRef ref,
    Object error, {
    required bool isUsersError,
  }) {
    return Center(
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
              isUsersError ? 'Failed to load users' : 'Failed to load colleges',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (isUsersError) {
                  ref.invalidate(userListProvider);
                }
                ref.invalidate(collegeServiceProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: VStack([
        Icon(icon, size: 32, color: color),
        AppSizes.paddingSmall.heightBox,
        value.text.size(24).bold.color(color).make(),
        AppSizes.paddingSmall.heightBox,
        title.text
            .size(14)
            .color(
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            )
            .center
            .make(),
      ], crossAlignment: CrossAxisAlignment.center).p(AppSizes.paddingMedium),
    );
  }
}
