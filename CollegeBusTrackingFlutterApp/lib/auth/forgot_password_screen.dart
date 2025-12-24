import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:email_validator/email_validator.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/widgets/custom_input_field.dart';
import 'package:collegebus/widgets/custom_button.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/widgets/success_modal.dart';
import 'package:collegebus/widgets/api_error_modal.dart';
import 'package:velocity_x/velocity_x.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final email = _emailController.text.trim();

      // Check if user exists first? sendOtp does that.
      final result = await authService.sendOtp(email);

      if (!mounted) return;

      if (result['success']) {
        await SuccessModal.show(
          context: context,
          title: 'OTP Sent',
          message: 'Please check your email for the verification code.',
          icon: Icons.email_rounded,
          autoCloseDurationSeconds: 2,
        );
        if (mounted) {
          context.push(
            '/otp-verify',
            extra: {'email': email, 'isResetPassword': true},
          );
        }
      } else {
        _showErrorSnackBar(result['message']);
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('An error occurred. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ApiErrorModal.show(context: context, error: message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ZStack([
        // Main Content
        VStack([
          AppSizes.paddingXLarge.heightBox,

          // Header
          Icon(Icons.lock_reset, size: 80, color: AppColors.primary).centered(),

          AppSizes.paddingLarge.heightBox,

          'Reset Password'.text
              .size(28)
              .bold
              .color(Theme.of(context).colorScheme.onSurface)
              .makeCentered(),

          AppSizes.paddingMedium.heightBox,

          'Enter your email address and we\'ll send you a OTP to reset your password.'
              .text
              .size(16)
              .color(
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              )
              .center
              .makeCentered(),

          AppSizes.paddingXLarge.heightBox,

          // Email field
          Form(
            key: _formKey,
            child: CustomInputField(
              label: 'Email',
              hint: 'Enter your email address',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.email_outlined),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!EmailValidator.validate(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
          ),

          AppSizes.paddingLarge.heightBox,

          // Reset button
          CustomButton(
            text: 'Send OTP',
            onPressed: _handleResetPassword,
            isLoading: _isLoading,
          ),

          AppSizes.paddingMedium.heightBox,

          // Back to login
          GestureDetector(
            onTap: () => context.go('/login'),
            child: 'Back to Login'.text.semiBold
                .color(AppColors.primary)
                .makeCentered(),
          ),

          AppSizes.paddingXLarge.heightBox,

          // Note
          HStack([
                Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                  size: AppSizes.iconMedium,
                ),
                AppSizes.paddingMedium.widthBox,
                'Check your email inbox and spam folder for the OTP.'.text
                    .color(AppColors.primary)
                    .size(14)
                    .make()
                    .expand(),
              ])
              .p(AppSizes.paddingMedium)
              .box
              .color(AppColors.primary.withValues(alpha: 0.1))
              .rounded
              .make(),
        ]).p(AppSizes.paddingLarge).scrollVertical().safeArea(),

        // Back Button (Top Left)
        IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => context.go('/login'),
        ).safeArea().p16(),
      ]),
    );
  }
}
