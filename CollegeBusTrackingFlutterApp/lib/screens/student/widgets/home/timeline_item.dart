import 'package:flutter/material.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:velocity_x/velocity_x.dart';

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
    return HStack([
      VStack([
        Icon(
          isActive ? Icons.radio_button_checked : Icons.circle,
          size: 24,
          color: isActive
              ? AppColors.primary
              : colorScheme.onSurface.withValues(alpha: 0.2),
        ),
        if (!isLast)
          Container(
            width: 2,
            height: 40,
            color: colorScheme.onSurface.withValues(alpha: 0.1),
          ).pOnly(left: 11),
      ], crossAlignment: CrossAxisAlignment.center),

      20.widthBox,

      VStack([
        title.text
            .size(12)
            .bold
            .letterSpacing(1)
            .color(
              isActive
                  ? AppColors.primary
                  : colorScheme.onSurface.withValues(alpha: 0.4),
            )
            .make(),
        4.heightBox,
        location.text.size(17).bold.color(colorScheme.onSurface).make(),
        if (subtext != null)
          subtext!.text
              .size(13)
              .color(colorScheme.onSurface.withValues(alpha: 0.6))
              .make()
              .pOnly(top: 2),
      ]).pOnly(bottom: isLast ? 0 : 20),
    ], crossAlignment: CrossAxisAlignment.start);
  }
}
