import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:email_validator/email_validator.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/services/data_service.dart';
import 'package:collegebus/widgets/custom_input_field.dart';
import 'package:collegebus/widgets/custom_button.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/models/college_model.dart';
import 'package:collegebus/widgets/api_error_modal.dart';
import 'package:collegebus/widgets/success_modal.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/l10n/signup/auth_signup_localizations.dart';
import 'package:collegebus/widgets/language_selector.dart';

// Import New Widgets
import 'package:collegebus/auth/widgets/register_header.dart';
import 'package:collegebus/auth/widgets/role_selection_grid.dart';
import 'package:collegebus/auth/widgets/college_selection_field.dart';
import 'package:collegebus/auth/widgets/coordinator_email_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'nani');
  final _emailController = TextEditingController(
    text: 'chundu.siva2k03@gmail.com',
  );
  final _passwordController = TextEditingController(text: 'nanini');
  final _confirmPasswordController = TextEditingController(text: 'nanini');
  final _collegeController = TextEditingController();
  final _phoneController = TextEditingController(text: '9701330350');
  final _rollNumberController = TextEditingController(text: '181ijwn2n2');

  UserRole _selectedRole = UserRole.student;
  bool _isLoading = false;
  List<CollegeModel> _colleges = [];
  CollegeModel? _selectedCollege;
  final _emailIdController = TextEditingController();
  final _emailDomainController = TextEditingController();
  String? _emailDomainHint;
  bool _isLoadingColleges = false;

  @override
  void initState() {
    super.initState();
    _fetchColleges();
  }

  Future<void> _fetchColleges() async {
    setState(() => _isLoadingColleges = true);
    final firestoreService = Provider.of<DataService>(context, listen: false);
    firestoreService.getAllColleges().listen((colleges) {
      if (mounted) {
        setState(() {
          _colleges = colleges;
          _isLoadingColleges = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _collegeController.dispose();
    _phoneController.dispose();
    _rollNumberController.dispose();
    _emailIdController.dispose();
    _emailDomainController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      String email = '';
      String collegeName = '';
      String? rollNumber = _selectedRole == UserRole.student
          ? _rollNumberController.text.trim()
          : null;
      String? phoneNumber = _phoneController.text.trim();

      if (_selectedRole == UserRole.busCoordinator) {
        email =
            '${_emailIdController.text.trim()}@${_emailDomainController.text.trim()}';
        collegeName = _collegeController.text.trim();
      } else {
        email = _emailController.text.trim();
        collegeName = _selectedCollege?.name ?? '';

        if (_selectedCollege != null) {
          final domain = email.split('@').last;
          final allowedDomains = _selectedCollege!.allowedDomains;

          if (!allowedDomains.contains(domain)) {
            final l10n = SignupLocalizations.of(context)!;
            final shouldContinue = await showDialog<bool>(
              context: context,
              builder: (context) => ApiErrorModal(
                title: l10n.personalEmailDetected,
                message:
                    '${l10n.personalEmailMessage}\n\nCollege domains: ${allowedDomains.join(", ")}\n\nDo you want to continue?',
                icon: Icons.warning_amber_rounded,
                baseColor: Colors.orange,
                primaryActionText: l10n.continueText,
                onPrimaryAction: () => Navigator.of(context).pop(true),
                secondaryActionText: l10n.cancel,
                onSecondaryAction: () => Navigator.of(context).pop(false),
              ),
            );

            if (shouldContinue != true) {
              setState(() => _isLoading = false);
              return;
            }
          }
        }
      }

      final result = await authService.registerUser(
        email: email,
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        collegeName: collegeName,
        role: _selectedRole,
        phoneNumber: phoneNumber,
        rollNumber: rollNumber,
      );

      if (result['success']) {
        if (email.isNotEmpty) {
          final otpResult = await authService.sendOtp(email);
          if (otpResult['success']) {
            if (!mounted) return;
            context.push(
              '/otp-verify',
              extra: {'email': email, 'isResetPassword': false},
            );
          } else {
            if (!mounted) return;
            _showErrorSnackBar(
              'Registration successful but failed to send OTP: ${otpResult['message']}',
            );
            context.go('/login');
          }
        } else {
          if (!mounted) return;
          _showSuccessDialog('Registration Successful. Please Login.');
        }
      } else {
        if (!mounted) return;
        _showErrorSnackBar(result['message']);
      }
    } catch (e) {
      if (!mounted) return;
      final l10n = SignupLocalizations.of(context)!;
      _showErrorSnackBar(l10n.genericError);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ApiErrorModal.show(context: context, error: message);
  }

  void _showSuccessDialog(String message) {
    final l10n = SignupLocalizations.of(context)!;
    SuccessModal.show(
      context: context,
      title: l10n.registrationSuccessful,
      message: message,
      icon: Icons.check_circle_rounded,
      onPrimaryAction: () {
        Navigator.pop(context);
        context.go('/login');
      },
      primaryActionText: l10n.loginNow,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = SignupLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: VStack([
        // Header Section
        ZStack([
          const RegisterHeader(),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 16,
            child: const LanguageSelector(),
          ),
        ]),

        50.heightBox, // Space for floating icon

        Form(
          key: _formKey,
          child: VStack([
            // Headline
            l10n.createAccount.text
                .size(32)
                .bold
                .color(Theme.of(context).colorScheme.onSurface)
                .letterSpacing(-0.5)
                .makeCentered(),

            8.heightBox,

            l10n.joinToTrack.text
                .size(15)
                .color(
                  Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                )
                .heightLoose
                .center
                .makeCentered(),

            32.heightBox,

            // Role Selection
            l10n.whoAreYou.text
                .size(16)
                .semiBold
                .color(Theme.of(context).colorScheme.onSurface)
                .make(),
            16.heightBox,
            RoleSelectionGrid(
              selectedRole: _selectedRole,
              onRoleSelected: (role) => setState(() => _selectedRole = role),
            ),

            32.heightBox,

            // 1. College Selection / Coordinate College Field
            if (_selectedRole == UserRole.busCoordinator)
              CustomInputField(
                label: l10n.collegeName,
                hint: l10n.collegeHint,
                controller: _collegeController,
                prefixIcon: const Icon(Icons.school_outlined),
                validator: (value) => (value == null || value.isEmpty)
                    ? l10n.requiredField
                    : null,
              )
            else
              CollegeSelectionField(
                colleges: _colleges,
                selectedCollege: _selectedCollege,
                isLoading: _isLoadingColleges,
                onChanged: (college) {
                  setState(() {
                    _selectedCollege = college;
                    if (college != null) {
                      _emailDomainHint =
                          '${l10n.collegeDomains}: ${college.allowedDomains.join(", ")}';
                    } else {
                      _emailDomainHint = null;
                    }
                  });
                },
              ),

            AppSizes.paddingMedium.heightBox,

            // 2. Full Name
            CustomInputField(
              label: l10n.fullName,
              hint: l10n.fullNameHint,
              controller: _nameController,
              prefixIcon: const Icon(Icons.person_outline_rounded),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.requiredField;
                }
                return null;
              },
            ),

            AppSizes.paddingMedium.heightBox,

            // 3. Roll Number (Student Only)
            if (_selectedRole == UserRole.student) ...[
              CustomInputField(
                label: l10n.rollNumber,
                hint: l10n.rollNumberHint,
                controller: _rollNumberController,
                prefixIcon: const Icon(Icons.badge_outlined),
                validator: (value) {
                  if (_selectedRole != UserRole.student) return null;
                  if (value == null || value.isEmpty) {
                    return l10n.requiredField;
                  }
                  return null;
                },
              ),
              AppSizes.paddingMedium.heightBox,
            ],

            // 4. Email
            if (_selectedRole == UserRole.busCoordinator)
              CoordinatorEmailField(
                idController: _emailIdController,
                domainController: _emailDomainController,
              )
            else
              VStack([
                CustomInputField(
                  label: l10n.emailAddress,
                  hint: l10n.emailAddressHint,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                  validator: (value) {
                    if (_selectedRole == UserRole.parent) {
                      if (value != null &&
                          value.isNotEmpty &&
                          !EmailValidator.validate(value)) {
                        return l10n.genericError;
                      }
                      return null;
                    }
                    if (value == null || value.isEmpty) {
                      return l10n.requiredField;
                    }
                    if (!EmailValidator.validate(value)) {
                      return l10n.genericError;
                    }
                    return null;
                  },
                ),
                if (_selectedRole != UserRole.parent &&
                    _emailDomainHint != null)
                  _emailDomainHint!.text
                      .color(AppColors.primary.withOpacity(0.8))
                      .size(12)
                      .medium
                      .make()
                      .pOnly(top: 6, left: 4),
              ]),

            AppSizes.paddingMedium.heightBox,

            // 5. Phone Number
            CustomInputField(
              label: l10n.phoneNumber,
              hint: l10n.phoneNumberHint,
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              prefixIcon: const Icon(Icons.phone_outlined),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.requiredField;
                }
                return null;
              },
            ),

            AppSizes.paddingMedium.heightBox,

            // 6. Password
            CustomInputField(
              label: l10n.password,
              hint: '••••••••',
              controller: _passwordController,
              isPassword: true,
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.requiredField;
                }
                return null;
              },
            ),

            AppSizes.paddingMedium.heightBox,

            // 7. Confirm Password
            CustomInputField(
              label: l10n.confirmPassword,
              hint: '••••••••',
              controller: _confirmPasswordController,
              isPassword: true,
              prefixIcon: const Icon(Icons.lock_reset_rounded),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.requiredField;
                }
                if (value != _passwordController.text) {
                  return l10n.passwordsDoNotMatch;
                }
                return null;
              },
            ),

            AppSizes.paddingLarge.heightBox,

            // Register button
            CustomButton(
              text: l10n.register,
              onPressed: _handleRegister,
              isLoading: _isLoading,
            ),

            AppSizes.paddingLarge.heightBox,

            // Sign in link
            HStack([
              l10n.alreadyHaveAccount.text
                  .color(AppColors.textSecondary)
                  .make(),
              GestureDetector(
                onTap: () => context.go('/login'),
                child: l10n.signIn.text.semiBold
                    .color(AppColors.primary)
                    .make(),
              ),
            ], alignment: MainAxisAlignment.center).centered(),

            AppSizes.paddingXLarge.heightBox,
            AppSizes.paddingMedium.heightBox,
          ]).pSymmetric(h: AppSizes.paddingLarge),
        ),
      ]).scrollVertical(),
    );
  }
}
