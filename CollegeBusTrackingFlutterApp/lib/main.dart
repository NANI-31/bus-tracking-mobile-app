import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/services/data_service.dart';
import 'package:collegebus/services/location_service.dart';
import 'package:collegebus/services/notification_service.dart';
import 'package:collegebus/services/api_service.dart';
import 'package:collegebus/services/fcm_service.dart';
import 'package:collegebus/repositories/repositories.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/utils/router.dart';
import 'package:collegebus/screens/splash_screen.dart';
import 'package:collegebus/utils/app_logger.dart';

import 'package:collegebus/services/theme_service.dart';
import 'package:collegebus/services/locale_service.dart';
import 'package:collegebus/services/socket_service.dart';
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
  runApp(const AppInitializer());
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
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Logger with File Support
    await AppLogger.init();

    // Initialize Google Maps Renderer (Android)
    try {
      final GoogleMapsFlutterPlatform mapsImplementation =
          GoogleMapsFlutterPlatform.instance;
      if (mapsImplementation is GoogleMapsFlutterAndroid) {
        await mapsImplementation.initializeWithRenderer(
          AndroidMapRenderer.latest,
        );
      }
    } catch (e) {
      AppLogger.e('Google Maps initialization error: $e');
    }

    try {
      // Initialize Firebase
      await Firebase.initializeApp();

      // Initialize FCM Service
      await FCMService.initialize();
    } catch (e) {
      AppLogger.e('Firebase/FCM initialization error: $e');
    }

    try {
      await NotificationService.initialize();
    } catch (e) {
      // Notification service initialization failed, but app can continue
    }

    setState(() {
      _initialized = true;
    });
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Repository providers (singletons via BaseRepository)
        Provider(create: (_) => AuthRepository()),
        Provider(create: (_) => UserRepository()),
        Provider(create: (_) => BusRepository()),
        Provider(create: (_) => RouteRepository()),
        Provider(create: (_) => ScheduleRepository()),
        Provider(create: (_) => NotificationRepository()),
        Provider(create: (_) => CollegeRepository()),
        Provider(create: (_) => IncidentRepository()),

        // ApiService (kept for backward compatibility with DataService)
        Provider(create: (_) => ApiService()),

        // AuthService with repository injection
        ChangeNotifierProxyProvider3<
          AuthRepository,
          UserRepository,
          NotificationRepository,
          AuthService
        >(
          create: (_) => AuthService(),
          update: (_, authRepo, userRepo, notificationRepo, authService) =>
              authService!
                ..updateRepositories(authRepo, userRepo, notificationRepo),
        ),

        ChangeNotifierProxyProvider<AuthService, SocketService>(
          create: (_) => SocketService(),
          update: (_, auth, socket) {
            if (socket!.isConnected == false &&
                socket.isConnecting == false &&
                auth.token != null) {
              socket.init(AppConstants.baseUrl, token: auth.token);
            } else if (auth.token != socket.token) {
              socket.updateAuth(auth.token);
            }
            return socket;
          },
        ),

        ChangeNotifierProxyProvider2<ApiService, SocketService, DataService>(
          create: (context) => DataService(
            Provider.of<ApiService>(context, listen: false),
            Provider.of<SocketService>(context, listen: false),
          ),
          update: (_, api, socket, dataService) =>
              dataService!..updateDependencies(api, socket),
        ),

        Provider(create: (_) => LocationService()),
        Provider(create: (_) => NotificationService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => LocaleService()),
        ProxyProvider<AuthService, GoRouter>(
          update: (_, auth, previousRouter) {
            // Return existing router if auth service hasn't changed (which it shouldn't)
            // But actually we want the router to listen to the auth service.
            // Since we pass auth to AppRouter, GoRouter listens to it given refreshListenable.
            // We just need to ensure we don't recreate GoRouter unnecessarily which would reset nav stack.
            // Since AuthService instance is stable, AppRouter(auth).router will be new instance
            // BUT previousRouter logic helps. However, we only have the router, not the AppRouter instance.
            // If previousRouter is not null, we can return it.
            if (previousRouter != null) return previousRouter;
            return AppRouter(auth).router;
          },
        ),
      ],
      child: Consumer3<ThemeService, LocaleService, GoRouter>(
        builder: (context, themeService, localeService, router, child) {
          return MaterialApp.router(
            title: 'Upasthit',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeService.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            locale: localeService.locale,
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
        },
      ),
    );
  }
}
