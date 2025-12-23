import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/widgets/custom_button.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:pinput/pinput.dart';
import 'package:collegebus/widgets/api_error_modal.dart';
import 'package:collegebus/widgets/success_modal.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final bool isResetPassword;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    this.isResetPassword = false,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerifyOtp() async {
    if (_otpController.text.length != 6) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.verifyOtp(
        widget.email,
        _otpController.text,
      );

      if (!mounted) return;

      if (result['success']) {
        if (widget.isResetPassword) {
          context.go('/reset-password?email=${widget.email}');
        } else {
          _showSuccessDialog('Email Verified Successfully. Please login.');
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

  void _showSuccessDialog(String message) {
    SuccessModal.show(
      context: context,
      title: 'Success',
      message: message,
      icon: Icons.check_circle_rounded,
      onPrimaryAction: () {
        Navigator.pop(context); // Close modal
        context.go('/login');
      },
      primaryActionText: 'Login Now',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('OTP Verification'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSizes.paddingXLarge),
              const Text(
                'Enter Verification Code',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSizes.paddingSmall),
              Text(
                'We have sent a code to ${widget.email}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSizes.paddingXLarge),
              Pinput(
                length: 6,
                controller: _otpController,
                defaultPinTheme: PinTheme(
                  width: 56,
                  height: 56,
                  textStyle: const TextStyle(
                    fontSize: 20,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                focusedPinTheme: PinTheme(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onCompleted: (pin) => _handleVerifyOtp(),
              ),
              const SizedBox(height: AppSizes.paddingXLarge),
              CustomButton(
                text: 'Verify',
                onPressed: _handleVerifyOtp,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
