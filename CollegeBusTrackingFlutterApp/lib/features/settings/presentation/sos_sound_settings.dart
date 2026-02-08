import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:collegebus/core/utils/app_logger.dart';

class SosSettingsService {
  static const String keySoundEnabled = 'sos_sound_enabled';
  static const String keySoundFile = 'sos_sound_file';

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
}

class SosSoundSettings extends StatefulWidget {
  const SosSoundSettings({super.key});

  @override
  State<SosSoundSettings> createState() => _SosSoundSettingsState();
}

class _SosSoundSettingsState extends State<SosSoundSettings> {
  bool _soundEnabled = true;
  String _selectedSound = 'sos_alarm_1.mp3';
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await SosSettingsService.isSoundEnabled();
    final sound = await SosSettingsService.getSoundFile();
    if (mounted) {
      setState(() {
        _soundEnabled = enabled;
        _selectedSound = sound;
      });
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
    _previewSound(filename);
  }

  Future<void> _previewSound(String filename) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/$filename'));
    } catch (e) {
      AppLogger.e('Error previewing sound: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SOS Alert Settings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
        ],
      ],
    );
  }
}
