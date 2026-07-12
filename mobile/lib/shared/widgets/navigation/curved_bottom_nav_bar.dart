import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:rive/rive.dart' hide LinearGradient, RadialGradient;
import 'package:flutter/services.dart';
import 'package:collegebus/widgets/liquid_glass/liquid_glass.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────

class CurvedBottomNavItem {
  final IconData icon;
  final String label;
  final int? badgeCount;
  final String? riveAsset;
  final String? artboard;
  final String? stateMachineName;
  final String? inputName;

  const CurvedBottomNavItem({
    required this.icon,
    required this.label,
    this.badgeCount,
    this.riveAsset,
    this.artboard,
    this.stateMachineName,
    this.inputName,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Rive animated icon
// ─────────────────────────────────────────────────────────────────────────────

class RiveNavIcon extends StatefulWidget {
  final CurvedBottomNavItem item;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;

  const RiveNavIcon({
    super.key,
    required this.item,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  State<RiveNavIcon> createState() => _RiveNavIconState();
}

class _RiveNavIconState extends State<RiveNavIcon> {
  StateMachineController? _controller;
  SMIInput<bool>? _activeInput;

  @override
  void didUpdateWidget(RiveNavIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSelected != widget.isSelected) {
      _activeInput?.value = widget.isSelected;
    }
  }

  void _onRiveInit(Artboard artboard) {
    _controller = StateMachineController.fromArtboard(
      artboard,
      widget.item.stateMachineName ?? 'State Machine 1',
    );
    if (_controller != null) {
      artboard.addController(_controller!);
      _activeInput = _controller!.findInput<bool>(
        widget.item.inputName ?? 'active',
      );
      _activeInput?.value = widget.isSelected;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final board =
        widget.item.artboard ??
        (isDark ? '${widget.item.label}_Dark' : widget.item.artboard);

    return SizedBox(
      height: 32,
      width: 32,
      child: widget.item.riveAsset!.startsWith('http')
          ? RiveAnimation.network(
              widget.item.riveAsset!,
              artboard: board,
              fit: BoxFit.contain,
              onInit: _onRiveInit,
            )
          : RiveAnimation.asset(
              widget.item.riveAsset!,
              artboard: board,
              fit: BoxFit.contain,
              onInit: _onRiveInit,
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glass specular highlight painter  (top-edge shimmer + inner vignette)
// ─────────────────────────────────────────────────────────────────────────────

class _GlassSpecularPainter extends CustomPainter {
  final bool isDark;
  final double cornerRadius;
  final double activeX; // centre X of active tab
  final double glowProgress; // 0-1 fade-in of radial glow
  final double tiltX;
  final double tiltY;
  final Color activeColor;

  const _GlassSpecularPainter({
    required this.isDark,
    required this.cornerRadius,
    required this.activeX,
    required this.glowProgress,
    required this.activeColor,
    this.tiltX = 0.0,
    this.tiltY = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(cornerRadius),
    );

    canvas.save();
    canvas.clipRRect(rrect);

    // ── 1. Radial spotlight glow that tracks the active tab ────────────────
    final glowOpacity = isDark ? 0.10 : 0.18;
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          ((activeX + tiltX) / size.width) * 2 - 1, // normalise to -1..+1
          -0.3 + (tiltY / size.height) * 2,
        ),
        radius: 0.7,
        colors: [
          Colors.white.withValues(alpha: glowOpacity * glowProgress),
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRRect(rrect, glowPaint);

    // ── 4. Bottom specular – subtle under-lighting reflection ──────────────
    final bottomGlow = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.0),
              Colors.white.withValues(alpha: isDark ? 0.04 : 0.10),
            ],
          ).createShader(
            Rect.fromLTWH(0, size.height * 0.6, size.width, size.height * 0.4),
          );
    canvas.drawRRect(rrect, bottomGlow);

    // ── 5. Inner-top gradient vignette (depth / thickness) ─────────────────
    final innerVignette = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: isDark ? 0.06 : 0.20),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.4],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.5));
    canvas.drawRRect(rrect, innerVignette);

    canvas.restore();

    // ── 6. Custom Split Border lines (Drawn outside clipping to preserve stroke thickness) ──
    // Path 1 Segment A (Top horizontal line)
    final path1A = Path()
      ..moveTo(size.width * 0.92, 0)
      ..lineTo(cornerRadius, 0);

    // Path 1 Segment B (Top-left curve + Left vertical line)
    final path1B = Path()
      ..moveTo(cornerRadius, 0)
      ..arcToPoint(
        Offset(0, cornerRadius),
        radius: Radius.circular(cornerRadius),
        clockwise: false,
      )
      ..lineTo(0, size.height - cornerRadius);

    // Path 2 Segment A (Bottom horizontal line)
    final path2A = Path()
      ..moveTo(size.width * 0.1, size.height)
      ..lineTo(size.width - cornerRadius, size.height);

    // Path 2 Segment B (Bottom-right curve + Right vertical line)
    final path2B = Path()
      ..moveTo(size.width - cornerRadius, size.height)
      ..arcToPoint(
        Offset(size.width, size.height - cornerRadius),
        radius: Radius.circular(cornerRadius),
        clockwise: false,
      )
      ..lineTo(size.width, cornerRadius);

    final baseColor = isDark ? Colors.white : Colors.black;

    // Paint 1A: Horizontal gradient fading to 0.0 at top-right
    final paint1A = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isDark ? 0.8 : 0.8
      ..shader = ui.Gradient.linear(
        Offset(size.width * 0.92, 0),
        Offset(cornerRadius, 0),
        [
          baseColor.withValues(alpha: 0.0),
          baseColor.withValues(alpha: isDark ? 0.75 : 0.2),
        ],
        const [0.0, 0.09],
      );

    // Paint 1B: Vertical gradient fading to 0.0 at the end of the left vertical line
    final paint1B = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isDark ? 0.8 : 0.8
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(0, size.height - cornerRadius),
        [
          baseColor.withValues(alpha: isDark ? 0.75 : 0.2),
          baseColor.withValues(alpha: isDark ? 0.75 : 0.2),
          baseColor.withValues(alpha: 0.0),
        ],
        const [0.0, 0, 1.0],
      );

    // Paint 2A: Horizontal gradient fading to 0.0 at bottom-left
    final paint2A = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isDark ? 0.8 : 0.8
      ..shader = ui.Gradient.linear(
        Offset(size.width * 0.1, size.height),
        Offset(size.width - cornerRadius, size.height),
        [
          baseColor.withValues(alpha: 0.0),
          baseColor.withValues(alpha: isDark ? 0.75 : 0.2),
        ],
        const [0.0, 0.09],
      );

    // Paint 2B: Vertical gradient fading to 0.0 at the end of the right vertical line
    final paint2B = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isDark ? 0.8 : 0.8
      ..shader = ui.Gradient.linear(
        Offset(size.width, size.height),
        Offset(size.width, cornerRadius),
        [
          baseColor.withValues(alpha: isDark ? 0.75 : 0.2),
          baseColor.withValues(alpha: isDark ? 0.75 : 0.2),
          baseColor.withValues(alpha: 0.0),
        ],
        const [0.0, 0, 1.0],
      );

    canvas.drawPath(path1A, paint1A);
    canvas.drawPath(path1B, paint1B);
    canvas.drawPath(path2A, paint2A);
    canvas.drawPath(path2B, paint2B);
  }

  @override
  bool shouldRepaint(_GlassSpecularPainter old) =>
      old.isDark != isDark ||
      old.activeX != activeX ||
      old.glowProgress != glowProgress ||
      old.tiltX != tiltX ||
      old.tiltY != tiltY ||
      old.activeColor != activeColor;
}

// ─────────────────────────────────────────────────────────────────────────────
// Caustic refraction painter (lenticular lines behind glass)
// ─────────────────────────────────────────────────────────────────────────────

class _CausticPainter extends CustomPainter {
  final bool isDark;
  final double phase; // 0..1 oscillation

