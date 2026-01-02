import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collegebus/services/data_service.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/widgets/success_modal.dart';
import 'package:collegebus/widgets/api_error_modal.dart';
import 'package:velocity_x/velocity_x.dart';

class BroadcastModal extends StatefulWidget {
  const BroadcastModal({super.key});

  @override
  State<BroadcastModal> createState() => _BroadcastModalState();
}

class _BroadcastModalState extends State<BroadcastModal> {
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
      final dataService = context.read<DataService>();
      await dataService.broadcastNotification(message);

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
                  const SizedBox(width: 8),
                  'Broadcast Message'.text.bold.xl2.make(),
                ],
              ),
              const SizedBox(height: 8),
              'Send an announcement to all students, teachers, and parents.'
                  .text
                  .color(AppColors.textSecondary)
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
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Send Broadcast'),
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
