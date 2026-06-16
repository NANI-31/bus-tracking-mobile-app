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
  final double activeX;       // centre X of active tab
  final double glowProgress;  // 0-1 fade-in of radial glow

  const _GlassSpecularPainter({
    required this.isDark,
    required this.cornerRadius,
    required this.activeX,
    required this.glowProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(cornerRadius),
    );

    // ── 1. Radial spotlight glow that tracks the active tab ────────────────
    final glowOpacity = isDark ? 0.10 : 0.18;
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          (activeX / size.width) * 2 - 1,  // normalise to -1..+1
          -0.3,
        ),
        radius: 0.7,
        colors: [
          Colors.white.withValues(alpha: glowOpacity * glowProgress),
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRRect(rrect, glowPaint);

    // ── 2. Top-edge specular bar (simulates glass rim) ─────────────────────
    const specularBarH = 1.5;
    final specularPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: isDark ? 0.18 : 0.55),
          Colors.white.withValues(alpha: isDark ? 0.22 : 0.65),
          Colors.white.withValues(alpha: isDark ? 0.18 : 0.55),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, specularBarH));
    final path = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(cornerRadius * 0.6, 0, size.width - cornerRadius * 1.2, specularBarH),
          topLeft: const Radius.circular(2),
          topRight: const Radius.circular(2),
        ),
      );
    canvas.drawPath(path, specularPaint);

    // ── 3. Bottom specular – subtle under-lighting reflection ──────────────
    final bottomGlow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: isDark ? 0.04 : 0.10),
        ],
      ).createShader(Rect.fromLTWH(0, size.height * 0.6, size.width, size.height * 0.4));
    canvas.drawRRect(rrect, bottomGlow);

    // ── 4. Inner-top gradient vignette (depth / thickness) ─────────────────
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
  }

  @override
  bool shouldRepaint(_GlassSpecularPainter old) =>
      old.isDark != isDark ||
      old.activeX != activeX ||
      old.glowProgress != glowProgress;
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
      final offset = size.width * (0.25 + i * 0.25 + math.sin(phase * math.pi * 2 + i) * 0.04);
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
  // Slide / squash animation
  late AnimationController _slideController;
  double _fromIndex = 0.0;
  double _toIndex = 0.0;

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

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

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

        final Curve leadCurve = const Cubic(0.20, 1.0, 0.25, 1.0);
        final Curve trailCurve = const Cubic(0.65, 0.0, 0.20, 1.15);

        final double tLead = leadCurve.transform(progress);
        final double tTrail = trailCurve.transform(progress);

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

  @override
  void dispose() {
    _slideController.dispose();
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
                  animation: _slideController,
                  builder: (context, _) {
                    final double progress = _slideController.value;
                    final double xStart = (itemWidth * _fromIndex) + (itemWidth / 2);
                    final double xEnd = (itemWidth * _toIndex) + (itemWidth / 2);

                    final Curve leadCurve = const Cubic(0.20, 1.0, 0.25, 1.0);
                    final Curve trailCurve = const Cubic(0.65, 0.0, 0.20, 1.15);

                    final double tLead = leadCurve.transform(progress);
                    final double tTrail = trailCurve.transform(progress);

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

                    return Positioned(
                      left: pillCX - 50,
                      bottom: -24,
                      child: IgnorePointer(
                        child: Container(
                          width: 100,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: widget.activeColor
                                    .withValues(alpha: isDark ? 0.40 : 0.18),
                                blurRadius: 48,
                                spreadRadius: 10,
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

                // ── C. Glass backdrop ─────────────────────────────────────────
                // If the parent provided a RepaintBoundary key we use the real
                // refractive liquid-glass lens shader. Otherwise fall back to a
                // plain BackdropFilter frosted blur.
                if (widget.backgroundKey != null && _lensShader != null)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(cornerRadius),
                      child: BackgroundCaptureWidget(
                        width: dockWidth,
                        height: dockHeight,
                        backgroundKey: widget.backgroundKey!,
                        shader: _lensShader!,
                        borderRadius: BorderRadius.circular(cornerRadius),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  )
                else
                  // Fallback: standard frosted glass when no background key given.
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(cornerRadius),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.08),
                            blurRadius: 30,
                            spreadRadius: -2,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                    ),
                  ),
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
                                : Colors.white.withValues(alpha: 0.20),
                            border: Border.all(
                              color: (isDark ? Colors.white : Colors.black)
                                  .withValues(alpha: 0.08),
                              width: 1.0,
                            ),
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
                    final double xStart = (itemWidth * _fromIndex) + (itemWidth / 2);
                    final double xEnd = (itemWidth * _toIndex) + (itemWidth / 2);

                    final Curve leadCurve = const Cubic(0.20, 1.0, 0.25, 1.0);
                    final Curve trailCurve = const Cubic(0.65, 0.0, 0.20, 1.15);

                    final double tLead = leadCurve.transform(progress);
                    final double tTrail = trailCurve.transform(progress);

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

                    return CustomPaint(
                      size: Size(dockWidth, dockHeight),
                      painter: _GlassSpecularPainter(
                        isDark: isDark,
                        cornerRadius: cornerRadius,
                        activeX: pillCX,
                        glowProgress: _glowAnimation.value,
                      ),
                    );
                  },
                ),

                // ── G. Active indicator pill (frosted lens) ────────────────────
                AnimatedBuilder(
                  animation: _slideController,
                  builder: (context, _) {
                    final double progress = _slideController.value;
                    final double xStart = (itemWidth * _fromIndex) + (itemWidth / 2);
                    final double xEnd = (itemWidth * _toIndex) + (itemWidth / 2);

                    final Curve leadCurve = const Cubic(0.20, 1.0, 0.25, 1.0);
                    final Curve trailCurve = const Cubic(0.65, 0.0, 0.20, 1.15);

                    final double tLead = leadCurve.transform(progress);
                    final double tTrail = trailCurve.transform(progress);

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

                    final double pillW = right - left;
                    final double widthRatio = basePillW / pillW;
                    final double heightScale = math.pow(widthRatio.clamp(0.5, 1.5), 0.35).toDouble();
                    final double pillH = basePillH * heightScale;
                    final double pillTop = pillCY - (pillH / 2);

                    return Positioned(
                      left: left,
                      top: pillTop,
                      child: _GlassPill(
                        width: pillW,
                        height: pillH,
                        activeColor: widget.activeColor,
                        isDark: isDark,
                      ),
                    );
                  },
                ),

                // ── H. Navigation items ────────────────────────────────────────
                Row(
                  children: widget.items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final bool isSelected = widget.currentIndex == index;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (widget.currentIndex != index) {
                            HapticFeedback.selectionClick();
                            widget.onTap(index);
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
                              duration: const Duration(milliseconds: 380),
                              curve: Curves.easeOutBack,
                              builder: (context, val, _) {
                                return Transform.translate(
                                  offset: Offset(0, iconFloatOffset * val),
                                  child: Transform.scale(
                                    scale: 1.0 + (val * 0.18),
                                    child: _buildNavItemIcon(
                                        item, val, isSelected),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 4),
                            // ── Label ─────────────────────────────────────────
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(
                                begin: isSelected ? 1.0 : 0.0,
                                end: isSelected ? 1.0 : 0.0,
                              ),
                              duration: const Duration(milliseconds: 320),
                              curve: Curves.easeOutQuad,
                              builder: (context, val, _) {
                                return AnimatedDefaultTextStyle(
                                  duration:
                                      const Duration(milliseconds: 320),
                                  style: TextStyle(
                                    color: Color.lerp(
                                      isDark
                                          ? Colors.white
                                              .withValues(alpha: 0.40)
                                          : widget.inactiveColor
                                              .withValues(alpha: 0.50),
                                      widget.activeColor,
                                      val,
                                    ),
                                    fontWeight: val > 0.5
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    fontSize: 10,
                                    letterSpacing: val > 0.5 ? 0.3 : 0,
                                  ),
                                  child: Text(item.label),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
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
      CurvedBottomNavItem item, double val, bool isSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final color = Color.lerp(
      isDark
          ? Colors.white.withValues(alpha: 0.42)
          : widget.inactiveColor.withValues(alpha: 0.52),
      widget.activeColor,
      val,
    )!;

    Widget iconWidget;

    if (item.riveAsset != null) {
      iconWidget = RiveNavIcon(
        item: item,
        isSelected: isSelected,
        activeColor: widget.activeColor,
        inactiveColor: widget.inactiveColor,
      );
    } else {
      iconWidget = Icon(item.icon, color: color, size: 24);
    }

    if (item.badgeCount != null && item.badgeCount! > 0) {
      return Badge(
        label: Text(
          item.badgeCount.toString(),
          style: const TextStyle(color: Colors.white, fontSize: 8),
        ),
        backgroundColor: Colors.red,
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
  final Color activeColor;
  final bool isDark;

  const _GlassPill({
    required this.width,
    required this.height,
    required this.activeColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final r = height / 2;

    return ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(r),
            // Multi-stop gradient – mimics a refracting glass lozenge
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                activeColor.withValues(alpha: isDark ? 0.30 : 0.18),
                activeColor.withValues(alpha: isDark ? 0.16 : 0.10),
                activeColor.withValues(alpha: isDark ? 0.22 : 0.14),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            border: Border.all(
              color: activeColor.withValues(alpha: isDark ? 0.45 : 0.35),
              width: 1.2,
            ),
            boxShadow: [
              // Outer glow
              BoxShadow(
                color: activeColor.withValues(alpha: isDark ? 0.30 : 0.20),
                blurRadius: 14,
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
                    borderRadius: BorderRadius.circular(r),
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
