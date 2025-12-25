import 'package:flutter/material.dart';
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
              ? 'Your Location: ${currentLocation!.latitude.toStringAsFixed(4)}, ${currentLocation!.longitude.toStringAsFixed(4)}'
              : 'Location not available. Please enable location services.')
          .text
          .color(color)
          .medium
          .make()
          .expand(),
    ]).p(AppSizes.paddingMedium).box.color(color.withValues(alpha: 0.1)).make();
  }
}
