import 'package:flutter/material.dart';

class MapSkeletonLoader extends StatefulWidget {
  final double bottomPadding;
  const MapSkeletonLoader({super.key, this.bottomPadding = 0.0});

  @override
  State<MapSkeletonLoader> createState() => _MapSkeletonLoaderState();
}

class _MapSkeletonLoaderState extends State<MapSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Smooth modern slate/grey base colors
    final baseColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final highlightColor = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
    final roadColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            // 1. Map Canvas Background (base gray)
            Container(
              color: baseColor,
            ),

            // 2. Faux modern grid/road lines to mimic a real map
            CustomPaint(
              size: Size.infinite,
              painter: _MapRoadsPainter(
                roadColor: roadColor.withValues(alpha: 0.4),
                slidePercent: _controller.value,
              ),
            ),

            // 3. Floating top card bar (mimics route info card)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: _buildShimmerContainer(
                width: double.infinity,
                height: 72,
                borderRadius: 16,
                baseColor: baseColor,
                highlightColor: highlightColor,
              ),
            ),

            // 4. Floating Action Buttons (mimics GPS recenter & SOS)
            Positioned(
              bottom: 240 + widget.bottomPadding,
              right: 16,
              child: Column(
                children: [
                  _buildShimmerContainer(
                    width: 48,
                    height: 48,
                    borderRadius: 24,
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                  ),
                  const SizedBox(height: 12),
                  _buildShimmerContainer(
                    width: 48,
                    height: 48,
                    borderRadius: 24,
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                  ),
                ],
              ),
            ),

            // 5. Bottom Sheet Card (mimics selected bus/ETA info)
            Positioned(
              bottom: widget.bottomPadding,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[700] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Row with circular bus avatar skeleton and text details
                      Row(
                        children: [
                          _buildShimmerContainer(
                            width: 60,
                            height: 60,
                            borderRadius: 30,
                            baseColor: baseColor,
                            highlightColor: highlightColor,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildShimmerContainer(
                                  width: 140,
                                  height: 20,
                                  borderRadius: 6,
                                  baseColor: baseColor,
                                  highlightColor: highlightColor,
                                ),
                                const SizedBox(height: 10),
                                _buildShimmerContainer(
                                  width: 200,
                                  height: 14,
                                  borderRadius: 4,
                                  baseColor: baseColor,
                                  highlightColor: highlightColor,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      // Route path line timeline skeleton
                      Row(
                        children: [
                          _buildShimmerContainer(
                            width: 24,
                            height: 24,
                            borderRadius: 12,
                            baseColor: baseColor,
                            highlightColor: highlightColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildShimmerContainer(
                              width: double.infinity,
                              height: 6,
                              borderRadius: 3,
                              baseColor: baseColor,
                              highlightColor: highlightColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildShimmerContainer(
                            width: 24,
                            height: 24,
                            borderRadius: 12,
                            baseColor: baseColor,
                            highlightColor: highlightColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Details row skeleton
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildShimmerContainer(
                            width: 90,
                            height: 16,
                            borderRadius: 4,
                            baseColor: baseColor,
                            highlightColor: highlightColor,
                          ),
                          _buildShimmerContainer(
                            width: 70,
                            height: 16,
                            borderRadius: 4,
                            baseColor: baseColor,
                            highlightColor: highlightColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShimmerContainer({
    required double width,
    required double height,
    required double borderRadius,
    required Color baseColor,
    required Color highlightColor,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseColor,
            highlightColor,
            baseColor,
          ],
          stops: const [
            0.1,
            0.5,
            0.9,
          ],
          transform: _SlidingGradientTransform(slidePercent: _controller.value),
        ),
      ),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent - 0.5) * 2, 0.0, 0.0);
  }
}

class _MapRoadsPainter extends CustomPainter {
  final Color roadColor;
  final double slidePercent;
  _MapRoadsPainter({required this.roadColor, required this.slidePercent});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = roadColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final dashPaint = Paint()
      ..color = roadColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    // Road 1 (Primary highway)
    final path1 = Path()
      ..moveTo(0, size.height * 0.3)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.25, size.width * 0.6, size.height * 0.5)
      ..lineTo(size.width, size.height * 0.65);
    canvas.drawPath(path1, paint);

    // Road 2 (Diagonal highway)
    final path2 = Path()
      ..moveTo(size.width * 0.2, 0)
      ..lineTo(size.width * 0.8, size.height);
    canvas.drawPath(path2, paint);

    // Minor roads
    canvas.drawLine(Offset(0, size.height * 0.6), Offset(size.width, size.height * 0.45), dashPaint);
    canvas.drawLine(Offset(size.width * 0.1, size.height * 0.8), Offset(size.width * 0.9, size.height * 0.1), dashPaint);
  }

  @override
  bool shouldRepaint(covariant _MapRoadsPainter oldDelegate) {
    return oldDelegate.roadColor != roadColor || oldDelegate.slidePercent != slidePercent;
  }
}
