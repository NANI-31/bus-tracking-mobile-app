import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class LiquidBackground extends StatefulWidget {
  final Widget child;
  const LiquidBackground({super.key, required this.child});

  @override
  State<LiquidBackground> createState() => _LiquidBackgroundState();
}

class _LiquidBackgroundState extends State<LiquidBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Radial Gradient Blobs Layer
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value * 2 * math.pi;
              return CustomPaint(
                painter: _BlobPainter(t: t),
              );
            },
          ),
        ),

        // 2. Blur overlay
        Positioned.fill(
          child: ClipRect(
            child: BackdropFilter(
              // P2.2 perf fix: sigma:60 was extreme (6x more GPU work than sigma:10).
              // sigma:30 keeps the frosted-glass look while cutting render cost by ~half.
              filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),

        // 3. Child content
        Positioned.fill(child: widget.child),
      ],
    );
  }
}

class _BlobPainter extends CustomPainter {
  final double t;
  _BlobPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    final paint = Paint()..style = PaintingStyle.fill;

    // Blob 1: Deep purple, drifts around top-left
    final blob1Pos = Offset(
      size.width * (0.25 + 0.15 * math.sin(t)),
      size.height * (0.25 + 0.10 * math.cos(t)),
    );
    paint.shader = ui.Gradient.radial(
      blob1Pos,
      size.width * 0.5,
      [
        const Color(0xFF6B35D9),
        const Color(0x006B35D9),
      ],
    );
    canvas.drawCircle(blob1Pos, size.width * 0.5, paint);

    // Blob 2: Electric blue, drifts around top-right
    final blob2Pos = Offset(
      size.width * (0.75 + 0.10 * math.cos(t * 1.2)),
      size.height * (0.35 + 0.15 * math.sin(t * 0.8)),
    );
    paint.shader = ui.Gradient.radial(
      blob2Pos,
      size.width * 0.45,
      [
        const Color(0xFF2D9CDB),
        const Color(0x002D9CDB),
      ],
    );
    canvas.drawCircle(blob2Pos, size.width * 0.45, paint);

    // Blob 3: Rose pink, drifts around bottom-right
    final blob3Pos = Offset(
      size.width * (0.65 + 0.15 * math.sin(t * 0.9)),
      size.height * (0.75 + 0.12 * math.cos(t * 1.1)),
    );
    paint.shader = ui.Gradient.radial(
      blob3Pos,
      size.width * 0.55,
      [
        const Color(0xFFE91E8C),
        const Color(0x00E91E8C),
      ],
    );
    canvas.drawCircle(blob3Pos, size.width * 0.55, paint);

    // Blob 4: Teal, drifts around bottom-left
    final blob4Pos = Offset(
      size.width * (0.30 + 0.12 * math.cos(t * 0.7)),
      size.height * (0.70 + 0.15 * math.sin(t * 1.3)),
    );
    paint.shader = ui.Gradient.radial(
      blob4Pos,
      size.width * 0.4,
      [
        const Color(0xFF00BCD4),
        const Color(0x0000BCD4),
      ],
    );
    canvas.drawCircle(blob4Pos, size.width * 0.4, paint);
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.t != t;
}
