import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/services/data_service.dart';
import 'package:collegebus/services/location_service.dart';
import 'package:collegebus/services/notification_service.dart';
import 'package:collegebus/services/api_service.dart';
import 'package:collegebus/services/fcm_service.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/utils/router.dart';
import 'package:collegebus/screens/splash_screen.dart';

import 'package:collegebus/services/theme_service.dart';
import 'package:collegebus/services/locale_service.dart';
import 'package:collegebus/services/socket_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:collegebus/l10n/auth/login/auth_login_localizations.dart';
import 'package:collegebus/l10n/auth/signup/auth_signup_localizations.dart';

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

    try {
      // Initialize Firebase
      await Firebase.initializeApp();

      // Initialize FCM Service
      await FCMService.initialize();
    } catch (e) {
      debugPrint('Firebase/FCM initialization error: $e');
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
        Provider(create: (_) => ApiService()),

        ChangeNotifierProxyProvider<ApiService, AuthService>(
          create: (_) => AuthService(),
          update: (_, api, auth) => auth!..updateApiService(api),
        ),

        ChangeNotifierProvider(
          create: (_) {
            final socket = SocketService();
            socket.init(AppConstants.baseUrl);
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
      ],
      child: Consumer2<ThemeService, LocaleService>(
        builder: (context, themeService, localeService, child) {
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
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('te'), Locale('hi')],
            routerConfig: AppRouter.router,
            themeAnimationDuration: Duration.zero,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
