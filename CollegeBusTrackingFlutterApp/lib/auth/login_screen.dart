import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/widgets/custom_input_field.dart';
import 'package:velocity_x/velocity_x.dart';

import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/widgets/api_error_modal.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collegebus/l10n/login/auth_login_localizations.dart';
import 'package:collegebus/widgets/language_selector.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(
    text: 'darkbutterflystar31@gmail.com',
  );
  final _passwordController = TextEditingController(text: 'a');
  bool _isLoading = false;
  String? _pendingApprovalMessage;
  String? _lastTriedEmail;
  String? _lastTriedPassword;
  UserRole _selectedRole = UserRole.student;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin({String? email, String? password}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _pendingApprovalMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final loginEmail = email ?? _emailController.text.trim();
      final loginPassword = password ?? _passwordController.text;
      _lastTriedEmail = loginEmail;
      _lastTriedPassword = loginPassword;

      final result = await authService.loginUser(
        email: loginEmail,
        password: loginPassword,
      );

      if (result['success']) {
        final userRole = authService.userRole;
        String route = '/login'; // default fallback

        switch (userRole) {
          case UserRole.student:
          case UserRole.parent:
            route = '/student';
            break;
          case UserRole.teacher:
            route = '/teacher';
            break;
          case UserRole.driver:
            route = '/driver';
            break;
          case UserRole.busCoordinator:
            route = '/coordinator';
            break;
          case UserRole.admin:
            route = '/admin';
            break;
          case null:
            route = '/login';
            break;
        }
        if (!mounted) return;
        context.go(route);
      } else {
        if (!mounted) return;
        _showErrorSnackBar(result['message']);
        if (result['needsEmailVerification'] == true) {
          _showEmailVerificationDialog();
        }
        if (result['message']?.toLowerCase().contains('pending approval') ==
            true) {
          setState(() {
            _pendingApprovalMessage = result['message'];
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      final l10n = LoginLocalizations.of(context)!;
      _showErrorSnackBar(l10n.genericError);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ApiErrorModal.show(context: context, error: message);
  }

  void _showEmailVerificationDialog() {
    final l10n = LoginLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => ApiErrorModal(
        title: l10n.verifyEmail,
        message: l10n.verifyEmailMessage,
        icon: Icons.mark_email_read_rounded,
        baseColor: Colors.orangeAccent,
        primaryActionText: l10n.ok,
        onPrimaryAction: () => Navigator.pop(context),
        secondaryActionText: l10n.resendVerification,
        onSecondaryAction: () async {
          final authService = Provider.of<AuthService>(context, listen: false);
          Navigator.pop(context);

          await authService.resendEmailVerification();
          if (!mounted) return;

          // Show feedback
          ApiErrorModal.show(
            context: context,
            error: l10n.verificationEmailSent,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LoginLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: VStack([
        // Header Image & Logo Section
        ZStack(
          [
            // Background Image
            VxBox()
                .bgImage(
                  DecorationImage(
                    image: CachedNetworkImageProvider(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuAhoVjzOMAAtG2ZhYD-_E4cE8rln6afXo2yCEcciNGD-ETd6sJlt_OR5iE5TVIWrcY0JwmrUmn8VEV2Zlcmu-4aT3JKaN2lWbBU_AOLHjKFAtKYbJWGQ1cAtLiEc4-roVY0L5XDKurzZXwWHlHbGCzQMHxWCMzzfYc3yfLkok2ulqHzUdm39kVAqaSy9_4pKylchOvtBqv2qJQGzbd38cEODfoaAjfJCsln4aXfowd69XBQLr4Sbx8-33NOJjziZW-FFtvvuAUOmJke',
                    ),
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

            // Floating Logo
            VxBox(
                  child: Icon(
                    Icons.directions_bus_rounded,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ).white.rounded.shadow
                .size(70, 70)
                .make()
                .centered()
                .pOnly(bottom: 0) // Adjusted since we are in VStack/ZStack
                .positioned(bottom: -35, left: 0, right: 0),
          ],
          alignment: Alignment.bottomCenter,
          fit: StackFit.loose,
        ).h(280 + 35), // Enable overflow space or explicitly size

        50.heightBox,

        // Main Content
        Form(
          key: _formKey,
          child: VStack([
            // Headlines
            l10n.trackYourRide.text
                .size(28)
                .bold
                .color(
                  Theme.of(context).textTheme.headlineMedium?.color ??
                      AppColors.textPrimary,
                )
                .letterSpacing(-0.5)
                .makeCentered(),

            8.heightBox,

            l10n.loginDescription.text
                .size(12)
                .color(
                  Theme.of(context).textTheme.bodyMedium?.color ??
                      AppColors.textSecondary,
                )
                .center
                .makeCentered()
                .px16(),

            16.heightBox,

            // Account Input
            l10n.email.text.semiBold
                .color(
                  Theme.of(context).textTheme.bodyLarge?.color ??
                      AppColors.textPrimary,
                )
                .make(),
            8.heightBox,
            CustomInputField(
              label: '',
              hint: l10n.emailOrPhone,
              controller: _emailController,
              prefixIcon: const Icon(Icons.email_outlined),
              validator: (value) =>
                  (value == null || value.isEmpty) ? l10n.requiredField : null,
            ),

            20.heightBox,

            // Password Input
            l10n.password.text.semiBold
                .color(
                  Theme.of(context).textTheme.bodyLarge?.color ??
                      AppColors.textPrimary,
                )
                .make(),
            8.heightBox,
            CustomInputField(
              label: '',
              hint: l10n.password,
              controller: _passwordController,
              isPassword: true,
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              validator: (value) =>
                  (value == null || value.isEmpty) ? l10n.requiredField : null,
            ),

            // Forgot Password
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => context.push('/forgot-password'),
                child: l10n.forgotPassword.text.semiBold
                    .color(AppColors.primary)
                    .make()
                    .p8(), // padding still works
              ),
            ),

            16.heightBox,

            // Login Button
            ElevatedButton(
              onPressed: _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ).box.size(24, 24).make()
                  : HStack([
                      l10n.login.text.size(16).bold.make(),
                      8.widthBox,
                      const Icon(Icons.arrow_forward_rounded),
                    ], alignment: MainAxisAlignment.center),
            ).h(56).wFull(context),

            32.heightBox,

            // Footer
            HStack([
              l10n.newHere.text.color(AppColors.textSecondary).make(),
              GestureDetector(
                onTap: () => context.go('/register'),
                child: l10n.createAccount.text.bold
                    .color(AppColors.primary)
                    .make(),
              ),
            ], alignment: MainAxisAlignment.center).centered(),

            32.heightBox,
          ]).pSymmetric(h: AppSizes.paddingLarge),
        ),
      ]).scrollVertical(),
    );
  }
}
