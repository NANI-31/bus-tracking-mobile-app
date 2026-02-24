import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/core/providers/api_provider.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/features/notification/application/notification_provider.dart';
import 'package:collegebus/shared/widgets/success_modal.dart';
import 'package:collegebus/shared/widgets/api_error_modal.dart';
import 'package:collegebus/features/driver/presentation/widgets/voice_message_button.dart';
import 'package:velocity_x/velocity_x.dart';

class BroadcastModal extends ConsumerStatefulWidget {
  const BroadcastModal({super.key});

  @override
  ConsumerState<BroadcastModal> createState() => _BroadcastModalState();
}

class _BroadcastModalState extends ConsumerState<BroadcastModal> {
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final api = ref.read(apiServiceProvider);
      await api.broadcastToCollege(message);

      // Refresh own notifications instantly
      ref
          .read(notificationsProvider.notifier)
          .refreshNotifications(silent: true);

      if (mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (context) => const SuccessModal(
            title: 'Broadcast Sent',
            message:
                'Broadcast message sent successfully to all students, teachers, and parents.',
            primaryActionText: 'OK',
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ApiErrorModal.show(context: context, error: e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.broadcast_on_home, color: AppColors.primary),
                  const SizedBox(width: 8.0),
                  'Broadcast Message'.text.bold.xl2.make(),
                ],
              ),
              const SizedBox(height: 8),
              'Send an announcement to all students, teachers, and parents via text or voice recording.'
                  .text
                  .color(context.colorScheme.onSurface.withValues(alpha: 0.6))
                  .make(),
              const SizedBox(height: 20),
              TextField(
                controller: _messageController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Type your message here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  VoiceMessageButton(
                    receiverId: 'broadcast',
                    label: 'Record Voice Broadcast',
                    defaultMessage: 'New voice broadcast from administration',
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSend,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Send Text'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
