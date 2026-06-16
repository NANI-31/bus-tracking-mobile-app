import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapMarkerHelper {
  static BitmapDescriptor? _cachedBusMarker;
  static final Map<Color, BitmapDescriptor> _startMarkers = {};
  static final Map<Color, BitmapDescriptor> _stopMarkers = {};
  static final Map<Color, BitmapDescriptor> _endMarkers = {};

  /// Creates a small bus marker icon by resizing the asset image.
  /// [targetWidth] controls the physical pixel width of the marker on screen.
  static Future<BitmapDescriptor> createBusMarker({
    int targetWidth = 70,
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

  /// Draws a modern, clean circular stop marker.
  static Future<BitmapDescriptor> createStopMarker({
    required Color color,
    required int size,
  }) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final double s = size.toDouble();
    final double center = s / 2;

    // 1. Shadow Paint
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = MaskFilter.blur(ui.BlurStyle.normal, s * 0.08);
    canvas.drawCircle(Offset(center, center + s * 0.04), s * 0.38, shadowPaint);

    // 2. White Border Paint
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = ui.PaintingStyle.fill;
    canvas.drawCircle(Offset(center, center), s * 0.38, borderPaint);

    // 3. Colored Core Paint
    final Paint corePaint = Paint()
      ..color = color
      ..style = ui.PaintingStyle.fill;
    canvas.drawCircle(Offset(center, center), s * 0.28, corePaint);

    // 4. White Center Dot Paint
    final Paint dotPaint = Paint()
      ..color = Colors.white
      ..style = ui.PaintingStyle.fill;
    canvas.drawCircle(Offset(center, center), s * 0.09, dotPaint);

    final ui.Image image = await recorder.endRecording().toImage(size, size);
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (byteData == null) {
      throw Exception(
        '[MapMarkerHelper] Failed to encode custom stop marker to PNG',
      );
    }
    return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
  }

  static Future<BitmapDescriptor> getStartMarker({
    required Color color,
    int size = 42,
  }) async {
    if (_startMarkers.containsKey(color)) {
      return _startMarkers[color]!;
    }
    final marker = await createStopMarker(color: color, size: size);
    _startMarkers[color] = marker;
    return marker;
  }

  static Future<BitmapDescriptor> getStopMarker({
    required Color color,
    int size = 32,
  }) async {
    if (_stopMarkers.containsKey(color)) {
      return _stopMarkers[color]!;
    }
    final marker = await createStopMarker(color: color, size: size);
    _stopMarkers[color] = marker;
    return marker;
  }

  static Future<BitmapDescriptor> getEndMarker({
    required Color color,
    int size = 42,
  }) async {
    if (_endMarkers.containsKey(color)) {
      return _endMarkers[color]!;
    }
    final marker = await createStopMarker(color: color, size: size);
    _endMarkers[color] = marker;
    return marker;
  }

  /// Clear the cache to force re-creation (e.g. after theme change).
  static void clearCache() {
    _cachedBusMarker = null;
    _startMarkers.clear();
    _stopMarkers.clear();
    _endMarkers.clear();
  }
}
