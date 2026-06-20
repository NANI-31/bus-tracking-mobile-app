import 'package:flutter/material.dart';

class TabTransitionView extends StatefulWidget {
  final TabController controller;
  final List<Widget> children;
  final Duration duration;
  final Curve curve;

  const TabTransitionView({
    super.key,
    required this.controller,
    required this.children,
    this.duration = const Duration(milliseconds: 400),
    this.curve = const Cubic(0.3, 1.0, 0.4, 1.0), // Responsive deceleration curve
  });

  @override
  State<TabTransitionView> createState() => _TabTransitionViewState();
}

class _TabTransitionViewState extends State<TabTransitionView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;
  int _currentIndex = 0;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.controller.index;
    _previousIndex = _currentIndex;
    _animController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: widget.curve,
    );
    widget.controller.addListener(_handleTabChange);
    // Start in fully visible state
    _animController.value = 1.0;
  }

  @override
  void didUpdateWidget(TabTransitionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleTabChange);
      widget.controller.addListener(_handleTabChange);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTabChange);
    _animController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (widget.controller.index != _currentIndex && mounted) {
      setState(() {
        _previousIndex = _currentIndex;
        _currentIndex = widget.controller.index;
      });
      _animController.reset();
      _animController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMovingRight = _currentIndex > _previousIndex;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final double progress = _animation.value;

        // Custom spatial route movement offsets
        // Next tab slides in from right/left, previous tab slides out to left/right
        final Offset prevOffset = isMovingRight
            ? Offset(-0.15 * progress, 0.0) // slides left slightly
            : Offset(0.15 * progress, 0.0);  // slides right slightly

        final Offset nextOffset = isMovingRight
            ? Offset(0.35 * (1.0 - progress), 0.0) // enters from right
            : Offset(-0.35 * (1.0 - progress), 0.0); // enters from left

        final List<Widget> stackChildren = [];
        for (int i = 0; i < widget.children.length; i++) {
          final bool isCurrent = i == _currentIndex;
          final bool isPrevious = i == _previousIndex && progress < 1.0;
          final bool isOffstage = !isCurrent && !isPrevious;

          final double opacity = isCurrent
              ? progress.clamp(0.0, 1.0)
              : isPrevious
                  ? (1.0 - progress).clamp(0.0, 1.0)
                  : 0.0;

          final Offset translation = isCurrent
              ? nextOffset
              : isPrevious
                  ? prevOffset
                  : Offset.zero;

          stackChildren.add(
            Offstage(
              offstage: isOffstage,
              child: IgnorePointer(
                ignoring: isOffstage,
                child: Opacity(
                  opacity: opacity,
                  child: FractionalTranslation(
                    translation: translation,
                    child: widget.children[i],
                  ),
                ),
              ),
            ),
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: stackChildren,
        );
      },
    );
  }
}
