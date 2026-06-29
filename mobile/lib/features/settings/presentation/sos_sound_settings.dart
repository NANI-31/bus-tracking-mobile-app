import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:collegebus/features/sos/application/sos_sound_provider.dart';
import 'package:collegebus/core/providers/service_providers.dart';

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

class _SosSoundSettingsState extends ConsumerState<SosSoundSettings>
    with TickerProviderStateMixin {
  bool _soundEnabled = true;
  String _selectedSound = 'sos_alarm_1.mp3';
  double _volume = 1.0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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
      ref.read(sosSoundPlayerProvider).setVolume(volume);
    }
  }

  Future<void> _toggleSound(bool value) async {
    await SosSettingsService.setSoundEnabled(value);
    setState(() => _soundEnabled = value);
  }

  Future<void> _selectSound(String filename) async {
    await SosSettingsService.setSoundFile(filename);
    setState(() => _selectedSound = filename);
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
    final themeService = ref.watch(themeServiceProvider);
    final isDark = themeService.isDarkMode;

    final playerState =
        ref.watch(sosPlayerStateProvider).value ?? PlayerState.stopped;
    final isPlaying = playerState == PlayerState.playing;

    if (isPlaying) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Custom Styled Switch Tile
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _soundEnabled
                      ? Colors.redAccent.withValues(alpha: isDark ? 0.15 : 0.08)
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.03)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _soundEnabled
                      ? Icons.emergency_rounded
                      : Icons.notifications_off_rounded,
                  color: _soundEnabled
                      ? Colors.redAccent
                      : (isDark ? Colors.white38 : Colors.black38),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enable SOS Sound Alert',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Play a loud alarm sound during emergencies',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _soundEnabled,
                activeThumbColor: Colors.redAccent,
                onChanged: _toggleSound,
              ),
            ],
          ),
        ),

        if (_soundEnabled) ...[
          const SizedBox(height: 16),
          Text(
            'ALERT SOUND TYPE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          const SizedBox(height: 10),

          // Horizontal Selector Cards
          Row(
            children: [
              Expanded(
                child: _SoundOptionCard(
                  title: 'Classic Alarm',
                  subtitle: 'Classic ringing alert',
                  icon: Icons.notifications_active_rounded,
                  isSelected: _selectedSound == 'sos_alarm_1.mp3',
                  onTap: () => _selectSound('sos_alarm_1.mp3'),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SoundOptionCard(
                  title: 'Siren Alert',
                  subtitle: 'Continuous vehicle horn',
                  icon: Icons.campaign_rounded,
                  isSelected: _selectedSound == 'sos_alarm_2.mp3',
                  onTap: () => _selectSound('sos_alarm_2.mp3'),
                  isDark: isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Text(
            'ALERT VOLUME',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          const SizedBox(height: 8),

          // Volume Slider with Custom Theme
          Row(
            children: [
              Icon(
                Icons.volume_down_rounded,
                color: isDark ? Colors.white38 : Colors.black38,
                size: 20,
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.redAccent,
                    inactiveTrackColor: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                    trackHeight: 4.5,
                    thumbColor: Colors.redAccent,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8.0,
                    ),
                    overlayColor: Colors.redAccent.withValues(alpha: 0.12),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 18.0,
                    ),
                  ),
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
              ),
              Icon(
                Icons.volume_up_rounded,
                color: isDark ? Colors.white38 : Colors.black38,
                size: 20,
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Custom Preview / Play Panel (Glassmorphic look)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.02)
                  : Colors.black.withValues(alpha: 0.015),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.04),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isPlaying)
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.redAccent.withValues(alpha: 0.15),
                          ),
                        ),
                      ),
                    GestureDetector(
                      onTap: _togglePlayback,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isPlaying
                              ? Colors.redAccent
                              : Colors.redAccent.withValues(alpha: 0.12),
                        ),
                        child: Icon(
                          isPlaying
                              ? Icons.stop_rounded
                              : Icons.play_arrow_rounded,
                          color: isPlaying ? Colors.white : Colors.redAccent,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPlaying
                            ? 'Alarm Preview Active'
                            : 'Preview Sound Settings',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isPlaying
                              ? Colors.redAccent
                              : (isDark ? Colors.white : Colors.black),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isPlaying
                            ? 'Tap stop to stop playback'
                            : 'Test the selected sound and volume',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SoundOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _SoundOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? Colors.redAccent.withValues(alpha: 0.08)
                    : Colors.red.withValues(alpha: 0.04))
              : (isDark
                    ? Colors.white.withValues(alpha: 0.02)
                    : Colors.black.withValues(alpha: 0.01)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.redAccent.withValues(alpha: 0.4)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05)),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.redAccent.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 26,
              color: isSelected
                  ? Colors.redAccent
                  : (isDark ? Colors.white60 : Colors.black45),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 12,
                color: isSelected
                    ? Colors.redAccent
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.8)
                          : Colors.black.withValues(alpha: 0.8)),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
