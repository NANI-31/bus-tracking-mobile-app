import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/core/constants/constants.dart';

class BusListSkeleton extends StatelessWidget {
  const BusListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMedium,
        vertical: 8,
      ),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Circular avatar placeholder
              VxBox()
                  .roundedFull
                  .color(colorScheme.surfaceContainerHighest)
                  .size(44, 44)
                  .make()
                  .shimmer(),
              16.widthBox,
              // Info block
              VStack([
                VxBox()
                    .roundedLg
                    .color(colorScheme.surfaceContainerHighest)
                    .height(16)
                    .width(100)
                    .make()
                    .shimmer(),
                8.heightBox,
                VxBox()
                    .roundedLg
                    .color(colorScheme.surfaceContainerHighest)
                    .height(12)
                    .width(160)
                    .make()
                    .shimmer(),
              ]).expand(),
              16.widthBox,
              // Trailing arrow / button placeholder
              VxBox()
                  .roundedFull
                  .color(colorScheme.surfaceContainerHighest)
                  .size(24, 24)
                  .make()
                  .shimmer(),
            ],
          ),
        );
      },
    );
  }
}

class BusAssignmentSkeleton extends StatelessWidget {
  const BusAssignmentSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      child: Column(
        children: [
          // LocationDisplay Skeleton
          Container(
            margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                VxBox()
                    .roundedFull
                    .color(colorScheme.surfaceContainerHighest)
                    .size(12, 12)
                    .make()
                    .shimmer(),
                12.widthBox,
                VxBox()
                    .roundedLg
                    .color(colorScheme.surfaceContainerHighest)
                    .height(14)
                    .width(180)
                    .make()
                    .shimmer()
                    .expand(),
                12.widthBox,
                VxBox()
                    .roundedFull
                    .color(colorScheme.surfaceContainerHighest)
                    .size(16, 16)
                    .make()
                    .shimmer(),
              ],
            ),
          ),
          // BusCard Assignment Skeleton
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top header row
                Row(
                  children: [
                    VxBox()
                        .roundedFull
                        .color(colorScheme.surfaceContainerHighest)
                        .size(24, 24)
                        .make()
                        .shimmer(),
                    12.widthBox,
                    VxBox()
                        .roundedLg
                        .color(colorScheme.surfaceContainerHighest)
                        .height(18)
                        .width(140)
                        .make()
                        .shimmer(),
                  ],
                ),
                28.heightBox,
                // Giant bus number
                VxBox()
                    .roundedLg
                    .color(colorScheme.surfaceContainerHighest)
                    .height(56)
                    .width(160)
                    .make()
                    .shimmer(),
                32.heightBox,
                // Divider line representation
                VxBox()
                    .roundedLg
                    .color(colorScheme.surfaceContainerHighest)
                    .height(2)
                    .width(double.infinity)
                    .make()
                    .shimmer(),
                24.heightBox,
                // Action Buttons
                Row(
                  children: [
                    VxBox()
                        .roundedLg
                        .color(colorScheme.surfaceContainerHighest)
                        .height(48)
                        .make()
                        .shimmer()
                        .expand(),
                    16.widthBox,
                    VxBox()
                        .roundedLg
                        .color(colorScheme.surfaceContainerHighest)
                        .height(48)
                        .make()
                        .shimmer()
                        .expand(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DriverSelectionSkeleton extends StatelessWidget {
  const DriverSelectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Search Bar Skeleton
        Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          child: VxBox()
              .roundedLg
              .color(colorScheme.surfaceContainerHighest)
              .height(48)
              .width(double.infinity)
              .make()
              .shimmer(),
        ),
        // Drivers List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 5,
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      VxBox()
                          .roundedFull
                          .color(colorScheme.surfaceContainerHighest)
                          .size(40, 40)
                          .make()
                          .shimmer(),
                      16.widthBox,
                      VStack([
                        VxBox()
                            .roundedLg
                            .color(colorScheme.surfaceContainerHighest)
                            .height(14)
                            .width(120)
                            .make()
                            .shimmer(),
                        8.heightBox,
                        VxBox()
                            .roundedLg
                            .color(colorScheme.surfaceContainerHighest)
                            .height(12)
                            .width(180)
                            .make()
                            .shimmer(),
                      ]).expand(),
                      16.widthBox,
                      VxBox()
                          .roundedFull
                          .color(colorScheme.surfaceContainerHighest)
                          .size(24, 24)
                          .make()
                          .shimmer(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class StatCardsSkeleton extends StatelessWidget {
  const StatCardsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: VStack([
        // Header placeholder
        VxBox()
            .roundedLg
            .color(colorScheme.surfaceContainerHighest)
            .height(28)
            .width(180)
            .make()
            .shimmer(),
        AppSizes.paddingLarge.heightBox,

        // Statistics Cards grid (shimmering containers mirroring StatCard shape)
        HStack([
          _buildCardPlaceholder(context, colorScheme).expand(),
          AppSizes.paddingMedium.widthBox,
          _buildCardPlaceholder(context, colorScheme).expand(),
        ]),

        AppSizes.paddingMedium.heightBox,

        HStack([
          _buildCardPlaceholder(context, colorScheme).expand(),
          AppSizes.paddingMedium.widthBox,
          _buildCardPlaceholder(context, colorScheme).expand(),
        ]),

        AppSizes.paddingMedium.heightBox,

        // Broadcast card placeholder
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              16.widthBox,
              VxBox()
                  .roundedFull
                  .color(colorScheme.surfaceContainerHighest)
                  .size(44, 44)
                  .make()
                  .shimmer(),
              16.widthBox,
              VStack([
                VxBox()
                    .roundedLg
                    .color(colorScheme.surfaceContainerHighest)
                    .height(16)
                    .width(140)
                    .make()
                    .shimmer(),
                8.heightBox,
                VxBox()
                    .roundedLg
                    .color(colorScheme.surfaceContainerHighest)
                    .height(12)
                    .width(220)
                    .make()
                    .shimmer(),
              ]).expand(),
              16.widthBox,
            ],
          ),
        ),
      ]).p(AppSizes.paddingMedium),
    );
  }

  Widget _buildCardPlaceholder(BuildContext context, ColorScheme colorScheme) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          VxBox()
              .roundedFull
              .color(colorScheme.surfaceContainerHighest)
              .size(36, 36)
              .make()
              .shimmer(),
          AppSizes.paddingSmall.heightBox,
          VxBox()
              .roundedLg
              .color(colorScheme.surfaceContainerHighest)
              .height(24)
              .width(60)
              .make()
              .shimmer(),
          AppSizes.paddingSmall.heightBox,
          VxBox()
              .roundedLg
              .color(colorScheme.surfaceContainerHighest)
              .height(12)
              .width(90)
              .make()
              .shimmer(),
        ],
      ),
    );
  }
}
