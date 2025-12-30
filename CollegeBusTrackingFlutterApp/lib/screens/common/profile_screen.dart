import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/services/data_service.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/widgets/app_drawer.dart';
import 'package:collegebus/services/theme_service.dart';
import 'package:collegebus/services/locale_service.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:flutter_tailwind_css_colors/flutter_tailwind_css_colors.dart';
import 'package:collegebus/l10n/common/app_localizations.dart' as common_l10n;

// New standalone widgets
import 'widgets/profile_section_card.dart';
import 'widgets/profile_list_item.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUserModel;
    // Safely get l10n, assuming context is valid and delegate is active
    final l10n = common_l10n.CommonLocalizations.of(context)!;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Consumer<ThemeService>(
      builder: (context, themeService, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          drawer: themeService.useBottomNavigation
              ? null
              : AppDrawer(user: user, authService: authService),
          appBar: AppBar(
            title: Text(l10n.profile),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            elevation: 0,
          ),
          body: VStack([
            // Header Section
            VxBox(
                  child: VStack([
                    16.heightBox,
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      child:
                          (user.fullName.isNotEmpty
                                  ? user.fullName.substring(0, 1).toUpperCase()
                                  : 'U')
                              .text
                              .size(36)
                              .bold
                              .color(Theme.of(context).primaryColor)
                              .make(),
                    ),
                    16.heightBox,
                    user.fullName.text
                        .size(24)
                        .bold
                        .color(Theme.of(context).colorScheme.onPrimary)
                        .make(),
                    8.heightBox,
                    user.email.text
                        .size(14)
                        .color(
                          Theme.of(
                            context,
                          ).colorScheme.onPrimary.withValues(alpha: 0.8),
                        )
                        .make(),
                  ], crossAlignment: CrossAxisAlignment.center),
                )
                .width(double.infinity)
                .color(Theme.of(context).primaryColor)
                .customRounded(
                  const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                )
                .make()
                .pOnly(bottom: 32),

            24.heightBox,

            // Sections
            VStack([
              // 1. Quick Stats Column
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatCard(
                    context,
                    l10n.role,
                    user.role.displayName,
                    Icons.badge_rounded,
                    Colors.blue,
                    fullWidth: true,
                  ),

                  12.heightBox,

                  _buildStatCard(
                    context,
                    l10n.collegeId,
                    user.collegeId.isNotEmpty ? user.collegeId : 'N/A',
                    Icons.school_rounded,
                    Colors.purple,
                    fullWidth: true,
                  ),

                  12.heightBox,

                  _buildStatCard(
                    context,
                    l10n.phone,
                    user.phoneNumber ?? 'Not provided',
                    Icons.phone_rounded,
                    Colors.teal,
                    fullWidth: true,
                  ),
                ],
              ),
              // Divider or spacing
              24.heightBox,

              // 2. Preferences Section
              ProfileSectionCard(
                title: l10n.preferences,
                children: [
                  ProfileListItem(
                    leadingIcon: Icons.notifications_active_outlined,
                    iconColor: TwColors.blue.i400,
                    title: l10n.notifications,
                    subtitle: l10n.receiveAlerts,
                    trailing: Switch(
                      value: true,
                      activeThumbColor: Colors.blue,
                      onChanged: (val) {},
                    ),
                    showDivider: true,
                  ),
                  _buildLanguageSelector(context, l10n),
                  ProfileListItem(
                    leadingIcon: Icons.location_on_outlined,
                    iconColor: TwColors.indigo.i400,
                    title: l10n.busStop,
                    subtitle: l10n.managePreferredPickup,
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    onTap: () => context.push('/student/bus-stop'),
                    showDivider: true,
                  ),
                  ProfileListItem(
                    leadingIcon: themeService.isDarkMode
                        ? Icons.dark_mode
                        : Icons.light_mode,
                    iconColor: TwColors.purple.i400,
                    title: l10n.darkMode,
                    subtitle: l10n.toggleDarkLight,
                    trailing: Switch(
                      value: themeService.isDarkMode,
                      activeThumbColor: Colors.blue,
                      onChanged: (val) => themeService.toggleTheme(val),
                    ),
                    showDivider: true,
                  ),
                  ProfileListItem(
                    leadingIcon: Icons.view_column_rounded,
                    iconColor: TwColors.teal.i400,
                    title: l10n.bottomNavigation,
                    subtitle: l10n.enableModernNav,
                    trailing: Switch(
                      value: themeService.useBottomNavigation,
                      activeThumbColor: Colors.blue,
                      onChanged: (val) {
                        if (val) {
                          themeService.toggleNavigationMode(true);
                          switch (user.role) {
                            case UserRole.busCoordinator:
                              context.go('/coordinator');
                              break;
                            case UserRole.driver:
                              context.go('/driver');
                              break;
                            case UserRole.teacher:
                              context.go('/student');
                              break;
                            case UserRole.admin:
                              context.go('/admin');
                              break;
                            default:
                              context.go('/student');
                          }
                        } else {
                          context.push('/profile'); // Updated path
                          themeService.toggleNavigationMode(false);
                        }
                      },
                    ),
                    showDivider: false,
                  ),
                ],
              ),

              24.heightBox,

              // 3. Account and Security Section
              ProfileSectionCard(
                title: l10n.accountSecurity,
                children: [
                  ProfileListItem(
                    leadingIcon: Icons.lock_outline_rounded,
                    iconColor: TwColors.blue.i400,
                    title: l10n.changePassword,
                    subtitle: l10n.updateCredentials,
                    onTap: () => context.push('/student/change-password'),
                    showDivider: true,
                  ),
                  ProfileListItem(
                    leadingIcon: Icons.privacy_tip_outlined,
                    iconColor: TwColors.teal.i400,
                    title: l10n.privacyPolicy,
                    subtitle: l10n.dataHandling,
                    onTap: () => context.push('/student/privacy-policy'),
                    showDivider: true,
                  ),
                  ProfileListItem(
                    leadingIcon: Icons.description_outlined,
                    iconColor: TwColors.indigo.i400,
                    title: l10n.termsConditions,
                    subtitle: l10n.legalUsageRequirements,
                    onTap: () => context.push('/student/terms-conditions'),
                    showDivider: false,
                  ),
                ],
              ),

              32.heightBox,

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await authService.signOut();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.logout),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              32.heightBox,
            ]).pSymmetric(h: 16),
          ]).scrollVertical(),
        );
      },
    );
  }

  Widget _buildLanguageSelector(
    BuildContext context,
    common_l10n.CommonLocalizations l10n,
  ) {
    return Consumer<LocaleService>(
      builder: (context, localeService, _) {
        final currentCode = localeService.locale.languageCode;
        final languageName = currentCode == 'en'
            ? l10n.english
            : currentCode == 'te'
            ? l10n.telugu
            : l10n.hindi;

        Future<void> cycleLanguage() async {
          String newLang;
          if (currentCode == 'en') {
            newLang = 'te';
            localeService.setLocale(const Locale('te'));
          } else if (currentCode == 'te') {
            newLang = 'hi';
            localeService.setLocale(const Locale('hi'));
          } else {
            newLang = 'en';
            localeService.setLocale(const Locale('en'));
          }

          // Update language in database
          final authService = Provider.of<AuthService>(context, listen: false);
          final user = authService.currentUserModel;
          if (user != null) {
            final dataService = Provider.of<DataService>(
              context,
              listen: false,
            );
            await dataService.updateUser(user.id, {'language': newLang});
          }
        }

        return ProfileListItem(
          leadingIcon: Icons.language_rounded,
          iconColor: TwColors.indigo.i400,
          title: l10n.language,
          subtitle: l10n.chooseLanguage,
          onTap: cycleLanguage,
          trailing: HStack([
            languageName.text.bold
                .color(Theme.of(context).colorScheme.onSurface)
                .make(),
            8.widthBox,
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ]),
          showDivider: true,
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    MaterialColor color, {
    bool fullWidth = false,
  }) {
    return VxBox(
          child: HStack([
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color[50], // Light shade
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color[600], size: 24),
            ),
            12.widthBox,
            VStack([
              label.text
                  .size(12)
                  .color(
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  )
                  .make(),
              4.heightBox,
              value.text
                  .size(16)
                  .bold
                  .color(Theme.of(context).colorScheme.onSurface)
                  .make(),
            ], crossAlignment: CrossAxisAlignment.start).expand(),
          ]),
        )
        .color(Theme.of(context).cardColor)
        .shadowSm
        .roundedLg
        .p12
        .make()
        .w(fullWidth ? double.infinity : context.percentWidth * 44);
  }
}
