import 'package:flutter/material.dart';
import 'package:collegebus/l10n/driver/app_localizations.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/models/route_model.dart';
import 'package:collegebus/widgets/custom_button.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LiveTrackingControlPanel extends StatelessWidget {
  final BusModel? bus;
  final RouteModel? route;
  final bool isSharing;
  final LatLng? currentLocation;
  final VoidCallback onToggleSharing;

  const LiveTrackingControlPanel({
    super.key,
    required this.bus,
    required this.route,
    required this.isSharing,
    required this.currentLocation,
    required this.onToggleSharing,
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
                  .color(AppColors.textPrimary)
                  .make(),
              AppSizes.paddingSmall.heightBox,
              if (route != null)
                VStack([
                  DriverLocalizations.of(context)!
                      .routeLabel(route!.routeName)
                      .text
                      .size(16)
                      .color(AppColors.textSecondary)
                      .make(),
                  DriverLocalizations.of(context)!
                      .routeTypeDetails(
                        route!.routeType.toUpperCase(),
                        route!.startPoint.name,
                        route!.endPoint.name,
                      )
                      .text
                      .size(14)
                      .color(AppColors.textSecondary)
                      .maxLines(2)
                      .ellipsis
                      .make(),
                ]),
              AppSizes.paddingMedium.heightBox,
            ]),
          CustomButton(
            text: isSharing
                ? DriverLocalizations.of(context)!.stopSharingLocation
                : DriverLocalizations.of(context)!.startSharingLocation,
            onPressed: onToggleSharing,
            backgroundColor: isSharing
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.secondary,
            icon: Icon(
              isSharing ? Icons.stop : Icons.play_arrow,
              color: isSharing
                  ? Theme.of(context).colorScheme.onError
                  : Theme.of(context).colorScheme.onSecondary,
            ),
          ),
          if (isSharing) _buildSharingStatus(context),
        ])
        .p(AppSizes.paddingMedium)
        .box
        .color(Theme.of(context).colorScheme.surface)
        .topRounded(value: AppSizes.radiusLarge)
        .make();
  }

  Widget _buildSharingStatus(BuildContext context) {
    return HStack([
          Icon(Icons.location_on, color: AppColors.success),
          AppSizes.paddingMedium.widthBox,
          VStack([
            DriverLocalizations.of(
              context,
            )!.sharingStatusMessage.text.color(AppColors.success).medium.make(),
            if (currentLocation != null)
              VStack([
                4.heightBox,
                DriverLocalizations.of(context)!
                    .currentLocationStats(
                      currentLocation!.latitude.toStringAsFixed(4),
                      currentLocation!.longitude.toStringAsFixed(4),
                    )
                    .text
                    .size(12)
                    .color(AppColors.success)
                    .make(),
              ]),
          ]).expand(),
        ])
        .p(AppSizes.paddingMedium)
        .box
        .color(AppColors.success.withValues(alpha: 0.1))
        .withRounded(value: AppSizes.radiusMedium)
        .make()
        .pOnly(top: AppSizes.paddingMedium);
  }
}
