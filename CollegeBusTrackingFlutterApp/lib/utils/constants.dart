import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_tailwind_css_colors/flutter_tailwind_css_colors.dart';

// ... (AppColors, AppTheme, AppSizes, AppStrings classes remain unchanged)

class AppColors {
  static const Color primary1 = Color(0xFF197FE6);
  static const Color secondary1 = Color(
    0xFF03DAC6,
  ); // Keeping secondary as is for now if not specified
  static const Color error1 = Color(0xFFB00020);
  static const Color success1 = Color(0xFF4CAF50);
  static const Color warning1 = Color(0xFFFF9800);

  static final Color primary = TwColors.blue.i500;
  static final Color secondary = TwColors.teal.i500;
  static final Color error = TwColors.red.i500;
  static final Color success = TwColors.green.i500;
  static final Color warning = TwColors.orange.i500;

  // Light Theme Colors
  static const Color background1 = Color(0xFFF6F7F8); // background-light
  static const Color surface1 = Color(0xFFFFFFFF); // surface-light
  static const Color onPrimary1 = Color(0xFFFFFFFF);
  static const Color onSecondary1 = Color(0xFF000000);
  static const Color onBackground1 = Color(
    0xFF111418,
  ); // text-main-light (using main text as onBackground)
  static const Color onSurface1 = Color(0xFF111418); // text-main-light
  static const Color textPrimary1 = Color(0xFF111418); // text-main-light
  static const Color textSecondary1 = Color(0xFF637588); // text-sub-light
  // Light Theme Colors
  static Color background = TwColors.slate.i100;
  static Color surface = Colors.white;
  static Color onPrimary = Colors.white;
  static Color onSecondary = Colors.black;
  static Color onBackground = TwColors.slate.i900;
  static Color onSurface = TwColors.slate.i900;
  static Color textPrimary = TwColors.slate.i900;
  static Color textSecondary = TwColors.slate.i500;

  // Dark Mode Colors
  static const Color darkBackground1 = Color(0xFF111921); // background-dark
  static const Color darkSurface1 = Color(0xFF1A2632); // surface-dark
  static const Color darkOnSurface1 = Color(0xFFFFFFFF); // text-main-dark
  static const Color darkTextPrimary1 = Color(0xFFFFFFFF); // text-main-dark
  static const Color darkTextSecondary1 = Color(0xFF93ADC8); // text-sub-dark
  // Dark Mode Colors
  static Color darkBackground = TwColors.slate.i950;
  static const Color darkSurface = Color.fromRGBO(18, 27, 45, 1);
  static Color darkOnSurface = Colors.white;
  static Color darkTextPrimary = Colors.white;
  static Color darkTextSecondary = TwColors.slate.i400;
}

class AppTheme {
  static final lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      onPrimary: AppColors.onPrimary,
      onSecondary: AppColors.onSecondary,
      onSurface: AppColors.onSurface,
      error: AppColors.error,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: AppColors.textPrimary,
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: AppColors.textPrimary),
      bodyMedium: TextStyle(color: AppColors.textPrimary),
      titleLarge: TextStyle(color: AppColors.textPrimary),
      titleMedium: TextStyle(color: AppColors.textPrimary),
      labelLarge: TextStyle(color: AppColors.textPrimary),
    ),
    iconTheme: IconThemeData(color: AppColors.textPrimary),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.darkBackground,
    colorScheme: ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.darkSurface,
      onPrimary: AppColors.onPrimary,
      onSecondary: AppColors.onSecondary,
      onSurface: AppColors.darkOnSurface,
      error: AppColors.error,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: AppColors.darkTextPrimary,
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: AppColors.darkTextPrimary),
      bodyMedium: TextStyle(color: AppColors.darkTextPrimary),
      titleLarge: TextStyle(color: AppColors.darkTextPrimary),
      titleMedium: TextStyle(color: AppColors.darkTextPrimary),
      labelLarge: TextStyle(color: AppColors.darkTextPrimary),
    ),
    iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
  );
}

class AppSizes {
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 16.0;

  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
}

class AppStrings {
  static const String appName = 'Upasthit';
  static const String loginTitle = 'Welcome Back';
  static const String registerTitle = 'Create Account';
  static const String emailHint = 'Enter your college email';
  static const String passwordHint = 'Enter your password';
  static const String nameHint = 'Enter your full name';
  static const String collegeHint = 'Enter your college name';
  static const String loginButton = 'Login';
  static const String registerButton = 'Register';
  static const String forgotPassword = 'Forgot Password?';
  static const String dontHaveAccount = "Don't have an account?";
  static const String alreadyHaveAccount = 'Already have an account?';
  static const String signUp = 'Sign Up';
  static const String signIn = 'Sign In';
}

enum UserRole { student, teacher, driver, busCoordinator, admin, parent }

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.student:
        return 'Student';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.driver:
        return 'Driver';
      case UserRole.busCoordinator:
        return 'Bus Coordinator';
      case UserRole.admin:
        return 'Admin';
      case UserRole.parent:
        return 'Parent';
    }
  }

  String get value {
    return toString().split('.').last;
  }
}

class AppConstants {
  // Use 10.0.2.2 for Android Emulator, 192.168.x.x for physical device.

  // Debug Mode (Development): Localhost (Requires 'adb reverse tcp:5000 tcp:5000')
  static const String _devUrl = 'http://127.0.0.1:5000';

  // Release Mode (Production): Render Server
  static const String _prodUrl =
      'https://college-bus-tracking-server.onrender.com';

  // Automatically switch info based on build mode
  static const String baseUrl = kReleaseMode ? _prodUrl : _devUrl;
  static const String apiBaseUrl = '$baseUrl/api';
}
