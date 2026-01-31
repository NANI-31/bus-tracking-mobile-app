import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';

class ProfileSectionCard extends StatelessWidget {
  final List<Widget> children;
  final String? title;

  const ProfileSectionCard({super.key, required this.children, this.title});

  @override
  Widget build(BuildContext context) {
    return VStack([
      if (title != null)
        title!.text
            .size(14)
            .bold
            .uppercase
            .letterSpacing(1.2)
            .color(
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            )
            .make()
            .pOnly(bottom: 12, left: 4),
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: VStack(children),
      ),
    ]);
  }
}
