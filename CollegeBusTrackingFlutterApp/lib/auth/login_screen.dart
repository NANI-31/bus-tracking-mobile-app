import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/widgets/custom_input_field.dart';
import 'package:velocity_x/velocity_x.dart';

import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/widgets/api_error_modal.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collegebus/l10n/auth/login/auth_login_localizations.dart';
import 'package:collegebus/widgets/language_selector.dart';
import 'package:collegebus/models/user_model.dart';
import 'package:collegebus/models/college_model.dart';
import 'package:collegebus/services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _bounceAnimation;
  final _emailController = TextEditingController(text: 'c@kkr.ac.in');
  final _passwordController = TextEditingController(text: 'a');
  bool _isLoading = false;

  // Testing Tool State
  List<UserModel> _allTestUsers = [];
  List<CollegeModel> _allColleges = [];
  UserRole? _selectedTestRole;
  CollegeModel? _selectedTestCollege;
  bool _isFetchingTestUsers = false;

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

    _fetchTestData();
  }

  Future<void> _fetchTestData() async {
    setState(() => _isFetchingTestUsers = true);
    try {
      final apiService = ApiService();
      final users = await apiService.getAllUsers();
      final colleges = await apiService.getAllColleges();
      setState(() {
        _allTestUsers = users;
        _allColleges = colleges;
      });
    } catch (e) {
      debugPrint('Error fetching test data: $e');
    } finally {
      setState(() => _isFetchingTestUsers = false);
    }
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
      final authService = Provider.of<AuthService>(context, listen: false);
      final loginEmail = email ?? _emailController.text.trim();
      final loginPassword = password ?? _passwordController.text;

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

                // Floating Logo with bounce animation
                AnimatedBuilder(
                  animation: _bounceAnimation,
                  builder: (context, child) {
                    return VxBox(
                          child: Icon(
                            Icons.directions_bus_rounded,
                            color: AppColors.primary,
                            size: 32,
                          ),
                        ).white.rounded.shadow
                        .size(70, 70)
                        .make()
                        .centered()
                        .pOnly(bottom: 0)
                        .positioned(
                          bottom: -35 + _bounceAnimation.value,
                          left: 0,
                          right: 0,
                        );
                  },
                ),
              ],
              alignment: Alignment.bottomCenter,
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

                    // --- TESTING TOOL START ---
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'TEST TOOL (DEV ONLY)',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: UserRole.values
                                .map(
                                  (role) => ChoiceChip(
                                    label: Text(
                                      role.displayName,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    selected: _selectedTestRole == role,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedTestRole = selected
                                            ? role
                                            : null;
                                        _selectedTestCollege =
                                            null; // Reset college on role change
                                      });
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                          if (_selectedTestRole != null) ...[
                            const SizedBox(height: 12),
                            const Text(
                              'Select College:',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: _allColleges
                                  .map(
                                    (college) => ChoiceChip(
                                      label: Text(
                                        college.name.split(' ').first,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                      selected:
                                          _selectedTestCollege?.id ==
                                          college.id,
                                      onSelected: (selected) {
                                        setState(() {
                                          _selectedTestCollege = selected
                                              ? college
                                              : null;
                                        });
                                      },
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                          if (_selectedTestRole != null &&
                              _selectedTestCollege != null) ...[
                            const SizedBox(height: 12),
                            if (_isFetchingTestUsers)
                              const CircularProgressIndicator().centered()
                            else if (_allTestUsers
                                .where(
                                  (u) =>
                                      u.role == _selectedTestRole &&
                                      u.collegeId == _selectedTestCollege!.id,
                                )
                                .isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'No users found',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: _allTestUsers
                                    .where(
                                      (u) =>
                                          u.role == _selectedTestRole &&
                                          u.collegeId ==
                                              _selectedTestCollege!.id,
                                    )
                                    // Ensure unique IDs to prevent UI confusion
                                    .fold<List<UserModel>>([], (list, u) {
                                      if (!list.any((e) => e.id == u.id))
                                        list.add(u);
                                      return list;
                                    })
                                    .map(
                                      (user) => ActionChip(
                                        avatar: Icon(
                                          Icons.person,
                                          size: 14,
                                          color: AppColors.primary,
                                        ),
                                        label: Text(
                                          '${user.fullName.split(' ').first} (${user.email.split('@').first})',
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _emailController.text = user.email;
                                            _passwordController.text = 'a';
                                          });
                                        },
                                      ),
                                    )
                                    .toList(),
                              ).centered(),
                          ],
                        ],
                      ),
                    ),
                    const Divider().pSymmetric(v: 16),
                    // --- TESTING TOOL END ---

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
                      validator: (value) => (value == null || value.isEmpty)
                          ? l10n.requiredField
                          : null,
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
