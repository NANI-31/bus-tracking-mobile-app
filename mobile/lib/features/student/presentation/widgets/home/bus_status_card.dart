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

    final liveLocation = busLocationAsync.valueOrNull;
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: context.isDarkMode
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: context.isDarkMode ? 0.08 : 0.05),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "ASSIGNED VEHICLE",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.directions_bus_filled_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        busNumber == '---' ? '---' : "Bus $busNumber",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: (isRunning ? Colors.green : colorScheme.onSurface)
                      .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PulsingDot(color: isRunning ? Colors.green : Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      status.isNotEmpty
                          ? status
                                .split(' ')
                                .map((s) => s[0].toUpperCase() + s.substring(1))
                                .join(' ')
                          : '',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: (isRunning ? Colors.green : colorScheme.onSurface)
                            .withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: colorScheme.onSurface.withValues(alpha: 0.08)),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ESTIMATED BOARDING TIME",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_filled_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          arrivalText,
                          style: const TextStyle(
                            fontSize: 20,
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
                      "ETA IN MINUTES",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        etaText,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
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

class _PulsingDot extends StatefulWidget {
  final Color color;

  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 14 * _controller.value,
              height: 14 * _controller.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 1.0 - _controller.value),
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
              ),
            ),
          ],
        );
      },
    );
  }
}

