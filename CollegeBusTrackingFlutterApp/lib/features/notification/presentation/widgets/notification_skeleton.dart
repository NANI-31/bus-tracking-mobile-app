import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';

class NotificationSkeleton extends StatelessWidget {
  const NotificationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Placeholder
          VxBox().roundedFull
              .color(colorScheme.surfaceContainerHighest)
              .size(48, 48)
              .make()
              .shimmer(),
          16.widthBox,
          // Content Placeholder
          VStack([
            HStack([
              VxBox().roundedLg
                  .color(colorScheme.surfaceContainerHighest)
                  .height(16)
                  .width(120)
                  .make()
                  .shimmer(),
              const Spacer(),
              VxBox().roundedLg
                  .color(colorScheme.surfaceContainerHighest)
                  .height(12)
                  .width(40)
                  .make()
                  .shimmer(),
            ]),
            8.heightBox,
            VxBox().roundedLg
                .color(colorScheme.surfaceContainerHighest)
                .height(14)
                .width(double.infinity)
                .make()
                .shimmer(),
            4.heightBox,
            VxBox().roundedLg
                .color(colorScheme.surfaceContainerHighest)
                .height(14)
                .width(200)
                .make()
                .shimmer(),
          ]).expand(),
        ],
      ),
    );
  }
}
