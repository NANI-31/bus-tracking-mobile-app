import 'package:flutter/material.dart';
import 'package:collegebus/l10n/driver/app_localizations.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/features/route/domain/route_model.dart';
import 'package:collegebus/shared/widgets/custom_button.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LiveTrackingControlPanel extends StatelessWidget {
  final BusModel? bus;
  final RouteModel? route;
  final bool isSharing;
  final LatLng? currentLocation;
  final VoidCallback onToggleSharing;
  final VoidCallback? onCompleteTrip;

  const LiveTrackingControlPanel({
    super.key,
    required this.bus,
    required this.route,
    required this.isSharing,
    required this.currentLocation,
    required this.onToggleSharing,
    this.onCompleteTrip,
  });

  @override
  Widget build(BuildContext context) {
    return VStack([
          if (bus != null)
            VStack([
              DriverLocalizations.of(context)!
                  .busHeader(bus!.busNumber)
                  .text
                  .size(20)
                  .bold
                  .color(Theme.of(context).colorScheme.onSurface)
                  .make(),
              AppSizes.paddingSmall.heightBox,
              if (route != null)
                VStack([
                  DriverLocalizations.of(context)!
                      .routeLabel(route!.routeName)
                      .text
                      .size(16)
                      .color(
                        context.colorScheme.onSurface.withValues(alpha: 0.6),
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
                        context.colorScheme.onSurface.withValues(alpha: 0.6),
                      )
                      .maxLines(2)
                      .ellipsis
                      .make(),
                ]),
              AppSizes.paddingMedium.heightBox,
            ]),
          if (isSharing)
            HStack([
              CustomButton(
                text: 'STOP',
                onPressed: onToggleSharing,
                backgroundColor: Theme.of(context).colorScheme.error,
                icon: Icon(
                  Icons.stop,
                  color: Theme.of(context).colorScheme.onError,
                ),
              ).expand(),
              12.widthBox,
              CustomButton(
                text: 'TRIP COMPLETE',
                onPressed: onCompleteTrip,
                backgroundColor: AppColors.success,
                textColor: Colors.white,
                icon: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                ),
              ).expand(),
            ])
          else
            CustomButton(
              text: DriverLocalizations.of(context)!.startSharingLocation,
              onPressed: onToggleSharing,
              backgroundColor: Theme.of(context).colorScheme.secondary,
              icon: Icon(
                Icons.play_arrow,
                color: Theme.of(context).colorScheme.onSecondary,
              ),
            ),
        ])
        .p(AppSizes.paddingMedium)
        .box
        .color(Theme.of(context).colorScheme.surface)
        .topRounded(value: AppSizes.radiusLarge)
        .make();
  }
}
