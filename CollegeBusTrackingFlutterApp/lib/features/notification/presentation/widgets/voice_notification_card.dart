import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/features/notification/domain/notification_model.dart';
import 'package:intl/intl.dart';
import 'simple_audio_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/features/notification/application/notification_provider.dart';

class VoiceNotificationCard extends ConsumerWidget {
  final NotificationModel notification;
  final bool isUnread;

  const VoiceNotificationCard({
    super.key,
    required this.notification,
    required this.isUnread,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final timeStr = DateFormat(
      'hh:mm a',
    ).format(notification.timestamp.toLocal());
    final currentUser = ref.watch(currentUserProvider);
    final isSender = currentUser?.id == notification.senderId;
    final isCoordinator = currentUser?.role == 'Bus Coordinator';
    final canDelete = isSender || isCoordinator;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isUnread
            ? Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFE3F2FD),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic, color: Colors.blue, size: 24),
              ),
              16.widthBox,
              // Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      "Voice Message".text.bold
                          .size(16)
                          .color(colorScheme.onSurface)
                          .make(),
                      timeStr.text
                          .size(12)
                          .color(colorScheme.onSurface.withValues(alpha: 0.5))
                          .make(),
                    ],
                  ),
                  4.heightBox,
                  notification.message.text
                      .size(14)
                      .color(colorScheme.onSurface.withValues(alpha: 0.7))
                      .make(),
                ],
              ).expand(),
              if (canDelete)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  onPressed: () => _confirmDelete(context, ref),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              if (isUnread && !isSender)
                Container(
                  width: 8.0,
                  height: 8,
                  margin: const EdgeInsets.only(left: 8, top: 8),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          16.heightBox,
          if (notification.audioUrl != null)
            SimpleAudioPlayer(url: notification.audioUrl!)
          else
            "Audio unavailable".text.italic.color(Colors.red).make(),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Notification?'),
        content: const Text(
          'This will permanently delete this voice message for everyone.',
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
}
