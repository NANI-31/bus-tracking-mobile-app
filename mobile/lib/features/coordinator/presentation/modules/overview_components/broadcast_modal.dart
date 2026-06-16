import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/core/providers/repository_providers.dart';
import 'package:collegebus/core/providers/service_providers.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/features/notification/application/notification_provider.dart';
import 'package:collegebus/shared/widgets/success_modal.dart';
import 'package:collegebus/shared/widgets/api_error_modal.dart';
import 'package:collegebus/core/services/persistence_service.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:audioplayers/audioplayers.dart';

class BroadcastModal extends ConsumerStatefulWidget {
  const BroadcastModal({super.key});

  @override
  ConsumerState<BroadcastModal> createState() => _BroadcastModalState();
}

class _BroadcastModalState extends ConsumerState<BroadcastModal> {
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;

  // Tabs
  int _selectedTab = 0; // 0: Text, 1: Voice

  // Voice recording state
  bool _isRecording = false;
  bool _hasRecorded = false;
  String? _recordedPath;
  int _recordDuration = 0;
  Timer? _recordingTimer;
  double _currentNormalizedAmplitude = 0.0; // Vocal amplitude tracking

  // Audio Quality Settings
  bool _noiseSuppress = true;
  bool _echoCancel = true;
  bool _autoGain = true;

  // Waveform amplitude visualizer
  Timer? _waveTimer;
  final List<double> _waveHeights = [12, 24, 8, 32, 16, 28, 10, 18, 14];

  // Playback state
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  int _playPosition = 0;

