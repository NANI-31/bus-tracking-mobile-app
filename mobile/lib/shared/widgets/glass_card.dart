import 'dart:ui';
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

  const GlassCard({
    super.key,
    required this.child,
    this.sigmaX = 12.0,
    this.sigmaY = 12.0,
    this.width,
    this.height,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final designTheme = Theme.of(context).extension<DesignSystemThemeExtension>();
    final baseDecoration = designTheme?.glassDecoration ?? BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.black.withValues(alpha: 0.6)
          : Colors.white.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.3),
        width: 1.5,
      ),
    );

    // Apply custom border radius if specified
    final decoration = baseDecoration.copyWith(
      borderRadius: borderRadius != null ? BorderRadius.circular(borderRadius!) : baseDecoration.borderRadius,
    );

    return ClipRRect(
      borderRadius: decoration.borderRadius as BorderRadius? ?? BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: decoration,
          child: child,
        ),
      ),
    );
  }
}
