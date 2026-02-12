import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapMarkerHelper {
  static BitmapDescriptor? _cachedBusMarker;

  static Future<BitmapDescriptor> createBusMarker({
    Color color = const Color(0xFFFFC107),
  }) async {
    if (_cachedBusMarker != null) {
      return _cachedBusMarker!;
    }

    _cachedBusMarker = await BitmapDescriptor.asset(
      const ImageConfiguration(devicePixelRatio: 2.5),
      'assets/images/bus_icon.png',
      width: 40, // Correct size for the map
    );

    return _cachedBusMarker!;
  }
}