  // Long press safety flag
  bool _isLongPressActive = false;
  double _playbackSpeed = 1.0;
  int _playPositionMs = 0;
  int _trackDurationMs = 0;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    // Bind audio player event listeners
    _audioPlayer?.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });

    _audioPlayer?.onPositionChanged.listen((pos) {
      if (!mounted) return;
      setState(() {
        _playPosition = pos.inSeconds;
        _playPositionMs = pos.inMilliseconds;
      });
    });

    _audioPlayer?.onDurationChanged.listen((dur) {
      if (!mounted) return;
      setState(() {
        _trackDurationMs = dur.inMilliseconds;
      });
    });

    _audioPlayer?.onPlayerComplete.listen((event) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _playPosition = 0;
        _playPositionMs = 0;
      });
    });

    // Load draft data
    _loadDraft();

    // Listener for text change to auto-save draft
    _messageController.addListener(_saveTextDraft);
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _waveTimer?.cancel();
    _audioPlayer?.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // Load draft data and settings on modal init
  void _loadDraft() {
    final storedText = PersistenceService.getString('broadcast_draft_text');
    if (storedText != null) {
      _messageController.text = storedText;
    }

    final storedTab = PersistenceService.getString('broadcast_draft_tab');
    if (storedTab != null) {
      _selectedTab = int.tryParse(storedTab) ?? 0;
    }

    final storedVoicePath = PersistenceService.getString('broadcast_draft_voice_path');
    if (storedVoicePath != null) {
      final file = File(storedVoicePath);
      if (file.existsSync()) {
        _recordedPath = storedVoicePath;
        _hasRecorded = true;
        final storedDuration = PersistenceService.getString('broadcast_draft_voice_duration');
        _recordDuration = int.tryParse(storedDuration ?? '0') ?? 0;
      } else {
        PersistenceService.remove('broadcast_draft_voice_path');
        PersistenceService.remove('broadcast_draft_voice_duration');
      }
    }

    // Load audio config settings
    final storedNoise = PersistenceService.getString('broadcast_audio_noise');
    if (storedNoise != null) _noiseSuppress = storedNoise == 'true';
    final storedEcho = PersistenceService.getString('broadcast_audio_echo');
    if (storedEcho != null) _echoCancel = storedEcho == 'true';
    final storedGain = PersistenceService.getString('broadcast_audio_gain');
    if (storedGain != null) _autoGain = storedGain == 'true';
  }

  void _saveTextDraft() {
    PersistenceService.setString('broadcast_draft_text', _messageController.text);
  }

  void _saveVoiceDraft(String path, int duration) {
    PersistenceService.setString('broadcast_draft_voice_path', path);
    PersistenceService.setString('broadcast_draft_voice_duration', duration.toString());
  }

  void _clearAllDrafts() {
    PersistenceService.remove('broadcast_draft_text');
    PersistenceService.remove('broadcast_draft_tab');
    PersistenceService.remove('broadcast_draft_voice_path');
    PersistenceService.remove('broadcast_draft_voice_duration');
  }

  // Timer helper to format seconds into MM:SS
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _startTimer() {
    _recordingTimer?.cancel();
    _recordDuration = 0;
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recordDuration++;
        });
      }
    });
  }

  // Visualizer animated sound wave by listening to real-time dB amplitude
  void _startWaveAnimation() {
    _waveTimer?.cancel();
    _waveTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (!mounted || !_isRecording) return;

      try {
        final recordingService = ref.read(voiceRecordingServiceProvider);
        final amplitude = await recordingService.getAmplitude();

        // Decibels range from -160.0 (silent) to 0.0 (max loudness).
        // Common human vocal output lies within -50.0 to -10.0 range.
        final currentDb = amplitude.current;
        double normalized = (currentDb + 50.0) / 45.0; // Normalize dB range
        normalized = normalized.clamp(0.0, 1.0);

        // Calculate visual height based on normalized decibel input
        final double targetHeight = 6.0 + normalized * 38.0;

        if (mounted) {
          setState(() {
            if (normalized > _currentNormalizedAmplitude) {
              _currentNormalizedAmplitude = normalized;
            } else {
              _currentNormalizedAmplitude -= (_currentNormalizedAmplitude - normalized) * 0.25;
            }
            _waveHeights.removeAt(0);
            _waveHeights.add(targetHeight);
          });
        }
      } catch (_) {
        // Fallback smooth oscillation on exception
        if (mounted) {
          setState(() {
            _waveHeights.removeAt(0);
            _waveHeights.add(6.0 + (timer.tick % 5) * 6.0);
          });
        }
      }
    });
  }

  Future<void> _startRecording() async {
    final recordingService = ref.read(voiceRecordingServiceProvider);
    HapticFeedback.mediumImpact();
    try {
      await recordingService.startRecording(
        noiseSuppress: _noiseSuppress,
        echoCancel: _echoCancel,
        autoGain: _autoGain,
      );
      if (!mounted) return;
      setState(() {
        _isRecording = true;
        _hasRecorded = false;
        _recordedPath = null;
        _recordDuration = 0;
      });
      _startTimer();
      _startWaveAnimation();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    final recordingService = ref.read(voiceRecordingServiceProvider);
    _recordingTimer?.cancel();
    _waveTimer?.cancel();
    HapticFeedback.mediumImpact();
    try {
      final path = await recordingService.stopRecording();
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _currentNormalizedAmplitude = 0.0;
        if (path != null) {
          _hasRecorded = true;
          _recordedPath = path;
          _saveVoiceDraft(path, _recordDuration);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onRecordTap() async {
    if (_isLongPressActive) return;
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  void _onRecordLongPressStart(LongPressStartDetails details) async {
    if (_isRecording) return;
    _isLongPressActive = true;
    await _startRecording();
  }

  void _onRecordLongPressEnd(LongPressEndDetails details) async {
    if (!_isRecording) return;
    await _stopRecording();
    // Safety delay to reset long press lock state
    Future.delayed(const Duration(milliseconds: 300), () {
      _isLongPressActive = false;
    });
  }

  Future<void> _discardRecording() async {
    HapticFeedback.vibrate();
    await _audioPlayer?.stop();
    if (_recordedPath != null) {
      final file = File(_recordedPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }

    // Wipe drafts
    PersistenceService.remove('broadcast_draft_voice_path');
    PersistenceService.remove('broadcast_draft_voice_duration');

    if (mounted) {
      setState(() {
        _hasRecorded = false;
        _recordedPath = null;
        _recordDuration = 0;
        _isPlaying = false;
        _playPosition = 0;
        _playPositionMs = 0;
        _trackDurationMs = 0;
      });
    }
  }

  // Confirm and warning sheet when closing with active changes
  Future<bool> _showDiscardWarningIfNeeded() async {
    final hasText = _messageController.text.trim().isNotEmpty;
    final hasVoice = _hasRecorded;

    if (!hasText && !hasVoice) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF161C24) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Discard Draft?'),
          content: const Text(
            'You have an unsent announcement draft. Closing this modal will discard your changes.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Keep Editing',
                style: TextStyle(color: Color(ref.watch(themeServiceProvider).accentColorValue)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _clearAllDrafts();
                if (_recordedPath != null) {
                  final file = File(_recordedPath!);
                  if (file.existsSync()) {
                    file.deleteSync();
                  }
                }
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Discard'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _sendVoiceBroadcast() async {
    if (_recordedPath == null) return;
    setState(() => _isLoading = true);

    try {
      final recordingService = ref.read(voiceRecordingServiceProvider);
      await recordingService.sendVoiceMessage(
        receiverId: 'broadcast',
        filePath: _recordedPath!,
        message: 'New voice broadcast from Bus Coordinator',
      );

      // Clear draft states
      _clearAllDrafts();

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
                'Voice broadcast message sent successfully to all students, teachers, and parents.',
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

  Future<void> _handleSend() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(notificationRepositoryProvider);
      await repo.broadcastToCollege(message);

      // Clear draft states
      _clearAllDrafts();

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeService = ref.watch(themeServiceProvider);
    final accentColor = Color(themeService.accentColorValue);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldClose = await _showDiscardWarningIfNeeded();
        if (shouldClose && context.mounted) {
          Navigator.of(context).pop(result);
        }
      },
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Material(
            color: isDark ? const Color(0xFF161C24) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            elevation: 8,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag-to-dismiss handle
                        Center(
                          child: Builder(
                            builder: (context) {
                              final routeAnimation = ModalRoute.of(context)?.animation;
                              if (routeAnimation == null) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 20),
                                  width: 40,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(2.5),
                                  ),
                                );
                              }
                              return AnimatedBuilder(
                                animation: routeAnimation,
                                builder: (context, child) {
                                  final progress = routeAnimation.value;
                                  final dragFactor = (1.0 - progress).clamp(0.0, 1.0);
                                  
                                  final width = 40.0 + dragFactor * 20.0;
                                  final height = 5.0 + dragFactor * 2.0;
                                  final baseColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
                                  final color = Color.lerp(baseColor, accentColor, dragFactor) ?? baseColor;
                                  
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 20),
                                    width: width,
                                    height: height,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(height / 2),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                // Header title and icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.broadcast_on_home_rounded,
                          color: accentColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: 'Broadcast announcement'
                          .text
                          .bold
                          .xl2
                          .color(isDark ? Colors.white : Colors.black)
                          .make(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                'Send a text or voice message to all members of the college community.'
                    .text
                    .color(context.colorScheme.onSurface.withValues(alpha: 0.6))
                    .size(13)
                    .make(),
                const SizedBox(height: 20),

                // Segmented Tab Selector
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF212B36) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (_isRecording) return;
                            setState(() {
                              _selectedTab = 0;
                            });
                            PersistenceService.setString('broadcast_draft_tab', '0');
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedTab == 0
                                  ? (isDark ? const Color(0xFF161C24) : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _selectedTab == 0
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                            alpha: isDark ? 0.2 : 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 16,
                                    color: _selectedTab == 0
                                        ? accentColor
                                        : (isDark
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade600),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Text Message',
                                    style: TextStyle(
                                      fontWeight: _selectedTab == 0
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: 13,
                                      color: _selectedTab == 0
                                          ? (isDark ? Colors.white : Colors.black)
                                          : (isDark
                                              ? Colors.grey.shade400
                                              : Colors.grey.shade600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTab = 1;
                            });
                            PersistenceService.setString('broadcast_draft_tab', '1');
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedTab == 1
                                  ? (isDark ? const Color(0xFF161C24) : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _selectedTab == 1
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                            alpha: isDark ? 0.2 : 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : [],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.mic_none_rounded,
                                  size: 16,
                                  color: _selectedTab == 1
                                      ? accentColor
                                      : (isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Voice Recording',
                                  style: TextStyle(
                                    fontWeight: _selectedTab == 1
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 13,
                                    color: _selectedTab == 1
                                        ? (isDark ? Colors.white : Colors.black)
                                        : (isDark
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Animated size and horizontal slide-and-fade switcher between tab screens
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      final isTextTab = child.key == const ValueKey<int>(0);
                      final beginOffset = isTextTab ? const Offset(-0.06, 0.0) : const Offset(0.06, 0.0);
                      return SlideTransition(
                        position: animation.drive(
                          Tween<Offset>(
                            begin: beginOffset,
                            end: Offset.zero,
                          ).chain(CurveTween(curve: Curves.easeOutCubic)),
                        ),
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: _selectedTab == 0
                        ? KeyedSubtree(
                            key: const ValueKey<int>(0),
                            child: _buildTextTabContent(context, isDark, accentColor),
                          )
                        : KeyedSubtree(
                            key: const ValueKey<int>(1),
                            child: _buildVoiceTabContent(context, isDark, accentColor),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextTabContent(
      BuildContext context, bool isDark, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _messageController,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            style: TextStyle(
                fontSize: 14, color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: 'Type your broadcast announcement here...',
              hintStyle: TextStyle(
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      final shouldClose = await _showDiscardWarningIfNeeded();
                      if (shouldClose && context.mounted) {
                        Navigator.pop(context);
                      }
                    },
              style: TextButton.styleFrom(
                foregroundColor:
                    isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text('Cancel'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleSend,
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Send Broadcast'),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceTabContent(
      BuildContext context, bool isDark, Color accentColor) {
    if (_hasRecorded) {
      // Audio playback & send action pane
      return Column(
        children: [
          Container(
            height: 180,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade200,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Waveform visualization representing playback progress
                Builder(
                  builder: (context) {
                    final hsv = HSVColor.fromColor(accentColor);
                    final shiftedColor = hsv
                        .withValue((hsv.value + 0.15).clamp(0.0, 1.0))
                        .withHue((hsv.hue + 25) % 360)
                        .toColor();
                    final double progress = _trackDurationMs > 0
                        ? (_playPositionMs / _trackDurationMs).clamp(0.0, 1.0)
                        : (_recordDuration > 0
                            ? (_playPositionMs / (_recordDuration * 1000.0)).clamp(0.0, 1.0)
                            : 0.0);
                    return SizedBox(
                      height: 40,
                      width: 260,
                      child: CustomPaint(
                        painter: BezierWaveformPainter(
                          waveHeights: _waveHeights,
                          primaryColor: accentColor,
                          secondaryColor: shiftedColor,
                          playbackProgress: progress,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Play/Pause button
                    GestureDetector(
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        if (_isPlaying) {
                          await _audioPlayer?.pause();
                        } else {
                          if (_recordedPath != null) {
                            await _audioPlayer?.play(
                                DeviceFileSource(_recordedPath!));
                            await _audioPlayer?.setPlaybackRate(_playbackSpeed);
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.35),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Sound progress slider
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6),
                              overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 14),
                              activeTrackColor: accentColor,
                              inactiveTrackColor: accentColor.withValues(alpha: 0.15),
                              thumbColor: accentColor,
                              overlayColor: accentColor.withValues(alpha: 0.1),
                            ),
                            child: Slider(
                              value: _playPosition.toDouble().clamp(
                                  0.0, _recordDuration.toDouble()),
                              max: _recordDuration.toDouble() > 0
                                  ? _recordDuration.toDouble()
                                  : 1.0,
                              onChanged: (val) async {
                                await _audioPlayer
                                    ?.seek(Duration(seconds: val.toInt()));
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _formatDuration(_playPosition)
                                    .text
                                    .size(11)
                                    .color(isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600)
                                    .make(),
                                _formatDuration(_recordDuration)
                                    .text
                                    .size(11)
                                    .color(isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600)
                                    .make(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    'Playback Speed:'.text.size(11).color(isDark ? Colors.grey.shade400 : Colors.grey.shade600).make(),
                    const SizedBox(width: 12),
                    ...[1.0, 1.5, 2.0].map((speed) {
                      final isSelected = _playbackSpeed == speed;
                      return GestureDetector(
                        onTap: () async {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _playbackSpeed = speed;
                          });
                          await _audioPlayer?.setPlaybackRate(speed);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? accentColor.withValues(alpha: 0.15) 
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? accentColor : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: '${speed.toStringAsFixed(1).replaceAll('.0', '')}x'
                              .text
                              .bold
                              .size(11)
                              .color(isSelected 
                                  ? accentColor 
                                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade600))
                              .make(),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              TextButton.icon(
                onPressed: _isLoading ? null : _discardRecording,
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 18, color: Colors.red),
                label:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        final shouldClose = await _showDiscardWarningIfNeeded();
                        if (shouldClose && context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                style: TextButton.styleFrom(
                  foregroundColor:
                      isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _sendVoiceBroadcast,
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Send Broadcast'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      );
    }

    // Active recording or idle recording container
    return Column(
      children: [
        TweenAnimationBuilder<Color?>(
          tween: ColorTween(begin: accentColor, end: accentColor),
          duration: const Duration(milliseconds: 400),
          builder: (context, animColor, child) {
            final activeColor = animColor ?? accentColor;
            
            // Calculate a complementary hue/value shifted color for the gradient
            final hsv = HSVColor.fromColor(activeColor);
            final shiftedColor = hsv
                .withValue((hsv.value + 0.15).clamp(0.0, 1.0))
                .withHue((hsv.hue + 25) % 360)
                .toColor();

            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _isRecording
                      ? activeColor.withValues(
                          alpha: 0.15 + _currentNormalizedAmplitude * 0.5)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.shade200),
                  width: _isRecording ? 2.0 : 1.5,
                ),
                boxShadow: _isRecording
                    ? [
                        BoxShadow(
                          color: activeColor.withValues(
                              alpha: 0.1 + _currentNormalizedAmplitude * 0.3),
                          blurRadius: 12 + _currentNormalizedAmplitude * 12,
                          spreadRadius: 1 + _currentNormalizedAmplitude * 3,
                        ),
                        BoxShadow(
                          color: shiftedColor.withValues(
                              alpha: 0.05 + _currentNormalizedAmplitude * 0.15),
                          blurRadius: 20 + _currentNormalizedAmplitude * 10,
                          spreadRadius: 0,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isRecording) ...[
                    // Flashing red dot and timer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.2, end: 1.0),
                          duration: const Duration(milliseconds: 550),
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: (_recordDuration % 2 == 0)
                                  ? value
                                  : 1.0 - value,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        _formatDuration(_recordDuration)
                            .text
                            .bold
                            .size(32)
                            .color(isDark ? Colors.white : Colors.black)
                            .make(),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Smooth continuous Bézier audio waveform custom paint
                    SizedBox(
                      height: 50,
                      width: 260,
                      child: CustomPaint(
                        painter: BezierWaveformPainter(
                          waveHeights: _waveHeights,
                          primaryColor: activeColor,
                          secondaryColor: shiftedColor,
                          playbackProgress: 0.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    'Tap mic button again to stop recording'
                        .text
                        .size(11)
                        .color(isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600)
                        .make(),
                  ] else ...[
                    // Idle mic screen
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          activeColor,
                          activeColor.withValues(alpha: 0.6)
                        ],
                      ).createShader(bounds),
                      child: const Icon(Icons.mic_none_rounded,
                          size: 48, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    'Hold or tap the mic button to record voice announcement'
                        .text
                        .align(TextAlign.center)
                        .size(13)
                        .color(isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600)
                        .make()
                        .pSymmetric(h: 30),
                  ],
                ],
              ),
            );
          },
        ),

        // Audio Quality Controls Expansion Panel
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: 'Audio Quality Settings'
                  .text
                  .bold
                  .size(12)
                  .color(accentColor)
                  .make(),
              leading: Icon(Icons.tune_rounded, color: accentColor, size: 18),
              dense: true,
              tilePadding: EdgeInsets.zero,
              children: [
                SwitchListTile(
                  title: const Text('Noise Suppression',
                      style: TextStyle(fontSize: 12)),
                  subtitle: const Text('Minimize background ambient noises',
                      style: TextStyle(fontSize: 10)),
                  value: _noiseSuppress,
                  activeThumbColor: accentColor,
                  dense: true,
                  onChanged: (val) {
                    setState(() => _noiseSuppress = val);
                    PersistenceService.setString(
                        'broadcast_audio_noise', val.toString());
                  },
                ),
                SwitchListTile(
                  title: const Text('Echo Cancellation',
                      style: TextStyle(fontSize: 12)),
                  subtitle: const Text('Eliminate speaker feedback echoes',
                      style: TextStyle(fontSize: 10)),
                  value: _echoCancel,
                  activeThumbColor: accentColor,
                  dense: true,
                  onChanged: (val) {
                    setState(() => _echoCancel = val);
                    PersistenceService.setString(
                        'broadcast_audio_echo', val.toString());
                  },
                ),
                SwitchListTile(
                  title: const Text('Auto Gain Control',
                      style: TextStyle(fontSize: 12)),
                  subtitle: const Text(
                      'Automatic voice volume boost and stabilization',
                      style: TextStyle(fontSize: 10)),
                  value: _autoGain,
                  activeThumbColor: accentColor,
                  dense: true,
                  onChanged: (val) {
                    setState(() => _autoGain = val);
                    PersistenceService.setString(
                        'broadcast_audio_gain', val.toString());
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Record Trigger Button
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: _onRecordTap,
                onLongPressStart: _onRecordLongPressStart,
                onLongPressEnd: _onRecordLongPressEnd,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1.0, end: _isRecording ? 1.15 : 1.0),
                  duration: const Duration(milliseconds: 150),
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _isRecording ? Colors.red : accentColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_isRecording ? Colors.red : accentColor)
                                  .withValues(alpha: 0.35),
                              blurRadius: _isRecording ? 20 : 10,
                              spreadRadius: _isRecording ? 4 : 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              (_isRecording ? 'Recording...' : 'Record Button')
                  .text
                  .bold
                  .size(12)
                  .color(isDark ? Colors.grey.shade400 : Colors.grey.shade600)
                  .make(),
            ],
          ),
        ),

        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () async {
                final shouldClose = await _showDiscardWarningIfNeeded();
                if (shouldClose && context.mounted) {
                  Navigator.pop(context);
                }
              },
              style: TextButton.styleFrom(
                foregroundColor:
                    isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ],
    );
  }
}

class BezierWaveformPainter extends CustomPainter {
  final List<double> waveHeights;
  final Color primaryColor;
  final Color secondaryColor;
  final double playbackProgress;

  BezierWaveformPainter({
    required this.waveHeights,
    required this.primaryColor,
    required this.secondaryColor,
    required this.playbackProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waveHeights.isEmpty) return;

    final double activeStop = playbackProgress.clamp(0.0, 1.0);

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          primaryColor,
          primaryColor,
          primaryColor.withValues(alpha: 0.25),
          primaryColor.withValues(alpha: 0.25),
        ],
        stops: [
          0.0,
          activeStop,
          activeStop,
          1.0,
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final double widthBetweenPoints = size.width / (waveHeights.length - 1);
    final double midY = size.height / 2;

    // Top path
    path.moveTo(0, midY - waveHeights[0] / 2);
    for (int i = 0; i < waveHeights.length - 1; i++) {
      final x1 = i * widthBetweenPoints;
      final y1 = midY - waveHeights[i] / 2;
      final x2 = (i + 1) * widthBetweenPoints;
      final y2 = midY - waveHeights[i + 1] / 2;
      
      final cx = (x1 + x2) / 2;
      path.cubicTo(cx, y1, cx, y2, x2, y2);
    }

    // Bottom path (mirror)
    final bottomPath = Path();
    bottomPath.moveTo(0, midY + waveHeights[0] / 2);
    for (int i = 0; i < waveHeights.length - 1; i++) {
      final x1 = i * widthBetweenPoints;
      final y1 = midY + waveHeights[i] / 2;
      final x2 = (i + 1) * widthBetweenPoints;
      final y2 = midY + waveHeights[i + 1] / 2;
      
      final cx = (x1 + x2) / 2;
      bottomPath.cubicTo(cx, y1, cx, y2, x2, y2);
    }

    canvas.drawPath(path, paint);
    canvas.drawPath(bottomPath, paint);

    // Dynamic gradient fill for visual depth
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          primaryColor.withValues(alpha: 0.18),
          primaryColor.withValues(alpha: 0.18),
          primaryColor.withValues(alpha: 0.03),
          primaryColor.withValues(alpha: 0.03),
        ],
        stops: [
          0.0,
          activeStop,
          activeStop,
          1.0,
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final closedPath = Path();
    closedPath.moveTo(0, midY - waveHeights[0] / 2);
    for (int i = 0; i < waveHeights.length - 1; i++) {
      final x1 = i * widthBetweenPoints;
      final y1 = midY - waveHeights[i] / 2;
      final x2 = (i + 1) * widthBetweenPoints;
      final y2 = midY - waveHeights[i + 1] / 2;
      final cx = (x1 + x2) / 2;
      closedPath.cubicTo(cx, y1, cx, y2, x2, y2);
    }
    closedPath.lineTo(size.width, midY + waveHeights.last / 2);
    for (int i = waveHeights.length - 1; i > 0; i--) {
      final x1 = i * widthBetweenPoints;
      final y1 = midY + waveHeights[i] / 2;
      final x2 = (i - 1) * widthBetweenPoints;
      final y2 = midY + waveHeights[i - 1] / 2;
      final cx = (x1 + x2) / 2;
      closedPath.cubicTo(cx, y1, cx, y2, x2, y2);
    }
    closedPath.close();
    canvas.drawPath(closedPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant BezierWaveformPainter oldDelegate) {
    return oldDelegate.waveHeights != waveHeights ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.playbackProgress != playbackProgress;
  }
}
