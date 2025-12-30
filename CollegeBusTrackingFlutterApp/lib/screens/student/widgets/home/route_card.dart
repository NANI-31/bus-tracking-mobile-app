import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'timeline_item.dart';

import 'package:collegebus/models/route_model.dart';
import 'package:collegebus/utils/constants.dart';

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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: VStack([
        HStack([
          VStack([
            "CURRENT ROUTE".text
                .size(13)
                .bold
                .letterSpacing(1.2)
                .color(colorScheme.onSurface.withValues(alpha: 0.5))
                .make(),
            4.heightBox,
            routeName.text.xl2.bold.color(colorScheme.onSurface).make(),
          ]).expand(),
          if (route != null)
            TextButton(
              onPressed: () => _showFullRouteSheet(context),
              child: "View Full".text.color(AppColors.primary).semiBold.make(),
            ),
          12.widthBox,
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
        ]),

        24.heightBox,

        // Vertical Timeline
        if (route != null)
          VStack([
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
          ])
        else
          "Please select a bus stop in profile to see your route details."
              .text
              .italic
              .center
              .color(colorScheme.onSurface.withValues(alpha: 0.5))
              .make()
              .centered(),
      ]),
    );
  }

  void _showFullRouteSheet(BuildContext context) {
    if (route == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: context.percentHeight * 80,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: VStack([
          HStack([
            "Full Route Details".text.xl2.bold.make().expand(),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(context),
            ),
          ]),
          20.heightBox,
          VStack([
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
          ]).scrollVertical().expand(),
        ]),
      ),
    );
  }
}
