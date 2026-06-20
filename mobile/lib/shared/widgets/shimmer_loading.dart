import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class Shimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const Shimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
  });

  static ShimmerState? of(BuildContext context) {
    return context.findAncestorStateOfType<ShimmerState>();
  }

  @override
  State<Shimmer> createState() => ShimmerState();
}

class ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  Listenable get shiftAnimation => _controller;

  double get value => _controller.value;
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent - 0.5) * 2, 0.0, 0.0);
  }
}

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxShape shape;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.shape = BoxShape.rectangle,
  });

  const SkeletonBox.circle({
    super.key,
    double? size,
  })  : width = size,
        height = size,
        borderRadius = 0,
        shape = BoxShape.circle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Premium Glassmorphic colors for skeleton placeholders with a glowing ice-cyan tint
    final baseColor = isDark
        ? const Color(0xFF0F172A).withValues(alpha: 0.35)
        : Colors.white.withValues(alpha: 0.30);
    final highlightColor = isDark
        ? const Color(0xFF00C6E6).withValues(alpha: 0.22)
        : const Color(0xFFE0F7FA).withValues(alpha: 0.60);

    final border = shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius);

    final shimmer = Shimmer.of(context);
    if (shimmer == null) {
      final Widget baseBox = Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          shape: shape,
          borderRadius: border,
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.05 : 0.08),
            width: 0.8,
          ),
        ),
      );
      if (shape == BoxShape.circle) {
        return ClipOval(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
            child: baseBox,
          ),
        );
      } else {
        return ClipRRect(
          borderRadius: border ?? BorderRadius.zero,
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
            child: baseBox,
          ),
        );
      }
    }

    return AnimatedBuilder(
      animation: shimmer.shiftAnimation,
      builder: (context, child) {
        final Widget containerWidget = Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            shape: shape,
            borderRadius: border,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.1, 0.5, 0.9],
              transform: _SlidingGradientTransform(slidePercent: shimmer.value),
            ),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.05 : 0.08),
              width: 0.8,
            ),
          ),
        );

        if (shape == BoxShape.circle) {
          return ClipOval(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
              child: containerWidget,
            ),
          );
        } else {
          return ClipRRect(
            borderRadius: border ?? BorderRadius.zero,
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
              child: containerWidget,
            ),
          );
        }
      },
    );
  }
}
