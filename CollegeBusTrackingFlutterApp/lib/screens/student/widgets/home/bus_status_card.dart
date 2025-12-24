import 'package:flutter/material.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:velocity_x/velocity_x.dart';

class BusStatusCard extends StatelessWidget {
  const BusStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ZStack([
        VStack([
          // Header Section
          HStack([
            VStack([
              "BUS NUMBER".text
                  .size(12)
                  .bold
                  .letterSpacing(1.2)
                  .color(colorScheme.onSurface.withValues(alpha: 0.4))
                  .make(),
              8.heightBox,
              HStack([
                Icon(
                  Icons.directions_bus_filled_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
                8.widthBox,
                "12".text.size(32).bold.color(colorScheme.onSurface).make(),
              ]),
            ]).expand(),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
              ),
              child: HStack([
                Icon(
                  Icons.circle,
                  size: 10,
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                8.widthBox,
                "Not Started".text.bold
                    .color(colorScheme.onSurface.withValues(alpha: 0.7))
                    .make(),
              ]),
            ),
          ]),

          8.heightBox,
          Divider(color: colorScheme.onSurface.withValues(alpha: 0.2)),
          8.heightBox,

          "ESTIMATED ARRIVAL".text
              .size(8)
              .bold
              .letterSpacing(1.2)
              .color(colorScheme.onSurface.withValues(alpha: 0.5))
              .make(),

          8.heightBox,

          HStack([
            Icon(
              Icons.access_time_filled_rounded,
              color: AppColors.primary,
              size: 24,
            ),
            8.widthBox,
            "8:45 AM".text.size(22).extraBold.color(AppColors.primary).make(),
          ]),
        ]),
      ]),
    );
  }
}
