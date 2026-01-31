import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';

class NotificationCard extends StatelessWidget {
  final String title;
  final String description;
  final String time;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final bool isUnread;

  const NotificationCard({
    super.key,
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.isUnread,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isUnread
            ? Border.all(color: iconColor.withValues(alpha: 0.3), width: 1.5)
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          16.widthBox,
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  title.text.bold.size(16).color(colorScheme.onSurface).make(),
                  time.text
                      .size(12)
                      .color(colorScheme.onSurface.withValues(alpha: 0.5))
                      .make(),
                ],
              ),
              4.heightBox,
              description.text
                  .size(14)
                  .color(colorScheme.onSurface.withValues(alpha: 0.7))
                  .make(),
            ],
          ).expand(),
          if (isUnread)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(left: 8, top: 8),
              decoration: BoxDecoration(
                color: iconColor,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
