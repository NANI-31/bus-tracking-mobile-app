import 'package:flutter/material.dart';
import 'package:collegebus/l10n/driver/app_localizations.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/models/route_model.dart';
import 'package:collegebus/utils/constants.dart';

class BusAssignmentCard extends StatelessWidget {
  final BusModel bus;
  final RouteModel? route;
  final VoidCallback onRemove;

  const BusAssignmentCard({
    super.key,
    required this.bus,
    required this.route,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: VStack([
        DriverLocalizations.of(
          context,
        )!.busLabel(bus.busNumber).text.size(18).semiBold.make(),
        AppSizes.paddingSmall.heightBox,
        if (route != null)
          VStack([
            DriverLocalizations.of(context)!
                .routeLabel(route!.routeName)
                .text
                .size(16)
                .color(
                  Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                )
                .make(),
            DriverLocalizations.of(context)!
                .routeTypeDetails(
                  route!.routeType.toUpperCase(),
                  route!.startPoint.name,
                  route!.endPoint.name,
                )
                .text
                .size(14)
                .color(
                  Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                )
                .maxLines(2)
                .ellipsis
                .make(),
          ]),
        AppSizes.paddingMedium.heightBox,
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onRemove,
            icon: const Icon(Icons.remove_circle),
            label: Text(
              DriverLocalizations.of(context)!.removeAssignmentButton,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
          ),
        ),
      ]).p(AppSizes.paddingMedium),
    );
  }
}
