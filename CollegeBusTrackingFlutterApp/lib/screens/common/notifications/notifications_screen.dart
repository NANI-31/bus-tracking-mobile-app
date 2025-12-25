import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:dio/dio.dart';
import 'widgets/notification_card.dart';
import 'widgets/filter_tabs.dart';
import 'widgets/test_notification_button.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ["All", "Important", "Updates"];
  bool _isTestingNotification = false;
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://192.168.29.27:5000/api',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: 'Notifications'.text.bold.make(),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: VStack([
          16.heightBox,

          // Header with Mark all as read
          HStack([
            "All Notifications".text.xl.bold
                .color(colorScheme.onSurface)
                .make()
                .expand(),
            Icon(Icons.done_all_rounded, color: AppColors.primary, size: 24),
          ]).pSymmetric(h: 24),

          16.heightBox,

          // Test Notification Button
          TestNotificationButton(
            isLoading: _isTestingNotification,
            onPressed: _sendTestNotification,
          ),

          16.heightBox,

          // Filter Tabs
          FilterTabs(
            filters: _filters,
            selectedIndex: _selectedFilterIndex,
            onTabSelected: (index) {
              setState(() {
                _selectedFilterIndex = index;
              });
            },
          ),

          16.heightBox,

          // Notifications List
          VStack([
            NotificationCard(
              title: "Bus 12 Delayed",
              description:
                  "Due to heavy traffic near the Science block, Bus 12 is running 15 mins late.",
              time: "Now",
              icon: Icons.warning_rounded,
              iconColor: const Color(0xFFEF4444),
              iconBgColor: const Color(0xFFFEE2E2),
              isUnread: true,
            ),
            NotificationCard(
              title: "Route 5 Arriving",
              description:
                  "Your bus is arriving at the Main Gate in 5 minutes.",
              time: "10 min ago",
              icon: Icons.directions_bus_rounded,
              iconColor: AppColors.primary,
              iconBgColor: AppColors.primary.withValues(alpha: 0.1),
              isUnread: true,
            ),
            NotificationCard(
              title: "Schedule Change",
              description:
                  "The holiday schedule has been uploaded for next week.",
              time: "Yesterday",
              icon: Icons.calendar_today_rounded,
              iconColor: const Color(0xFF6B7280),
              iconBgColor: const Color(0xFFF3F4F6),
              isUnread: false,
            ),
            NotificationCard(
              title: "System Update",
              description:
                  "We've improved the live tracking accuracy for all routes.",
              time: "2 days ago",
              icon: Icons.notifications_rounded,
              iconColor: const Color(0xFF4B5563),
              iconBgColor: const Color(0xFFF3F4F6),
              isUnread: false,
            ),
          ]).pSymmetric(h: 24).scrollVertical().expand(),
        ]),
      ),
    );
  }

  Future<void> _sendTestNotification() async {
    setState(() {
      _isTestingNotification = true;
    });

    try {
      // Wait 2 seconds before making the API call
      await Future.delayed(const Duration(seconds: 2));

      final response = await _dio.post('/notifications/test');

      if (response.statusCode == 200) {
        final message = response.data['message'] as String;

        // Show real notification
        await _showNotification('College Bus Tracking', message);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Notification sent: $message'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send test notification: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTestingNotification = false;
        });
      }
    }
  }

  Future<void> _showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'bus_tracking_channel',
      'Bus Tracking Notifications',
      channelDescription: 'Notifications for bus tracking updates',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
    );
  }
}
