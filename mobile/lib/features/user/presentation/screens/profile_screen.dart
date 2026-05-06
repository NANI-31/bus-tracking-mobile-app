import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:collegebus/features/payment/presentation/screens/payment_screen.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/core/providers/service_providers.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:flutter_tailwind_css_colors/flutter_tailwind_css_colors.dart';
import 'package:collegebus/l10n/common/app_localizations.dart' as common_l10n;
import 'package:collegebus/features/college/application/college_provider.dart';

// New standalone widgets
import '../widgets/profile_section_card.dart';
import '../widgets/profile_list_item.dart';
import 'package:collegebus/shared/widgets/logout_confirmation_dialog.dart';
import 'package:collegebus/shared/widgets/logout_loading_dialog.dart';
import 'package:collegebus/features/settings/presentation/sos_sound_settings.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final themeService = ref.watch(themeServiceProvider);

    // Safely get l10n, assuming context is valid and delegate is active
    final l10n = common_l10n.CommonLocalizations.of(context)!;
    final collegesAsync = ref.watch(collegeServiceProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isDark = themeService.isDarkMode;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        drawer: null,
        appBar: AppBar(
          title: Text(l10n.profile),
          backgroundColor: isDark
              ? Colors.transparent
              : Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: VStack([
          // Header Section
          VxBox(
                child: VStack([
                  24.heightBox,
                  // Avatar with glow
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: user.isPremium
                            ? Colors.amber
                            : Colors.white.withValues(alpha: 0.2),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: user.isPremium
                              ? Colors.amber.withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white.withValues(alpha: 0.9),
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Center(
                            child:
                                (user.fullName.isNotEmpty
                                        ? user.fullName
                                              .substring(0, 1)
                                              .toUpperCase()
                                        : 'U')
                                    .text
                                    .size(36)
                                    .bold
                                    .color(AppColors.primary)
                                    .make(),
                          ),
                          if (user.isPremium)
                            const Icon(
                              Icons.verified_rounded,
                              color: Colors.amber,
                              size: 28,
                            ),
                        ],
                      ),
                    ),
                  ),
                  20.heightBox,
                  HStack([
                    user.fullName.text.size(26).bold.color(Colors.white).make(),
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        if (context.canPop()) {
                          // If we're deep in student routes
                          context.push('/student/edit-profile');
                        } else {
                          // Global profile route
                          context.push('/profile/edit');
                        }
                      },
                      tooltip: 'Edit Profile',
                    ),
                    if (user.isPremium) ...[
                      8.widthBox,
                      const Icon(
                        Icons.workspace_premium_rounded,
                        color: Colors.amber,
                        size: 28,
                      ),
                    ],
                  ], crossAlignment: CrossAxisAlignment.center),
                  if (user.isPremium) ...[
                    8.heightBox,
                    VxBox(
                          child: "PREMIUM MEMBER".text
                              .size(10)
                              .bold
                              .color(Colors.amber.shade700)
                              .make()
                              .pSymmetric(h: 8, v: 2),
                        ).amber100.roundedLg
                        .border(color: Colors.amber.shade300)
                        .make(),
                  ],
                  4.heightBox,
                  user.email.text
                      .size(14)
                      .color(Colors.white.withValues(alpha: 0.7))
                      .make(),
                  24.heightBox,
                ], crossAlignment: CrossAxisAlignment.center),
              )
              .width(double.infinity)
              .withGradient(
                LinearGradient(
                  colors: [
                    isDark
                        ? AppColors.primary.withValues(alpha: 0.8)
                        : AppColors.primary,
                    isDark
                        ? context.colorScheme.primaryContainer
                        : AppColors.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              )
              .customRounded(
                const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              )
              .shadow2xl
              .make()
              .pOnly(bottom: 24),

          24.heightBox,

          // Sections
          VStack([
            // 1. Quick Stats Grid
            VStack([
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
                'College',
                collegesAsync.maybeWhen(
                  data: (colleges) {
                    try {
                      return colleges
                          .firstWhere((c) => c.id == user.collegeId)
                          .name;
                    } catch (_) {
                      return user.collegeId.isNotEmpty ? user.collegeId : 'N/A';
                    }
                  },
                  orElse: () => 'Loading...',
                ),
                Icons.school_rounded,
                Colors.purple,
                fullWidth: true,
              ),
            ]),
            12.heightBox,
            _buildStatCard(
              context,
              l10n.phone,
              user.phoneNumber ?? 'Not provided',
              Icons.phone_rounded,
              Colors.teal,
              fullWidth: true,
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
                    onChanged: (val) => ref
                        .read(themeServiceProvider.notifier)
                        .toggleTheme(val),
                  ),
                  showDivider: false,
                ),
              ],
            ),

            24.heightBox,

            24.heightBox,

            // Emergency Settings (Hidden for Student, Parent, Teacher)
            if (![
              UserRole.student,
              UserRole.parent,
              UserRole.teacher,
            ].contains(user.role))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: const SosSoundSettings(),
                  ),
                ),
              ),

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
                  showDivider: true,
                ),
                /*
                if ([
                  UserRole.student,
                  UserRole.parent,
                  UserRole.teacher,
                ].contains(user.role))
                  ProfileListItem(
                    leadingIcon: Icons.card_giftcard_rounded,
                    iconColor: TwColors.pink.i400,
                    title: "Refer & Earn",
                    subtitle: "Get free Premium by inviting friends",
                    onTap: () => context.push('/referral'),
                    showDivider: true,
                  ),
                */
                if ([
                  UserRole.student,
                  UserRole.parent,
                  UserRole.teacher,
                ].contains(user.role))
                  ProfileListItem(
                    leadingIcon: Icons.payment_rounded,
                    iconColor: TwColors.green.i400, // Green for money
                    title: "Payments",
                    subtitle: user.isPremium && user.premiumUntil != null
                        ? "Premium active until ${user.premiumUntil!.day}/${user.premiumUntil!.month}/${user.premiumUntil!.year}"
                        : "Pay fees & dues",
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PaymentScreen()),
                    ),
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
                  final confirmed = await LogoutConfirmationDialog.show(
                    context,
                  );
                  if (confirmed) {
                    if (context.mounted) {
                      LogoutLoadingDialog.show(context);
                    }
                    await ref.read(authProvider.notifier).signOut();
                    if (context.mounted) {
                      context.go('/login');
                    }
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
      ),
    );
  }

  Widget _buildLanguageSelector(
    BuildContext context,
    common_l10n.CommonLocalizations l10n,
  ) {
    final locale = ref.watch(localeServiceProvider);
    final currentCode = locale.languageCode;
    final languageName = currentCode == 'en'
        ? l10n.english
        : currentCode == 'te'
        ? l10n.telugu
        : l10n.hindi;

    return ProfileListItem(
      leadingIcon: Icons.language_rounded,
      iconColor: TwColors.indigo.i400,
      title: l10n.language,
      subtitle: l10n.chooseLanguage,
      onTap: () => context.push('/student/language'),
      trailing: HStack([
        languageName.text.bold
            .color(Theme.of(context).colorScheme.onSurface)
            .make(),
        8.widthBox,
        Icon(
          Icons.chevron_right_rounded,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ]),
      showDivider: true,
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
                    Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
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
