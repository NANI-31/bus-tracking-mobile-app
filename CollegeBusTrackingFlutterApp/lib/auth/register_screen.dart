import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:email_validator/email_validator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/services/firestore_service.dart';
import 'package:collegebus/widgets/custom_input_field.dart';
import 'package:collegebus/widgets/custom_button.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/models/college_model.dart';
import 'package:collegebus/widgets/api_error_modal.dart';
import 'package:collegebus/widgets/success_modal.dart';

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
    print('DEBUG: Fetching colleges...'); // Debug log
    final firestoreService = Provider.of<FirestoreService>(
      context,
      listen: false,
    );
    firestoreService.getAllColleges().listen((colleges) {
      print('DEBUG: Colleges fetched: ${colleges.length}'); // Debug log
      for (var c in colleges) {
        print('DEBUG: College: ${c.name}'); // Debug log
      }
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

        // Check if using college email or personal email
        if (_selectedCollege != null) {
          final domain = email.split('@').last;
          final allowedDomains = _selectedCollege!.allowedDomains;

          // If not using college domain, they need manual approval
          if (!allowedDomains.contains(domain)) {
            // Show warning about manual approval for personal emails
            final shouldContinue = await showDialog<bool>(
              context: context,
              builder: (context) => ApiErrorModal(
                title: 'Personal Email Detected',
                message:
                    'You are using a personal email address. Your account will need to be approved by ${_selectedRole == UserRole.student ? 'a teacher' : 'a coordinator'} before you can access the app.\n\nCollege domains: ${allowedDomains.join(", ")}\n\nDo you want to continue?',
                icon: Icons.warning_amber_rounded,
                baseColor: Colors.orange,
                primaryActionText: 'Continue',
                onPrimaryAction: () => Navigator.of(context).pop(true),
                secondaryActionText: 'Cancel',
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
        // Send OTP (Only if email is present)
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
          // No email (Parent role), skip OTP
          if (!mounted) return;
          _showSuccessDialog('Registration Successful. Please Login.');
        }
      } else {
        if (!mounted) return;
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
      title: 'Registration Successful',
      message: message,
      icon: Icons.check_circle_rounded,
      onPrimaryAction: () {
        Navigator.pop(context); // Close modal
        context.go('/login');
      },
      primaryActionText: 'Login Now',
    );
  }

  Widget _buildRoleGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildRoleCard(
                role: UserRole.student,
                icon: Icons.school_rounded,
                color: Colors.blueAccent,
                bgColor: const Color(0xFFE3F2FD),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildRoleCard(
                role: UserRole.teacher,
                icon: Icons.cast_for_education_rounded,
                color: Colors.purpleAccent,
                bgColor: const Color(0xFFF3E5F5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildRoleCard(
                role: UserRole.driver,
                icon: Icons.directions_bus_rounded,
                color: Colors.orangeAccent,
                bgColor: const Color(0xFFFFF3E0),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildRoleCard(
                role: UserRole.parent,
                icon: Icons.family_restroom_rounded,
                color: Colors.green,
                bgColor: const Color(0xFFE8F5E9),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildRoleCard(
          role: UserRole.busCoordinator,
          icon: Icons.admin_panel_settings_rounded,
          color: Colors.blueGrey,
          bgColor: const Color(0xFFECEFF1),
          isFullWidth: true,
          label: 'Bus Coordinator',
          subLabel: 'Manage routes & schedules',
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required UserRole role,
    required IconData icon,
    required Color color,
    required Color bgColor,
    bool isFullWidth = false,
    String? label,
    String? subLabel,
  }) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        height: isFullWidth ? 80 : 135,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: isFullWidth
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label ?? role.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (subLabel != null)
                        Text(
                          subLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                    ],
                  ),
                  if (isSelected) ...[
                    const Spacer(),
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primary,
                    ),
                  ],
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSelected)
                    const Align(
                      alignment: Alignment.topRight,
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    )
                  else
                    const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label ?? role.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
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
            // Header Section
            Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                // Background Image
                Container(
                  height: 260,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuBJItvO1MgqjYaxS_PfHAyRmbVhVWYpLXUl8F4KCUTCh4_c_itizw_oquqb5HY7la0sDtQ9HLqA9IKUFzmL9yULoXzIOVLeIiVFwpzx7XqL_ng2ylqv2J4hwd0Wagvhyv0X064b8Wu7tjLGDgW-LzwRaTxVYYiGQ3xOn4_5_D9WaLw5NxQGPXhSz3MyyVKu1tGRPOrYtRkoT9yWxa5T_CXnz-wUJcVF79QNONhwV87nLeP3Efjd81tkpq0g8l5qKG7lfyr5aQ4jC25B',
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
                          Colors.black.withOpacity(
                            0.3,
                          ), // For back button visibility
                          Colors.transparent,
                          Theme.of(
                            context,
                          ).scaffoldBackgroundColor.withValues(alpha: 0.2),
                          Theme.of(context).scaffoldBackgroundColor,
                        ],
                        stops: const [0.0, 0.4, 0.8, 1.0],
                      ),
                    ),
                  ),
                ),

                // Floating Icon Card
                Positioned(
                  bottom: -35,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
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
                      Icons.location_on_rounded,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                ),

                // Back Button Overlay
                Positioned(
                  top: 50, // SafeArea approximation
                  left: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.go('/login'),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 50), // Space for floating icon

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingLarge,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Headline
                    Center(
                      child: Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 32, // Large as requested
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onBackground,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Join to track your college bus in real-time.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                          height: 1.4,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    const SizedBox(height: 32),

                    // Role Selection Grid
                    Text(
                      'Who are you?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRoleGrid(),

                    const SizedBox(height: 32),

                    // Form Section
                    if (_selectedRole == UserRole.busCoordinator)
                      const SizedBox(
                        height: 0,
                      ) // Coordinator specific fields handled below
                    else
                      const SizedBox(
                        height: 0,
                      ), // Just spacing placeholder logic

                    const SizedBox(height: AppSizes.paddingMedium),

                    // 1. College Selection
                    if (_selectedRole == UserRole.busCoordinator)
                      CustomInputField(
                        label: 'College Name',
                        hint: AppStrings.collegeHint,
                        controller: _collegeController,
                        prefixIcon: const Icon(Icons.school_outlined),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your college name';
                          }
                          return null;
                        },
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'College',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onBackground,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Custom Dropdown visual manually built to match text field look
                          Builder(
                            builder: (context) {
                              // Calculate available width for the dropdown items
                              // Screen width - Screen Padding (24*2) - Dropdown Internal Padding (16*2) roughly
                              final double dropdownWidth =
                                  MediaQuery.of(context).size.width -
                                  (AppSizes.paddingLarge * 2) -
                                  32;

                              return _isLoadingColleges
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : DropdownButtonFormField<CollegeModel>(
                                      isExpanded: true,
                                      value: _selectedCollege,
                                      items: _colleges.map((college) {
                                        return DropdownMenuItem(
                                          value: college,
                                          child: SizedBox(
                                            width: dropdownWidth,
                                            child: Text(
                                              college.name,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              softWrap: false,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (college) {
                                        setState(() {
                                          _selectedCollege = college;
                                          if (college != null) {
                                            _emailDomainHint =
                                                'College domains: ${college.allowedDomains.join(", ")}';
                                          } else {
                                            _emailDomainHint = null;
                                          }
                                        });
                                      },
                                      decoration: InputDecoration(
                                        hintText: 'Select your college',
                                        prefixIcon: const Icon(
                                          Icons.school_outlined,
                                        ),
                                        filled: true,
                                        fillColor: Theme.of(
                                          context,
                                        ).colorScheme.surface,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.1),
                                            width: 1,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.1),
                                            width: 1,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Theme.of(
                                              context,
                                            ).primaryColor,
                                            width: 1.5,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                      ),
                                      validator: (value) {
                                        if (value == null) {
                                          return 'Please select your college';
                                        }
                                        return null;
                                      },
                                    );
                            },
                          ),
                        ],
                      ),

                    const SizedBox(height: AppSizes.paddingMedium),

                    // 2. Full Name
                    CustomInputField(
                      label: 'Full Name',
                      hint: 'e.g. John Doe',
                      controller: _nameController,
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        if (value.length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppSizes.paddingMedium),

                    // 3. Roll Number (Student Only)
                    if (_selectedRole == UserRole.student) ...[
                      CustomInputField(
                        label: 'Roll Number / ID',
                        hint: 'e.g. 21CSE102',
                        controller: _rollNumberController,
                        prefixIcon: const Icon(Icons.badge_outlined),
                        validator: (value) {
                          if (_selectedRole != UserRole.student) return null;
                          if (value == null || value.isEmpty) {
                            return 'Please enter your roll number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSizes.paddingMedium),
                    ],

                    // 4. Email
                    if (_selectedRole == UserRole.busCoordinator)
                      Row(
                        children: [
                          Expanded(
                            child: CustomInputField(
                              label: 'Email ID',
                              hint: 'e.g. john.doe',
                              controller: _emailIdController,
                              prefixIcon: const Icon(Icons.email_outlined),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter email id';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CustomInputField(
                              label: 'Domain',
                              hint: 'e.g. rvrjc.ac.in',
                              controller: _emailDomainController,
                              prefixIcon: const Icon(Icons.alternate_email),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter domain';
                                }
                                if (!value.contains('.')) {
                                  return 'Invalid domain';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomInputField(
                            label: 'Email Address',
                            hint: 'john@example.com',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: const Icon(Icons.email_outlined),
                            validator: (value) {
                              if (_selectedRole == UserRole.parent) {
                                // Optional for parent?
                                if (value != null &&
                                    value.isNotEmpty &&
                                    !EmailValidator.validate(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              }
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!EmailValidator.validate(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          if (_selectedRole != UserRole.parent &&
                              _emailDomainHint != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6, left: 4),
                              child: Text(
                                _emailDomainHint!,
                                style: TextStyle(
                                  color: AppColors.primary.withOpacity(0.8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),

                    const SizedBox(height: AppSizes.paddingMedium),

                    // 5. Phone Number
                    CustomInputField(
                      label: 'Phone Number',
                      hint: '+1 234 567 8900',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Icons.phone_outlined),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        if (value.length < 8) {
                          return 'Enter a valid phone number';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppSizes.paddingMedium),

                    // 6. Password
                    CustomInputField(
                      label: 'Password',
                      hint: '••••••••',
                      controller: _passwordController,
                      isPassword: true,
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppSizes.paddingMedium),

                    // 7. Confirm Password
                    CustomInputField(
                      label: 'Confirm Password',
                      hint: '••••••••',
                      controller: _confirmPasswordController,
                      isPassword: true,
                      prefixIcon: const Icon(Icons.lock_reset_rounded),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppSizes.paddingLarge),

                    // Register button
                    CustomButton(
                      text: AppStrings.registerButton,
                      onPressed: _handleRegister,
                      isLoading: _isLoading,
                    ),

                    const SizedBox(height: AppSizes.paddingLarge),

                    // Sign in link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          AppStrings.alreadyHaveAccount,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: const Text(
                            AppStrings.signIn,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.paddingXLarge),
                    const SizedBox(height: AppSizes.paddingMedium),
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
