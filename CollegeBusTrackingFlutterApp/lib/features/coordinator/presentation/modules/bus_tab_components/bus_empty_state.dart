import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/l10n/coordinator/app_localizations.dart'
    as coord_l10n;

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
    final l10n = coord_l10n.CoordinatorLocalizations.of(context)!;
    return VStack(
      [
        Icon(
          isSearching ? Icons.search_off : Icons.directions_bus_outlined,
          size: 64,
          color: context.colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        AppSizes.paddingMedium.heightBox,
        (isSearching
                ? l10n.noBusesFoundMatching(searchQuery)
                : l10n.noBusesFound)
            .text
            .size(16)
            .color(context.colorScheme.onSurface.withValues(alpha: 0.6))
            .make(),
        if (!isSearching) ...[
          AppSizes.paddingSmall.heightBox,
          l10n.addBusPrompt.text
              .size(14)
              .color(context.colorScheme.onSurface.withValues(alpha: 0.4))
              .center
              .make(),
        ],
      ],
      alignment: MainAxisAlignment.center,
      crossAlignment: CrossAxisAlignment.center,
    ).centered();
  }
}
