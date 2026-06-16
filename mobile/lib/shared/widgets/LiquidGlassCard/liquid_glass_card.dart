import 'dart:math' show pi;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class LiquidGlassCard extends StatefulWidget {
  final Widget child;
  final Color tint;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  const LiquidGlassCard({
    super.key,
    required this.child,
    this.tint = const Color(0x1AFFFFFF),
    this.borderRadius = 24,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  State<LiquidGlassCard> createState() => _LiquidGlassCardState();
}

class _LiquidGlassCardState extends State<LiquidGlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  ui.FragmentProgram? _glassProgram;
  ui.FragmentProgram? _shimmerProgram;
  ui.FragmentProgram? _refractionProgram;
  bool _shadersReady = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _loadShaders();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadShaders() async {
    try {
      final glass = await ui.FragmentProgram.fromAsset(
        'shaders/liquid_glass.frag',
      );
      final shimmer = await ui.FragmentProgram.fromAsset(
        'shaders/shimmer.frag',
      );
      final refraction = await ui.FragmentProgram.fromAsset(
        'shaders/refraction.frag',
      );

      if (mounted) {
        setState(() {
          _glassProgram = glass;
          _shimmerProgram = shimmer;
          _refractionProgram = refraction;
          _shadersReady = true;
        });
        debugPrint('LiquidGlassCard: Shaders loaded successfully!');
      }
    } catch (e) {
      debugPrint('Failed to load shaders: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Stack(
        children: [
          // Layer 1 — BackdropFilter (blur)
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: Colors.transparent),
            ),
          ),

          // Layer 2 — Background tint & shadow / border
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: widget.tint,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                  width: 1.2,
                ),
              ),
            ),
          ),

          // Layer 3 — Shaders CustomPaint
          if (_shadersReady)
            Positioned.fill(
              child: CustomPaint(
                painter: _GlassOverlayPainter(
                  glassShader: _glassProgram!.fragmentShader(),
                  shimmerShader: _shimmerProgram!.fragmentShader(),
                  refractionShader: _refractionProgram!.fragmentShader(),
                  time: _controller.value * 2 * pi,
                  tint: widget.tint,
                ),
              ),
            ),

          // Layer 4 — content
          Padding(
            padding: widget.padding,
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

class _GlassOverlayPainter extends CustomPainter {
  final ui.FragmentShader glassShader;
  final ui.FragmentShader shimmerShader;
  final ui.FragmentShader refractionShader;
  final double time;
  final Color tint;

  _GlassOverlayPainter({
    required this.glassShader,
    required this.shimmerShader,
    required this.refractionShader,
    required this.time,
    required this.tint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Procedural glass liquid highlight layer
    glassShader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, time)
      ..setFloat(3, 1.0)
      ..setFloat(4, tint.r)
      ..setFloat(5, tint.g)
      ..setFloat(6, tint.b)
      ..setFloat(7, tint.a);
    canvas.drawRect(Offset.zero & size, Paint()..shader = glassShader);

    // 2. Shimmer sweep
    shimmerShader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, time)
      ..setFloat(3, 1.0)
      ..setFloat(4, 1.0)
      ..setFloat(5, 1.0)
      ..setFloat(6, 1.0);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shimmerShader);

    // 3. Top-edge specular highlight
    refractionShader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, 24.0);
    canvas.drawRect(Offset.zero & size, Paint()..shader = refractionShader);
  }

  @override
  bool shouldRepaint(_GlassOverlayPainter old) => old.time != time;
}
