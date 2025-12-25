import 'package:flutter/material.dart';
import 'package:collegebus/utils/constants.dart';
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
    this.isUnread = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isUnread
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: HStack([
        // Icon
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 26),
        ),

        20.widthBox,

        // Content
        VStack([
          HStack([
            title.text.lg.bold.color(colorScheme.onSurface).make().expand(),
            HStack([
              time.text.size(12).color(_getTimeColor(context)).make(),
              if (isUnread) ...[
                8.widthBox,
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ]),
          ]),

          6.heightBox,

          description.text
              .color(colorScheme.onSurface.withValues(alpha: 0.6))
              .lineHeight(1.4)
              .make(),
        ]).expand(),
      ], crossAlignment: CrossAxisAlignment.start),
    );
  }

  Color _getTimeColor(BuildContext context) {
    if (isUnread) return AppColors.primary;
    return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);
  }
}
