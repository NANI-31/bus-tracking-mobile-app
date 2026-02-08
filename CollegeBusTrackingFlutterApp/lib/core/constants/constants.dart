import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// ... (AppColors, AppTheme, AppSizes, AppStrings classes remain unchanged)

class AppColors {
  // New Color Schema
  static const Color primary = Color(0xFF00C6E6); // #00c6e6
  static const Color secondary = Color(0xFFBFC0D1); // #bfc0d1
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFB00020);
  static const Color warning = Color(0xFFFF9800);

  // Light Theme Colors
  static const Color background = Color(0xFFF6F7F8);
  static const Color surface = Colors.white;
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Color(0xFF191E2B);
  static const Color onBackground = Color(0xFF111418);
  static const Color onSurface = Color(0xFF111418);
  static const Color textPrimary = Color(0xFF111418);
  static const Color textSecondary = Color(0xFF637588);

  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF191E2B); // #191e2b
  static const Color darkSurface = Color(0xFF253041); // #25304 (assumed 1)
  static const Color darkOnSurface = Colors.white;
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xFFBFC0D1); // #bfc0d1
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

enum UserRole {
  student,
  teacher,
  driver,
  busCoordinator,
  admin,
  parent,
  collegeAdmin,
  superAdmin,
}

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
      case UserRole.collegeAdmin:
        return 'College Admin';
      case UserRole.superAdmin:
        return 'Super Admin';
    }
  }

  String get value {
    return toString().split('.').last;
  }
}

class AppConstants {
  // Use 10.0.2.2 for Android Emulator, 192.168.x.x for physical device.

  // Host injected via --dart-define=API_HOST=192.168.x.x
  static const String apiHost = String.fromEnvironment(
    'API_HOST',
    defaultValue: '127.0.0.1',
  );

  // Port injected via --dart-define=SERVER_PORT=XXXX
  static const String serverPort = String.fromEnvironment(
    'SERVER_PORT',
    defaultValue: '5000',
  );

  // Debug Mode (Development): PC IP over Wi-Fi or Localhost (if using adb reverse)
  static const String _devUrl = 'http://$apiHost:$serverPort';

  // Release Mode (Production): Render Server
  static const String _prodUrl =
      'https://college-bus-tracking-server.onrender.com';

  // Automatically switch info based on build mode
  static const String baseUrl = kReleaseMode ? _prodUrl : _devUrl;
  static const String apiBaseUrl = '$baseUrl/api/v1';
}
