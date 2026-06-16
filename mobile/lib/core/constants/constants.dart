import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

extension ThemeContext on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  ThemeData get theme => Theme.of(this);
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}

// ... (AppColors, AppTheme, AppSizes, AppStrings classes remain unchanged)

class AppColors {
  // --- Core Brand Colors ---
  static const Color turkishBlue = Color(0xFF00C6E6); // Main Brand Color
  static const Color deepTeal = Color(0xFF0097B2); // Accessible (Light Mode)
  static const Color gunmetal = Color(0xFF12181F); // Dark Background
  static const Color coolSlate = Color(0xFF546E7A); // Secondary
  static const Color amberAccent = Color(0xFFFFC107); // Tertiary/Accent
  static const Color googleBlue = Color(0xFF1967D2); // Google Maps Deep Blue

  // --- Functional Colors ---
  static const Color success = Color(0xFF4CAF50);
  static const Color danger = Color(0xFFE53935); // Replaces Colors.red
  static const Color error = Color.fromARGB(
    255,
    194,
    10,
    44,
  ); // Material Error (lighter red)
  static const Color warning = Color(0xFFFF9800);

  // --- Light Theme Colors ---
  static const Color lightPrimary = deepTeal; // Darker for accessibility
  static const Color lightOnPrimary = Colors.white;
  static const Color lightPrimaryContainer = Color(0xFFB3EBF2);
  static const Color lightOnPrimaryContainer = Color(0xFF004D40);
  static const Color lightSecondary = coolSlate;
  static const Color lightOnSecondary = Colors.white;
  static const Color lightBackground = Color(0xFFF2F2F7);
  static const Color lightSurface = Colors.white;
  static const Color lightOnSurface = Color(0xFF111418);
  static const Color lightOutline = Color(0xFF78909C);

  // --- Dark Theme Colors ---
  static const Color darkPrimary = turkishBlue; // Brighter for dark mode
  static const Color darkOnPrimary = Color(
    0xFF00363D,
  ); // Dark text on bright btn
  static const Color darkPrimaryContainer = Color(
    0xFF23303B,
  ); // Dark Blue-Grey (No Green)
  static const Color darkOnPrimaryContainer = Color(0xFFCFD8DC);
  static const Color darkSecondary = Color(0xFFB0BEC5); // Lighter slate
  static const Color darkOnSecondary = Color(0xFF191E2B);
  static const Color darkBackground = gunmetal;
  static const Color darkSurface = Color(
    0xFF1E2732,
  ); // Slightly lighter than bg
  static const Color darkOnSurface = Color(0xFFE1E3E6);