  const _CausticPainter({required this.isDark, required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw 3 subtle diagonal light bands
    final baseAlpha = isDark ? 0.025 : 0.06;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    for (int i = 0; i < 3; i++) {
      final offset =
          size.width *
          (0.25 + i * 0.25 + math.sin(phase * math.pi * 2 + i) * 0.04);
      paint.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: baseAlpha),
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(offset - 20, 0, 40, size.height));
      canvas.drawLine(
        Offset(offset, 0),
        Offset(offset - 10, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CausticPainter old) => old.phase != phase;
}

// ─────────────────────────────────────────────────────────────────────────────
// Main widget
// ─────────────────────────────────────────────────────────────────────────────

class CurvedBottomNavBar extends StatefulWidget {
  final List<CurvedBottomNavItem> items;
  final int currentIndex;
  final Function(int) onTap;
  final Color backgroundColor;
  final Color activeColor;
  final Color inactiveColor;
  final List<Color>? activeColors;

  /// Optional key targeting a [RepaintBoundary] that wraps the content behind
  /// this nav bar. When provided, the bar uses the liquid-glass lens shader
  /// for a real refractive / glassmorphic background instead of a plain blur.
  final GlobalKey? backgroundKey;

  const CurvedBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.backgroundColor = Colors.white,
    this.activeColor = const Color(0xFF00C6E6),
    this.inactiveColor = Colors.black,
    this.backgroundKey,
    this.activeColors,
  });

  // ── Bottom clearance helpers ─────────────────────────────────────────────
  // These mirror the dockHeight + bottomMargin values used in build() so that
  // screens can add exactly the right amount of bottom padding to keep their
  // last items scrollable above the floating dock.

  /// Bottom clearance in portrait orientation (dockHeight 76 + margin 16).
  static const double portraitClearance = 92.0;

  /// Bottom clearance in landscape orientation (dockHeight 66 + margin 12).
  static const double landscapeClearance = 78.0;

