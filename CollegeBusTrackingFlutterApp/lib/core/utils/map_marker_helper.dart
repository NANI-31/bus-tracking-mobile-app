import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapMarkerHelper {
  static BitmapDescriptor? _cachedBusMarker;

  /// Creates a small bus marker icon by resizing the asset image.
  /// [targetWidth] controls the physical pixel width of the marker on screen.
  static Future<BitmapDescriptor> createBusMarker({
    int targetWidth = 100,
  }) async {
    if (_cachedBusMarker != null) {
      return _cachedBusMarker!;
    }

    try {
      final Uint8List resizedBytes = await _resizeAsset(
        'assets/bus_icon.png',
        targetWidth,
      );
      _cachedBusMarker = BitmapDescriptor.bytes(resizedBytes);
    } catch (e) {
      debugPrint(
        '[MapMarkerHelper] fromBytes failed ($e), trying canvas approach',
      );
      // Fallback: draw a small colored circle as the bus marker
      _cachedBusMarker = await _drawSmallBusMarker(targetWidth);
    }

    return _cachedBusMarker!;
  }

  /// Resizes a PNG asset to [targetWidth] pixels using instantiateImageCodec.
  static Future<Uint8List> _resizeAsset(String path, int width) async {
    final ByteData data = await rootBundle.load(path);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ByteData? byteData = await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (byteData == null) throw Exception('Failed to encode resized image');
    return byteData.buffer.asUint8List();
  }

  /// Fallback: programmatically draw a small bus icon using Canvas.
  static Future<BitmapDescriptor> _drawSmallBusMarker(int size) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final double s = size.toDouble();

    // Draw circle background
    final Paint bgPaint = Paint()..color = const Color(0xFFFFC107);
    canvas.drawCircle(Offset(s / 2, s / 2), s / 2, bgPaint);

    // Draw border
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.08;
    canvas.drawCircle(Offset(s / 2, s / 2), s / 2 - s * 0.04, borderPaint);

    // Draw bus icon text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '🚌',
        style: TextStyle(fontSize: s * 0.45),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((s - textPainter.width) / 2, (s - textPainter.height) / 2),
    );

    final ui.Image image = await recorder.endRecording().toImage(size, size);
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  /// Clear the cache to force re-creation (e.g. after theme change).
  static void clearCache() {
    _cachedBusMarker = null;
  }
}
