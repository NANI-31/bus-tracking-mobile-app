import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';

class ProfileSectionCard extends StatelessWidget {
  final List<Widget> children;
  final String? title;

  const ProfileSectionCard({super.key, required this.children, this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return VStack([
      if (title != null)
        title!.text
            .size(12)
            .semiBold
            .uppercase
            .letterSpacing(1.5)
            .color(
              colorScheme.onSurface.withValues(alpha: 0.5),
            )
            .make()
            .pOnly(bottom: 10, left: 8),
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: isDark ? 0.08 : 0.04),
              blurRadius: 20,
              spreadRadius: -4,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surface.withValues(alpha: 0.45)
                    : colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                  width: 1.0,
                ),
              ),
              child: VStack(children),
            ),
          ),
        ),
      ),
    ]);
  }
}
