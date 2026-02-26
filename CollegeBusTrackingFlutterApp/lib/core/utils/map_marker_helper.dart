import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapMarkerHelper {
  static BitmapDescriptor? _cachedBusMarker;

  static Future<BitmapDescriptor> createBusMarker({
    Color color = const Color(0xFFFFC107),
  }) async {
    if (_cachedBusMarker != null) {
      return _cachedBusMarker!;
    }

    // Target a physical width of 45 pixels, which is ~15 logical pixels on a 3x density device.
    // This matches the visual scale of a standard location dot/icon.
    final Uint8List markerIcon = await _getBytesFromAsset('assets/bus_icon.png', 45);
    _cachedBusMarker = BitmapDescriptor.fromBytes(markerIcon);

    return _cachedBusMarker!;
  }

  static Future<Uint8List> _getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }
}
