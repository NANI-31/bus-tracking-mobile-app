import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/core/services/sos_sound_service.dart';

final sosSoundPlayerProvider = Provider<SosSoundService>((ref) {
  final service = SosSoundService();
  ref.onDispose(() => service.dispose());
  return service;
});

final sosPlayerStateProvider = StreamProvider<dynamic>((ref) {
  final player = ref.watch(sosSoundPlayerProvider);
  return player.onPlayerStateChanged;
});
