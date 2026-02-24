import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/core/providers/service_providers.dart';
import 'package:velocity_x/velocity_x.dart';
import 'dart:async';

class VoiceMessageButton extends ConsumerStatefulWidget {
  final String? receiverId; // If null, sends to coordinator broadcast
  final String? label; // Tooltip or instruction
  final String? defaultMessage; // Text message part of the notification

  const VoiceMessageButton({
    super.key,
    this.receiverId,
    this.label,
    this.defaultMessage,
  });

  @override
  ConsumerState<VoiceMessageButton> createState() => _VoiceMessageButtonState();
}

class _VoiceMessageButtonState extends ConsumerState<VoiceMessageButton> {
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _recordDuration = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (mounted) setState(() => _recordDuration++);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _handleRecording() async {
    final recordingService = ref.read(voiceRecordingServiceProvider);

    if (_isRecording) {
      // Stop recording
      _stopTimer();
      final path = await recordingService.stopRecording();
      if (mounted) setState(() => _isRecording = false);

      if (path != null) {
        // Show sending status
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sending voice message...')),
          );
        }

        try {
          await recordingService.sendVoiceMessage(
            filePath: path,
            receiverId: widget.receiverId ?? 'coordinator',
            message: widget.defaultMessage ?? 'Voice message from driver',
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Voice message sent!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to send: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } else {
      // Start recording
      await recordingService.startRecording();
      _startTimer();
      if (mounted) setState(() => _isRecording = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onLongPress: () => _handleRecording(),
      onLongPressUp: _isRecording ? () => _handleRecording() : null,
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.label ?? 'Long press to record voice message'),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isRecording ? Colors.red : colorScheme.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (_isRecording ? Colors.red : colorScheme.primary)
                  .withValues(alpha: 0.4),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.mic, color: Colors.white, size: 28),
            if (_isRecording)
              Positioned(
                top: -20,
                child: _formatDuration(
                  _recordDuration,
                ).text.white.bold.size(12).make().box.black.rounded.p4.make(),
              ),
          ],
        ),
      ),
    );
  }
}
