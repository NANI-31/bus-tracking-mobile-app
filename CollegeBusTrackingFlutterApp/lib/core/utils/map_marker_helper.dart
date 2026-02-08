import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapMarkerHelper {
  static Future<BitmapDescriptor> createBusMarker() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 120.0; // High res for crispness
    const double width = size * 0.6;
    const double height = size;

    final Paint paint = Paint()
      ..color = const Color(0xFFFFC107); // School Bus Yellow
    final Paint paintBlack = Paint()..color = Colors.black;
    final Paint paintWindow = Paint()
      ..color = const Color(0xFF42A5F5); // Blue/Glass
    final Paint paintLights = Paint()..color = Colors.red;

    // Bus Body (Rounded Rectangle)
    final RRect busBody = RRect.fromRectAndRadius(
      Rect.fromLTWH(size * 0.2, 0, width, height),
      const Radius.circular(8.0),
    );
    canvas.drawRRect(busBody, paint);

    // Windshield (Front) - Top
    canvas.drawRect(
      Rect.fromLTWH(size * 0.25, size * 0.05, width * 0.8, size * 0.15),
      paintWindow,
    );

    // Rear Window - Bottom
    canvas.drawRect(
      Rect.fromLTWH(size * 0.3, size * 0.85, width * 0.6, size * 0.1),
      paintWindow,
    );

    // Roof Hatch / AC (Center)
    canvas.drawCircle(
      Offset(size * 0.5, size * 0.5),
      size * 0.1,
      paintBlack
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Headlights
    canvas.drawCircle(
      Offset(size * 0.25, size * 0.02),
      4,
      paint..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(size * 0.75, size * 0.02),
      4,
      paint..color = Colors.white,
    );

    // Tail lights
    canvas.drawRect(
      Rect.fromLTWH(size * 0.22, size * 0.96, 10, 4),
      paintLights,
    );
    canvas.drawRect(
      Rect.fromLTWH(size * 0.70, size * 0.96, 10, 4),
      paintLights,
    );

    // Convert to Image
    final ui.Image image = await pictureRecorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final ByteData? data = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }
}
