import 'package:flutter/services.dart' show rootBundle;

class MapStyleHelper {
  static String? _darkMapStyle;

  /// Loads the dark map style from assets if not already loaded.
  static Future<void> loadStyles() async {
    if (_darkMapStyle == null) {
      try {
        _darkMapStyle = await rootBundle.loadString(
          'assets/map_styles/dark_map_style.json',
        );
      } catch (e) {
        // Fallback or silent error if asset is missing
        print('Error loading map style: $e');
      }
    }
  }

  /// Returns the appropriate map style based on [isDarkMode].
  static Future<String?> getStyle(bool isDarkMode) async {
    if (isDarkMode) {
      if (_darkMapStyle == null) {
        await loadStyles();
      }
      return _darkMapStyle;
    }
    return null;
  }
}
