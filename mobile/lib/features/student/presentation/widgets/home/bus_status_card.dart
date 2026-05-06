import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/bus/application/bus_provider.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class BusStatusCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final busNumber = bus?.busNumber ?? '---';
    final status = bus?.status ?? 'Not Running';
    final isRunning = bus?.status == 'running';

    final busLocationAsync = bus != null
        ? ref.watch(busLocationProvider(bus!.id))
        : const AsyncValue<BusLocationModel?>.data(null);

    final liveLocation = busLocationAsync.value;
    String arrivalText = "Not Started";
    String etaText = "---";

    if (isRunning && liveLocation != null && stopLocation != null) {
      etaText = _calculateETA(liveLocation.currentLocation, stopLocation!);
      arrivalText = (etaText == "Arrived")
          ? "Now"
          : _getExpectedTime(liveLocation.currentLocation, stopLocation!);
    } else if (isRunning) {
      arrivalText = "Calculating...";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: context.isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
        border: context.isDarkMode
            ? Border.all(
                color: context.colorScheme.onSurface.withValues(alpha: 0.1),
              )
            : null,
      ),
      child: Column(
        children: [
          // Header Section
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "BUS NUMBER",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.directions_bus_filled_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          busNumber,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

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
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 10,
                      color: isRunning
                          ? Colors.greenAccent
                          : colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      status.isNotEmpty
                          ? status
                                .split(' ')
                                .map((s) => s[0].toUpperCase() + s.substring(1))
                                .join(' ')
                          : '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            (isRunning ? Colors.green : colorScheme.onSurface)
                                .withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          Divider(color: colorScheme.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ESTIMATED ARRIVAL",
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_filled_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          arrivalText,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (isRunning && etaText != "---")
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "REMAINING",
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      etaText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
