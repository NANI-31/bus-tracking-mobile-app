import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:collegebus/core/utils/app_logger.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);
    AppLogger.i('Notification Service Initialized (Local Only)');
  }

  static Future<void> showProximityAlert({
    required String busNumber,
    required String stopName,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'proximity_alerts',
      'Proximity Alerts',
      channelDescription: 'Alarm when bus is 2 stops away',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('alarm'),
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentSound: true,
      presentAlert: true,
      sound: 'alarm.aiff',
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      'Bus $busNumber is approaching!',
      'Bus is currently 2 stops away from $stopName. Get ready!',
      details,
    );
  }

  static Future<void> showSOSAlert({
    required String busNumber,
    required String driverName,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'sos_alerts',
      'SOS Emergency Alerts',
      channelDescription: 'Alarm when a driver triggers SOS',
      importance: Importance.max,
      priority: Priority.max,
      sound: RawResourceAndroidNotificationSound('alarm'),
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true, // Emergency popup
      color: Colors.red,
    );

    const iosDetails = DarwinNotificationDetails(
      presentSound: true,
      presentAlert: true,
      sound: 'alarm.aiff',
      interruptionLevel: InterruptionLevel.critical,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      911, // Unique ID for SOS
      '🚨 EMERGENCY SOS: Bus $busNumber',
      'Driver $driverName has triggered an emergency alert!',
      details,
    );
  }

  static Future<void> showStopArrivalAlert({
    required String busNumber,
    required String stopName,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'stop_arrivals',
      'Stop Arrivals',
      channelDescription: 'Alarm when the bus arrives at a stop',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentSound: true,
      presentAlert: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond + 2000,
      'Bus $busNumber has arrived!',
      'Now at: $stopName',
      details,
    );
  }

  /// Cancel a specific local notification by ID

  static Future<void> cancel(int id) async {
    await _localNotifications.cancel(id);
    AppLogger.d('Canceled local notification: $id');
  }

  /// Cancel all local notifications
  static Future<void> cancelAll() async {
    await _localNotifications.cancelAll();
    AppLogger.d('Canceled all local notifications');
  }
}
