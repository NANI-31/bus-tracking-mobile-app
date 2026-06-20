import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/core/constants/constants.dart';

class BusSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final VoidCallback onClear;
  final String searchQuery;
  final String hintText;
  final FocusNode focusNode;

  const BusSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.searchQuery,
    this.hintText = 'Search...',
    required this.focusNode,
  });

  @override
  State<BusSearchBar> createState() => _BusSearchBarState();
}

class _BusSearchBarState extends State<BusSearchBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _focusAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _focusAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Cubic(0.05, 0.7, 0.1, 1.0), // M3 Emphasized Decelerate
    );

    widget.focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (!mounted) return;
    final hasFocus = widget.focusNode.hasFocus;
    if (hasFocus != _isFocused) {
      setState(() {
        _isFocused = hasFocus;
      });
      if (hasFocus) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChange);
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        TextField(
          controller: widget.controller,
          onChanged: widget.onChanged,
          focusNode: widget.focusNode,
          textAlignVertical: TextAlignVertical.center,
          style: TextStyle(
            fontSize: 16,
            color: context.colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            prefixIcon: AnimatedBuilder(
              animation: _focusAnimation,
              builder: (context, child) {
                final double rotation = -0.12 * (1.0 - _focusAnimation.value) * 2 * math.pi;
                final color = Color.lerp(
                  context.colorScheme.onSurface.withValues(alpha: 0.4),
                  context.colorScheme.primary,
                  _focusAnimation.value,
                );
                return Transform.rotate(
                  angle: rotation,
                  child: Icon(
                    Icons.search,
                    color: color,
                    size: 28,
                  ),
                );
              },
            ),
            suffixIcon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: CurvedAnimation(
                    parent: animation,
                    curve: const Cubic(0.05, 0.7, 0.1, 1.0),
                  ),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: widget.searchQuery.isNotEmpty
                  ? IconButton(
                      key: const ValueKey('clear_search'),
                      icon: Icon(
                        Icons.clear,
                        color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      onPressed: widget.onClear,
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _focusAnimation,
            builder: (context, child) {
              final showHint = widget.controller.text.isEmpty;
              if (!showHint) return const SizedBox.shrink();

              final double startOffset = 52.0;
              final double endOffset = 44.0;
              final currentOffset = startOffset + (endOffset - startOffset) * _focusAnimation.value;
              final double opacity = 0.4 + (0.2 - 0.4) * _focusAnimation.value;

              return Padding(
                padding: EdgeInsets.only(left: currentOffset),
                child: Text(
                  widget.hintText,
                  style: TextStyle(
                    color: context.colorScheme.onSurface.withValues(alpha: opacity),
                    fontSize: 16,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    )
    .pSymmetric(h: 16, v: 0)
    .box
    .color(context.cardColor)
    .withRounded(value: 35)
    .shadowSm
    .border(color: context.colorScheme.onSurface.withValues(alpha: 0.1))
    .make()
    .pOnly(left: 16, right: 16, top: 16, bottom: 12);
  }
}
