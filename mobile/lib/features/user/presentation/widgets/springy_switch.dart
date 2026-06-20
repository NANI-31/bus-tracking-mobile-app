import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SpringySwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  const SpringySwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.activeColor,
  });

  @override
  State<SpringySwitch> createState() => _SpringySwitchState();
}

class _SpringySwitchState extends State<SpringySwitch>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _thumbPosition;
  late Animation<double> _thumbWidthMultiplier;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _thumbPosition = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutBack, // Springy back-and-forth bounce
    );

    _thumbWidthMultiplier = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.35).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.35, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.value) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(SpringySwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (widget.value) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        widget.onChanged(!widget.value);
        HapticFeedback.lightImpact();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final color = Color.lerp(
            isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.06),
            widget.activeColor,
            _thumbPosition.value,
          )!;

          final borderColor = Color.lerp(
            isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.1),
            widget.activeColor.withValues(alpha: 0.4),
            _thumbPosition.value,
          )!;

          return Container(
            width: 50,
            height: 30,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: borderColor,
                width: 1.2,
              ),
            ),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Transform.translate(
                    offset: Offset(_thumbPosition.value * 20.0, 0),
                    child: Transform.scale(
                      scaleX: _thumbWidthMultiplier.value,
                      scaleY: 1.0 / (_thumbWidthMultiplier.value * 0.92),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 1.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
