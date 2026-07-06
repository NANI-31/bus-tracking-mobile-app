import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:velocity_x/velocity_x.dart';

class ProfileListItem extends StatefulWidget {
  final IconData leadingIcon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  const ProfileListItem({
    super.key,
    required this.leadingIcon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  @override
  State<ProfileListItem> createState() => _ProfileListItemState();
}

class _ProfileListItemState extends State<ProfileListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.04,
    )..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _scale = 1.0 - _controller.value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget child = Column(
      children: [
        Material(
          color: Colors.transparent,
          child: ListTile(
            onTap: widget.onTap != null
                ? () {
                    widget.onTap!();
                  }
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 6,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.iconColor.withValues(alpha: isDark ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: widget.iconColor.withValues(alpha: isDark ? 0.25 : 0.15),
                  width: 1,
                ),
              ),
              child: Icon(widget.leadingIcon, color: widget.iconColor, size: 22),
            ),
            title: widget.title.text.semiBold
                .size(15)
                .color(Theme.of(context).colorScheme.onSurface)
                .make(),
            subtitle: widget.subtitle != null && widget.subtitle!.isNotEmpty
                ? widget.subtitle!.text
                    .size(12)
                    .color(
                      Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    )
                    .make()
                    .pOnly(top: 2)
                : null,
            trailing: widget.trailing != null
                ? AnimatedTrailingChevron(
                    parentController: _controller,
                    child: widget.trailing!,
                  )
                : null,
          ),
        ),
        if (widget.showDivider)
          Divider(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.05),
            indent: 68,
            endIndent: 20,
            height: 1,
          ),
      ],
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTapDown: (_) {
          _controller.forward();
          HapticFeedback.selectionClick();
        },
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: widget.onTap,
        child: Transform.scale(
          scale: _scale,
          child: child,
        ),
      );
    }

    return child;
  }
}

class AnimatedTrailingChevron extends StatefulWidget {
  final Widget child;
  final AnimationController parentController;

  const AnimatedTrailingChevron({
    super.key,
    required this.child,
    required this.parentController,
  });

  @override
  State<AnimatedTrailingChevron> createState() => _AnimatedTrailingChevronState();
}

class _AnimatedTrailingChevronState extends State<AnimatedTrailingChevron>
    with SingleTickerProviderStateMixin {
  late AnimationController _localController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _localController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 5.0).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 5.0, end: -1.5).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -1.5, end: 0.0).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 30,
      ),
    ]).animate(_localController);

    widget.parentController.addStatusListener(_onStatusChanged);
  }

  void _onStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.forward) {
      _localController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    widget.parentController.removeStatusListener(_onStatusChanged);
    _localController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_slideAnimation.value, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

