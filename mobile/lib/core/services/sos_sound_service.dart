import 'package:audioplayers/audioplayers.dart';
import 'package:collegebus/core/utils/app_logger.dart';

class SosSoundService {
  final AudioPlayer _player = AudioPlayer();
  double _volume = 1.0;

  SosSoundService() {
    _player.onPlayerStateChanged.listen((state) {
      AppLogger.d('SOS Sound Player State: $state');
    });
  }

  Stream<PlayerState> get onPlayerStateChanged => _player.onPlayerStateChanged;
  PlayerState get state => _player.state;

  Future<void> play(String assetPath, {bool loop = false}) async {
    try {
      if (_player.state == PlayerState.playing) {
        await _player.stop();
      }
      await _player.setReleaseMode(
        loop ? ReleaseMode.loop : ReleaseMode.release,
      );
      await _player.setVolume(_volume);
      await _player.play(AssetSource(assetPath));
    } catch (e) {
      AppLogger.e('Error playing SOS sound: $e');
    }
  }

  Future<void> stop() async {
    try {
      if (_player.state == PlayerState.playing ||
          _player.state == PlayerState.paused) {
        await _player.stop();
      }
    } catch (e) {
      AppLogger.e('Error stopping SOS sound: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    _volume = volume;
    await _player.setVolume(volume);
  }

  double get volume => _volume;

  void dispose() {
    _player.dispose();
  }
}
