import 'package:flutter/services.dart' show rootBundle;
import 'package:collegebus/core/utils/app_logger.dart';

class MapStyleHelper {
  static String? _darkMapStyle;
  static String? _retroMapStyle;
  static String? _aubergineMapStyle;
  static String? _uberMapStyle;
  static String? _olaMapStyle;

  /// Returns the appropriate map style based on the selected theme and system dark mode.
  static Future<String?> getStyleForTheme(String? mapTheme, bool isDarkMode) async {
    switch (mapTheme) {
      case 'standard':
        return null;
      case 'dark':
        if (_darkMapStyle == null) {
          try {
            _darkMapStyle = await rootBundle.loadString(
              'assets/map_styles/dark_map_style.json',
            );
          } catch (e) {
            AppLogger.e('Error loading dark map style: $e');
          }
        }
        return _darkMapStyle;
      case 'retro':
        if (_retroMapStyle == null) {
          try {
            _retroMapStyle = await rootBundle.loadString(
              'assets/map_styles/retro_map_style.json',
            );
          } catch (e) {
            AppLogger.e('Error loading retro map style: $e');
          }
        }
        return _retroMapStyle;
      case 'aubergine':
        if (_aubergineMapStyle == null) {
          try {
            _aubergineMapStyle = await rootBundle.loadString(
              'assets/map_styles/aubergine_map_style.json',
            );
          } catch (e) {
            AppLogger.e('Error loading aubergine map style: $e');
          }
        }
        return _aubergineMapStyle;
      case 'uber':
        if (_uberMapStyle == null) {
          try {
            _uberMapStyle = await rootBundle.loadString(
              'assets/map_styles/uber_map_style.json',
            );
          } catch (e) {
            AppLogger.e('Error loading uber map style: $e');
          }
        }
        return _uberMapStyle;
      case 'ola':
        if (_olaMapStyle == null) {
          try {
            _olaMapStyle = await rootBundle.loadString(
              'assets/map_styles/ola_map_style.json',
            );
          } catch (e) {
            AppLogger.e('Error loading ola map style: $e');
          }
        }
        return _olaMapStyle;
      case 'auto':
      default:
        if (isDarkMode) {
          if (_darkMapStyle == null) {
            try {
              _darkMapStyle = await rootBundle.loadString(
                'assets/map_styles/dark_map_style.json',
              );
            } catch (e) {
              AppLogger.e('Error loading dark map style: $e');
            }
          }
          return _darkMapStyle;
        }
        return null;
    }
  }

  /// Returns the appropriate map style based on [isDarkMode].
  static Future<String?> getStyle(bool isDarkMode) async {
    return getStyleForTheme('auto', isDarkMode);
  }
}





