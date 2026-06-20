import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';

class VectorEmptyState extends StatefulWidget {
  final String title;
  final String description;

  const VectorEmptyState({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  State<VectorEmptyState> createState() => _VectorEmptyStateState();
}

class _VectorEmptyStateState extends State<VectorEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _hoverAnimation = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bobbing custom painter container
          AnimatedBuilder(
            animation: _hoverAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _hoverAnimation.value),
                child: child,
              );
            },
            child: CustomPaint(
              size: const Size(200, 160),
              painter: _EmptyStateVectorPainter(
                primaryColor: primaryColor,
                onSurface: onSurface,
                isDark: isDark,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: onSurface.withValues(alpha: 0.85),
            ),
            textAlign: TextAlign.center,
          ).pSymmetric(h: 24),
          const SizedBox(height: 8),
          Text(
            widget.description,
            style: TextStyle(
              fontSize: 14,
              color: onSurface.withValues(alpha: 0.5),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ).pSymmetric(h: 32),
        ],
      ),
    );
  }
}

class _EmptyStateVectorPainter extends CustomPainter {
  final Color primaryColor;
  final Color onSurface;
  final bool isDark;

  _EmptyStateVectorPainter({
    required this.primaryColor,
    required this.onSurface,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 1. Draw Dotted Background Grid
    final dotPaint = Paint()
      ..color = onSurface.withValues(alpha: isDark ? 0.08 : 0.05)
      ..style = PaintingStyle.fill;

    const int cols = 7;
    const int rows = 5;
    final double spacingX = size.width / (cols - 1);
    final double spacingY = size.height / (rows - 1);
    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        final double x = i * spacingX;
        final double y = j * spacingY;
        canvas.drawCircle(Offset(x, y), 2.0, dotPaint);
      }
    }

    // 2. Draw modern floating background glow circle
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withValues(alpha: isDark ? 0.15 : 0.1),
          primaryColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 60));
    canvas.drawCircle(center, 60, glowPaint);

    // 3. Draw a modern geometric isometric sheet/card outline
    final cardPath = Path();
    final cardPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = onSurface.withValues(alpha: isDark ? 0.15 : 0.1);

    // Tilt coordinates slightly to give a 3D isometric plane feel
    Offset isoOffset(double x, double y) {
      final rx =
          center.dx + (x - size.width / 2) * 0.9 - (y - size.height / 2) * 0.2;
      final ry =
          center.dy + (x - size.width / 2) * 0.1 + (y - size.height / 2) * 0.8;
      return Offset(rx, ry);
    }

    final p1 = isoOffset(size.width * 0.25, size.height * 0.25);
    final p2 = isoOffset(size.width * 0.75, size.height * 0.25);
    final p3 = isoOffset(size.width * 0.75, size.height * 0.75);
    final p4 = isoOffset(size.width * 0.25, size.height * 0.75);

    cardPath.moveTo(p1.dx, p1.dy);
    cardPath.lineTo(p2.dx, p2.dy);
    cardPath.lineTo(p3.dx, p3.dy);
    cardPath.lineTo(p4.dx, p4.dy);
    cardPath.close();
    canvas.drawPath(cardPath, cardPaint);

    // Draw dashed pattern lines inside the card to look like documents/routes
    final dashPaint = Paint()
      ..color = onSurface.withValues(alpha: isDark ? 0.1 : 0.06)
      ..strokeWidth = 2.0;

    // Draw horizontal text/lines inside
    for (double i = 0.35; i <= 0.65; i += 0.12) {
      final start = isoOffset(size.width * 0.35, size.height * i);
      final end = isoOffset(
        size.width * (i > 0.6 ? 0.55 : 0.65),
        size.height * i,
      );
      canvas.drawLine(start, end, dashPaint);
    }

    // 4. Draw modern looking floating magnifying glass offset from the card
    final lensCenter = isoOffset(size.width * 0.65, size.height * 0.65);
    final lensPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = primaryColor;

    // Draw lens circle
    canvas.drawCircle(lensCenter, 18, lensPaint);

    // Draw lens reflection highlight arc
    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.white.withValues(alpha: 0.6);
    canvas.drawArc(
      Rect.fromCircle(center: lensCenter, radius: 14),
      -math.pi / 4,
      math.pi / 2,
      false,
      highlightPaint,
    );

    // Draw handle with a modern accent
    final handleStart = Offset(
      lensCenter.dx + 18 * math.cos(math.pi / 4),
      lensCenter.dy + 18 * math.sin(math.pi / 4),
    );
    final handleEnd = Offset(
      lensCenter.dx + 34 * math.cos(math.pi / 4),
      lensCenter.dy + 34 * math.sin(math.pi / 4),
    );
    final handlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..color = primaryColor;
    canvas.drawLine(handleStart, handleEnd, handlePaint);

    // 5. Draw a soft cross / visual cancellation sign inside the lens
    final xPaint = Paint()
      ..color = isDark
          ? Colors.orangeAccent.withValues(alpha: 0.8)
          : Colors.deepOrange.withValues(alpha: 0.8)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    const double xSize = 4.0;
    canvas.drawLine(
      Offset(lensCenter.dx - xSize, lensCenter.dy - xSize),
      Offset(lensCenter.dx + xSize, lensCenter.dy + xSize),
      xPaint,
    );
    canvas.drawLine(
      Offset(lensCenter.dx + xSize, lensCenter.dy - xSize),
      Offset(lensCenter.dx - xSize, lensCenter.dy + xSize),
      xPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
