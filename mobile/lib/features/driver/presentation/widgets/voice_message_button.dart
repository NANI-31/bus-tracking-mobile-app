import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/core/providers/service_providers.dart';
import 'package:velocity_x/velocity_x.dart';

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

class _VoiceMessageButtonState extends ConsumerState<VoiceMessageButton>
    with TickerProviderStateMixin {
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _timer;
  double _currentAmplitude = -160.0;
  bool _isCancelled = false;
  bool _hasSignalledCancel = false;
  Offset? _longPressStartPos;

  late AnimationController _pulseController;
  OverlayEntry? _recordingOverlay;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _recordingOverlay?.remove();
    _recordingOverlay = null;
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _recordDuration = 0;
    _currentAmplitude = -160.0;
    _timer = Timer.periodic(const Duration(milliseconds: 150), (Timer t) async {
      if (!mounted) return;
      
      // Update duration (every 1000ms approximate)
      final newDuration = t.tick * 150 ~/ 1000;
      if (newDuration != _recordDuration) {
        setState(() {
          _recordDuration = newDuration;
        });
      }

      // Read audio amplitude for soundwave visualizer
      try {
        final amp = await ref.read(voiceRecordingServiceProvider).getAmplitude();
        if (mounted) {
          setState(() {
            _currentAmplitude = amp.current; // dB: -160 (quiet) to 0 (loud)
          });
        }
      } catch (_) {}

      // Refresh overlay rendering
      _recordingOverlay?.markNeedsBuild();
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

  void _showOverlayToast(String message, {bool isError = false}) {
    if (!mounted) return;

    late OverlayEntry toastEntry;
    toastEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isError ? Colors.red.shade800 : const Color(0xFF0097B2),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  isError ? Icons.error_outline : Icons.check_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
                12.widthBox,
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(toastEntry);
    Future.delayed(const Duration(seconds: 3), () {
      if (toastEntry.mounted) {
        toastEntry.remove();
      }
    });
  }

  Future<void> _startRecording() async {
    final recordingService = ref.read(voiceRecordingServiceProvider);
    try {
      await recordingService.startRecording();
      HapticFeedback.mediumImpact();

      setState(() {
        _isRecording = true;
        _recordDuration = 0;
        _currentAmplitude = -160.0;
        _isCancelled = false;
        _hasSignalledCancel = false;
      });

      _pulseController.repeat();
      _showRecordingOverlay();
      _startTimer();
    } catch (e) {
      _showOverlayToast('Microphone permission required to record messages', isError: true);
    }
  }

  void _showRecordingOverlay() {
    _recordingOverlay?.remove();

    _recordingOverlay = OverlayEntry(
      builder: (context) {
        final db = _currentAmplitude.clamp(-50.0, 0.0);
        final norm = 1.0 - (db / -50.0); // 0.0 (silent) to 1.0 (loud)

        return Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _isCancelled 
                    ? Colors.red.shade900.withValues(alpha: 0.95) 
                    : const Color(0xFF1E293B).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _RecordingDot(),
                  10.widthBox,
                  _formatDuration(_recordDuration).text.white.bold.make(),
                  16.widthBox,

                  // Live Amplitude Waveform Visualizer
                  Expanded(
                    child: SizedBox(
                      height: 24,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(8, (index) {
                          final factor = (index % 3 == 0) ? 0.6 : (index % 2 == 0) ? 0.95 : 0.45;
                          final barHeight = (norm * 24 * factor).clamp(4.0, 24.0);
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            width: 3.5,
                            height: barHeight,
                            margin: const EdgeInsets.symmetric(horizontal: 2.0),
                            decoration: BoxDecoration(
                              color: _isCancelled ? Colors.white70 : const Color(0xFF00C6E6),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),

                  16.widthBox,

                  // Gesture Hint Text
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isCancelled ? Icons.delete_outline : Icons.arrow_forward_ios_rounded,
                        color: _isCancelled ? Colors.white : Colors.white54,
                        size: 13,
                      ),
                      4.widthBox,
                      (_isCancelled ? 'Release to discard' : 'Slide right to cancel')
                          .text
                          .color(_isCancelled ? Colors.white : Colors.white70)
                          .size(11)
                          .bold
                          .make(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_recordingOverlay!);
  }

  Future<void> _stopRecording() async {
    _stopTimer();
    _pulseController.stop();
    _recordingOverlay?.remove();
    _recordingOverlay = null;

    final recordingService = ref.read(voiceRecordingServiceProvider);
    final path = await recordingService.stopRecording();

    setState(() {
      _isRecording = false;
    });

    if (_isCancelled) {
      HapticFeedback.selectionClick();
      _showOverlayToast('Recording discarded');
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
      return;
    }

    if (path != null) {
      _showOverlayToast('Sending voice message...');
      try {
        await recordingService.sendVoiceMessage(
          filePath: path,
          receiverId: widget.receiverId ?? 'coordinator',
          message: widget.defaultMessage ?? 'Voice message from driver',
        );
        HapticFeedback.mediumImpact();
        _showOverlayToast('Voice message sent!');
      } catch (e) {
        _showOverlayToast('Failed to send: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF0097B2);

    return GestureDetector(
      onLongPressStart: (details) {
        _longPressStartPos = details.localPosition;
        _startRecording();
      },
      onLongPressMoveUpdate: (details) {
        if (_longPressStartPos == null) return;
        final offset = details.localPosition.dx - _longPressStartPos!.dx;
        final isCancelled = offset > 70.0;
        if (isCancelled && !_hasSignalledCancel) {
          HapticFeedback.heavyImpact();
          _hasSignalledCancel = true;
        } else if (!isCancelled && _hasSignalledCancel) {
          _hasSignalledCancel = false;
        }
        setState(() {
          _isCancelled = isCancelled;
        });
        _recordingOverlay?.markNeedsBuild();
      },
      onLongPressEnd: (_) => _stopRecording(),
      onTap: () {
        _showOverlayToast(widget.label ?? 'Hold button to record voice message');
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Wave pulse ring
          if (_isRecording)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 50 * (1.0 + _pulseController.value * 0.45),
                  height: 50 * (1.0 + _pulseController.value * 0.45),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (_isCancelled ? Colors.red : primaryColor)
                        .withValues(alpha: (1.0 - _pulseController.value) * 0.45),
                  ),
                );
              },
            ),

          // Central circular button
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: _isRecording ? 58 : 48,
            height: _isRecording ? 58 : 48,
            decoration: BoxDecoration(
              color: _isRecording
                  ? (_isCancelled ? Colors.red.shade900 : Colors.red.shade600)
                  : primaryColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_isRecording ? Colors.red : primaryColor).withValues(alpha: 0.35),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              _isRecording 
                  ? (_isCancelled ? Icons.delete_outline : Icons.mic)
                  : Icons.mic,
              color: Colors.white,
              size: _isRecording ? 26 : 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordingDot extends StatefulWidget {
  @override
  State<_RecordingDot> createState() => _RecordingDotState();
}

class _RecordingDotState extends State<_RecordingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WidgetAccessor(
      child: FadeTransition(
        opacity: _controller,
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Helper to resolve build type mapping issues or directly display widget
class WidgetAccessor extends StatelessWidget {
  final Widget child;
  const WidgetAccessor({super.key, required this.child});
  @override
  Widget build(BuildContext context) => child;
}
