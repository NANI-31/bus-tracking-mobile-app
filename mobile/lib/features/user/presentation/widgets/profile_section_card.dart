import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';

class ProfileSectionCard extends StatelessWidget {
  final List<Widget> children;
  final String? title;

  const ProfileSectionCard({super.key, required this.children, this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return VStack([
      if (title != null)
        title!.text
            .size(12)
            .semiBold
            .uppercase
            .letterSpacing(1.5)
            .color(
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            )
            .make()
            .pOnly(bottom: 10, left: 8),
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1A222D).withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: VStack(children),
        ),
      ),
    ]);
  }
}

