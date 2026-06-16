import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:collegebus/features/notification/data/notification_repository.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service to handle voice recording and uploading
class VoiceRecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  final NotificationRepository _notificationRepo;

  VoiceRecordingService(this._notificationRepo);

  bool _isRecording = false;
  String? _recordingPath;

  bool get isRecording => _isRecording;

  /// Start recording
  Future<void> startRecording({
    bool noiseSuppress = true,
    bool echoCancel = true,
    bool autoGain = true,
  }) async {
    try {
      // Check permissions
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw Exception('Microphone permission not granted');
      }

      final directory = await getTemporaryDirectory();
      _recordingPath = p.join(
        directory.path,
        'voice_${DateTime.now().millisecondsSinceEpoch}.mp3',
      );

      final config = RecordConfig(
        noiseSuppress: noiseSuppress,
        echoCancel: echoCancel,
        autoGain: autoGain,
      );

      await _recorder.start(config, path: _recordingPath!);
      _isRecording = true;
      debugPrint(
        '[VoiceRecordingService] Recording started at: $_recordingPath',
      );
    } catch (e) {
      debugPrint('[VoiceRecordingService] Error starting recording: $e');
      rethrow;
    }
  }

  /// Stop recording and return file path
  Future<String?> stopRecording() async {
    try {
      final path = await _recorder.stop();
      _isRecording = false;
      return path;
    } catch (e) {
      debugPrint('[VoiceRecordingService] Error stopping recording: $e');
      return null;
    }
  }

  /// Send the recorded voice message
  Future<Map<String, dynamic>> sendVoiceMessage({
    required String receiverId,
    required String filePath,
    String? message,
  }) async {
    try {
      return await _notificationRepo.sendVoiceNotification(
        receiverId: receiverId,
        filePath: filePath,
        message: message,
      );
    } catch (e) {
      debugPrint('[VoiceRecordingService] Error sending voice message: $e');
      rethrow;
    } finally {
      // Clean up local file after upload attempt
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  /// Get current recording decibel amplitude
  Future<Amplitude> getAmplitude() => _recorder.getAmplitude();

  void dispose() {
    _recorder.dispose();
  }
}
