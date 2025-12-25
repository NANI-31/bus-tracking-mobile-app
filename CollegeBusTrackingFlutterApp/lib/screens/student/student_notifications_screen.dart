import 'package:flutter/material.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:velocity_x/velocity_x.dart';

class StudentNotificationsScreen extends StatefulWidget {
  const StudentNotificationsScreen({super.key});

  @override
  State<StudentNotificationsScreen> createState() =>
      _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState
    extends State<StudentNotificationsScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ["All", "Important", "Updates"];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: VStack([
          // 1. Header
          HStack([
            "Notifications".text.xl3.extraBold
                .color(colorScheme.onSurface)
                .make()
                .expand(),
            Icon(Icons.done_all_rounded, color: AppColors.primary, size: 28),
          ]).pSymmetric(h: 24, v: 16),

          // 2. Filter Tabs
          _buildFilterTabs(context),

          16.heightBox,

          // 3. Notifications List
          VStack([
            _buildNotificationCard(
              context,
              title: "Bus 12 Delayed",
              description:
                  "Due to heavy traffic near the Science block, Bus 12 is running 15 mins late.",
              time: "Now",
              icon: Icons.warning_rounded,
              iconColor: const Color(0xFFEF4444),
              iconBgColor: const Color(0xFFFEE2E2),
              isUnread: true,
            ),
            _buildNotificationCard(
              context,
              title: "Route 5 Arriving",
              description:
                  "Your bus is arriving at the Main Gate in 5 minutes.",
              time: "10 min ago",
              icon: Icons.directions_bus_rounded,
              iconColor: AppColors.primary,
              iconBgColor: AppColors.primary.withValues(alpha: 0.1),
              isUnread: true,
            ),
            _buildNotificationCard(
              context,
              title: "Schedule Change",
              description:
                  "The holiday schedule has been uploaded for next week.",
              time: "Yesterday",
              icon: Icons.calendar_today_rounded,
              iconColor: const Color(0xFF6B7280),
              iconBgColor: const Color(0xFFF3F4F6),
              isUnread: false,
            ),
            _buildNotificationCard(
              context,
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
          width: 1,
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
                  width: 8,
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
}