  /// Returns the bottom clearance for the current device orientation.
  static double clearance(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape
      ? landscapeClearance
      : portraitClearance;

  @override
  State<CurvedBottomNavBar> createState() => _CurvedBottomNavBarState();
}

/// Drop this as the **last item** inside any [ListView], [Column], or
/// [SingleChildScrollView] that lives behind the floating nav bar.
///
/// It reserves exactly the height from the dock's top edge to the screen
/// bottom so the scroll view can reveal its last item above the bar.
/// No padding is added at the dashboard level, so the glass blur remains
/// visible over real page content rather than a solid-colour gap.
class BottomNavSpacer extends StatelessWidget {
  const BottomNavSpacer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: CurvedBottomNavBar.clearance(context));
  }
}

class _CurvedBottomNavBarState extends State<CurvedBottomNavBar>
    with TickerProviderStateMixin {
  // Fluid morphing curves: fastOutSlowIn for leading edge stretch, custom cubic for trailing edge snap
  static const Curve _leadCurve = Interval(
    0.0,
    0.72,
    curve: Curves.fastOutSlowIn,
  );
  static const Curve _trailCurve = Interval(
    0.15,
    1.0,
    curve: Cubic(0.4, 0.0, 0.2, 1.12),
  );

  // Slide / squash animation
  late AnimationController _slideController;
  double _fromIndex = 0.0;
  double _toIndex = 0.0;

  // Drag / spring feedback
  late AnimationController _springController;
  double _dragOffsetX = 0.0;
  double _dragOffsetY = 0.0;
  double _springStartX = 0.0;
  double _springStartY = 0.0;

  // Gesture transition tracking
  bool _isGestureTransition = false;
  int _gestureOldIndex = 0;
  double _gestureReleasedOffsetX = 0.0;
  double _gestureReleasedOffsetY = 0.0;

  // Caustic shimmer idle animation
  late AnimationController _causticController;

  // Glow fade-in after tap
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  // Liquid-glass lens shader (only initialized when backgroundKey is provided)
  LiquidGlassLensShader? _lensShader;

  @override
  void initState() {
    super.initState();

    // Initialize the lens shader lazily if a background key was provided.
    if (widget.backgroundKey != null) {
      _lensShader = LiquidGlassLensShader()..initialize();
    }

    _fromIndex = widget.currentIndex.toDouble();
    _toIndex = widget.currentIndex.toDouble();

    _slideController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 420),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            HapticFeedback.lightImpact();
          }
        });

    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _springController.addListener(() {
      final double val = const Cubic(
        0.15,
        1.4,
        0.3,
        1.0,
      ).transform(_springController.value);
      setState(() {
        _dragOffsetX = ui.lerpDouble(_springStartX, 0.0, val)!;
        _dragOffsetY = ui.lerpDouble(_springStartY, 0.0, val)!;
      });
    });

    _causticController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeOut,
    );
  }

  @override
  void didUpdateWidget(CurvedBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      if (_isGestureTransition) {
        final double screenWidth = MediaQuery.of(context).size.width;
        final bool isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;
        final double dockWidth = isLandscape
            ? 480.0.clamp(300.0, screenWidth - 32.0)
            : (screenWidth - 32.0);
        final double itemWidth = dockWidth / widget.items.length;

        final double recalculatedOffsetX =
            (_gestureOldIndex - widget.currentIndex) * itemWidth +
            _gestureReleasedOffsetX;

        setState(() {
          _fromIndex = widget.currentIndex.toDouble();
          _toIndex = widget.currentIndex.toDouble();
          _dragOffsetX = recalculatedOffsetX;
          _dragOffsetY = _gestureReleasedOffsetY;
        });

        _springBack();
        _isGestureTransition = false;

        // Retrigger glow flash
        _glowController.forward(from: 0).then((_) => _glowController.reverse());
      } else {
        final double screenWidth = MediaQuery.of(context).size.width;
        final bool isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;
        final double dockWidth = isLandscape
            ? 480.0.clamp(300.0, screenWidth - 32.0)
            : (screenWidth - 32.0);
        final double itemWidth = dockWidth / widget.items.length;
        final double basePillW = isLandscape ? 46.0 : 52.0;

        double currentVisualIndex = _toIndex;
        if (_slideController.isAnimating) {
          final double progress = _slideController.value;
          final double xStart = (itemWidth * _fromIndex) + (itemWidth / 2);
          final double xEnd = (itemWidth * _toIndex) + (itemWidth / 2);

          final double tLead = _leadCurve.transform(progress);
          final double tTrail = _trailCurve.transform(progress);

          double left, right;
          if (xStart < xEnd) {
            right = xStart + basePillW / 2 + (xEnd - xStart) * tLead;
            left = xStart - basePillW / 2 + (xEnd - xStart) * tTrail;
          } else if (xStart > xEnd) {
            left = xStart - basePillW / 2 + (xEnd - xStart) * tLead;
            right = xStart + basePillW / 2 + (xEnd - xStart) * tTrail;
          } else {
            left = xStart - basePillW / 2;
            right = xStart + basePillW / 2;
          }
          final double visualCenterX = (left + right) / 2;
          currentVisualIndex = (visualCenterX / itemWidth) - 0.5;
        }

        _fromIndex = currentVisualIndex;
        _toIndex = widget.currentIndex.toDouble();
        _slideController.forward(from: 0);

        // Retrigger glow flash
        _glowController.forward(from: 0).then((_) => _glowController.reverse());
      }
    }
  }

  Color _getActiveColorForIndex(double visualIndex) {
    final colors =
        widget.activeColors ??
        [
          widget.activeColor,
          const Color(0xFF10B981), // emerald green
          const Color(0xFFF59E0B), // amber
          const Color(0xFFE53935), // warning red
          const Color(0xFF8B5CF6), // purple
        ];

    if (colors.isEmpty) return widget.activeColor;

    // Ensure resolvedColors list is at least as long as items length
    final List<Color> resolvedColors = List<Color>.generate(
      widget.items.length,
      (i) {
        if (i < colors.length) return colors[i];
        return widget.activeColor;
      },
    );

    final double clampedIndex = visualIndex.clamp(
      0.0,
      widget.items.length - 1.0,
    );
    final int i1 = clampedIndex.floor();
    final int i2 = clampedIndex.ceil();
    final double t = clampedIndex - i1;

    return Color.lerp(resolvedColors[i1], resolvedColors[i2], t) ??
        widget.activeColor;
  }

  void _springBack() {
    _springStartX = _dragOffsetX;
    _springStartY = _dragOffsetY;
    _springController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _slideController.dispose();
    _springController.dispose();
    _causticController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final double dockWidth = isLandscape
        ? 480.0.clamp(300.0, screenWidth - 32.0)
        : (screenWidth - 32.0);
    final double itemWidth = dockWidth / widget.items.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final double dockHeight = isLandscape ? 66.0 : 76.0;
    final double bottomMargin = isLandscape ? 12.0 : 16.0;
    final double cornerRadius = 32.0;

    final double basePillW = isLandscape ? 46.0 : 52.0;
    final double basePillH = isLandscape ? 32.0 : 38.0;
    final double iconFloatOffset = isLandscape ? -3.0 : -4.0;

    // Vertical centre of the pill
    final double unselectedIconCY = ((dockHeight - 40.0) / 2) + 12.0;
    final double pillCY = unselectedIconCY + iconFloatOffset;

    return MediaQuery.removePadding(
      context: context,
      removeBottom: true,
      child: SizedBox(
        width: dockWidth,
        height: dockHeight + bottomMargin,
        child: Container(
          width: dockWidth,
          height: dockHeight,
          margin: EdgeInsets.only(bottom: bottomMargin),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ── A. Far-field under-glow (below the dock) ──────────────────
              AnimatedBuilder(
                animation: Listenable.merge([
                  _slideController,
                  _springController,
                ]),
                builder: (context, _) {
                  final double progress = _slideController.value;
                  final double xStart =
                      (itemWidth * _fromIndex) + (itemWidth / 2);
                  final double xEnd = (itemWidth * _toIndex) + (itemWidth / 2);

                  final double tLead = _leadCurve.transform(progress);
                  final double tTrail = _trailCurve.transform(progress);

                  double left, right;
                  if (xStart < xEnd) {
                    right = xStart + basePillW / 2 + (xEnd - xStart) * tLead;
                    left = xStart - basePillW / 2 + (xEnd - xStart) * tTrail;
                  } else if (xStart > xEnd) {
                    left = xStart - basePillW / 2 + (xEnd - xStart) * tLead;
                    right = xStart + basePillW / 2 + (xEnd - xStart) * tTrail;
                  } else {
                    left = xStart - basePillW / 2;
                    right = xStart + basePillW / 2;
                  }
                  final double pillCX = (left + right) / 2 + _dragOffsetX;
                  final double visualIndex = (pillCX / itemWidth) - 0.5;
                  final Color dynamicColor = _getActiveColorForIndex(
                    visualIndex,
                  );

                  return Positioned(
                    left: pillCX - 50,
                    bottom: -24 + _dragOffsetY,
                    child: IgnorePointer(
                      child: Container(
                        width: 100,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: dynamicColor.withValues(
                                alpha: isDark ? 0.15 : 0.07,
                              ),
                              blurRadius: 48,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              // ── B. Caustic refraction lines (behind glass, innermost) ──────
              ClipRRect(
                borderRadius: BorderRadius.circular(cornerRadius),
                child: AnimatedBuilder(
                  animation: _causticController,
                  builder: (context, _) => CustomPaint(
                    size: Size(dockWidth, dockHeight),
                    painter: _CausticPainter(
                      isDark: isDark,
                      phase: _causticController.value,
                    ),
                  ),
                ),
              ),

              // ── Base shadow layer for floating elevation (refractive & fallback) ──
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(cornerRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.45 : 0.16,
                        ),
                        blurRadius: isDark ? 36.0 : 28.0,
                        spreadRadius: isDark ? -1.0 : -4.0,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                ),
              ),

              // ── C. Glass backdrop ─────────────────────────────────────────
              // If the parent provided a RepaintBoundary key we use the real
              // refractive liquid-glass lens shader. Otherwise fall back to a
              // plain BackdropFilter frosted blur.
              if (widget.backgroundKey != null && _lensShader != null)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(cornerRadius),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: BackgroundCaptureWidget(
                            width: dockWidth,
                            height: dockHeight,
                            backgroundKey: widget.backgroundKey!,
                            shader: _lensShader!,
                            borderRadius: BorderRadius.circular(cornerRadius),
                            child: const SizedBox.expand(),
                          ),
                        ),
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(cornerRadius),
                            child: BackdropFilter(
                              filter: ui.ImageFilter.blur(
                                sigmaX: 5.0,
                                sigmaY: 5.0,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    cornerRadius,
                                  ),
                                  color: isDark
                                      ? Colors.black.withValues(alpha: 0.28)
                                      : const ui.Color.fromARGB(
                                          255,
                                          255,
                                          255,
                                          255,
                                        ).withValues(alpha: 0.24),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.black.withValues(alpha: 0.09),
                                    width: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                // Fallback container shadow placeholder (handled by unified base shadow above)
                const SizedBox.shrink(),
              if (widget.backgroundKey == null)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(cornerRadius),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(cornerRadius),
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.15)
                              : const Color.fromARGB(
                                  255,
                                  255,
                                  255,
                                  255,
                                ).withValues(alpha: 0.24),
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),

              // ── E. Specular highlights + radial glow (painted on top of glass) ─
              AnimatedBuilder(
                animation: Listenable.merge([_slideController, _glowAnimation]),
                builder: (context, _) {
                  final double progress = _slideController.value;
                  final double xStart =
                      (itemWidth * _fromIndex) + (itemWidth / 2);
                  final double xEnd = (itemWidth * _toIndex) + (itemWidth / 2);

                  final double tLead = _leadCurve.transform(progress);
                  final double tTrail = _trailCurve.transform(progress);

                  double left, right;
                  if (xStart < xEnd) {
                    right = xStart + basePillW / 2 + (xEnd - xStart) * tLead;
                    left = xStart - basePillW / 2 + (xEnd - xStart) * tTrail;
                  } else if (xStart > xEnd) {
                    left = xStart - basePillW / 2 + (xEnd - xStart) * tLead;
                    right = xStart + basePillW / 2 + (xEnd - xStart) * tTrail;
                  } else {
                    left = xStart - basePillW / 2;
                    right = xStart + basePillW / 2;
                  }
                  final double pillCX = (left + right) / 2;

                  // Multi-directional Spotlight Shading:
                  // Shift highlight dynamically during slide speed and drag pan
                  double tiltX = _dragOffsetX * 0.25;
                  double tiltY = _dragOffsetY * 0.25;
                  if (_slideController.isAnimating) {
                    final double speedFactor = (xEnd - xStart) * 0.12;
                    final double stretch = (tLead - tTrail);
                    tiltX += speedFactor * stretch;
                  }

                  final double visualIndex = (pillCX / itemWidth) - 0.5;
                  final Color dynamicColor = _getActiveColorForIndex(
                    visualIndex,
                  );

                  return CustomPaint(
                    size: Size(dockWidth, dockHeight),
                    painter: _GlassSpecularPainter(
                      isDark: isDark,
                      cornerRadius: cornerRadius,
                      activeX: pillCX,
                      glowProgress: _glowAnimation.value,
                      tiltX: tiltX,
                      tiltY: tiltY,
                      activeColor: dynamicColor,
                    ),
                  );
                },
              ),

              // ── G. Active indicator pill (frosted lens) ────────────────────
              AnimatedBuilder(
                animation: Listenable.merge([
                  _slideController,
                  _springController,
                ]),
                builder: (context, _) {
                  final double progress = _slideController.value;
                  final double xStart =
                      (itemWidth * _fromIndex) + (itemWidth / 2);
                  final double xEnd = (itemWidth * _toIndex) + (itemWidth / 2);

                  final double tLead = _leadCurve.transform(progress);
                  final double tTrail = _trailCurve.transform(progress);

                  double left, right;
                  if (xStart < xEnd) {
                    right = xStart + basePillW / 2 + (xEnd - xStart) * tLead;
                    left = xStart - basePillW / 2 + (xEnd - xStart) * tTrail;
                  } else if (xStart > xEnd) {
                    left = xStart - basePillW / 2 + (xEnd - xStart) * tLead;
                    right = xStart + basePillW / 2 + (xEnd - xStart) * tTrail;
                  } else {
                    left = xStart - basePillW / 2;
                    right = xStart + basePillW / 2;
                  }

                  double pillW = right - left;
                  if (isLandscape) {
                    final double excessStretch = pillW - basePillW;
                    pillW = basePillW + excessStretch * 0.62;
                  }

                  final double widthRatio = basePillW / pillW;
                  final double squashExponent = isLandscape ? 0.20 : 0.35;
                  final double heightScale = math
                      .pow(widthRatio.clamp(0.5, 1.5), squashExponent)
                      .toDouble();
                  double pillH = basePillH * heightScale;

                  // Dynamic Drag Taffy Stretch and Squash:
                  // Horizontal drag stretches width and squashes height.
                  final double dragSensX = isLandscape ? 0.0018 : 0.003;
                  final double dragSensY = isLandscape ? 0.003 : 0.005;
                  final double dragStretchX =
                      1.0 + (_dragOffsetX.abs() * dragSensX).clamp(0.0, 0.4);
                  // Vertical drag stretches height and squashes width.
                  final double dragStretchY =
                      1.0 + (_dragOffsetY.abs() * dragSensY).clamp(0.0, 0.3);

                  pillW = pillW * dragStretchX / (dragStretchY * 0.4 + 0.6);
                  pillH = pillH * dragStretchY / (dragStretchX * 0.4 + 0.6);

                  final double pillCX = (left + right) / 2 + _dragOffsetX;
                  final double pillTop = pillCY + _dragOffsetY - (pillH / 2);

                  // Dynamic Corner Radius Morphing:
                  // Shrink corner radius when pill is stretched (flattening the corners)
                  final double stretchRatio = pillW / basePillW;
                  final double rawRadius = pillH / 2;
                  final double cornerRadius =
                      (rawRadius *
                      (1.0 - (stretchRatio - 1.0) * 0.18).clamp(0.55, 1.0));

                  final double visualIndex = (pillCX / itemWidth) - 0.5;
                  final Color dynamicColor = _getActiveColorForIndex(
                    visualIndex,
                  );

                  return Positioned(
                    left: pillCX - (pillW / 2),
                    top: pillTop,
                    child: _GlassPill(
                      width: pillW,
                      height: pillH,
                      cornerRadius: cornerRadius,
                      activeColor: dynamicColor,
                      isDark: isDark,
                    ),
                  );
                },
              ),

              // ── H. Navigation items ────────────────────────────────────────
              // ── H. Navigation items ────────────────────────────────────────
              AnimatedBuilder(
                animation: Listenable.merge([
                  _slideController,
                  _springController,
                ]),
                builder: (context, _) {
                  final double progress = _slideController.value;
                  final double xStart =
                      (itemWidth * _fromIndex) + (itemWidth / 2);
                  final double xEnd = (itemWidth * _toIndex) + (itemWidth / 2);

                  final double tLead = _leadCurve.transform(progress);
                  final double tTrail = _trailCurve.transform(progress);

                  double left, right;
                  if (xStart < xEnd) {
                    right = xStart + basePillW / 2 + (xEnd - xStart) * tLead;
                    left = xStart - basePillW / 2 + (xEnd - xStart) * tTrail;
                  } else if (xStart > xEnd) {
                    left = xStart - basePillW / 2 + (xEnd - xStart) * tLead;
                    right = xStart + basePillW / 2 + (xEnd - xStart) * tTrail;
                  } else {
                    left = xStart - basePillW / 2;
                    right = xStart + basePillW / 2;
                  }

                  double pillW = right - left;
                  if (isLandscape) {
                    final double excessStretch = pillW - basePillW;
                    pillW = basePillW + excessStretch * 0.62;
                  }
                  final double dragSensX = isLandscape ? 0.0018 : 0.003;
                  final double dragSensY = isLandscape ? 0.003 : 0.005;
                  final double dragStretchX =
                      1.0 + (_dragOffsetX.abs() * dragSensX).clamp(0.0, 0.4);
                  final double dragStretchY =
                      1.0 + (_dragOffsetY.abs() * dragSensY).clamp(0.0, 0.3);
                  final double stretchedPillW =
                      pillW * dragStretchX / (dragStretchY * 0.4 + 0.6);
                  final double pillWHalf = stretchedPillW / 2;

                  final double pillCX = (left + right) / 2 + _dragOffsetX;
                  final double visualIndex = (pillCX / itemWidth) - 0.5;
                  final Color dynamicColor = _getActiveColorForIndex(
                    visualIndex,
                  );

                  return Row(
                    children: widget.items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final bool isSelected = widget.currentIndex == index;

                      // Calculate overlap for inactive tab labels
                      double overlap = 0.0;
                      if (!isSelected) {
                        final double xTab =
                            (itemWidth * index) + (itemWidth / 2);
                        final double d = (xTab - pillCX).abs();
                        if (d < pillWHalf && pillWHalf > 0) {
                          overlap = (1.0 - (d / pillWHalf)).clamp(0.0, 1.0);
                        }
                      }

                      // Parallax effect: shift downward, scale down, and fade out
                      final double labelShiftY = overlap * 5.0; // max 5px shift
                      final double labelScale =
                          1.0 - (overlap * 0.08); // max 8% shrink
                      final double labelOpacity =
                          1.0 - (overlap * 0.45); // max 45% fade out

                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (widget.currentIndex != index) {
                              HapticFeedback.mediumImpact();
                              widget.onTap(index);
                            }
                          },
                          onPanStart: (details) {
                            if (isSelected) {
                              _springController.stop();
                              _springStartX = _dragOffsetX;
                              _springStartY = _dragOffsetY;
                            }
                          },
                          onPanUpdate: (details) {
                            if (isSelected) {
                              setState(() {
                                _dragOffsetX += details.delta.dx;
                                _dragOffsetY += details.delta.dy * 0.65;
                                final double minDragX =
                                    -widget.currentIndex * itemWidth;
                                final double maxDragX =
                                    (widget.items.length -
                                        1 -
                                        widget.currentIndex) *
                                    itemWidth;
                                _dragOffsetX = _dragOffsetX.clamp(
                                  minDragX - itemWidth * 0.25,
                                  maxDragX + itemWidth * 0.25,
                                );
                                _dragOffsetY = _dragOffsetY.clamp(-12.0, 48.0);
                              });
                            }
                          },
                          onPanEnd: (details) {
                            if (isSelected) {
                              final double t =
                                  0.35; // Responsive threshold fraction
                              final double val = _dragOffsetX / itemWidth;
                              int targetOffset = 0;
                              if (val >= 0) {
                                final int integer = val.floor();
                                final double fraction = val - integer;
                                targetOffset = fraction >= t
                                    ? integer + 1
                                    : integer;
                              } else {
                                final int integer = val.ceil();
                                final double fraction = val - integer;
                                targetOffset = fraction.abs() >= t
                                    ? integer - 1
                                    : integer;
                              }

                              if (targetOffset != 0) {
                                final int targetIndex =
                                    (widget.currentIndex + targetOffset).clamp(
                                      0,
                                      widget.items.length - 1,
                                    );
                                if (targetIndex != widget.currentIndex) {
                                  HapticFeedback.mediumImpact();
                                  _isGestureTransition = true;
                                  _gestureOldIndex = widget.currentIndex;
                                  _gestureReleasedOffsetX = _dragOffsetX;
                                  _gestureReleasedOffsetY = _dragOffsetY;
                                  widget.onTap(targetIndex);
                                } else {
                                  _springBack();
                                }
                              } else {
                                _springBack();
                              }
                            }
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // ── Icon with float + scale animation ─────────────
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(
                                  begin: isSelected ? 1.0 : 0.0,
                                  end: isSelected ? 1.0 : 0.0,
                                ),
                                duration: const Duration(milliseconds: 440),
                                curve: const Cubic(0.34, 1.65, 0.54, 1.0),
                                builder: (context, val, _) {
                                  return Transform.translate(
                                    offset: Offset(0, iconFloatOffset * val),
                                    child: Transform.scale(
                                      scale: 1.0 + (val * 0.22),
                                      child: _buildNavItemIcon(
                                        item,
                                        val,
                                        isSelected,
                                        dynamicColor,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 4),
                              // ── Label with parallax depth ─────────────────────
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(
                                  begin: isSelected ? 1.0 : 0.0,
                                  end: isSelected ? 1.0 : 0.0,
                                ),
                                duration: const Duration(milliseconds: 320),
                                curve: Curves.easeOutQuad,
                                builder: (context, val, _) {
                                  return Transform.translate(
                                    offset: Offset(0, labelShiftY),
                                    child: Transform.scale(
                                      scale: labelScale,
                                      child: Opacity(
                                        opacity: labelOpacity,
                                        child: AnimatedDefaultTextStyle(
                                          duration: const Duration(
                                            milliseconds: 320,
                                          ),
                                          style: TextStyle(
                                            color: Color.lerp(
                                              isDark
                                                  ? Colors.white
                                                  : Colors.black,
                                              dynamicColor,
                                              val,
                                            ),
                                            fontWeight: val > 0.5
                                                ? FontWeight.w700
                                                : FontWeight.w400,
                                            fontSize: 10,
                                            letterSpacing: val > 0.5 ? 0.3 : 0,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black.withValues(
                                                  alpha: isDark ? 0.35 : 0.12,
                                                ),
                                                blurRadius: 3.0,
                                                offset: const Offset(0.0, 1.0),
                                              ),
                                            ],
                                          ),
                                          child: Text(item.label),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Icon builder
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildNavItemIcon(
    CurvedBottomNavItem item,
    double val,
    bool isSelected,
    Color activeColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final color = Color.lerp(
      isDark ? Colors.white : Colors.black,
      activeColor,
      val,
    )!;

    Widget iconWidget;

    if (item.riveAsset != null) {
      iconWidget = RiveNavIcon(
        item: item,
        isSelected: isSelected,
        activeColor: activeColor,
        inactiveColor: widget.inactiveColor,
      );
    } else {
      iconWidget = Icon(
        item.icon,
        color: color,
        size: 24,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.12),
            blurRadius: 3.0,
            offset: const Offset(0.0, 1.0),
          ),
        ],
      );
    }

    if (item.badgeCount != null && item.badgeCount! > 0) {
      return BadgeParticleBurstWidget(
        badgeCount: item.badgeCount!,
        activeColor: activeColor,
        child: iconWidget,
      );
    }

    return iconWidget;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Liquid glass pill – frosted inner-lens active indicator
// ─────────────────────────────────────────────────────────────────────────────

class _GlassPill extends StatelessWidget {
  final double width;
  final double height;
  final double cornerRadius;
  final Color activeColor;
  final bool isDark;

  const _GlassPill({
    required this.width,
    required this.height,
    required this.cornerRadius,
    required this.activeColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(cornerRadius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cornerRadius),
            // Multi-stop gradient – mimics a refracting glass lozenge
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                activeColor.withValues(alpha: isDark ? 0.10 : 0.06),
                activeColor.withValues(alpha: isDark ? 0.05 : 0.03),
                activeColor.withValues(alpha: isDark ? 0.07 : 0.04),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            border: Border.all(
              color: activeColor.withValues(alpha: isDark ? 0.15 : 0.12),
              width: 1.2,
            ),
            boxShadow: [
              // Outer glow
              BoxShadow(
                color: activeColor.withValues(alpha: isDark ? 0.05 : 0.06),
                blurRadius: 12,
                spreadRadius: 1,
              ),
              // Inner light (simulated)
              BoxShadow(
                color: Colors.white.withValues(alpha: isDark ? 0.04 : 0.20),
                blurRadius: 4,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Top specular highlight inside pill
              Positioned(
                top: 1,
                left: width * 0.15,
                right: width * 0.15,
                height: height * 0.35,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(cornerRadius),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: isDark ? 0.15 : 0.45),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Badge Particle Burst Widget & Particle Painter
// ─────────────────────────────────────────────────────────────────────────────

class BadgeParticleBurstWidget extends StatefulWidget {
  final int badgeCount;
  final Widget child;
  final Color activeColor;

  const BadgeParticleBurstWidget({
    super.key,
    required this.badgeCount,
    required this.child,
    required this.activeColor,
  });

  @override
  State<BadgeParticleBurstWidget> createState() =>
      _BadgeParticleBurstWidgetState();
}

class _Particle {
  final double angle;
  final double maxDistance;
  final double size;
  final Color color;

  _Particle({
    required this.angle,
    required this.maxDistance,
    required this.size,
    required this.color,
  });
}

class _BadgeParticleBurstWidgetState extends State<BadgeParticleBurstWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _burstController;
  late Animation<double> _scaleAnimation;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.4,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.4,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70,
      ),
    ]).animate(_burstController);
  }

  @override
  void didUpdateWidget(BadgeParticleBurstWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.badgeCount > oldWidget.badgeCount) {
      _spawnParticles();
      _burstController.forward(from: 0.0);
    }
  }

  void _spawnParticles() {
    _particles.clear();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Spawn 6 glass/bubble particles
    for (int i = 0; i < 6; i++) {
      _particles.add(
        _Particle(
          // Upward semi-circle (radians: -3*pi/4 to -pi/4)
          angle: -math.pi / 4 - _random.nextDouble() * (math.pi / 2),
          maxDistance: 24.0 + _random.nextDouble() * 16.0,
          size: 2.0 + _random.nextDouble() * 3.0,
          color: widget.activeColor.withValues(alpha: isDark ? 0.7 : 0.9),
        ),
      );
    }
  }

  @override
  void dispose() {
    _burstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (widget.badgeCount > 0)
          Positioned(
            right: -6,
            top: -4,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Badge(
                label: Text(
                  widget.badgeCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 8),
                ),
                backgroundColor: Colors.red,
              ),
            ),
          ),
        // Render burst particles
        if (_burstController.isAnimating)
          Positioned(
            right: 0,
            top: 0,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _burstController,
                builder: (context, _) {
                  final double t = _burstController.value;
                  return CustomPaint(
                    painter: _ParticlePainter(
                      particles: _particles,
                      progress: t,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final double distance = p.maxDistance * progress;
      final double dx = math.cos(p.angle) * distance;
      final double dy = math.sin(p.angle) * distance - (progress * 8.0);
      final double opacity = (1.0 - progress).clamp(0.0, 1.0);

      paint.color = p.color.withValues(alpha: p.color.a * opacity);

      if (p.size > 3.5) {
        final path = Path()
          ..moveTo(dx, dy - p.size)
          ..lineTo(dx + p.size * 0.7, dy)
          ..lineTo(dx, dy + p.size)
          ..lineTo(dx - p.size * 0.7, dy)
          ..close();
        canvas.drawPath(path, paint);
      } else {
        canvas.drawCircle(Offset(dx, dy), p.size, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
