import 'package:flutter/material.dart';
import 'timeline_item.dart';

import 'package:collegebus/features/route/domain/route_model.dart';
import 'package:collegebus/core/constants/constants.dart';

class RouteCard extends StatelessWidget {
  final RouteModel? route;
  final String? userStop;

  /// 'pickup' or 'drop' — controls stop display order and start/end dot colors.
  final String? tripType;

  const RouteCard({super.key, this.route, this.userStop, this.tripType});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final routeName = route?.routeName ?? 'No Route Assigned';

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
          color: colorScheme.onSurface
              .withValues(alpha: context.isDarkMode ? 0.08 : 0.05),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "CURRENT ROUTE",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      routeName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (route != null)
                TextButton.icon(
                  onPressed: () => _showFullRouteSheet(context),
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 10),
                  label: const Text(
                    "View Full",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.alt_route_rounded,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Vertical Timeline — order and colors respect tripType
          if (route != null)
            _buildTimeline(context)
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.location_off_rounded,
                      size: 40,
                      color: colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Please select a bus stop in profile to see your route details.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeline(BuildContext context) {
    final isPickup = tripType != 'drop';
    final ordered = route!.getOrderedStops(tripType);
    if (ordered.isEmpty) return const SizedBox.shrink();

    final firstPt = ordered.first;
    final lastPt = ordered.last;

    return Column(
      children: [
        // First stop — green dot
        TimelineItem(
          title: isPickup ? 'START' : 'DROP START',
          location: firstPt.name,
          isActive: firstPt.name == userStop,
          isLast: false,
          dotColor: AppColors.success,
        ),

        // User's preferred stop (if it's not the first or last)
        if (userStop != null &&
            userStop != firstPt.name &&
            userStop != lastPt.name)
          TimelineItem(
            title: 'YOUR STOP',
            location: userStop!,
            subtext: 'Assigned Boarding Stop',
            isActive: true,
            isLast: false,
          ),

        // Last stop — red dot
        TimelineItem(
          title: isPickup ? 'DESTINATION' : 'DROP END',
          location: lastPt.name,
          isActive: lastPt.name == userStop,
          isLast: true,
          dotColor: AppColors.danger,
        ),
      ],
    );
  }

  void _showFullRouteSheet(BuildContext context) {
    if (route == null) return;

    final isPickup = tripType != 'drop';
    final ordered = route!.getOrderedStops(tripType);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(ctx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Full Route Details",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      // Trip direction badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isPickup ? AppColors.success : Colors.orange)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isPickup
                              ? 'PICKUP — Stops → College'
                              : 'DROP — College → Stops',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color:
                                isPickup ? AppColors.success : Colors.orange,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx2, index) {
                        final stop = ordered[index];
                        final isFirst = index == 0;
                        final isLast = index == ordered.length - 1;

                        final String title;
                        final Color? dotColor;

                        if (isFirst) {
                          title = isPickup ? 'START' : 'DROP START';
                          dotColor = AppColors.success;
                        } else if (isLast) {
                          title = isPickup ? 'DESTINATION' : 'DROP END';
                          dotColor = AppColors.danger;
                        } else {
                          title = 'STOP $index';
                          dotColor = Colors.orange;
                        }

                        return TimelineItem(
                          title: title,
                          location: stop.name,
                          isActive: stop.name == userStop,
                          isLast: isLast,
                          dotColor: dotColor,
                        );
                      },
                      childCount: ordered.length,
                    ),
                  ),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }
}
