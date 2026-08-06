import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:collegebus/core/constants/constants.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double sigmaX;
  final double sigmaY;
  final double? width;
  final double? height;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  const GlassCard({
    super.key,
    required this.child,
    this.sigmaX = 12.0,
    this.sigmaY = 12.0,
    this.width,
    this.height,
    this.borderRadius,
    this.padding,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final designTheme = Theme.of(
      context,
    ).extension<DesignSystemThemeExtension>();
    final baseDecoration =
        designTheme?.glassDecoration ??
        BoxDecoration(
          color: isDark
              ? Colors.black.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.35),
            width: 1.5,
          ),
        );

    final effectiveRadius = BorderRadius.circular(borderRadius ?? 24.0);
    final effectiveColor = color ?? baseDecoration.color;
    final effectiveBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.15);

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          // Glass blur and fill clipped inside effectiveRadius
          Positioned.fill(
            child: ClipRRect(
              borderRadius: effectiveRadius,
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
                child: Container(color: effectiveColor),
              ),
            ),
          ),
          // Normal border overlay (unclipped so corners render correctly)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: effectiveRadius,
                  border: Border.all(color: effectiveBorderColor, width: 1.5),
                ),
              ),
            ),
          ),
          // Content (non-positioned so Stack sizes to child)
          Padding(padding: padding ?? EdgeInsets.zero, child: child),
        ],
      ),
    );
  }
}
