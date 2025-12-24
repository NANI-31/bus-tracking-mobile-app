import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';

class WelcomeSection extends StatelessWidget {
  final String userName;

  const WelcomeSection({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return VStack([
      "Good Morning, $userName".text
          .size(32)
          .extraBlack
          .color(colorScheme.onSurface)
          .make(),
      2.heightBox,
      "Your bus status for today".text
          .size(16)
          .color(colorScheme.onSurface.withValues(alpha: 0.7))
          .make(),
    ]);
  }
}
