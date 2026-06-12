import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/notification/application/notification_provider.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/features/notification/domain/notification_model.dart';
import '../widgets/notification_card.dart';
import '../widgets/voice_notification_card.dart';
import '../widgets/filter_tabs.dart';
import '../widgets/notification_skeleton.dart';
import 'package:flutter/services.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ["All", "Important", "Updates"];
  // bool _isTestingNotification = false;
  // final Dio _dio = Dio(
  //   BaseOptions(
  //     // baseUrl: 'http://192.168.29.27:5000/api',
  //     baseUrl: AppConstants.apiBaseUrl,
  //     connectTimeout: const Duration(seconds: 10),
  //     receiveTimeout: const Duration(seconds: 10),
  //   ),
  // );

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    Future.microtask(() {
      ref.read(notificationsProvider.notifier).refreshNotifications();
      ref.read(notificationsProvider.notifier).markAllAsRead();
    });
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
    final currentUser = ref.watch(currentUserProvider);
    final isCoordinatorOrAdmin =
        currentUser?.role == UserRole.busCoordinator ||
        currentUser?.role == UserRole.superAdmin;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: "Notifications".text.white.bold.make(),
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: true,
        ),
        body: VStack([
          8.heightBox,

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
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref
                    .read(notificationsProvider.notifier)
                    .refreshNotifications();
              },
              child: ref
                  .watch(notificationsProvider)
                  .when(
                    loading: () => ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: 6,
                      itemBuilder: (context, index) =>
                          const NotificationSkeleton(),
                    ),
                    error: (err, stack) =>
                        Center(child: Text("Failed to load: $err")),
                    data: (notifications) {
                      List<NotificationModel> filtered = notifications;
                      if (_selectedFilterIndex == 1) {
                        // Important
                        filtered = notifications
                            .where(
                              (n) =>
                                  n.type == 'EMERGENCY_ALERT' ||
                                  n.type == 'BUS_CANCELLED' ||
                                  n.type == 'BUS_DELAYED',
                            )
                            .toList();
                      } else if (_selectedFilterIndex == 2) {
                        // Updates
                        filtered = notifications
                            .where(
                              (n) =>
                                  n.type != 'EMERGENCY_ALERT' &&
                                  n.type != 'BUS_CANCELLED' &&
                                  n.type != 'BUS_DELAYED',
                            )
                            .toList();
                      }

                      if (filtered.isEmpty) {
                        return ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.2,
                            ),
                            const Center(
                              child: Text(
                                "No notifications yet.",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final notif = filtered[index];

                          if (notif.isVoice) {
                            return GestureDetector(
                              onTap: () {
                                if (!notif.isRead) {
                                  ref
                                      .read(notificationsProvider.notifier)
                                      .markAsRead(notif.id);
                                }
                              },
                              child: VoiceNotificationCard(
                                notification: notif,
                                isUnread: !notif.isRead,
                              ),
                            );
                          }

                          // Infer styling from type
                          Color iconColor = AppColors.primary;
                          Color iconBgColor = AppColors.primary.withValues(
                            alpha: 0.1,
                          );
                          IconData icon = Icons.notifications_rounded;
                          String derivedTitle = "Notification";

                          switch (notif.type) {
                            case "EMERGENCY_ALERT":
                              iconColor = const Color(0xFFEF4444);
                              iconBgColor = const Color(0xFFFEE2E2);
                              icon = Icons.warning_rounded;
                              derivedTitle = "Emergency Alert";
                              break;
                            case "BUS_DELAYED":
                              iconColor = const Color(0xFFEF4444);
                              iconBgColor = const Color(0xFFFEE2E2);
                              icon = Icons.warning_rounded;
                              derivedTitle = "Bus Delayed";
                              break;
                            case "BUS_CANCELLED":
                              iconColor = const Color(0xFFEF4444);
                              iconBgColor = const Color(0xFFFEE2E2);
                              icon = Icons.cancel_rounded;
                              derivedTitle = "Bus Cancelled";
                              break;
                            case "BUS_ARRIVING":
                            case "BUS_NEARBY":
                              iconColor = AppColors.primary;
                              iconBgColor = AppColors.primary.withValues(
                                alpha: 0.1,
                              );
                              icon = Icons.directions_bus_rounded;
                              derivedTitle = notif.type == "BUS_ARRIVING"
                                  ? "Bus Arriving"
                                  : "Bus Nearby";
                              break;
                            case "ROUTE_CHANGE":
                              iconColor = const Color(0xFFF59E0B);
                              iconBgColor = const Color(0xFFFEF3C7);
                              icon = Icons.alt_route_rounded;
                              derivedTitle = "Route Changed";
                              break;
                            default:
                              iconColor = const Color(0xFF6B7280);
                              iconBgColor = const Color(0xFFF3F4F6);
                              icon = Icons.info_outline_rounded;
                              derivedTitle = "Update";
                              break;
                          }

                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              if (!notif.isRead) {
                                ref
                                    .read(notificationsProvider.notifier)
                                    .markAsRead(notif.id);
                              }
                            },
                            child: NotificationCard(
                              title: derivedTitle,
                              description: notif.message,
                              time: _formatTimestamp(notif.timestamp),
                              icon: icon,
                              iconColor: iconColor,
                              iconBgColor: iconBgColor,
                              isUnread: !notif.isRead,
                              onDelete:
                                  (isCoordinatorOrAdmin ||
                                      notif.senderId == currentUser?.id ||
                                      notif.receiverId == currentUser?.id)
                                  ? () => _confirmDelete(context, ref, notif)
                                  : null,
                            ),
                          );
                        },
                      );
                    },
                  ),
            ),
          ),
        ]),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notification,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Notification?'),
        content: const Text(
          'This will permanently delete this notification from your list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(notificationsProvider.notifier)
                    .deleteNotification(notification.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notification deleted')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp.toLocal());

    if (difference.inMinutes < 1) {
      return "Just now";
    } else if (difference.inHours < 1) {
      return "${difference.inMinutes}m ago";
    } else if (difference.inDays < 1) {
      return "${difference.inHours}h ago";
    } else if (difference.inDays < 7) {
      return "${difference.inDays}d ago";
    } else {
      return "${timestamp.day}/${timestamp.month}/${timestamp.year}";
    }
  }
}
