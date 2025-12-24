import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'timeline_item.dart';

class RouteCard extends StatelessWidget {
  const RouteCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
            "North Campus Express".text.xl2.bold
                .color(colorScheme.onSurface)
                .make(),
          ]).expand(),
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
        VStack([
          // Your Stop
          const TimelineItem(
            title: "YOUR STOP",
            location: "Maple Ave Junction",
            subtext: "Pick up in 15 mins",
            isActive: true,
            isLast: false,
          ),

          // Next Stop
          const TimelineItem(
            title: "NEXT STOP",
            location: "Central Library",
            subtext: null,
            isActive: false,
            isLast: true,
          ),
        ]),
      ]),
    );
  }
}
