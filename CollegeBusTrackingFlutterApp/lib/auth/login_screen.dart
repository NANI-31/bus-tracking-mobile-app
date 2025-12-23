import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/widgets/custom_input_field.dart';

import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/widgets/api_error_modal.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
      _showErrorSnackBar('An error occurred. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    void _showErrorSnackBar(String message) {
      ApiErrorModal.show(context: context, error: message);
    }
  }

  void _showEmailVerificationDialog() {
    showDialog(
      context: context,
      builder: (context) => ApiErrorModal(
        title: 'Verify Email',
        message: 'Please verify your email address. Check your inbox.',
        icon: Icons.mark_email_read_rounded,
        baseColor: Colors.orangeAccent,
        primaryActionText: 'OK',
        onPrimaryAction: () => Navigator.pop(context),
        secondaryActionText: 'Resend Verification',
        onSecondaryAction: () async {
          final authService = Provider.of<AuthService>(context, listen: false);
          Navigator.pop(
            context,
          ); // Close dialog first to avoid stack issues? Or keep open?
          // "Resend" usually triggers action then maybe shows success.
          // Let's close, trigger, and show success snackbar/modal.

          await authService.resendEmailVerification();
          if (!mounted) return;

          // Show feedback
          ApiErrorModal.show(
            context: context,
            error: "Verification email sent!",
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Image & Logo Section
            Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                // Background Image
                Container(
                  height: 280,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuAhoVjzOMAAtG2ZhYD-_E4cE8rln6afXo2yCEcciNGD-ETd6sJlt_OR5iE5TVIWrcY0JwmrUmn8VEV2Zlcmu-4aT3JKaN2lWbBU_AOLHjKFAtKYbJWGQ1cAtLiEc4-roVY0L5XDKurzZXwWHlHbGCzQMHxWCMzzfYc3yfLkok2ulqHzUdm39kVAqaSy9_4pKylchOvtBqv2qJQGzbd38cEODfoaAjfJCsln4aXfowd69XBQLr4Sbx8-33NOJjziZW-FFtvvuAUOmJke',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.background.withOpacity(0.2),
                          AppColors.background,
                        ],
                        stops: const [0.6, 0.9, 1.0],
                      ),
                    ),
                  ),
                ),
                // Floating Logo
                Positioned(
                  bottom: -30,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.directions_bus_rounded,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 50), // Space for matching floating logo
            // Main Content
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingLarge,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Headlines
                    const Text(
                      'Track your ride.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Log in to view real-time bus schedules and campus routes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Inputs on left alignment labels
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Account',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomInputField(
                      label: '', // Label handled externally for this design
                      hint: 'Email or Phone Number',
                      controller: _emailController,
                      prefixIcon: const Icon(Icons.email_outlined),
                      validator: (value) {
                        return (value == null || value.isEmpty)
                            ? 'Required'
                            : null;
                      },
                    ),

                    const SizedBox(height: 20),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Password',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomInputField(
                      label: '',
                      hint: 'Password',
                      controller: _passwordController,
                      isPassword: true,
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      validator: (value) {
                        return (value == null || value.isEmpty)
                            ? 'Required'
                            : null;
                      },
                    ),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Login Button (Full Width Blue)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => _handleLogin(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'New here? ',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/register'),
                          child: const Text(
                            'Create an Account',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32), // Bottom padding
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
