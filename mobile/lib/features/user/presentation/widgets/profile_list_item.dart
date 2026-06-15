import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:velocity_x/velocity_x.dart';

class ProfileListItem extends StatefulWidget {
  final IconData leadingIcon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  const ProfileListItem({
    super.key,
    required this.leadingIcon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
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
        ListTile(
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
          subtitle: widget.subtitle.text
              .size(12)
              .color(
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              )
              .make()
              .pOnly(top: 2),
          trailing: widget.trailing,
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

