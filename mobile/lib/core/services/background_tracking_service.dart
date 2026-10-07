import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:collegebus/core/utils/app_logger.dart';

/// Background Tracking Service
///
/// Ensures the application process is not suspended or terminated by Android Doze
/// or iOS background execution limits during active driver or teacher tracking sessions.
/// Maintains a persistent Foreground Service notification: "Upasthit Bus Tracking is Active".
class BackgroundTrackingService {
  static const String notificationChannelId = 'bus_tracking_foreground_service';
  static const int notificationId = 8888;
  static bool _isInitialized = false;

  /// Initializes and configures the background service.
  /// Called once during app initialization.
  static Future<void> initialize() async {
    if (kIsWeb) return;
    if (_isInitialized) return;

    try {
      final service = FlutterBackgroundService();

      // Create notification channel for Android
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        notificationChannelId,
        'Upasthit Bus Tracking Live Service',
        description:
            'Persistent notification keeping bus location sharing alive during active trips',
        importance: Importance.low,
      );

      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onBackgroundServiceStart,
          autoStart: false,
          autoStartOnBoot: false,
          isForegroundMode: true,
          notificationChannelId: notificationChannelId,
          initialNotificationTitle: 'Upasthit Bus Tracking is Active',
          initialNotificationContent:
              'Sharing live location with students and coordinators',
          foregroundServiceNotificationId: notificationId,
          foregroundServiceTypes: [AndroidForegroundType.location],
        ),
        iosConfiguration: IosConfiguration(
          autoStart: false,
          onForeground: onBackgroundServiceStart,
          onBackground: onIosBackground,
        ),
      );

      _isInitialized = true;
      AppLogger.i('[BackgroundTrackingService] Initialized successfully');
    } catch (e) {
      AppLogger.e('[BackgroundTrackingService] Failed to initialize: $e');
    }
  }

  /// Starts the continuous foreground service when live trip tracking begins.
  static Future<void> start({
    String title = 'Upasthit Bus Tracking is Active',
    String content = 'Sharing live location with students and coordinators',
  }) async {
    if (kIsWeb) return;
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();
      if (!isRunning) {
        await service.startService();
        AppLogger.i('[BackgroundTrackingService] Started foreground service');
      }

      service.invoke('updateNotification', {
        'title': title,
        'content': content,
      });
    } catch (e) {
      AppLogger.e('[BackgroundTrackingService] Error starting service: $e');
    }
  }

  /// Updates the notification text (e.g., with trip status or ETA).
  static void updateNotification({
    required String title,
    required String content,
  }) {
    if (kIsWeb) return;
    try {
      final service = FlutterBackgroundService();
      service.invoke('updateNotification', {
        'title': title,
        'content': content,
      });
    } catch (e) {
      AppLogger.w('[BackgroundTrackingService] Failed to update notification: $e');
    }
  }

  /// Stops the foreground service when the trip ends or location sharing stops.
  static Future<void> stop() async {
    if (kIsWeb) return;
    try {
      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();
      if (isRunning) {
        service.invoke('stopService');
        AppLogger.i('[BackgroundTrackingService] Stopped foreground service');
      }
    } catch (e) {
      AppLogger.e('[BackgroundTrackingService] Error stopping service: $e');
    }
  }

  /// Checks whether the foreground service is actively running.
  static Future<bool> isRunning() async {
    if (kIsWeb) return false;
    try {
      return await FlutterBackgroundService().isRunning();
    } catch (_) {
      return false;
    }
  }
}

/// Entry point for the background service isolate.
@pragma('vm:entry-point')
void onBackgroundServiceStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });

    service.on('updateNotification').listen((event) {
      final title = event?['title'] as String? ?? 'Upasthit Bus Tracking is Active';
      final content = event?['content'] as String? ??
          'Sharing live location with students and coordinators';
      service.setForegroundNotificationInfo(
        title: title,
        content: content,
      );
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });
}

/// Entry point for iOS background fetch.
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}
