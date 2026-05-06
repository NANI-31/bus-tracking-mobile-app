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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "CURRENT ROUTE",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      routeName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              if (route != null)
                TextButton(
                  onPressed: () => _showFullRouteSheet(context),
                  child: const Text(
                    "View Full",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.alt_route_rounded,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
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
                    subtext: "Assigned Stop",
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
            Center(
              child: Text(
                "Please select a bus stop in profile to see your route details.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: context.colorScheme.onSurface.withValues(alpha: 0.4),
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
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Start Point
                    TimelineItem(
                      title: "START",
                      location: route!.startPoint.name,
                      isActive: route!.startPoint.name == userStop,
                      isLast: false,
                    ),

                    // All Intermediate Stops
                    ...route!.stopPoints.map(
                      (stop) => TimelineItem(
                        title: "STOP",
                        location: stop.name,
                        isActive: stop.name == userStop,
                        isLast: false,
                      ),
                    ),

                    // End Point
                    TimelineItem(
                      title: "DESTINATION",
                      location: route!.endPoint.name,
                      isActive: route!.endPoint.name == userStop,
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
