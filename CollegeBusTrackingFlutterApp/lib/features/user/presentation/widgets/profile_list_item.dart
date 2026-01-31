import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';

class ProfileListItem extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(leadingIcon, color: iconColor, size: 24),
          ),
          title: title.text.bold
              .size(16)
              .color(Theme.of(context).colorScheme.onSurface)
              .make(),
          subtitle: subtitle.text
              .size(13)
              .color(
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              )
              .make()
              .pOnly(top: 2),
          trailing: trailing,
        ),
        if (showDivider)
          Divider(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.05),
            indent: 72,
            endIndent: 20,
            height: 1,
          ),
      ],
    );
  }
}
