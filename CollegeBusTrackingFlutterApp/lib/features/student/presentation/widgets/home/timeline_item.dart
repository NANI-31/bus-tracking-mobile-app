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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.radio_button_checked : Icons.circle,
              size: 24,
              color: isActive
                  ? AppColors.primary
                  : colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            if (!isLast)
              Padding(
                padding: const EdgeInsets.only(left: 0), // Centered under icon
                child: Container(
                  width: 2.0,
                  height: 40,
                  color: colorScheme.onSurface.withValues(alpha: 0.1),
                ),
              ),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: isActive
                        ? AppColors.primary
                        : colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  location,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (subtext != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtext!,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
