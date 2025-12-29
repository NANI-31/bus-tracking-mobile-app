import 'package:flutter/material.dart';
import 'package:collegebus/l10n/driver/app_localizations.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationDisplay extends StatelessWidget {
  final LatLng? currentLocation;

  const LocationDisplay({super.key, required this.currentLocation});

  @override
  Widget build(BuildContext context) {
    final hasLocation = currentLocation != null;
    final color = hasLocation
        ? Theme.of(context).primaryColor
        : Theme.of(context).colorScheme.error;

    return HStack([
      Icon(Icons.location_on, color: color),
      AppSizes.paddingSmall.widthBox,
      (hasLocation
              ? DriverLocalizations.of(context)!.yourLocationLabel(
                  currentLocation!.latitude.toStringAsFixed(4),
                  currentLocation!.longitude.toStringAsFixed(4),
                )
              : DriverLocalizations.of(context)!.locationNotAvailable)
          .text
          .color(color)
          .medium
          .make()
          .expand(),
    ]).p(AppSizes.paddingMedium).box.color(color.withValues(alpha: 0.1)).make();
  }
}
