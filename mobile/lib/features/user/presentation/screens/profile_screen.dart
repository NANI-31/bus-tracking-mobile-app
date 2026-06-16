import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:collegebus/features/payment/presentation/screens/payment_screen.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/core/providers/service_providers.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/l10n/common/app_localizations.dart' as common_l10n;
import 'package:collegebus/features/college/application/college_provider.dart';
import 'package:collegebus/features/user/domain/user_model.dart';
import 'package:collegebus/shared/widgets/shimmer_loading.dart';

// New standalone widgets
import '../widgets/profile_section_card.dart';
import '../widgets/profile_list_item.dart';
import 'package:collegebus/shared/widgets/logout_confirmation_dialog.dart';
import 'package:collegebus/features/settings/presentation/sos_sound_settings.dart';
import 'package:collegebus/shared/widgets/navigation/curved_bottom_nav_bar.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final isScrolled = _scrollController.offset > 50;
    if (isScrolled != _isScrolled) {
      setState(() {
        _isScrolled = isScrolled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final themeService = ref.watch(themeServiceProvider);

    // Safely get l10n, assuming context is valid and delegate is active
    final l10n = common_l10n.CommonLocalizations.of(context)!;
    final collegesAsync = ref.watch(collegeServiceProvider);

    if (user == null) {
      return const ProfileScreenSkeleton();
    }

    final isDark = themeService.isDarkMode;
    final isWide = context.isTabletLayout || context.isDesktopLayout;
    final accentColor = Color(themeService.accentColorValue);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: isDark ? const Color(0xFF12181F) : const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: Text(
            l10n.profile,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: _isScrolled
              ? (isDark
                  ? const Color(0xFF12181F).withValues(alpha: 0.9)
                  : const Color(0xFFF5F7FA).withValues(alpha: 0.9))
              : Colors.transparent,
          foregroundColor: _isScrolled
              ? Theme.of(context).colorScheme.onSurface
              : Colors.white,
          elevation: 0,
          flexibleSpace: _isScrolled
              ? ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(color: Colors.transparent),
                  ),
                )
              : null,
        ),
        body: Stack(
          children: [
            // Colorful Header Background Cover
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: isWide ? 180 : 240,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      isDark
                          ? accentColor.withValues(alpha: 0.8)
                          : accentColor,
                      isDark
                          ? Color.alphaBlend(Colors.black.withValues(alpha: 0.3), accentColor)
                          : Color.alphaBlend(Colors.white.withValues(alpha: 0.15), accentColor),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(isWide ? 24 : 40),
                    bottomRight: Radius.circular(isWide ? 24 : 40),
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -40,
                      right: -30,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      left: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.04),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Scrollable Content Layout
            isWide
                ? SafeArea(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column (Persistent Profile Card & Stats)
                        Expanded(
                          flex: 4,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            child: VStack([
                              30.heightBox, // Padding offset for avatar
                              _buildUserProfileCard(context, user),
                              24.heightBox,
                              // Quick stats stack inside left column
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
                              12.heightBox,
                              _buildStatCard(
                                context,
                                l10n.phone,
                                user.phoneNumber ?? 'Not provided',
                                Icons.phone_rounded,
                                Colors.teal,
                                fullWidth: true,
                              ),
                            ]),
                          ),
                        ),
                        // Soft Vertical Divider
                        Container(
                          width: 1.5,
                          height: double.infinity,
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                        ),
                        // Right Column (Settings Grid / Sections)
                        Expanded(
                          flex: 5,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            child: VStack([
                              // Preferences
                              ProfileSectionCard(
                                title: l10n.preferences,
                                children: [
                                  ProfileListItem(
                                    leadingIcon: Icons.notifications_active_outlined,
                                    iconColor: accentColor,
                                    title: l10n.notifications,
                                    subtitle: l10n.receiveAlerts,
                                    trailing: Switch(
                                      value: true,
                                      activeThumbColor: accentColor,
                                      activeTrackColor: accentColor.withValues(alpha: 0.3),
                                      onChanged: (val) {},
                                    ),
                                    showDivider: true,
                                  ),
                                  _buildLanguageSelector(context, l10n),
                                  _buildAccentColorSelector(context, themeService.accentColorValue),
                                  ProfileListItem(
                                    leadingIcon: Icons.location_on_outlined,
                                    iconColor: accentColor,
                                    title: l10n.busStop,
                                    subtitle: l10n.managePreferredPickup,
                                    trailing: Icon(
                                      Icons.chevron_right_rounded,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                    ),
                                    onTap: () => context.push('/student/bus-stop'),
                                    showDivider: true,
                                  ),
                                  _buildMapThemeSelector(
                                    context,
                                    themeService.mapTheme,
                                    themeService.isDarkMode,
                                  ),
                                  ProfileListItem(
                                    leadingIcon: themeService.isDarkMode
                                        ? Icons.dark_mode_rounded
                                        : Icons.light_mode_rounded,
                                    iconColor: accentColor,
                                    title: l10n.darkMode,
                                    subtitle: l10n.toggleDarkLight,
                                    trailing: Switch(
                                      value: themeService.isDarkMode,
                                      activeThumbColor: accentColor,
                                      activeTrackColor: accentColor.withValues(alpha: 0.3),
                                      onChanged: (val) => ref
                                          .read(themeServiceProvider.notifier)
                                          .toggleTheme(val),
                                    ),
                                    showDivider: false,
                                  ),
                                ],
                              ),
                              24.heightBox,
                              // Account & Security
                              ProfileSectionCard(
                                title: l10n.accountSecurity,
                                children: [
                                  ProfileListItem(
                                    leadingIcon: Icons.lock_outline_rounded,
                                    iconColor: accentColor,
                                    title: l10n.changePassword,
                                    subtitle: l10n.updateCredentials,
                                    onTap: () => context.push('/student/change-password'),
                                    showDivider: true,
                                  ),
                                  ProfileListItem(
                                    leadingIcon: Icons.privacy_tip_outlined,
                                    iconColor: accentColor,
                                    title: l10n.privacyPolicy,
                                    subtitle: l10n.dataHandling,
                                    onTap: () => context.push('/student/privacy-policy'),
                                    showDivider: true,
                                  ),
                                  ProfileListItem(
                                    leadingIcon: Icons.description_outlined,
                                    iconColor: accentColor,
                                    title: l10n.termsConditions,
                                    subtitle: l10n.legalUsageRequirements,
                                    onTap: () => context.push('/student/terms-conditions'),
                                    showDivider: true,
                                  ),
                                  if ([
                                    UserRole.student,
                                    UserRole.parent,
                                    UserRole.teacher,
                                  ].contains(user.role))
                                    ProfileListItem(
                                      leadingIcon: Icons.payment_rounded,
                                      iconColor: accentColor,
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
                              _buildLogoutButton(context),
                              24.heightBox,
                              const BottomNavSpacer(),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    child: VStack([
                      // Spacer for status bar and appbar height
                      (MediaQuery.of(context).padding.top + kToolbarHeight + 64).heightBox,

                      // User details card (overlapping layout)
                      _buildUserProfileCard(context, user),

                      24.heightBox,

                      // Main sections
                      VStack([
                        // Quick stats grid
                        HStack([
                          _buildStatCard(
                            context,
                            l10n.role,
                            user.role.displayName,
                            Icons.badge_rounded,
                            Colors.blue,
                          ),
                          12.widthBox,
                          _buildStatCard(
                            context,
                            l10n.phone,
                            user.phoneNumber ?? 'Not provided',
                            Icons.phone_rounded,
                            Colors.teal,
                          ),
                        ]),

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

                        24.heightBox,

                        // Preferences section
                        ProfileSectionCard(
                          title: l10n.preferences,
                          children: [
                            ProfileListItem(
                              leadingIcon: Icons.notifications_active_outlined,
                              iconColor: accentColor,
                              title: l10n.notifications,
                              subtitle: l10n.receiveAlerts,
                              trailing: Switch(
                                value: true,
                                activeThumbColor: accentColor,
                                activeTrackColor: accentColor.withValues(alpha: 0.3),
                                onChanged: (val) {},
                              ),
                              showDivider: true,
                            ),
                            _buildLanguageSelector(context, l10n),
                            _buildAccentColorSelector(context, themeService.accentColorValue),
                            ProfileListItem(
                              leadingIcon: Icons.location_on_outlined,
                              iconColor: accentColor,
                              title: l10n.busStop,
                              subtitle: l10n.managePreferredPickup,
                              trailing: Icon(
                                Icons.chevron_right_rounded,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                              onTap: () => context.push('/student/bus-stop'),
                              showDivider: true,
                            ),
                            _buildMapThemeSelector(
                              context,
                              themeService.mapTheme,
                              themeService.isDarkMode,
                            ),
                            ProfileListItem(
                              leadingIcon: themeService.isDarkMode
                                  ? Icons.dark_mode_rounded
                                  : Icons.light_mode_rounded,
                              iconColor: accentColor,
                              title: l10n.darkMode,
                              subtitle: l10n.toggleDarkLight,
                              trailing: Switch(
                                value: themeService.isDarkMode,
                                activeThumbColor: accentColor,
                                activeTrackColor: accentColor.withValues(alpha: 0.3),
                                onChanged: (val) => ref
                                    .read(themeServiceProvider.notifier)
                                    .toggleTheme(val),
                              ),
                              showDivider: false,
                            ),
                          ],
                        ),

                        24.heightBox,

                        // Emergency Settings (Hidden for Student, Parent, Teacher)
                        if (![
                          UserRole.student,
                          UserRole.parent,
                          UserRole.teacher,
                        ].contains(user.role)) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: ProfileSectionCard(
                              title: 'Emergency Settings',
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: const SosSoundSettings(),
                                ),
                              ],
                            ),
                          ),
                          24.heightBox,
                        ],

                        // Account and Security Section
                        ProfileSectionCard(
                          title: l10n.accountSecurity,
                          children: [
                            ProfileListItem(
                              leadingIcon: Icons.lock_outline_rounded,
                              iconColor: accentColor,
                              title: l10n.changePassword,
                              subtitle: l10n.updateCredentials,
                              onTap: () => context.push('/student/change-password'),
                              showDivider: true,
                            ),
                            ProfileListItem(
                              leadingIcon: Icons.privacy_tip_outlined,
                              iconColor: accentColor,
                              title: l10n.privacyPolicy,
                              subtitle: l10n.dataHandling,
                              onTap: () => context.push('/student/privacy-policy'),
                              showDivider: true,
                            ),
                            ProfileListItem(
                              leadingIcon: Icons.description_outlined,
                              iconColor: accentColor,
                              title: l10n.termsConditions,
                              subtitle: l10n.legalUsageRequirements,
                              onTap: () => context.push('/student/terms-conditions'),
                              showDivider: true,
                            ),
                            if ([
                              UserRole.student,
                              UserRole.parent,
                              UserRole.teacher,
                            ].contains(user.role))
                              ProfileListItem(
                                leadingIcon: Icons.payment_rounded,
                                iconColor: accentColor,
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

                        // Logout button
                        _buildLogoutButton(context),

                        32.heightBox,
                        const BottomNavSpacer(),
                      ]).pSymmetric(h: 16),
                    ]),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfileCard(BuildContext context, UserModel user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeService = ref.watch(themeServiceProvider);
    final accentColor = Color(themeService.accentColorValue);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A222D).withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Inner translucent decorative overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 60,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.06),
                      accentColor.withValues(alpha: 0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),

          VStack([
            56.heightBox, // Offset down for half-avatar overlap

            // Name and optional PRO badge
            HStack([
              user.fullName.text
                  .size(22)
                  .bold
                  .color(Theme.of(context).colorScheme.onSurface)
                  .make(),
              if (user.isPremium) ...[
                8.widthBox,
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF8F00), Color(0xFFFFC107)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF8F00).withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.workspace_premium_rounded, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        "PRO",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ], crossAlignment: CrossAxisAlignment.center).centered(),

            6.heightBox,

            // Email address
            user.email.text
                .size(13)
                .color(Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))
                .make()
                .centered(),

            16.heightBox,

            // Subscription Premium Actions banner
            if (user.isPremium)
              GestureDetector(
                onTap: () => _showSubscriptionDetailsSheet(context, true),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: isDark ? 0.12 : 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: isDark ? 0.25 : 0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                      10.widthBox,
                      Expanded(
                        child: "Premium Membership Active".text
                            .size(12)
                            .semiBold
                            .color(isDark ? Colors.amber.shade300 : Colors.amber.shade800)
                            .make(),
                      ),
                      Icon(
                        Icons.info_outline_rounded,
                        color: isDark ? Colors.amber.shade300 : Colors.amber.shade800,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: () => _showSubscriptionDetailsSheet(context, false),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentColor, Color.alphaBlend(Colors.white.withValues(alpha: 0.15), accentColor)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: Colors.white, size: 22),
                      10.widthBox,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "Upgrade to Premium",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "Unlock live map tracking & proximity alerts",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),

            16.heightBox,
          ], crossAlignment: CrossAxisAlignment.center),

          // Floating overlapping Avatar
          Positioned(
            top: -45,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: user.isPremium
                        ? Colors.amber.withValues(alpha: 0.35)
                        : accentColor.withValues(alpha: 0.25),
                    blurRadius: 16,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Hero(
                    tag: 'profile-avatar',
                    child: CircleAvatar(
                      radius: 42,
                      backgroundColor: isDark
                          ? const Color(0xFF24303E)
                          : Colors.white,
                      child: (user.fullName.isNotEmpty
                              ? user.fullName.substring(0, 1).toUpperCase()
                              : 'U')
                          .text
                          .size(30)
                          .bold
                          .color(accentColor)
                          .make(),
                    ),
                  ),

                  // Floating Edit Profile trigger bubble
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        if (context.canPop()) {
                          context.push('/student/edit-profile');
                        } else {
                          context.push('/profile/edit');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(
    BuildContext context,
    common_l10n.CommonLocalizations l10n,
  ) {
    final locale = ref.watch(localeServiceProvider);
    final themeService = ref.watch(themeServiceProvider);
    final accentColor = Color(themeService.accentColorValue);
    final currentCode = locale.languageCode;
    final languageName = currentCode == 'en'
        ? l10n.english
        : currentCode == 'te'
        ? l10n.telugu
        : l10n.hindi;

    return ProfileListItem(
      leadingIcon: Icons.language_rounded,
      iconColor: accentColor,
      title: l10n.language,
      subtitle: l10n.chooseLanguage,
      onTap: () => _showLanguageBottomSheet(context, currentCode, l10n),
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

  void _showLanguageBottomSheet(
    BuildContext context,
    String currentCode,
    common_l10n.CommonLocalizations l10n,
  ) {
    final themeService = ref.read(themeServiceProvider);
    final accentColor = Color(themeService.accentColorValue);

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final languages = [
          {'code': 'en', 'name': l10n.english, 'flag': '🇺🇸'},
          {'code': 'hi', 'name': l10n.hindi, 'flag': '🇮🇳'},
          {'code': 'te', 'name': l10n.telugu, 'flag': '🇮🇳'},
        ];

        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  l10n.chooseLanguage,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                Column(
                  children: languages.map((lang) {
                    final isSelected = currentCode == lang['code'];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? accentColor.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.15 : 0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? accentColor.withValues(alpha: 0.4)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: ListTile(
                        leading: Text(
                          lang['flag']!,
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: Text(
                          lang['name']!,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected
                                ? accentColor
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: accentColor,
                                size: 24,
                              )
                            : null,
                        onTap: () {
                          ref.read(localeServiceProvider.notifier).setLocale(Locale(lang['code']!));
                          Navigator.pop(context);
                        },
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccentColorSelector(BuildContext context, int currentColorValue) {
    final themeService = ref.watch(themeServiceProvider);
    final accentColor = Color(themeService.accentColorValue);

    return ProfileListItem(
      leadingIcon: Icons.palette_outlined,
      iconColor: accentColor,
      title: "Accent Color",
      subtitle: "Customize UI highlight colors",
      onTap: () => _showAccentColorBottomSheet(context, currentColorValue),
      trailing: HStack([
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: accentColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
        8.widthBox,
        Icon(
          Icons.chevron_right_rounded,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ]),
      showDivider: true,
    );
  }

  void _showAccentColorBottomSheet(BuildContext context, int currentColorValue) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final accents = [
          {'name': 'Turkish Blue', 'value': 0xFF00C6E6},
          {'name': 'Emerald Green', 'value': 0xFF10B981},
          {'name': 'Sunset Orange', 'value': 0xFFF97316},
          {'name': 'Electric Cyan', 'value': 0xFF06B6D4},
          {'name': 'Royal Purple', 'value': 0xFF8B5CF6},
          {'name': 'Crimson Red', 'value': 0xFFEF4444},
        ];

        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Choose Accent Theme',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: accents.map((accent) {
                        final val = accent['value'] as int;
                        final isSelected = currentColorValue == val;
                        final color = Color(val);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.12 : 0.06)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? color : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                            title: Text(
                              accent['name'] as String,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? color : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(Icons.check_circle_rounded, color: color, size: 24)
                                : null,
                            onTap: () {
                              ref.read(themeServiceProvider.notifier).setAccentColor(val);
                              Navigator.pop(context);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSubscriptionDetailsSheet(BuildContext context, bool isCurrentlyPremium) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Colors.amber,
                        size: 40,
                      ),
                    ),
                  ),
                  16.heightBox,
                  Center(
                    child: "Upasthit Premium".text
                        .size(24)
                        .bold
                        .color(Theme.of(context).colorScheme.onSurface)
                        .make(),
                  ),
                  4.heightBox,
                  Center(
                    child: "Experience college bus transit like never before"
                        .text
                        .size(13)
                        .color(Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))
                        .make(),
                  ),

                  24.heightBox,

                  "PREMIUM FEATURES"
                      .text
                      .size(11)
                      .bold
                      .letterSpacing(1.2)
                      .color(Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))
                      .make(),
                  12.heightBox,

                  _buildPremiumFeatureRow(
                    context,
                    Icons.map_rounded,
                    "Real-Time Map Tracking",
                    "Track the exact coordinate location of your college bus in real time.",
                  ),
                  _buildPremiumFeatureRow(
                    context,
                    Icons.notifications_active_rounded,
                    "Instant Proximity Alerts",
                    "Receive alerts when the bus is within 1km or 5 mins of your stop.",
                  ),
                  _buildPremiumFeatureRow(
                    context,
                    Icons.route_rounded,
                    "Route Progress Indicator",
                    "Check live ETA and timeline progress for all intermediate stops.",
                  ),
                  _buildPremiumFeatureRow(
                    context,
                    Icons.bolt_rounded,
                    "Priority Coordination",
                    "Direct emergency sound options and coordinator priority lines.",
                  ),

                  24.heightBox,

                  // Plans selection
                  if (!isCurrentlyPremium) ...[
                    "SELECT YOUR PLAN"
                        .text
                        .size(11)
                        .bold
                        .letterSpacing(1.2)
                        .color(Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))
                        .make(),
                    12.heightBox,
                    Row(
                      children: [
                        Expanded(
                          child: _buildPlanSelectionCard(
                            context,
                            "Monthly",
                            "₹99",
                            "Renews monthly",
                            isSelected: true,
                          ),
                        ),
                        12.widthBox,
                        Expanded(
                          child: _buildPlanSelectionCard(
                            context,
                            "Annual",
                            "₹799",
                            "Save 33% yearly",
                            isSelected: false,
                            badgeText: "SAVE 33%",
                          ),
                        ),
                      ],
                    ),
                    24.heightBox,
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const PaymentScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Subscribe Now",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.2),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 32),
                          8.heightBox,
                          "You're a Premium Member".text.bold.size(15).color(Colors.green.shade700).make(),
                          4.heightBox,
                          "Enjoy all the high-end premium features and real-time transit updates."
                              .text
                              .size(12)
                              .align(TextAlign.center)
                              .color(Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))
                              .make(),
                        ],
                      ),
                    ),
                  ],
                  24.heightBox,
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPremiumFeatureRow(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    final themeService = ref.read(themeServiceProvider);
    final accentColor = Color(themeService.accentColorValue);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check_rounded, color: Colors.green, size: 18),
          ),
          12.widthBox,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title.text.bold.size(14).color(Theme.of(context).colorScheme.onSurface).make(),
                4.heightBox,
                description.text
                    .size(12)
                    .color(Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))
                    .make(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSelectionCard(
    BuildContext context,
    String planName,
    String price,
    String billing, {
    required bool isSelected,
    String? badgeText,
  }) {
    final themeService = ref.read(themeServiceProvider);
    final accentColor = Color(themeService.accentColorValue);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.amber.withValues(alpha: isDark ? 0.12 : 0.06)
                : (isDark ? const Color(0xFF1A222D) : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? Colors.amber
                  : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              planName.text.bold.size(15).color(Theme.of(context).colorScheme.onSurface).make(),
              8.heightBox,
              price.text.size(24).bold.color(accentColor).make(),
              4.heightBox,
              billing.text
                  .size(11)
                  .color(Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))
                  .make(),
            ],
          ),
        ),
        if (badgeText != null)
          Positioned(
            top: -12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badgeText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMapThemeSelector(
    BuildContext context,
    String? currentTheme,
    bool isDark,
  ) {
    final themeService = ref.watch(themeServiceProvider);
    final accentColor = Color(themeService.accentColorValue);

    String themeDisplayName(String? themeKey) {
      switch (themeKey) {
        case 'standard':
          return 'Standard';
        case 'dark':
          return 'Dark Mode';
        case 'retro':
          return 'Retro';
        case 'aubergine':
          return 'Aubergine';
        case 'uber':
          return 'Uber';
        case 'ola':
          return 'Ola';
        case 'auto':
        default:
          return 'System Default';
      }
    }

    IconData themeIcon(String? themeKey) {
      switch (themeKey) {
        case 'standard':
          return Icons.wb_sunny_outlined;
        case 'dark':
          return Icons.dark_mode_outlined;
        case 'retro':
          return Icons.explore_outlined;
        case 'aubergine':
          return Icons.palette_outlined;
        case 'uber':
          return Icons.local_taxi_outlined;
        case 'ola':
          return Icons.directions_car_outlined;
        case 'auto':
        default:
          return Icons.brightness_auto_outlined;
      }
    }

    return ProfileListItem(
      leadingIcon: Icons.map_outlined,
      iconColor: accentColor,
      title: 'Map Theme',
      subtitle: 'Change Google Maps styling',
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (context) {
            return Consumer(
              builder: (context, ref, child) {
                final currentMapTheme = ref.watch(themeServiceProvider).mapTheme;
                final themes = [
                  'auto',
                  'standard',
                  'dark',
                  'retro',
                  'aubergine',
                  'uber',
                  'ola',
                ];

                return SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Drag handle
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Text(
                          'Select Map Theme',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: themes.map((themeKey) {
                                final isSelected = currentMapTheme == themeKey;
                                return ListTile(
                                  leading: Icon(
                                    themeIcon(themeKey),
                                    color: isSelected
                                        ? accentColor
                                        : Theme.of(context).colorScheme.onSurface,
                                  ),
                                  title: isSelected
                                      ? themeDisplayName(themeKey).text.bold
                                          .color(accentColor)
                                          .make()
                                      : themeDisplayName(themeKey).text
                                          .color(Theme.of(context).colorScheme.onSurface)
                                          .make(),
                                  trailing: isSelected
                                      ? Icon(
                                          Icons.check_circle_rounded,
                                          color: accentColor,
                                        )
                                      : null,
                                  onTap: () {
                                    ref.read(themeServiceProvider.notifier).setMapTheme(themeKey);
                                    ref.invalidate(mapStyleProvider);
                                    Navigator.pop(context);
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
      trailing: HStack([
        themeDisplayName(currentTheme).text.bold
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
    Color color, {
    bool fullWidth = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return VxBox(
          child: HStack([
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withValues(alpha: isDark ? 0.25 : 0.12),
                  width: 1.0,
                ),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            12.widthBox,
            VStack([
              label.text
                  .size(11)
                  .semiBold
                  .uppercase
                  .letterSpacing(0.8)
                  .color(
                    Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.45),
                  )
                  .make(),
              4.heightBox,
              value.text
                  .size(15)
                  .bold
                  .color(Theme.of(context).colorScheme.onSurface)
                  .make(),
            ], crossAlignment: CrossAxisAlignment.start).expand(),
          ]),
        )
        .color(isDark ? const Color(0xFF1A222D).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.9))
        .border(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
          width: 1.5,
        )
        .roundedLg
        .p12
        .make()
        .w(fullWidth ? double.infinity : context.percentWidth * 44);
  }

  Widget _buildLogoutButton(BuildContext context) {
    final l10n = common_l10n.CommonLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: isDark ? 0.12 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () async {
          final confirmed = await LogoutConfirmationDialog.show(
            context,
          );
          if (confirmed) {
            await ref.read(authProvider.notifier).signOut();
          }
        },
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: Text(l10n.logout),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE53935),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.red.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileScreenSkeleton extends StatelessWidget {
  const ProfileScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = context.isTabletLayout || context.isDesktopLayout;

    Widget buildMainSkeleton(BuildContext context) {
      return VStack([
        (MediaQuery.of(context).padding.top + kToolbarHeight + 64).heightBox,

        // Overlapping card skeleton
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1A222D).withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              width: 1.5,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              VStack([
                50.heightBox, // Offset down for half-avatar
                const SkeletonBox(width: 140, height: 22, borderRadius: 6).centered(),
                10.heightBox,
                const SkeletonBox(width: 200, height: 12, borderRadius: 4).centered(),
                16.heightBox,
              ]),
              // Floating overlapping avatar skeleton
              const Positioned(
                top: -65,
                child: SkeletonBox.circle(size: 88),
              ),
            ],
          ),
        ),

        24.heightBox,

        VStack([
          // Quick stats grid skeleton
          HStack([
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1A222D).withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const SkeletonBox.circle(size: 40),
                    12.widthBox,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SkeletonBox(width: 40, height: 8),
                        SizedBox(height: 6),
                        SkeletonBox(width: 80, height: 14),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            12.widthBox,
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1A222D).withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const SkeletonBox.circle(size: 40),
                    12.widthBox,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SkeletonBox(width: 45, height: 8),
                        SizedBox(height: 6),
                        SkeletonBox(width: 70, height: 14),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ]),

          12.heightBox,

          // Full width stat card skeleton
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1A222D).withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const SkeletonBox.circle(size: 40),
                12.widthBox,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonBox(width: 50, height: 8),
                    SizedBox(height: 6),
                    SkeletonBox(width: 150, height: 14),
                  ],
                ),
              ],
            ),
          ),

          24.heightBox,

          // Preferences card skeleton
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1A222D).withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: List.generate(3, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      const SkeletonBox.circle(size: 42),
                      16.widthBox,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            SkeletonBox(width: 100, height: 14),
                            SizedBox(height: 6),
                            SkeletonBox(width: 160, height: 10),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),

          32.heightBox,
        ]).pSymmetric(h: 16),
      ]);
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF12181F) : const Color(0xFFF5F7FA),
      body: Shimmer(
        child: Stack(
          children: [
            // Backdrop Gradient mockup
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: isWide ? 180 : 240,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      isDark
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : AppColors.primary.withValues(alpha: 0.2),
                      isDark
                          ? const Color(0xFF1E3C40).withValues(alpha: 0.2)
                          : AppColors.primary.withValues(alpha: 0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(isWide ? 24 : 40),
                    bottomRight: Radius.circular(isWide ? 24 : 40),
                  ),
                ),
              ),
            ),

            isWide
                ? SafeArea(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left skeleton pane
                        Expanded(
                          flex: 4,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            child: VStack([
                              30.heightBox,
                              // Card skeleton
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1A222D).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                child: Column(
                                  children: [
                                    50.heightBox,
                                    const SkeletonBox(width: 140, height: 22, borderRadius: 6).centered(),
                                    10.heightBox,
                                    const SkeletonBox(width: 200, height: 12, borderRadius: 4).centered(),
                                    16.heightBox,
                                  ],
                                ),
                              ),
                              24.heightBox,
                              const SkeletonBox(width: double.infinity, height: 60, borderRadius: 16),
                              12.heightBox,
                              const SkeletonBox(width: double.infinity, height: 60, borderRadius: 16),
                              12.heightBox,
                              const SkeletonBox(width: double.infinity, height: 60, borderRadius: 16),
                            ]),
                          ),
                        ),
                        // Divider
                        Container(width: 1.5, color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
                        // Right skeleton pane
                        Expanded(
                          flex: 5,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            child: VStack([
                              // Settings card skeleton
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1A222D).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Column(
                                  children: List.generate(4, (index) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      child: Row(
                                        children: [
                                          const SkeletonBox.circle(size: 42),
                                          16.widthBox,
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: const [
                                                SkeletonBox(width: 100, height: 14),
                                                SizedBox(height: 6),
                                                SkeletonBox(width: 160, height: 10),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                              ),
                              24.heightBox,
                              // Account card skeleton
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1A222D).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Column(
                                  children: List.generate(3, (index) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      child: Row(
                                        children: [
                                          const SkeletonBox.circle(size: 42),
                                          16.widthBox,
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: const [
                                                SkeletonBox(width: 120, height: 14),
                                                SizedBox(height: 6),
                                                SkeletonBox(width: 140, height: 10),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: buildMainSkeleton(context),
                  ),
          ],
        ),
      ),
    );
  }
}
