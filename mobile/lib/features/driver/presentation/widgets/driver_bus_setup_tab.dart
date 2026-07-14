// driver_bus_setup_tab.dart
//
// Extracted from driver_dashboard.dart.
// Renders the "Bus Setup" tab — shows a pending-assignment card, the
// BusAssignmentCard for an accepted bus, or an empty-state illustration
// when no bus is assigned.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velocity_x/velocity_x.dart';

import 'package:collegebus/l10n/driver/app_localizations.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/features/route/domain/route_model.dart';
import 'package:collegebus/features/driver/application/driver_map_provider.dart';
import 'package:collegebus/shared/widgets/navigation/curved_bottom_nav_bar.dart';
import 'bus_assignment_card.dart';
import 'location_display.dart';


class DriverBusSetupTab extends ConsumerWidget {
  const DriverBusSetupTab({
    super.key,
    required this.myBus,
    required this.routesAsync,
    required this.busNumbersAsync,
    required this.onRemoveAssignment,
    required this.onRejectAssignment,
    required this.onAcceptAssignment,
  });

  final BusModel? myBus;
  final AsyncValue<List<RouteModel>> routesAsync;
  final AsyncValue<List<String>> busNumbersAsync;
  final VoidCallback onRemoveAssignment;
  final void Function(String busId) onRejectAssignment;
  final void Function(BusModel bus) onAcceptAssignment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (myBus != null && myBus!.assignmentStatus == 'pending') {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          children: [
            _buildPendingAssignmentUI(context),
            const BottomNavSpacer(),
          ],
        ),
      );
    }

    final designTheme =
        Theme.of(context).extension<DesignSystemThemeExtension>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      child: Column(
        children: [
          const LocationDisplay(),
          if (myBus == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.paddingLarge),
              decoration:
                  designTheme?.cardDecoration ??
                  BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.08),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).disabledColor.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.assignment_ind_outlined,
                      size: 56,
                      color: Theme.of(
                        context,
                      ).disabledColor.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Assignments Yet',
                    style:
                        designTheme?.cardHeaderStyle ??
                        TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You are not currently assigned to any bus or route. '
                    'Please contact your administrator or bus coordinator '
                    'to receive an assignment.',
                    textAlign: TextAlign.center,
                    style:
                        designTheme?.cardBodyStyle ??
                        TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            )
          else
            BusAssignmentCard(
              bus: myBus!,
              route: ref.watch(
                driverMapStateProvider.select((s) => s.selectedRoute),
              ),
              onRemove: onRemoveAssignment,
            ),
          const BottomNavSpacer(),
        ],
      ),
    );
  }

  Widget _buildPendingAssignmentUI(BuildContext context) {
    final bus = myBus!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final gradientColors = isDark
        ? [const Color(0xFF2E3192), const Color(0xFF1BFFFF)]
        : [const Color(0xFF667EEA), const Color(0xFF764BA2)];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: CircleAvatar(
              radius: 80,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          VStack([
            HStack([
              const Icon(
                Icons.directions_bus_filled_rounded,
                color: Colors.white,
                size: 28,
              ),
              12.widthBox,
              'New Trip Assignment'.text.white.xl.bold.make(),
            ]).pOnly(bottom: 24),

            'Bus Number'.text.white.make().opacity(value: 0.8),
            bus.busNumber.text.xl6.white.bold.make().pOnly(bottom: 32),

            HStack([
              OutlinedButton(
                onPressed: () => onRejectAssignment(bus.id),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: DriverLocalizations.of(context)!.declineButton.text.make(),
              ).expand(),

              16.widthBox,

              ElevatedButton(
                onPressed: () => onAcceptAssignment(bus),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: gradientColors.first,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: 'START TRIP'.text.bold.make(),
              ).expand(),
            ]),
          ]).p(24),
        ],
      ),
    );
  }
}

