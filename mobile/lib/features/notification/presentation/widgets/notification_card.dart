import 'dart:ui' as ui;
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
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const NotificationCard({
    super.key,
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.isUnread,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: (isUnread ? iconColor : colorScheme.primary).withValues(alpha: isDark ? 0.12 : 0.08),
              blurRadius: 16,
              spreadRadius: -2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surface.withValues(alpha: 0.45)
                    : colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (isUnread ? iconColor : colorScheme.primary).withValues(alpha: isDark ? 0.25 : 0.15),
                  width: 1.0,
                ),
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
                    title.text.bold
                        .size(16)
                        .color(colorScheme.onSurface)
                        .make(),
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
            if (onDelete != null)
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            if (isUnread)
              Container(
                width: 8.0,
                height: 8,
                margin: const EdgeInsets.only(left: 8, top: 8),
                decoration: BoxDecoration(
                  color: iconColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    ),
  ),
),
);
  }
}
