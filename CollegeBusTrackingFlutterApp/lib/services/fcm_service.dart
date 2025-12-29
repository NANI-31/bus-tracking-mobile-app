import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collegebus/utils/app_logger.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  AppLogger.i('Background message: ${message.notification?.title}');
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  final _tokenController = StreamController<String>.broadcast();
  Stream<String> get tokenStream => _tokenController.stream;

  final _messageController = StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get messageStream => _messageController.stream;

  /// Initialize FCM and local notifications
  static Future<void> initialize() async {
    await Firebase.initializeApp();

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final instance = FCMService();
    await instance._init();
  }

  Future<void> _init() async {
    // Request permission
    await _requestPermission();

    // Initialize local notifications for foreground
    await _initLocalNotifications();

    // Get FCM token
    await _getToken();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      _tokenController.add(token);
      _saveTokenLocally(token);
      AppLogger.i('FCM Token refreshed: $token');
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    AppLogger.i('FCM Permission status: ${settings.authorizationStatus}');
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        AppLogger.i('Local notification tapped: ${details.payload}');
      },
    );

    // Create notification channel for Android
    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description:
          'This channel is used for important bus tracking notifications',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<void> _getToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        AppLogger.i('FCM Token: $_fcmToken');
        await _saveTokenLocally(_fcmToken!);
        _tokenController.add(_fcmToken!);
      }
    } catch (e) {
      AppLogger.e('Error getting FCM token: $e');
    }
  }

  Future<void> _saveTokenLocally(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
  }

  Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fcm_token');
  }

  void _handleForegroundMessage(RemoteMessage message) {
    AppLogger.i('Foreground message received: ${message.notification?.title}');
    AppLogger.i('Foreground message body: ${message.notification?.body}');
    AppLogger.i('Foreground message data: ${message.data}');
    _messageController.add(message);

    // Show local notification for foreground messages
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'Bus tracking notifications',
            importance: Importance.high,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    AppLogger.i('Notification tapped: ${message.notification?.title}');
    // Handle navigation based on message data
    // You can use a navigation key to route to specific screens
  }

  /// Subscribe to a topic (e.g., college-specific notifications)
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    AppLogger.i('Subscribed to topic: $topic');
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    AppLogger.i('Unsubscribed from topic: $topic');
  }

  void dispose() {
    _tokenController.close();
    _messageController.close();
  }
}
