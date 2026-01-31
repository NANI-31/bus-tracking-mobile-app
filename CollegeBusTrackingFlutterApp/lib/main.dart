import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:collegebus/core/providers/service_providers.dart';
import 'package:collegebus/core/router/router.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/core/utils/app_logger.dart';
import 'package:collegebus/features/notification/services/fcm_service.dart';
import 'package:collegebus/features/notification/services/notification_service.dart';
import 'package:collegebus/shared/screens/splash_screen.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:collegebus/l10n/auth/login/auth_login_localizations.dart';
import 'package:collegebus/l10n/auth/signup/auth_signup_localizations.dart';
import 'package:collegebus/l10n/student/app_localizations.dart';
import 'package:collegebus/l10n/driver/app_localizations.dart';
import 'package:collegebus/l10n/coordinator/app_localizations.dart';
import 'package:collegebus/l10n/admin/app_localizations.dart';
import 'package:collegebus/l10n/notification/app_localizations.dart';
import 'package:collegebus/l10n/common/app_localizations.dart';

void main() {
  runApp(const riverpod.ProviderScope(child: AppInitializer()));
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    debugPrint('APP INIT: Starting initialization...');
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Logger with File Support
    await AppLogger.init();
    debugPrint('APP INIT: Logger initialized');

    // Initialize Firebase (Critical)
    try {
      debugPrint('APP INIT: Initializing Firebase...');
      await Firebase.initializeApp();
      debugPrint('APP INIT: Firebase initialized');
    } catch (e) {
      AppLogger.e('Firebase initialization error: $e');
      debugPrint('APP INIT: Firebase init error: $e');
    }

    // Initialize critical UI bits (Google Maps)
    try {
      final GoogleMapsFlutterPlatform mapsImplementation =
          GoogleMapsFlutterPlatform.instance;
      if (mapsImplementation is GoogleMapsFlutterAndroid) {
        debugPrint('APP INIT: Initializing Google Maps Renderer...');
        await mapsImplementation.initializeWithRenderer(
          AndroidMapRenderer.latest,
        );
        debugPrint('APP INIT: Google Maps Renderer initialized');
      }
    } catch (e) {
      debugPrint('APP INIT: Google Maps init error (non-fatal): $e');
    }

    // Show the app UI now, don't wait for FCM/Notifications
    debugPrint('APP INIT: Critical init complete, setting state.');
    setState(() {
      _initialized = true;
    });

    // Initialize Background Services (FCM, Notifications)
    // We run these unawaited or in background to not block splash
    _initBackgroundServices();
  }

  Future<void> _initBackgroundServices() async {
    try {
      debugPrint('APP INIT: Initializing Background Services...');
      await Future.wait([
        FCMService.initialize().catchError((e) {
          debugPrint('APP INIT: FCM Init Error: $e');
        }),
        NotificationService.initialize().catchError((e) {
          debugPrint('APP INIT: Notification Init Error: $e');
        }),
      ]);
      debugPrint('APP INIT: Background Services initialized');
    } catch (e) {
      debugPrint('APP INIT: Background Services Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const MaterialApp(
        home: SplashScreen(),
        debugShowCheckedModeBanner: false,
      );
    }
    return const MyApp();
  }
}

class MyApp extends riverpod.ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final themeService = ref.watch(themeServiceProvider);
    final localeService = ref.watch(localeServiceProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Upasthit',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      locale: localeService,
      localizationsDelegates: const [
        LoginLocalizations.delegate,
        SignupLocalizations.delegate,
        // New modular localizations
        CommonLocalizations.delegate,
        StudentLocalizations.delegate,
        DriverLocalizations.delegate,
        CoordinatorLocalizations.delegate,
        AdminLocalizations.delegate,
        NotificationLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('te'), Locale('hi')],
      routerConfig: router,
      themeAnimationDuration: Duration.zero,
      debugShowCheckedModeBanner: false,
    );
  }
}
