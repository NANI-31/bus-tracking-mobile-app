import 'package:flutter/material.dart';

class CurvedBottomNavIcon {
  final IconData icon;
  final String label;

  CurvedBottomNavIcon({required this.icon, required this.label});
}

class CurvedBottomNavBar extends StatefulWidget {
  final List<CurvedBottomNavIcon> items;
  final int currentIndex;
  final Function(int) onTap;
  final Color backgroundColor;
  final Color activeColor;
  final Color inactiveColor;

  const CurvedBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.backgroundColor = Colors.white,
    this.activeColor = const Color(
      0xFF00C6E6,
    ), // Updated to match primary color
    this.inactiveColor = const Color(
      0xFFBFC0D1,
    ), // Updated to match secondary color
  });

  @override
  State<CurvedBottomNavBar> createState() => _CurvedBottomNavBarState();
}

class _CurvedBottomNavBarState extends State<CurvedBottomNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation =
        Tween<double>(
          begin: widget.currentIndex.toDouble(),
          end: widget.currentIndex.toDouble(),
        ).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOutExpo),
        );
  }

  @override
  void didUpdateWidget(CurvedBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _animation =
          Tween<double>(
            begin: oldWidget.currentIndex.toDouble(),
            end: widget.currentIndex.toDouble(),
          ).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeInOutExpo),
          );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double itemWidth = width / widget.items.length;

    return Container(
      height: 90, // Sufficient height for the curve and labels
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Animated Background with Curve
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                size: Size(width, 90),
                painter: _BottomBarPainter(
                  index: _animation.value,
                  count: widget.items.length,
                  color: widget.backgroundColor,
                ),
              );
            },
          ),

          // Floating Circle Highlight
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final double centerX =
                  (itemWidth * _animation.value) + (itemWidth / 2);
              return Positioned(
                left: centerX - 30, // 30 is half of circle width
                top: -5, // Lift above the bar
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: widget.activeColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.activeColor.withValues(alpha: 0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Icons and Labels
          Row(
            children: widget.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final bool isSelected = widget.currentIndex == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () => widget.onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 5), // Adjust for floating circle
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: isSelected ? 1 : 0),
                        duration: const Duration(milliseconds: 300),
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, -10 * value),
                            child: Icon(
                              item.icon,
                              color: isSelected
                                  ? Colors.white
                                  : widget.inactiveColor,
                              size: 28,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: isSelected
                              ? widget.activeColor
                              : widget.inactiveColor,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _BottomBarPainter extends CustomPainter {
  final double index;
  final int count;
  final Color color;

  _BottomBarPainter({
    required this.index,
    required this.count,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw shadow manually for better control
    final Path shadowPath = _getPath(size);
    canvas.drawShadow(shadowPath, Colors.black, 10.0, true);

    canvas.drawPath(_getPath(size), paint);
  }

  Path _getPath(Size size) {
    final double itemWidth = size.width / count;
    final double curveCenter = (itemWidth * index) + (itemWidth / 2);
    final double curveWidth = 80; // Re-tuned width for smoothness
    final double curveHeight = 25;

    final Path path = Path();
    path.moveTo(0, 0);

    // Initial segment with corner rounding for the bar itself
    path.lineTo(curveCenter - curveWidth, 0);

    // Smooth Bezier Curve (S-shaped blend)
    path.cubicTo(
      curveCenter - curveWidth / 2,
      0,
      curveCenter - curveWidth / 2,
      -curveHeight,
      curveCenter,
      -curveHeight,
    );
    path.cubicTo(
      curveCenter + curveWidth / 2,
      -curveHeight,
      curveCenter + curveWidth / 2,
      0,
      curveCenter + curveWidth,
      0,
    );

    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldRepaint(covariant _BottomBarPainter oldDelegate) {
    return oldDelegate.index != index;
  }
}
