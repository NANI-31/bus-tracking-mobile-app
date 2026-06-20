import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';

class CoordinatorSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String) onChanged;
  final VoidCallback onClear;
  final String searchQuery;
  final String hintText;
  final bool hasWarningState;

  const CoordinatorSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
    required this.searchQuery,
    this.hintText = 'Search...',
    this.hasWarningState = false,
  });

  @override
  State<CoordinatorSearchBar> createState() => _CoordinatorSearchBarState();
}

class _CoordinatorSearchBarState extends State<CoordinatorSearchBar>
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;

    return AnimatedBuilder(
      animation: _focusAnimation,
      builder: (context, child) {
        final double glowOpacity = 0.08 * _focusAnimation.value;
        final baseBorderColor = widget.hasWarningState
            ? Colors.orange.withValues(alpha: 0.4)
            : colorScheme.onSurface.withValues(alpha: 0.08);
        final targetBorderColor = widget.hasWarningState
            ? Colors.orange
            : primaryColor;
        final borderColor = Color.lerp(
          baseBorderColor,
          targetBorderColor,
          _focusAnimation.value,
        )!;
        final borderWidth = 1.0 + (1.5 - 1.0) * _focusAnimation.value;
        final glowColor = widget.hasWarningState ? Colors.orange : primaryColor;

        return Container(
          margin: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(35),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(
                  alpha: widget.hasWarningState ? 0.06 : glowOpacity,
                ),
                blurRadius: 8 * _focusAnimation.value,
                spreadRadius: 2 * _focusAnimation.value,
              ),
              BoxShadow(
                color: isDark
                    ? Colors.black26
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      Colors.white.withValues(alpha: _isFocused ? 0.08 : 0.05),
                      Colors.white.withValues(alpha: _isFocused ? 0.04 : 0.02),
                    ]
                  : [
                      Colors.white.withValues(alpha: _isFocused ? 0.9 : 0.8),
                      Colors.white.withValues(alpha: _isFocused ? 0.8 : 0.7),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(35),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: child,
            ),
          ),
        );
      },
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          TextField(
            controller: widget.controller,
            onChanged: widget.onChanged,
            focusNode: widget.focusNode,
            textAlignVertical: TextAlignVertical.center,
            style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
              prefixIcon: AnimatedBuilder(
                animation: _focusAnimation,
                builder: (context, child) {
                  final double rotation =
                      -0.12 * (1.0 - _focusAnimation.value) * 2 * math.pi;
                  final normalColor = Color.lerp(
                    colorScheme.onSurface.withValues(alpha: 0.4),
                    primaryColor,
                    _focusAnimation.value,
                  )!;
                  final color = widget.hasWarningState
                      ? Colors.orange
                      : normalColor;

                  return Transform.rotate(
                    angle: rotation,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: widget.hasWarningState
                          ? Icon(
                              Icons.search_off_rounded,
                              key: const ValueKey('search_off'),
                              color: color,
                              size: 28,
                            )
                          : Icon(
                              Icons.search,
                              key: const ValueKey('search_on'),
                              color: color,
                              size: 28,
                            ),
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
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: widget.searchQuery.isNotEmpty
                    ? IconButton(
                        key: const ValueKey('clear_search'),
                        icon: Icon(
                          Icons.clear,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
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
                final currentOffset =
                    startOffset +
                    (endOffset - startOffset) * _focusAnimation.value;
                final double opacity =
                    0.4 + (0.2 - 0.4) * _focusAnimation.value;

                return Padding(
                  padding: EdgeInsets.only(left: currentOffset),
                  child: Text(
                    widget.hintText,
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: opacity),
                      fontSize: 15,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
