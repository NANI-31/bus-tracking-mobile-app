import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/models/route_model.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/models/user_model.dart';
import 'package:collegebus/l10n/coordinator/app_localizations.dart'
    as coord_l10n;
import 'package:collegebus/screens/coordinator/modules/overview_components/broadcast_modal.dart';

class OverviewTab extends StatelessWidget {
  final List<RouteModel> routes;
  final List<BusModel> buses;
  final List<UserModel> pendingDrivers;
  final List<String> busNumbers;
  final int activeSosCount;
  final VoidCallback? onSosTap;

  const OverviewTab({
    super.key,
    required this.routes,
    required this.buses,
    required this.pendingDrivers,
    required this.busNumbers,
    required this.activeSosCount,
    this.onSosTap,
  });

  @override
  Widget build(BuildContext context) {
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
          'Total Routes',
          routes.length.toString(),
          Icons.route,
          Theme.of(context).primaryColor,
        ).expand(),
        AppSizes.paddingMedium.widthBox,
        _buildStatCard(
          context,
          'Active Buses',
          buses.where((b) => b.isActive).length.toString(),
          Icons.directions_bus,
          Theme.of(context).colorScheme.secondary,
        ).expand(),
      ]),

      AppSizes.paddingMedium.heightBox,

      HStack([
        _buildStatCard(
          context,
          'Pending Drivers',
          pendingDrivers.length.toString(),
          Icons.pending,
          Theme.of(context).colorScheme.error,
        ).expand(),
        AppSizes.paddingMedium.widthBox,
        _buildStatCard(
          context,
          'Bus Numbers',
          busNumbers.length.toString(),
          Icons.confirmation_number,
          Theme.of(context).colorScheme.secondary,
        ).expand(),
      ]),

      AppSizes.paddingMedium.heightBox,

      // Broadcast Card
      Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  .color(AppColors.textSecondary)
                  .size(12)
                  .make(),
            ]).expand(),
            Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ]).p(16),
        ),
      ),

      if (activeSosCount > 0) ...[
        AppSizes.paddingMedium.heightBox,
        Card(
          color: AppColors.error.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.error, width: 2),
          ),
          child: HStack([
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 40),
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
    ]).p(AppSizes.paddingMedium);
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