  // --- Legacy/Direct Access (Backward Compatibility) ---
  static const Color primary = turkishBlue;
  static const Color brandPrimary = turkishBlue; // Replaces Colors.blue
  static const Color secondary = coolSlate;
}

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.lightPrimary,
      onPrimary: AppColors.lightOnPrimary,
      primaryContainer: AppColors.lightPrimaryContainer,
      onPrimaryContainer: AppColors.lightOnPrimaryContainer,
      secondary: AppColors.lightSecondary,
      onSecondary: AppColors.lightOnSecondary,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightOnSurface,
      outline: AppColors.lightOutline,
    ),
    scaffoldBackgroundColor: AppColors.lightBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: AppColors.lightOnSurface,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      showDragHandle: true,
      dragHandleColor: AppColors.lightOutline.withValues(alpha: 0.4),
      dragHandleSize: const Size(36, 4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: AppColors.lightSurface,
      elevation: 8,
    ),
    cardTheme: CardThemeData(
      color: AppColors.lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.lightOutline.withValues(alpha: 0.1),
          width: 1.2,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppColors.lightOutline.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.lightOutline.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.lightOutline.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lightPrimary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(
        color: AppColors.lightOnSurface,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: TextStyle(
        color: AppColors.lightOnSurface,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(color: AppColors.lightOnSurface),
      bodyMedium: TextStyle(color: AppColors.lightOnSurface),
      titleLarge: TextStyle(
        color: AppColors.lightOnSurface,
        fontWeight: FontWeight.w600,
      ),
      labelLarge: TextStyle(
        color: AppColors.lightOnSurface,
      ),
    ),
    iconTheme: IconThemeData(color: AppColors.lightOnSurface),
    extensions: <ThemeExtension<dynamic>>[
      const MapThemeExtension(
        routeColor: Color(0xFF1565C0), // Deep Royal Blue for high contrast on light maps
        startStopColor: Color(0xFF4CAF50), // Green (Success)
        intermediateStopColor: Color(0xFFFF9800), // Orange (Warning)
        endStopColor: Color(0xFFE53935), // Red (Danger)
      ),
      DesignSystemThemeExtension(
        mobileBreakpoint: 600.0,
        tabletBreakpoint: 1024.0,
        desktopBreakpoint: 1440.0,
        cardHeaderStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.lightOnSurface,
        ),
        cardBodyStyle: const TextStyle(
          fontSize: 14,
          height: 1.5,
          color: Color(0x99111418),
        ),
        badgeStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        primaryButtonElevation: 1.0,
        secondaryButtonElevation: 0.0,
        cardDecoration: BoxDecoration(
          color: AppColors.lightSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0x14111418),
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x05000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        glassDecoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
      ),
    ],
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.darkPrimary,
      onPrimary: AppColors.darkOnPrimary,
      primaryContainer: AppColors.darkPrimaryContainer,
      onPrimaryContainer: AppColors.darkOnPrimaryContainer,
      secondary: AppColors.darkSecondary,
      onSecondary: AppColors.darkOnSecondary,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkOnSurface,
      outline: AppColors.darkSecondary,
    ),
    scaffoldBackgroundColor: AppColors.darkBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: AppColors.darkOnSurface,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      showDragHandle: true,
      dragHandleColor: AppColors.darkSecondary.withValues(alpha: 0.3),
      dragHandleSize: const Size(36, 4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: AppColors.darkSurface,
      elevation: 8,
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.2,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppColors.darkSecondary.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.darkSecondary.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.darkSecondary.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkPrimary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(
        color: AppColors.darkOnSurface,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: TextStyle(
        color: AppColors.darkOnSurface,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(color: AppColors.darkOnSurface),
      bodyMedium: TextStyle(color: AppColors.darkOnSurface),
      titleLarge: TextStyle(
        color: AppColors.darkOnSurface,
        fontWeight: FontWeight.w600,
      ),
      labelLarge: TextStyle(color: AppColors.darkOnSurface),
    ),
    iconTheme: IconThemeData(color: AppColors.darkOnSurface),
    extensions: <ThemeExtension<dynamic>>[
      const MapThemeExtension(
        routeColor: Color(0xFF00E5FF), // Electric Cyan for high contrast on dark maps
        startStopColor: Color(0xFF00E676), // Bright Green
        intermediateStopColor: Color(0xFFFF9100), // Bright Orange
        endStopColor: Color(0xFFFF1744), // Bright Red
      ),
      DesignSystemThemeExtension(
        mobileBreakpoint: 600.0,
        tabletBreakpoint: 1024.0,
        desktopBreakpoint: 1440.0,
        cardHeaderStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.darkOnSurface,
        ),
        cardBodyStyle: const TextStyle(
          fontSize: 14,
          height: 1.5,
          color: Color(0x99E1E3E6),
        ),
        badgeStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        primaryButtonElevation: 0.0,
        secondaryButtonElevation: 0.0,
        cardDecoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0x14E1E3E6),
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x05000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        glassDecoration: BoxDecoration(
          color: AppColors.darkSurface.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
      ),
    ],
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
    defaultValue: '192.168.1.4',
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

class MapThemeExtension extends ThemeExtension<MapThemeExtension> {
  final Color routeColor;
  final Color startStopColor;
  final Color intermediateStopColor;
  final Color endStopColor;

  const MapThemeExtension({
    required this.routeColor,
    required this.startStopColor,
    required this.intermediateStopColor,
    required this.endStopColor,
  });

  @override
  MapThemeExtension copyWith({
    Color? routeColor,
    Color? startStopColor,
    Color? intermediateStopColor,
    Color? endStopColor,
  }) {
    return MapThemeExtension(
      routeColor: routeColor ?? this.routeColor,
      startStopColor: startStopColor ?? this.startStopColor,
      intermediateStopColor: intermediateStopColor ?? this.intermediateStopColor,
      endStopColor: endStopColor ?? this.endStopColor,
    );
  }

  @override
  MapThemeExtension lerp(ThemeExtension<MapThemeExtension>? other, double t) {
    if (other is! MapThemeExtension) {
      return this;
    }
    return MapThemeExtension(
      routeColor: Color.lerp(routeColor, other.routeColor, t)!,
      startStopColor: Color.lerp(startStopColor, other.startStopColor, t)!,
      intermediateStopColor: Color.lerp(intermediateStopColor, other.intermediateStopColor, t)!,
      endStopColor: Color.lerp(endStopColor, other.endStopColor, t)!,
    );
  }
}

class DesignSystemThemeExtension extends ThemeExtension<DesignSystemThemeExtension> {
  final double mobileBreakpoint;
  final double tabletBreakpoint;
  final double desktopBreakpoint;
  final TextStyle cardHeaderStyle;
  final TextStyle cardBodyStyle;
  final TextStyle badgeStyle;
  final double primaryButtonElevation;
  final double secondaryButtonElevation;
  final BoxDecoration cardDecoration;
  final BoxDecoration glassDecoration;

  const DesignSystemThemeExtension({
    required this.mobileBreakpoint,
    required this.tabletBreakpoint,
    required this.desktopBreakpoint,
    required this.cardHeaderStyle,
    required this.cardBodyStyle,
    required this.badgeStyle,
    required this.primaryButtonElevation,
    required this.secondaryButtonElevation,
    required this.cardDecoration,
    required this.glassDecoration,
  });

  @override
  DesignSystemThemeExtension copyWith({
    double? mobileBreakpoint,
    double? tabletBreakpoint,
    double? desktopBreakpoint,
    TextStyle? cardHeaderStyle,
    TextStyle? cardBodyStyle,
    TextStyle? badgeStyle,
    double? primaryButtonElevation,
    double? secondaryButtonElevation,
    BoxDecoration? cardDecoration,
    BoxDecoration? glassDecoration,
  }) {
    return DesignSystemThemeExtension(
      mobileBreakpoint: mobileBreakpoint ?? this.mobileBreakpoint,
      tabletBreakpoint: tabletBreakpoint ?? this.tabletBreakpoint,
      desktopBreakpoint: desktopBreakpoint ?? this.desktopBreakpoint,
      cardHeaderStyle: cardHeaderStyle ?? this.cardHeaderStyle,
      cardBodyStyle: cardBodyStyle ?? this.cardBodyStyle,
      badgeStyle: badgeStyle ?? this.badgeStyle,
      primaryButtonElevation: primaryButtonElevation ?? this.primaryButtonElevation,
      secondaryButtonElevation: secondaryButtonElevation ?? this.secondaryButtonElevation,
      cardDecoration: cardDecoration ?? this.cardDecoration,
      glassDecoration: glassDecoration ?? this.glassDecoration,
    );
  }

  @override
  DesignSystemThemeExtension lerp(ThemeExtension<DesignSystemThemeExtension>? other, double t) {
    if (other is! DesignSystemThemeExtension) {
      return this;
    }
    return DesignSystemThemeExtension(
      mobileBreakpoint: mobileBreakpoint + (other.mobileBreakpoint - mobileBreakpoint) * t,
      tabletBreakpoint: tabletBreakpoint + (other.tabletBreakpoint - tabletBreakpoint) * t,
      desktopBreakpoint: desktopBreakpoint + (other.desktopBreakpoint - desktopBreakpoint) * t,
      cardHeaderStyle: TextStyle.lerp(cardHeaderStyle, other.cardHeaderStyle, t)!,
      cardBodyStyle: TextStyle.lerp(cardBodyStyle, other.cardBodyStyle, t)!,
      badgeStyle: TextStyle.lerp(badgeStyle, other.badgeStyle, t)!,
      primaryButtonElevation: primaryButtonElevation + (other.primaryButtonElevation - primaryButtonElevation) * t,
      secondaryButtonElevation: secondaryButtonElevation + (other.secondaryButtonElevation - secondaryButtonElevation) * t,
      cardDecoration: BoxDecoration.lerp(cardDecoration, other.cardDecoration, t)!,
      glassDecoration: BoxDecoration.lerp(glassDecoration, other.glassDecoration, t)!,
    );
  }
}

extension DesignSystemThemeExtensionContext on BuildContext {
  DesignSystemThemeExtension get designTheme => Theme.of(this).extension<DesignSystemThemeExtension>()!;
  bool get isTabletLayout => MediaQuery.of(this).size.width >= designTheme.mobileBreakpoint && MediaQuery.of(this).size.width < designTheme.tabletBreakpoint;
  bool get isDesktopLayout => MediaQuery.of(this).size.width >= designTheme.tabletBreakpoint;
  bool get isMobileLayout => MediaQuery.of(this).size.width < designTheme.mobileBreakpoint;
}

