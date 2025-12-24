import 'package:flutter/material.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/l10n/signup/auth_signup_localizations.dart';

class RoleSelectionGrid extends StatelessWidget {
  final UserRole selectedRole;
  final ValueChanged<UserRole> onRoleSelected;

  const RoleSelectionGrid({
    super.key,
    required this.selectedRole,
    required this.onRoleSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = SignupLocalizations.of(context)!;
    return VStack([
      HStack([
        _buildRoleCard(
          context,
          role: UserRole.student,
          icon: Icons.school_rounded,
          color: Colors.blueAccent,
          bgColor: const Color(0xFFE3F2FD),
          label: l10n.roleStudent,
        ).expand(),
        16.widthBox,
        _buildRoleCard(
          context,
          role: UserRole.teacher,
          icon: Icons.cast_for_education_rounded,
          color: Colors.purpleAccent,
          bgColor: const Color(0xFFF3E5F5),
          label: l10n.roleTeacher,
        ).expand(),
      ]),
      16.heightBox,
      HStack([
        _buildRoleCard(
          context,
          role: UserRole.driver,
          icon: Icons.directions_bus_rounded,
          color: Colors.orangeAccent,
          bgColor: const Color(0xFFFFF3E0),
          label: l10n.roleDriver,
        ).expand(),
        16.widthBox,
        _buildRoleCard(
          context,
          role: UserRole.parent,
          icon: Icons.family_restroom_rounded,
          color: Colors.green,
          bgColor: const Color(0xFFE8F5E9),
          label: l10n.roleParent,
        ).expand(),
      ]),
      16.heightBox,
      _buildRoleCard(
        context,
        role: UserRole.busCoordinator,
        icon: Icons.admin_panel_settings_rounded,
        color: Colors.blueGrey,
        bgColor: const Color(0xFFECEFF1),
        isFullWidth: true,
        label: l10n.roleBusCoordinator,
        subLabel: l10n.roleCoordinatorDescription,
      ),
    ]);
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required UserRole role,
    required IconData icon,
    required Color color,
    required Color bgColor,
    bool isFullWidth = false,
    String? label,
    String? subLabel,
  }) {
    final isSelected = selectedRole == role;

    // Build the inner content
    final cardContent = isFullWidth
        ? HStack([
            Icon(
              icon,
              color: color,
              size: 24,
            ).box.color(bgColor).roundedFull.p12.make(),
            16.widthBox,
            VStack([
              (label ?? role.displayName).text.bold
                  .size(14)
                  .color(Theme.of(context).colorScheme.onSurface)
                  .make(),
              if (subLabel != null)
                subLabel.text
                    .size(12)
                    .color(
                      Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    )
                    .make(),
            ]).expand(),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: AppColors.primary),
          ])
        : VStack(
            [
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 20,
                ).objectTopRight()
              else
                20.heightBox,
              Icon(
                icon,
                color: color,
                size: 28,
              ).box.color(bgColor).roundedFull.p12.make(),
              8.heightBox,
              (label ?? role.displayName).text.semiBold
                  .size(14)
                  .color(Theme.of(context).colorScheme.onSurface)
                  .make(),
            ],
            alignment: MainAxisAlignment.center,
            crossAlignment: CrossAxisAlignment.center,
          );

    // Wrap in GestureDetector to remove ripple
    return GestureDetector(
      onTap: () => onRoleSelected(role),
      child: VxBox(child: cardContent).p12
          .color(Theme.of(context).colorScheme.surface)
          .border(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          )
          .rounded
          .withShadow([
            if (!isSelected)
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ])
          .width(context.screenWidth)
          .height(isFullWidth ? 110 : 145)
          .make(),
    );
  }
}
