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

    _cachedBusMarker = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(24, 24), devicePixelRatio: 2.5),
      'assets/bus_icon.png',
    );

    return _cachedBusMarker!;
  }
}
