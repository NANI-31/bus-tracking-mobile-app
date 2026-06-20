import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class StaggeredEntranceWidget extends StatefulWidget {
  final Widget child;
  final int index;
  final int staggerDelayMs;

  const StaggeredEntranceWidget({
    super.key,
    required this.child,
    required this.index,
    this.staggerDelayMs = 20,
  });

  @override
  State<StaggeredEntranceWidget> createState() => _StaggeredEntranceWidgetState();
}

class _StaggeredEntranceWidgetState extends State<StaggeredEntranceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  Curve _selectedCurve = const Cubic(0.34, 1.56, 0.64, 1.0); // Default overshoot
  Duration _animationDuration = const Duration(milliseconds: 550);

  @override
  void initState() {
    super.initState();

    _detectPerformanceAndAdjust();

    _controller = AnimationController(
      duration: _animationDuration,
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<double>(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: _selectedCurve,
      ),
    );

    if (widget.index > 8) {
      _controller.value = 1.0;
    } else {
      final int delayMs = (widget.index * widget.staggerDelayMs).clamp(0, 150);
      Future.delayed(Duration(milliseconds: delayMs), () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  void _detectPerformanceAndAdjust() {
    try {
      final double dpr = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;

      // Heuristic: low-spec devices typically have lower DPR (e.g., < 2.0).
      // We switch to a lightweight Curve (easeOutQuad) and speed up duration to 350ms to prevent frame drops.
      if (dpr < 2.0) {
        _selectedCurve = Curves.easeOutQuad;
        _animationDuration = const Duration(milliseconds: 350);
      } else {
        _selectedCurve = const Cubic(0.34, 1.56, 0.64, 1.0);
        _animationDuration = const Duration(milliseconds: 550);
      }
    } catch (_) {
      // Fallback
      _selectedCurve = const Cubic(0.34, 1.56, 0.64, 1.0);
      _animationDuration = const Duration(milliseconds: 550);
    }

    // Dynamic frame-rendering time measurement to degrade curves under load/slowness
    final stopwatch = Stopwatch()..start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      stopwatch.stop();
      final elapsed = stopwatch.elapsedMilliseconds;
      if (elapsed > 20 && mounted) {
        setState(() {
          _selectedCurve = Curves.easeOutQuad;
          _controller.duration = const Duration(milliseconds: 350);
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0.0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
