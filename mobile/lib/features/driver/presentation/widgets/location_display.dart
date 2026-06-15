import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/l10n/driver/app_localizations.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/features/driver/application/driver_location_provider.dart';
import 'package:collegebus/shared/widgets/glass_card.dart';

class LocationDisplay extends ConsumerWidget {
  const LocationDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocation = ref.watch(
      driverLocationProvider.select((s) => s.currentLocation),
    );
    final hasLocation = currentLocation != null;
    final statusColor = hasLocation
        ? const Color(0xFF00C853) // Premium green
        : const Color(0xFFFF3D00); // Premium orange/red

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
      child: GlassCard(
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMedium,
          vertical: AppSizes.paddingSmall + 4,
        ),
        child: Row(
          children: [
            // Glowing status indicator dot
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.4),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                currentLocation != null
                    ? DriverLocalizations.of(context)!.yourLocationLabel(
                        currentLocation.latitude.toStringAsFixed(5),
                        currentLocation.longitude.toStringAsFixed(5),
                      )
                    : DriverLocalizations.of(context)!.locationNotAvailable,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ),
            if (currentLocation != null)
              Icon(
                Icons.gps_fixed,
                size: 16,
                color: Theme.of(context).primaryColor.withValues(alpha: 0.6),
              ),
          ],
        ),
      ),
    );
  }
}
