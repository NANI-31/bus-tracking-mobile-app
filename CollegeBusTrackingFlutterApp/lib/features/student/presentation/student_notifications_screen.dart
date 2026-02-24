import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/notification/application/notification_provider.dart';
import 'package:collegebus/features/notification/domain/notification_model.dart';
import 'package:collegebus/features/notification/presentation/widgets/notification_skeleton.dart';
import 'package:collegebus/features/notification/presentation/widgets/voice_notification_card.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:flutter/services.dart';

class StudentNotificationsScreen extends ConsumerStatefulWidget {
  const StudentNotificationsScreen({super.key});

  @override
  ConsumerState<StudentNotificationsScreen> createState() =>
      _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState
    extends ConsumerState<StudentNotificationsScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ["All", "Important", "Updates"];

  @override
  void initState() {
    super.initState();
    // Fetch notifications gracefully when screen opens
    Future.microtask(() {
      ref.read(notificationsProvider.notifier).refreshNotifications();
      ref.read(notificationsProvider.notifier).markAllAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: "Notifications".text.white.bold.make(),
          backgroundColor: AppColors.primary,
          elevation: 0,
          centerTitle: false,
          automaticallyImplyLeading: true,
        ),
        body: VStack([
          8.heightBox,
          // 2. Filter Tabs
          _buildFilterTabs(context),

          16.heightBox,

          // 3. Notifications List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref
                    .read(notificationsProvider.notifier)
                    .refreshNotifications();
              },
              child: notificationsAsync.when(
                loading: () => ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: 6,
                  itemBuilder: (context, index) => const NotificationSkeleton(),
                ),
                error: (err, stack) =>
                    Center(child: Text('Failed to load notifications: $err')),
                data: (notifications) {
                  // Apply simple filter logic
                  List<NotificationModel> filtered = notifications;
                  if (_selectedFilterIndex == 1) {
                    // Important (Let's say they have specific types)
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
                            style: TextStyle(fontSize: 16, color: Colors.grey),
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
                        case "GENERAL_ANNOUNCEMENT":
                          iconColor = const Color(0xFF8B5CF6);
                          iconBgColor = const Color(0xFFEDE9FE);
                          icon = Icons.campaign_rounded;
                          derivedTitle = "College Announcement";
                          break;
                        default:
                          iconColor = const Color(0xFF6B7280);
                          iconBgColor = const Color(0xFFF3F4F6);
                          icon = Icons.info_outline_rounded;
                          derivedTitle = "Update";
                          break;
                      }

                      final timeStr = _formatTimestamp(notif.timestamp);

                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (!notif.isRead) {
                            ref
                                .read(notificationsProvider.notifier)
                                .markAsRead(notif.id);
                          }
                        },
                        child: _buildNotificationCard(
                          context,
                          title: derivedTitle,
                          description: notif.message,
                          time: timeStr,
                          icon: icon,
                          iconColor: iconColor,
                          iconBgColor: iconBgColor,
                          isUnread: !notif.isRead,
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

  Widget _buildFilterTabs(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(32),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / _filters.length;

          return Stack(
            children: [
              // Sliding background
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                left: _selectedFilterIndex * tabWidth,
                top: 0,
                bottom: 0,
                width: tabWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              // Tabs
              Row(
                children: _filters.mapIndexed((filter, index) {
                  final isSelected = _selectedFilterIndex == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFilterIndex = index;
                        });
                      },
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: filter.text.bold
                            .color(
                              isSelected
                                  ? AppColors.primary
                                  : colorScheme.onSurface.withValues(
                                      alpha: 0.5,
                                    ),
                            )
                            .make(),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context, {
    required String title,
    required String description,
    required String time,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    bool isUnread = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isUnread
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: HStack([
        // Icon
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 26),
        ),

        20.widthBox,

        // Content
        VStack([
          HStack([
            title.text.lg.bold.color(colorScheme.onSurface).make().expand(),
            HStack([
              time.text
                  .size(12)
                  .color(isSelectedColor(context, isUnread))
                  .make(),
              if (isUnread) ...[
                8.widthBox,
                Container(
                  width: 8.0,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ]),
          ]),

          6.heightBox,

          description.text
              .color(colorScheme.onSurface.withValues(alpha: 0.6))
              .lineHeight(1.4)
              .make(),
        ]).expand(),
      ], crossAlignment: CrossAxisAlignment.start),
    );
  }

  Color isSelectedColor(BuildContext context, bool isUnread) {
    if (isUnread) return AppColors.primary;
    return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

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
