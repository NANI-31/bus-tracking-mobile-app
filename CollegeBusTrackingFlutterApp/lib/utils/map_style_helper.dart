import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

  /// Applies the appropriate map style based on [isDarkMode].
  static Future<void> applyStyle(
    GoogleMapController? controller,
    bool isDarkMode,
  ) async {
    if (controller == null) return;

    if (isDarkMode) {
      if (_darkMapStyle == null) {
        await loadStyles();
      }
      if (_darkMapStyle != null) {
        await controller.setMapStyle(_darkMapStyle);
      }
    } else {
      await controller.setMapStyle(null);
    }
  }
}
