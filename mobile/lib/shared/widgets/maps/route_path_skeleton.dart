import 'package:flutter/material.dart';
import 'package:collegebus/shared/widgets/shimmer_loading.dart';

class RoutePathSkeleton extends StatefulWidget {
  final double height;
  final double width;

  const RoutePathSkeleton({
    super.key,
    this.height = 200,
    this.width = double.infinity,
  });

  @override
  State<RoutePathSkeleton> createState() => _RoutePathSkeletonState();
}

class _RoutePathSkeletonState extends State<RoutePathSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final roadColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1);

    return Shimmer(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: widget.width,
          height: widget.height,
          color: baseColor,
          child: Stack(
            children: [
              // Shimmer sliding gradient transform listener
              Positioned.fill(
                child: Builder(
                  builder: (context) {
                    final shimmer = Shimmer.of(context);
                    return AnimatedBuilder(
                      animation: Listenable.merge([
                        shimmer?.shiftAnimation,
                        _progressController,
                      ].whereType<Listenable>().toList()),
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _RoutePathPainter(
                            roadColor: roadColor.withValues(alpha: 0.5),
                            routeProgress: _progressController.value,
                            shimmerPercent: shimmer?.value ?? 0.0,
                            isDark: isDark,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              // Floating badge saying "Fetching coordinates..."
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Fetching route coordinates...',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutePathPainter extends CustomPainter {
  final Color roadColor;
  final double routeProgress;
  final double shimmerPercent;
  final bool isDark;

  _RoutePathPainter({
    required this.roadColor,
    required this.routeProgress,
    required this.shimmerPercent,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw grid / minor road lines
    final roadPaint = Paint()
      ..color = roadColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    // Grid road 1
    canvas.drawLine(
      Offset(0, size.height * 0.4),
      Offset(size.width, size.height * 0.5),
      roadPaint,
    );
    // Grid road 2
    canvas.drawLine(
      Offset(size.width * 0.3, 0),
      Offset(size.width * 0.45, size.height),
      roadPaint,
    );
    // Grid road 3 (diagonal minor road)
    canvas.drawLine(
      Offset(0, size.height * 0.8),
      Offset(size.width, size.height * 0.25),
      roadPaint..strokeWidth = 2.0,
    );

    // 2. Draw active route polyline path
    final routePath = Path()
      ..moveTo(size.width * 0.1, size.height * 0.75)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.85,
        size.width * 0.55,
        size.height * 0.15,
        size.width * 0.9,
        size.height * 0.25,
      );

    // Get path metrics to animate drawing along the path
    final pathMetrics = routePath.computeMetrics();
    final routePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    for (final metric in pathMetrics) {
      final totalLength = metric.length;
      final currentLength = totalLength * routeProgress;

      // Base route line (dim color showing route boundary)
      canvas.drawPath(routePath, Paint()
        ..color = (isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round
      );

      // Shimmering route shader path
      final extractPath = metric.extractPath(0, currentLength);
      
      // Dynamic color gradient shifting along the drawn route
      const routeColor1 = Color(0xFF3B82F6); // Blue
      const routeColor2 = Color(0xFF60A5FA); // Light Blue

      routePaint.shader = LinearGradient(
        colors: [
          routeColor1,
          routeColor2,
          routeColor1,
        ],
        stops: const [0.1, 0.5, 0.9],
        transform: _PainterGradientTransform(slidePercent: shimmerPercent),
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(extractPath, routePaint);

      // Draw starting point and destination point indicators
      final startPoint = metric.getTangentForOffset(0)?.position;
      final currentBusPoint = metric.getTangentForOffset(currentLength)?.position;
      final destinationPoint = metric.getTangentForOffset(totalLength)?.position;

      // Start stop dot
      if (startPoint != null) {
        canvas.drawCircle(
          startPoint,
          6.0,
          Paint()..color = const Color(0xFF10B981), // Green
        );
      }

      // End destination dot
      if (destinationPoint != null) {
        canvas.drawCircle(
          destinationPoint,
          6.0,
          Paint()..color = const Color(0xFFEF4444), // Red
        );
      }

      // Live animated bus/tracker dot
      if (currentBusPoint != null) {
        // Draw pulse circle
        final pulsePaint = Paint()
          ..color = const Color(0xFF3B82F6).withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(currentBusPoint, 14.0, pulsePaint);

        // Center dot
        canvas.drawCircle(
          currentBusPoint,
          6.0,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          currentBusPoint,
          4.0,
          Paint()..color = const Color(0xFF3B82F6),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RoutePathPainter oldDelegate) {
    return oldDelegate.roadColor != roadColor ||
        oldDelegate.routeProgress != routeProgress ||
        oldDelegate.shimmerPercent != shimmerPercent ||
        oldDelegate.isDark != isDark;
  }
}

class _PainterGradientTransform extends GradientTransform {
  final double slidePercent;
  const _PainterGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent - 0.5) * 2, 0.0, 0.0);
  }
}
