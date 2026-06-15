import 'package:flutter/material.dart';

class SkeletonTransition extends StatelessWidget {
  final bool isLoading;
  final Widget skeleton;
  final Widget child;
  final Duration duration;
  final Curve curve;

  const SkeletonTransition({
    super.key,
    required this.isLoading,
    required this.skeleton,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeInOut,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: curve,
      switchOutCurve: curve,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: isLoading
          ? KeyedSubtree(
              key: const ValueKey('skeleton_state'),
              child: skeleton,
            )
          : KeyedSubtree(
              key: const ValueKey('content_state'),
              child: child,
            ),
    );
  }
}
