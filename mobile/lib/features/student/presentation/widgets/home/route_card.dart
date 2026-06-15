import 'package:flutter/material.dart';
import 'timeline_item.dart';

import 'package:collegebus/features/route/domain/route_model.dart';
import 'package:collegebus/core/constants/constants.dart';

class RouteCard extends StatelessWidget {
  final RouteModel? route;
  final String? userStop;

  const RouteCard({super.key, this.route, this.userStop});

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
          color: colorScheme.onSurface.withValues(alpha: context.isDarkMode ? 0.08 : 0.05),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

          // Vertical Timeline
          if (route != null)
            Column(
              children: [
                // Start
                TimelineItem(
                  title: "START",
                  location: route!.startPoint.name,
                  subtext: null,
                  isActive: route!.startPoint.name == userStop,
                  isLast: false,
                ),

                // User Stop (if intermediate)
                if (userStop != null &&
                    userStop != route!.startPoint.name &&
                    userStop != route!.endPoint.name)
                  TimelineItem(
                    title: "YOUR STOP",
                    location: userStop!,
                    subtext: "Assigned Boarding Stop",
                    isActive: true,
                    isLast: false,
                  ),

                // End
                TimelineItem(
                  title: "DESTINATION",
                  location: route!.endPoint.name,
                  subtext: null,
                  isActive: route!.endPoint.name == userStop,
                  isLast: true,
                ),
              ],
            )
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

  void _showFullRouteSheet(BuildContext context) {
    if (route == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Full Route Details",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: route!.stopPoints.length + 2,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return TimelineItem(
                      title: "START",
                      location: route!.startPoint.name,
                      isActive: route!.startPoint.name == userStop,
                      isLast: false,
                    );
                  } else if (index == route!.stopPoints.length + 1) {
                    return TimelineItem(
                      title: "DESTINATION",
                      location: route!.endPoint.name,
                      isActive: route!.endPoint.name == userStop,
                      isLast: true,
                    );
                  } else {
                    final stop = route!.stopPoints[index - 1];
                    return TimelineItem(
                      title: "STOP",
                      location: stop.name,
                      isActive: stop.name == userStop,
                      isLast: false,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
