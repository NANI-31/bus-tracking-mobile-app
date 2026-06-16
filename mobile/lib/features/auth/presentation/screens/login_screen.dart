import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:collegebus/core/providers/providers.dart';
import 'package:collegebus/shared/widgets/custom_input_field.dart';
import 'package:velocity_x/velocity_x.dart';

import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/shared/widgets/api_error_modal.dart';
import 'package:collegebus/l10n/auth/login/auth_login_localizations.dart';
import 'package:collegebus/shared/widgets/language_selector.dart';
import 'package:collegebus/shared/widgets/buttons/rive_loading_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _bounceAnimation;
  final _emailController = TextEditingController(text: 'c@kkr.ac.in');
  final _passwordController = TextEditingController(text: 'a');
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Hide Status Bar
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom],
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin({String? email, String? password}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authNotifier = ref.read(authProvider.notifier);
      final loginEmail = email ?? _emailController.text.trim();
      final loginPassword = password ?? _passwordController.text;

      final result = await authNotifier.loginUser(
        email: loginEmail,
        password: loginPassword,
      );

      if (result['success']) {
        setState(() {
          _isLoading = false;
        });

        // Log the success and check provider state
        debugPrint('LOGIN SUCCESS: ${result['message']}');

        final userRole = ref.read(userRoleProvider);
        debugPrint('RESOLVED ROLE from provider: $userRole');

        // Check actual auth state directly
        final authState = ref.read(authProvider);
        debugPrint('AUTH STATE value: ${authState.value?.currentUser?.role}');

        String route = '/login'; // default fallback

        switch (userRole) {
          case UserRole.student:
          case UserRole.parent:
            route = '/student';
            break;
          case UserRole.teacher:
            route = '/student';
            break;
          case UserRole.driver:
            route = '/driver';
            break;
          case UserRole.busCoordinator:
            route = '/coordinator';
            break;
          case UserRole.collegeAdmin:
            route = '/college-admin';
            break;
          case UserRole.superAdmin:
            route = '/super-admin';
            break;
          case null:
            debugPrint('WARNING: UserRole is NULL, staying on /login');
            route = '/login';
            break;
        }

        debugPrint('NAVIGATING TO: $route');

        if (!mounted) return;
        context.go(route);
      } else {
        debugPrint('LOGIN FAILED: ${result['message']}');
        if (!mounted) return;

        if (result['requiresVerification'] == true) {
          // If unverified, redirect to OTP screen immediately
          context.push(
            '/otp-verify',
            extra: {'email': loginEmail, 'isResetPassword': false},
          );
          _showErrorSnackBar('Please verify your email to continue.');
          return;
        }

        _showErrorSnackBar(result['message']);
      }
    } catch (e) {
      if (!mounted) return;
      final l10n = LoginLocalizations.of(context)!;
      _showErrorSnackBar(l10n.genericError);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ApiErrorModal.show(context: context, error: message);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LoginLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        top: false, // Allow content to extend into status bar area
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header Image & Logo Section
            ZStack(
              [
                // Background Image
                VxBox()
                    .bgImage(
                      const DecorationImage(
                        image: AssetImage('assets/images/login.png'),
                        fit: BoxFit.cover,
                      ),
                    )
                    .height(280)
                    .width(double.infinity)
                    .make(),

                // Gradient Overlay
                VxBox()
                    .withDecoration(
                      BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Theme.of(
                              context,
                            ).scaffoldBackgroundColor.withValues(alpha: 0.2),
                            Theme.of(context).scaffoldBackgroundColor,
                          ],
                          stops: const [0.6, 0.9, 1.0],
                        ),
                      ),
                    )
                    .height(280)
                    .width(double.infinity)
                    .make(),

                // Language Selector
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  right: 16,
                  child: const LanguageSelector(),
                ),

                // Floating Logo with bounce animation
                AnimatedBuilder(
                  animation: _bounceAnimation,
                  builder: (context, child) {
                    return VxBox(
                          child: Icon(
                            Icons.directions_bus_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 32,
                          ),
                        ).white.rounded.shadow
                        .size(70, 70)
                        .make()
                        .centered()
                        .pOnly(bottom: 0)
                        .positioned(
                          bottom: 0 + _bounceAnimation.value,
                          left: 0,
                          right: 0,
                        );
                  },
                ),
              ],
              alignment: Alignment.topCenter,
              fit: StackFit.loose,
            ).h(280 + 35), // Enable overflow space or explicitly size

            50.heightBox,

            // Main Content
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingLarge,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Headlines
                    l10n.trackYourRide.text
                        .size(28)
                        .bold
                        .color(
                          Theme.of(context).textTheme.headlineMedium?.color ??
                              Theme.of(context).colorScheme.onSurface,
                        )
                        .letterSpacing(-0.5)
                        .makeCentered(),

                    8.heightBox,

                    l10n.loginDescription.text
                        .size(12)
                        .color(
                          Theme.of(context).textTheme.bodyMedium?.color ??
                              Theme.of(context).colorScheme.secondary,
                        )
                        .center
                        .makeCentered()
                        .px16(),

                    16.heightBox,

                    // --- TESTING TOOL START ---
                    // --- TESTING TOOL REMOVED ---

                    // Account Input
                    l10n.emailOrPhone.text.semiBold
                        .color(
                          Theme.of(context).textTheme.bodyLarge?.color ??
                              Theme.of(context).colorScheme.onSurface,
                        )
                        .make(),
                    8.heightBox,
                    CustomInputField(
                      label: '',
                      hint: l10n.emailOrPhone,
                      controller: _emailController,
                      prefixIcon: const Icon(Icons.email_outlined),
                      validator: (value) => (value == null || value.isEmpty)
                          ? l10n.requiredField
                          : null,
                    ),

                    20.heightBox,

                    // Password Input
                    l10n.password.text.semiBold
                        .color(
                          Theme.of(context).textTheme.bodyLarge?.color ??
                              Theme.of(context).colorScheme.onSurface,
                        )
                        .make(),
                    8.heightBox,
                    CustomInputField(
                      label: '',
                      hint: l10n.password,
                      controller: _passwordController,
                      isPassword: true,
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      validator: (value) => (value == null || value.isEmpty)
                          ? l10n.requiredField
                          : null,
                    ),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => context.push('/forgot-password'),
                        child: l10n.forgotPassword.text.semiBold
                            .color(Theme.of(context).colorScheme.primary)
                            .make()
                            .p8(), // padding still works
                      ),
                    ),

                    16.heightBox,

                    // Login Button
                    RiveLoadingButton(
                      onTap: _handleLogin,
                      isLoading: _isLoading,
                      label: l10n.login,
                    ).wFull(context),

                    32.heightBox,

                    // Footer
                    HStack([
                      l10n.newHere.text
                          .color(Theme.of(context).colorScheme.secondary)
                          .make(),
                      GestureDetector(
                        onTap: () => context.go('/register'),
                        child: l10n.createAccount.text.bold
                            .color(Theme.of(context).colorScheme.primary)
                            .make(),
                      ),
                    ], alignment: MainAxisAlignment.center).centered(),

                    32.heightBox,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
