import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/features/bus/application/bus_provider.dart';
import 'package:collegebus/features/route/application/route_provider.dart';
import 'package:collegebus/features/sos/application/sos_provider.dart';
import 'package:collegebus/features/user/application/user_provider.dart';
import 'package:collegebus/features/coordinator/presentation/modules/overview_components/broadcast_modal.dart';

class OverviewTab extends ConsumerWidget {
  final VoidCallback? onSosTap;

  const OverviewTab({super.key, this.onSosTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final collegeId = user?.collegeId;

    if (collegeId == null) return const SizedBox.shrink();

    final routes = ref.watch(collegeRoutesProvider(collegeId)).value ?? [];
    final buses = ref.watch(collegeBusesStreamProvider(collegeId)).value ?? [];
    final pendingDrivers =
        ref.watch(pendingApprovalsProvider(collegeId)).value ?? [];
    final busNumbers = ref.watch(busNumbersProvider(collegeId)).value ?? [];
    final activeSosCount = ref.watch(
      activeSosProvider(collegeId).select((v) => v.value?.length ?? 0),
    );
    return SingleChildScrollView(
      child: VStack([
        'System Overview'.text
            .size(24)
            .bold
            .color(
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : context.colorScheme.onSurface,
            )
            .make(),
        AppSizes.paddingLarge.heightBox,

        // Statistics Cards
        HStack([
          _buildStatCard(
            context,
            'Total Routes',
            routes.length.toString(),
            Icons.route,
            AppColors.primary,
          ).expand(),
          AppSizes.paddingMedium.widthBox,
          _buildStatCard(
            context,
            'Active Buses',
            buses.where((b) => b.isActive).length.toString(),
            Icons.directions_bus,
            AppColors.secondary,
          ).expand(),
        ]),

        AppSizes.paddingMedium.heightBox,

        HStack([
          _buildStatCard(
            context,
            'Pending Drivers',
            pendingDrivers.length.toString(),
            Icons.pending,
            AppColors.error,
          ).expand(),
          AppSizes.paddingMedium.widthBox,
          _buildStatCard(
            context,
            'Bus Numbers',
            busNumbers.length.toString(),
            Icons.confirmation_number,
            AppColors.secondary,
          ).expand(),
        ]),

        AppSizes.paddingMedium.heightBox,

        // Broadcast Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const BroadcastModal(),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: HStack([
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              16.widthBox,
              VStack([
                'Send Broadcast Message'.text.bold.lg.make(),
                'Notify all students, teachers & parents'.text
                    .color(context.colorScheme.onSurface.withValues(alpha: 0.6))
                    .size(12)
                    .make(),
              ]).expand(),
              Icon(
                Icons.chevron_right,
                color: context.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ]).p(16),
          ),
        ),

        if (activeSosCount > 0) ...[
          AppSizes.paddingMedium.heightBox,
          Card(
            color: AppColors.error.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.error, width: 2.0),
            ),
            child: HStack([
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
                size: 40,
              ),
              16.widthBox,
              VStack([
                'EMERGENCY ALERTS'.text.color(AppColors.error).bold.xl.make(),
                '$activeSosCount driver(s) requesting help!'.text
                    .color(AppColors.error)
                    .make(),
              ]).expand(),
              Icon(Icons.chevron_right, color: AppColors.error),
            ]).p(16),
          ).onTap(() {
            onSosTap?.call();
          }),
        ],
      ]).p(AppSizes.paddingMedium),
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
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.7)
                  : context.colorScheme.onSurface.withValues(alpha: 0.6),
            )
            .center
            .make(),
      ], crossAlignment: CrossAxisAlignment.center).p(AppSizes.paddingMedium),
    );
  }
}
