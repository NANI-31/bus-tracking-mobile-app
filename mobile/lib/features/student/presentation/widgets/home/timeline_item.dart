import 'package:flutter/material.dart';
import 'package:collegebus/core/constants/constants.dart';

class TimelineItem extends StatelessWidget {
  final String title;
  final String location;
  final String? subtext;
  final bool isActive;
  final bool isLast;

  const TimelineItem({
    super.key,
    required this.title,
    required this.location,
    this.subtext,
    this.isActive = false,
    this.isLast = false,
  });

  IconData _getIconData() {
    final t = title.toUpperCase();
    if (t == "START") {
      return Icons.trip_origin_rounded;
    }
    if (t == "DESTINATION") {
      return Icons.school_rounded;
    }
    if (t == "YOUR STOP") {
      return Icons.my_location_rounded;
    }
    return Icons.location_on_rounded;
  }

  Color _getIconColor(ColorScheme colorScheme) {
    if (isActive) {
      final t = title.toUpperCase();
      if (t == "START") return Colors.green;
      if (t == "DESTINATION") return AppColors.primary;
      return AppColors.amberAccent;
    }
    return colorScheme.onSurface.withValues(alpha: 0.35);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = _getIconColor(colorScheme);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withValues(alpha: 0.1),
                border: Border.all(
                  color: iconColor.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Icon(
                  _getIconData(),
                  size: 16,
                  color: iconColor,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2.0,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      iconColor.withValues(alpha: 0.3),
                      colorScheme.onSurface.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: isActive
                            ? AppColors.primary
                            : colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "ACTIVE",
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  location,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (subtext != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtext!,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
