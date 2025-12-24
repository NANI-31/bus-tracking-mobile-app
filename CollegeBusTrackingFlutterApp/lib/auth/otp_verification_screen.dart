import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/widgets/custom_button.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:pinput/pinput.dart';
import 'package:collegebus/widgets/api_error_modal.dart';
import 'package:collegebus/widgets/success_modal.dart';
import 'package:velocity_x/velocity_x.dart';

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
  bool _canResend = false;

  int _timerKey = 0;

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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResendOtp() async {
    if (!_canResend) return;

    setState(() => _canResend = false);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.sendOtp(widget.email);

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP sent successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() {
          _timerKey++;
          _canResend = false;
        });
      } else {
        _showErrorSnackBar(result['message']);
        setState(() => _canResend = true);
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Failed to resend OTP');
      setState(() => _canResend = true);
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
        Navigator.pop(context);
        context.go('/login');
      },
      primaryActionText: 'Login Now',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.onSurface.withValues(alpha: 0.2);
    final focusedBorderColor = theme.primaryColor;
    final fillColor = theme.colorScheme.surface;

    final defaultPinTheme = PinTheme(
      width: 50,
      height: 60,
      textStyle: TextStyle(
        fontSize: 22,
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      ),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingLarge,
            vertical: AppSizes.paddingXLarge,
          ),
          child: VStack([
            40.heightBox,

            // Header Icon
            Icon(
                  Icons.mark_email_read_rounded,
                  color: AppColors.primary,
                  size: 48,
                ).box.roundedFull
                .color(AppColors.primary.withValues(alpha: 0.1))
                .size(100, 100)
                .make(),

            32.heightBox,

            // Title
            'Verification Code'.text
                .size(26)
                .bold
                .color(theme.colorScheme.onSurface)
                .make(),

            16.heightBox,

            // Subtitle
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                ),
                children: [
                  const TextSpan(
                    text: 'We have sent the verification code to\n',
                  ),
                  TextSpan(
                    text: widget.email,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            40.heightBox,

            // OTP Input
            Pinput(
              length: 6,
              controller: _otpController,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: defaultPinTheme.copyWith(
                decoration: defaultPinTheme.decoration!.copyWith(
                  border: Border.all(color: focusedBorderColor, width: 2),
                  color: theme.colorScheme.surface,
                ),
              ),
              submittedPinTheme: defaultPinTheme.copyWith(
                decoration: defaultPinTheme.decoration!.copyWith(
                  color: theme.colorScheme.surface,
                ),
              ),
              onCompleted: (pin) => _handleVerifyOtp(),
            ),

            30.heightBox,

            // Timer Text or Resend Button
            SizedBox(
              height: 25,
              child: Center(
                child: !_canResend
                    ? CountdownWidget(
                        key: ValueKey(_timerKey),
                        duration: 59,
                        onFinish: () => setState(() => _canResend = true),
                      )
                    : 'Resend Code'.text
                          .size(16)
                          .bold
                          .color(AppColors.primary)
                          .make()
                          .onInkTap(_handleResendOtp),
              ),
            ),

            20.heightBox,

            // Verify Button
            CustomButton(
              text: 'Verify',
              onPressed: _handleVerifyOtp,
              isLoading: _isLoading,
              height: 56,
              borderRadius: 30,
            ),

            16.heightBox,

            // Change Number/Email
            'Change Number/Email'.text.medium
                .size(14)
                .color(theme.colorScheme.onSurface.withValues(alpha: 0.5))
                .make()
                .onInkTap(() => context.pop()),
          ], crossAlignment: CrossAxisAlignment.center),
        ),
      ),
    );
  }
}

class CountdownWidget extends StatefulWidget {
  final int duration;
  final VoidCallback onFinish;

  const CountdownWidget({
    super.key,
    required this.duration,
    required this.onFinish,
  });

  @override
  State<CountdownWidget> createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<CountdownWidget> {
  late Timer _timer;
  late int _start;

  @override
  void initState() {
    super.initState();
    _start = widget.duration;
    startTimer();
  }

  void startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(oneSec, (Timer timer) {
      if (_start == 0) {
        timer.cancel();
        widget.onFinish();
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _timerText {
    int minutes = _start ~/ 60;
    int seconds = _start % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return HStack([
      'Resend code in '.text
          .size(15)
          .color(Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))
          .make(),
      _timerText.text.size(15).bold.color(AppColors.primary).make(),
    ], alignment: MainAxisAlignment.center);
  }
}
