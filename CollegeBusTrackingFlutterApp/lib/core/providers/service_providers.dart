import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collegebus/features/bus/services/bus_service.dart';
import 'package:collegebus/features/user/services/user_service.dart';
import 'package:collegebus/features/route/services/route_service.dart';
import 'package:collegebus/features/incident/services/incident_service.dart';
import 'package:collegebus/features/notification/services/notification_data_service.dart';
import 'package:collegebus/features/payment/services/payment_service.dart';
import 'package:collegebus/core/services/data_service.dart';
import 'package:collegebus/core/services/theme_service.dart';
import 'package:collegebus/features/bus/services/location_service.dart';
import 'package:collegebus/core/services/voice_recording_service.dart';
import 'package:collegebus/core/providers/repository_providers.dart';
import 'socket_provider.dart';
import 'package:collegebus/core/utils/map_style_helper.dart';

/// VoiceRecordingService provider
final voiceRecordingServiceProvider = Provider<VoiceRecordingService>((ref) {
  final notificationRepo = ref.watch(notificationRepositoryProvider);
  return VoiceRecordingService(notificationRepo);
});

/// BusService provider
final busServiceProvider = Provider<BusService>(
  (ref) => BusService(
    ref.watch(busRepositoryProvider),
    ref.watch(collegeRepositoryProvider),
    ref.watch(socketServiceProvider),
  ),
);

/// UserService provider
final userServiceProvider = Provider<UserService>(
  (ref) => UserService(ref.watch(userRepositoryProvider)),
);

/// RouteService provider
final routeServiceProvider = Provider<RouteService>(
  (ref) => RouteService(
    ref.watch(routeRepositoryProvider),
    ref.watch(scheduleRepositoryProvider),
    ref.watch(socketServiceProvider),
  ),
);

/// IncidentService provider
final incidentServiceProvider = ChangeNotifierProvider<IncidentService>(
  (ref) => IncidentService(ref.watch(incidentRepositoryProvider)),
);

/// NotificationDataService provider
final notificationDataServiceProvider =
    ChangeNotifierProvider<NotificationDataService>(
      (ref) =>
          NotificationDataService(ref.watch(notificationRepositoryProvider)),
    );

/// PaymentService provider
final paymentServiceProvider = ChangeNotifierProvider<PaymentService>(
  (ref) => PaymentService(ref.watch(paymentRepositoryProvider)),
);

/// DataService (Facade) provider
final dataServiceProvider = ChangeNotifierProvider<DataService>((ref) {
  final bus = ref.watch(busServiceProvider);
  final user = ref.watch(userServiceProvider);
  final route = ref.watch(routeServiceProvider);
  final incident = ref.watch(incidentServiceProvider);
  final notification = ref.watch(notificationDataServiceProvider);
  final payment = ref.watch(paymentServiceProvider);

  return DataService(
    bus,
    user,
    route,
    ref, // Pass ref to DataService so it can access AsyncNotifiers
    incident,
    notification,
    payment,
  );
});

/// Theme notifier
class ThemeNotifier extends Notifier<ThemeState> {
  @override
  ThemeState build() {
    _loadTheme();
    return const ThemeState();
  }

  static const String _themeKey = 'is_dark_mode';
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(isDarkMode: prefs.getBool(_themeKey) ?? false);
  }

  Future<void> toggleTheme(bool isDark) async {
    state = state.copyWith(isDarkMode: isDark);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }
}

/// ThemeService provider
final themeServiceProvider = NotifierProvider<ThemeNotifier, ThemeState>(
  ThemeNotifier.new,
);

/// LocationService provider
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Locale notifier
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    _loadLocale();
    return const Locale('en');
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('languageCode') ?? 'en';
    state = Locale(languageCode);
  }

  Future<void> setLocale(Locale locale) async {
    if (!['en', 'te', 'hi'].contains(locale.languageCode)) return;
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', locale.languageCode);
  }
}

/// LocaleService provider
final localeServiceProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

/// MapStyle provider (async)
final mapStyleProvider = FutureProvider<String?>((ref) async {
  final isDarkMode = ref.watch(themeServiceProvider).isDarkMode;
  return await MapStyleHelper.getStyle(isDarkMode);
});
