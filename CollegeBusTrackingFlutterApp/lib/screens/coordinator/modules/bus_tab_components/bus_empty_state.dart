import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/utils/constants.dart';

class BusEmptyState extends StatelessWidget {
  final bool isSearching;
  final String searchQuery;

  const BusEmptyState({
    super.key,
    required this.isSearching,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return VStack(
      [
        Icon(
          isSearching ? Icons.search_off : Icons.directions_bus_outlined,
          size: 64,
          color: AppColors.textSecondary,
        ),
        AppSizes.paddingMedium.heightBox,
        (isSearching
                ? 'No buses found matching "$searchQuery"'
                : 'No buses found')
            .text
            .size(16)
            .color(AppColors.textSecondary)
            .make(),
        if (!isSearching) ...[
          AppSizes.paddingSmall.heightBox,
          'Add bus numbers for drivers to select'.text
              .size(14)
              .color(AppColors.textSecondary)
              .center
              .make(),
        ],
      ],
      alignment: MainAxisAlignment.center,
      crossAlignment: CrossAxisAlignment.center,
    ).centered();
  }
}
