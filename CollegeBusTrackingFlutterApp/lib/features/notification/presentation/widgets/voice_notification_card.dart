import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/features/notification/domain/notification_model.dart';
import 'package:intl/intl.dart';
import 'simple_audio_player.dart';

class VoiceNotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final bool isUnread;

  const VoiceNotificationCard({
    super.key,
    required this.notification,
    required this.isUnread,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final timeStr = DateFormat('hh:mm a').format(notification.timestamp);

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
              if (isUnread)
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
}
