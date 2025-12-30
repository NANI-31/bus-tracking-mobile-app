import 'package:flutter/material.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/services/data_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class BusStatusCard extends StatelessWidget {
  final BusModel? bus;
  final String? userStop;
  final Map<String, double>? stopLocation;

  const BusStatusCard({super.key, this.bus, this.userStop, this.stopLocation});

  String _calculateETA(LatLng busLoc, Map<String, double> stopLoc) {
    final distance = Geolocator.distanceBetween(
      busLoc.latitude,
      busLoc.longitude,
      stopLoc['lat']!,
      stopLoc['lng']!,
    );

    if (distance < 100) return "Arrived";

    // Assume average speed 15 km/h = 4.16 m/s
    final minutes = (distance / 4.16) / 60;

    if (minutes < 1) return "Less than 1 min";
    return "${minutes.round()} mins";
  }

  String _getExpectedTime(LatLng busLoc, Map<String, double> stopLoc) {
    final distance = Geolocator.distanceBetween(
      busLoc.latitude,
      busLoc.longitude,
      stopLoc['lat']!,
      stopLoc['lng']!,
    );
    final minutes = (distance / 4.16) / 60;
    final arrivalTime = DateTime.now().add(Duration(minutes: minutes.round()));
    return DateFormat('h:mm a').format(arrivalTime);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dataService = Provider.of<DataService>(context, listen: false);
    final busNumber = bus?.busNumber ?? '---';
    final status = bus?.status ?? 'Not Running';
    final isRunning = bus?.status == 'running';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: StreamBuilder<BusLocationModel?>(
        stream: bus != null
            ? dataService.getBusLocation(bus!.id)
            : Stream.value(null),
        builder: (context, snapshot) {
          final liveLocation = snapshot.data;
          String arrivalText = "Not Started";
          String etaText = "---";

          if (isRunning && liveLocation != null && stopLocation != null) {
            etaText = _calculateETA(
              liveLocation.currentLocation,
              stopLocation!,
            );
            arrivalText = (etaText == "Arrived")
                ? "Now"
                : _getExpectedTime(liveLocation.currentLocation, stopLocation!);
          } else if (isRunning) {
            arrivalText = "Calculating...";
          }

          return VStack([
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
                  busNumber.text
                      .size(32)
                      .bold
                      .color(colorScheme.onSurface)
                      .make(),
                ]),
              ]).expand(),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: (isRunning ? Colors.green : colorScheme.onSurface)
                      .withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: HStack([
                  Icon(
                    Icons.circle,
                    size: 10,
                    color: isRunning
                        ? Colors.greenAccent
                        : colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  8.widthBox,
                  status
                      .allWordsCapitilize()
                      .text
                      .bold
                      .color(
                        (isRunning ? Colors.green : colorScheme.onSurface)
                            .withValues(alpha: 0.7),
                      )
                      .make(),
                ]),
              ),
            ]),

            8.heightBox,
            Divider(color: colorScheme.onSurface.withValues(alpha: 0.2)),
            8.heightBox,

            HStack([
              VStack([
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
                  arrivalText.text
                      .size(22)
                      .extraBold
                      .color(AppColors.primary)
                      .make(),
                ]),
              ]).expand(),

              if (isRunning && etaText != "---")
                VStack([
                  "REMAINING".text
                      .size(8)
                      .bold
                      .letterSpacing(1.2)
                      .color(colorScheme.onSurface.withValues(alpha: 0.5))
                      .make(),
                  8.heightBox,
                  etaText.text
                      .size(16)
                      .bold
                      .color(colorScheme.onSurface)
                      .make(),
                ], crossAlignment: CrossAxisAlignment.end),
            ]),
          ]);
        },
      ),
    );
  }
}
