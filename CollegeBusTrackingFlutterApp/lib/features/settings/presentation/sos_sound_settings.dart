import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:collegebus/features/sos/application/sos_sound_provider.dart';

class SosSettingsService {
  static const String keySoundEnabled = 'sos_sound_enabled';
  static const String keySoundFile = 'sos_sound_file';
  static const String keyVolume = 'sos_sound_volume';

  static Future<bool> isSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keySoundEnabled) ?? true;
  }

  static Future<void> setSoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keySoundEnabled, enabled);
  }

  static Future<String> getSoundFile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keySoundFile) ?? 'sos_alarm_1.mp3';
  }

  static Future<void> setSoundFile(String filename) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keySoundFile, filename);
  }

  static Future<double> getVolume() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(keyVolume) ?? 1.0;
  }

  static Future<void> setVolume(double volume) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(keyVolume, volume);
  }
}

class SosSoundSettings extends ConsumerStatefulWidget {
  const SosSoundSettings({super.key});

  @override
  ConsumerState<SosSoundSettings> createState() => _SosSoundSettingsState();
}

class _SosSoundSettingsState extends ConsumerState<SosSoundSettings> {
  bool _soundEnabled = true;
  String _selectedSound = 'sos_alarm_1.mp3';
  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await SosSettingsService.isSoundEnabled();
    final sound = await SosSettingsService.getSoundFile();
    final volume = await SosSettingsService.getVolume();
    if (mounted) {
      setState(() {
        _soundEnabled = enabled;
        _selectedSound = sound;
        _volume = volume;
      });
      // Sync initial volume to service
      ref.read(sosSoundPlayerProvider).setVolume(volume);
    }
  }

  Future<void> _toggleSound(bool value) async {
    await SosSettingsService.setSoundEnabled(value);
    setState(() => _soundEnabled = value);
  }

  Future<void> _selectSound(String? filename) async {
    if (filename == null) return;
    await SosSettingsService.setSoundFile(filename);
    setState(() => _selectedSound = filename);
    // Stop any current playback when switching sounds
    await ref.read(sosSoundPlayerProvider).stop();
  }

  Future<void> _togglePlayback() async {
    final player = ref.read(sosSoundPlayerProvider);
    if (player.state == PlayerState.playing) {
      await player.stop();
    } else {
      await player.play('sounds/$_selectedSound');
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerState =
        ref.watch(sosPlayerStateProvider).value ?? PlayerState.stopped;
    final isPlaying = playerState == PlayerState.playing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'SOS Alert Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (_soundEnabled)
              IconButton.filledTonal(
                onPressed: _togglePlayback,
                iconSize: 32,
                icon: Icon(
                  isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  color: isPlaying ? Colors.red : Colors.green,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Enable SOS Sound'),
          subtitle: const Text('Play a loud alarm when an SOS is triggered'),
          value: _soundEnabled,
          onChanged: _toggleSound,
        ),
        if (_soundEnabled) ...[
          const Divider(),
          ListTile(
            title: const Text('Alert Sound'),
            subtitle: Text(
              _selectedSound == 'sos_alarm_1.mp3'
                  ? 'Classic Alarm'
                  : 'Siren Alert',
            ),
            trailing: DropdownButton<String>(
              value: _selectedSound,
              onChanged: _selectSound,
              items: const [
                DropdownMenuItem(
                  value: 'sos_alarm_1.mp3',
                  child: Text('Classic Alarm'),
                ),
                DropdownMenuItem(
                  value: 'sos_alarm_2.mp3',
                  child: Text('Siren Alert'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.volume_down, size: 20),
                Expanded(
                  child: Slider(
                    value: _volume,
                    onChanged: (val) {
                      setState(() => _volume = val);
                      ref.read(sosSoundPlayerProvider).setVolume(val);
                    },
                    onChangeEnd: (val) {
                      SosSettingsService.setVolume(val);
                    },
                  ),
                ),
                const Icon(Icons.volume_up, size: 20),
              ],
            ),
          ),
          if (isPlaying)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Alarm Playing...',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
