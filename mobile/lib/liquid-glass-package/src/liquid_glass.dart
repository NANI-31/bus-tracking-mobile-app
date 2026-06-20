import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:collegebus/core/utils/shader_precompiler.dart';
import 'utils.dart';

enum LiquidGlassMode { standard, polar, prominent, shader }

// Cached resources shared across all LiquidGlass instances
ui.FragmentProgram? _program;
ui.Image? _cachedDisplacement;
ui.Image? _cachedPolar;
ui.Image? _cachedProminent;
bool _resourcesLoading = false;
bool _resourcesLoaded = false;
bool _shaderLoadingFailed = false;
final List<VoidCallback> _pendingListeners = [];

Future<void> _initSharedResources() async {
  if (_resourcesLoaded) return;
  if (_resourcesLoading) {
    final completer = Completer<void>();
    _pendingListeners.add(() => completer.complete());
    await completer.future;
    return;
  }
  _resourcesLoading = true;

  // Load fragment shader
  try {
    _program = ShaderPrecompiler.hasProgram('shaders/liquid_glass.frag')
        ? ShaderPrecompiler.getProgram('shaders/liquid_glass.frag')!
        : await ui.FragmentProgram.fromAsset(
            'shaders/liquid_glass.frag',
          );
  } catch (e) {
    _shaderLoadingFailed = true;
    debugPrint('Failed to load liquid_glass shader: $e');
  }

  // Load and decode base64 displacement maps
  try {
    _cachedDisplacement = await _decodeBase64Image(displacementMap);
    _cachedPolar = await _decodeBase64Image(polarDisplacementMap);
    _cachedProminent = await _decodeBase64Image(prominentDisplacementMap);
    _resourcesLoaded = true;
  } catch (e) {
    debugPrint('Failed to load displacement maps: $e');
  } finally {
    _resourcesLoading = false;
    for (final listener in _pendingListeners) {
      listener();
    }
    _pendingListeners.clear();
  }
}

Future<ui.Image> _decodeBase64Image(String base64Str) async {
  final Uint8List bytes = base64Decode(base64Str.split(',').last);
  final ui.Codec codec = await ui.instantiateImageCodec(bytes);
  final ui.FrameInfo frameInfo = await codec.getNextFrame();
  return frameInfo.image;
}

class LiquidGlass extends StatefulWidget {
  const LiquidGlass({
    super.key,
    required this.child,
    this.displacementScale = 25,
    this.blurAmount = 0.0625,
    this.saturation = 180,
    this.aberrationIntensity = 2,
    this.elasticity = 0.15,
    this.cornerRadius = 999,
    this.globalMousePos,
    this.mouseOffset,
    this.onClick,
    this.overLight = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
    this.mode = LiquidGlassMode.standard,
    this.onHover,
    this.onExit,
    this.onTapDown,
    this.onTapUp,
  });

  final Widget child;
  final double displacementScale;
  final double blurAmount;
  final double saturation;
  final double aberrationIntensity;
  final double elasticity;
  final double cornerRadius;
  final Offset? globalMousePos;
  final Offset? mouseOffset;
  final bool overLight;
  final EdgeInsets padding;
  final LiquidGlassMode mode;
  final VoidCallback? onClick;
  final VoidCallback? onHover;
  final VoidCallback? onExit;
  final VoidCallback? onTapDown;
  final VoidCallback? onTapUp;

  @override
  State<LiquidGlass> createState() => _LiquidGlassState();
}

class _LiquidGlassState extends State<LiquidGlass> {
  final _containerKey = GlobalKey();
  Offset _internalGlobalMousePos = Offset.zero;
  Offset _internalMouseOffset = Offset.zero;
  bool _isHovered = false;
  bool _isPressed = false;
  Size _glassSize = const Size(270, 69);

  Offset get _globalMousePos =>
      widget.globalMousePos ?? _internalGlobalMousePos;
  Offset get _mouseOffset => widget.mouseOffset ?? _internalMouseOffset;

  /// Safe wrapper around [findRenderObject].
  ///
  /// [LayoutBuilder]'s builder fires during Flutter's *layout* phase, before
  /// the child [MouseRegion] widget is fully active. Calling
  /// [BuildContext.findRenderObject] on an inactive element throws an assertion
  /// in debug mode. This helper catches that and returns null so every call
  /// site degrades gracefully (identity transform / zero offset).
  RenderBox? _getRenderBox() {
    try {
      final ctx = _containerKey.currentContext;
      if (ctx == null) return null;
      final ro = ctx.findRenderObject();
      if (ro is RenderBox && ro.attached) return ro;
      return null;
    } catch (_) {
      return null;
    }
  }

  void _updateMousePosition(PointerEvent event) {
    final renderBox = _getRenderBox();
    if (renderBox == null) return;

    final localPosition = renderBox.globalToLocal(event.position);
    final width = renderBox.size.width;
    final height = renderBox.size.height;
    final centerX = width / 2;
    final centerY = height / 2;

    setState(() {
      _internalMouseOffset = Offset(
        ((localPosition.dx - centerX) / width) * 100,
        ((localPosition.dy - centerY) / height) * 100,
      );
      _internalGlobalMousePos = event.position;
    });
  }

  void _updateGlassSize() {
    final renderBox = _getRenderBox();
    if (renderBox != null && renderBox.size != _glassSize) {
      setState(() {
        _glassSize = renderBox.size;
      });
    }
  }

  double _calculateFadeInFactor() {
    if (_globalMousePos == Offset.zero) return 0;
    final renderBox = _getRenderBox();
    if (renderBox == null) return 0;

    final rect = renderBox.localToGlobal(Offset.zero) & renderBox.size;
    final pillCenter = rect.center;
    final edgeDistanceX = math.max(
        0, (_globalMousePos.dx - pillCenter.dx).abs() - rect.width / 2);
    final edgeDistanceY = math.max(
        0, (_globalMousePos.dy - pillCenter.dy).abs() - rect.height / 2);
    final edgeDistance = math
        .sqrt(edgeDistanceX * edgeDistanceX + edgeDistanceY * edgeDistanceY);
    const activationZone = 200;
    return edgeDistance > activationZone
        ? 0
        : 1 - edgeDistance / activationZone;
  }

  Matrix4 _calculateTransform() {
    final renderBox = _getRenderBox();
    if (renderBox == null || _globalMousePos == Offset.zero) {
      return Matrix4.identity();
    }

    final rect = renderBox.localToGlobal(Offset.zero) & renderBox.size;
    final pillCenter = rect.center;
    final deltaX = _globalMousePos.dx - pillCenter.dx;
    final deltaY = _globalMousePos.dy - pillCenter.dy;

    final edgeDistanceX = math.max(0, deltaX.abs() - rect.width / 2);
    final edgeDistanceY = math.max(0, deltaY.abs() - rect.height / 2);
    final edgeDistance = math
        .sqrt(edgeDistanceX * edgeDistanceX + edgeDistanceY * edgeDistanceY);
    const activationZone = 200;
    if (edgeDistance > activationZone || (deltaX == 0 && deltaY == 0)) {
      return Matrix4.identity();
    }

    final fadeInFactor = 1 - edgeDistance / activationZone;
    final centerDistance = math.sqrt(deltaX * deltaX + deltaY * deltaY);
    final normalizedX = deltaX / centerDistance;
    final normalizedY = deltaY / centerDistance;
    final stretchIntensity =
        math.min(centerDistance / 300, 1) * widget.elasticity * fadeInFactor;

    final scaleX = 1 +
        normalizedX.abs() * stretchIntensity * 0.3 -
        normalizedY.abs() * stretchIntensity * 0.15;
    final scaleY = 1 +
        normalizedY.abs() * stretchIntensity * 0.3 -
        normalizedX.abs() * stretchIntensity * 0.15;

    final matrix = Matrix4.identity();
    matrix.storage[0] = math.max(0.8, scaleX);
    matrix.storage[5] = math.max(0.8, scaleY);
    matrix.storage[10] = 1.0;
    return matrix;
  }

  Offset _calculateTranslation() {
    final renderBox = _getRenderBox();
    if (renderBox == null) return Offset.zero;

    final fadeInFactor = _calculateFadeInFactor();
    final rect = renderBox.localToGlobal(Offset.zero) & renderBox.size;
    final pillCenter = rect.center;

    return Offset(
      (_globalMousePos.dx - pillCenter.dx) *
          widget.elasticity *
          0.1 *
          fadeInFactor,
      (_globalMousePos.dy - pillCenter.dy) *
          widget.elasticity *
          0.1 *
          fadeInFactor,
    );
  }

  @override
  void initState() {
    super.initState();
    _initSharedResources().then((_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateGlassSize();
    });
  }

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder gives us the REAL parent constraints synchronously.
    // This fixes the first-frame sizing bug where _glassSize defaulted
    // to 270×69 instead of the nav bar's full width.
    return LayoutBuilder(
      builder: (context, constraints) {
        // Synchronously update _glassSize when tight constraints are known
        // (safe to mutate directly here – LayoutBuilder re-calls on change).
        if (constraints.maxWidth.isFinite && constraints.maxHeight.isFinite) {
          _glassSize = Size(constraints.maxWidth, constraints.maxHeight);
        } else {
          // Fallback: post-frame update for unconstrained parents
          WidgetsBinding.instance.addPostFrameCallback((_) => _updateGlassSize());
        }
        return _buildGlassContent(context);
      },
    );
  }

  Widget _buildGlassContent(BuildContext context) {
    final transform = _calculateTransform();
    final translation = _calculateTranslation();
    final effectiveTransform = Matrix4.identity();
    effectiveTransform.storage[12] = translation.dx;
    effectiveTransform.storage[13] = translation.dy;
    effectiveTransform.storage[14] = 0.0;
    effectiveTransform.multiply(transform);

    final double shadowOpacity = widget.overLight ? 0.08 : 0.30;
    final double shadowBlur = widget.overLight ? 24.0 : 40.0;
    final double shadowOffset = widget.overLight ? 4.0 : 12.0;

    final shadow = BoxShadow(
      color: Colors.black.withValues(alpha: shadowOpacity),
      blurRadius: shadowBlur,
      spreadRadius: 0,
      offset: Offset(0, shadowOffset),
    );

    // Compute mouse offset relative to center of the glass container for global mouse position inputs
    Offset effectiveMouseOffset = _mouseOffset;
    if (widget.globalMousePos != null && widget.globalMousePos != Offset.zero) {
      final renderBox = _getRenderBox();
      if (renderBox != null) {
        final localPosition = renderBox.globalToLocal(widget.globalMousePos!);
        final width = renderBox.size.width;
        final height = renderBox.size.height;
        if (width > 0 && height > 0) {
          final centerX = width / 2;
          final centerY = height / 2;
          effectiveMouseOffset = Offset(
            ((localPosition.dx - centerX) / width) * 100,
            ((localPosition.dy - centerY) / height) * 100,
          );
        }
      }
    }

    // Dynamic reflection gradient rotation/scale based on mouse offset
    final reflectionGradient = LinearGradient(
      begin: Alignment(-0.2 - effectiveMouseOffset.dx * 0.01, -1),
      end: Alignment(0.5 + effectiveMouseOffset.dx * 0.01, 1),
      colors: [
        Colors.white.withValues(alpha: 0.0),
        Colors.white.withValues(alpha: 
            (0.12 + effectiveMouseOffset.dx.abs() * 0.008).clamp(0.0, 1.0)),
        Colors.white
            .withValues(alpha: (0.4 + effectiveMouseOffset.dx.abs() * 0.012).clamp(0.0, 1.0)),
        Colors.white.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.33, 0.66, 1.0],
    );

    // Build the double-layer gradient border painters
    final borderGradient1 = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withValues(alpha: 0.0),
        Colors.white.withValues(alpha: 
            (0.12 + effectiveMouseOffset.dx.abs() * 0.008).clamp(0.0, 1.0)),
        Colors.white
            .withValues(alpha: (0.4 + effectiveMouseOffset.dx.abs() * 0.012).clamp(0.0, 1.0)),
        Colors.white.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.33, 0.66, 1.0],
    );

    final borderGradient2 = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withValues(alpha: 0.0),
        Colors.white.withValues(alpha: 
            (0.32 + effectiveMouseOffset.dx.abs() * 0.008).clamp(0.0, 1.0)),
        Colors.white
            .withValues(alpha: (0.6 + effectiveMouseOffset.dx.abs() * 0.012).clamp(0.0, 1.0)),
        Colors.white.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.33, 0.66, 1.0],
    );

    // Create ImageFilter
    ui.ImageFilter imageFilter;
    if (_resourcesLoaded && _program != null && !_shaderLoadingFailed) {
      final shader = _program!.fragmentShader();
      shader.setFloat(0, _glassSize.width);
      shader.setFloat(1, _glassSize.height);

      final double finalScale = widget.overLight
          ? widget.displacementScale * 0.5
          : widget.displacementScale;
      shader.setFloat(2, finalScale);
      shader.setFloat(3, widget.aberrationIntensity);

      double modeVal = 0.0;
      if (widget.mode == LiquidGlassMode.polar) {
        modeVal = 1.0;
      } else if (widget.mode == LiquidGlassMode.prominent) {
        modeVal = 2.0;
      } else if (widget.mode == LiquidGlassMode.shader) {
        modeVal = 3.0;
      }
      shader.setFloat(4, modeVal);

      ui.Image? dispImage;
      if (widget.mode == LiquidGlassMode.standard) {
        dispImage = _cachedDisplacement;
      } else if (widget.mode == LiquidGlassMode.polar) {
        dispImage = _cachedPolar;
      } else if (widget.mode == LiquidGlassMode.prominent) {
        dispImage = _cachedProminent;
      }

      if (dispImage != null) {
        shader.setImageSampler(1, dispImage);
      }
      imageFilter = ui.ImageFilter.shader(shader);
    } else {
      // Fallback blur filter – use iOS-quality blur (sigma 20 = frosted glass)
      final double backdropBlur =
          widget.overLight ? 20.0 : (4 + widget.blurAmount * 32);
      imageFilter =
          ui.ImageFilter.blur(sigmaX: backdropBlur, sigmaY: backdropBlur,
              tileMode: TileMode.mirror);
    }

    final double saturationVal = widget.saturation / 100.0;

    return MouseRegion(
      key: _containerKey,
      onHover: (event) {
        _updateMousePosition(event);
        if (!_isHovered) {
          setState(() => _isHovered = true);
          widget.onHover?.call();
        }
      },
      onExit: (event) {
        setState(() {
          _isHovered = false;
          _internalGlobalMousePos = Offset.zero;
          _internalMouseOffset = Offset.zero;
        });
        widget.onExit?.call();
      },
      child: GestureDetector(
        onTap: widget.onClick,
        onTapDown: (_) {
          setState(() => _isPressed = true);
          widget.onTapDown?.call();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTapUp?.call();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: Transform(
          transform: effectiveTransform,
          alignment: Alignment.center,
          child: Stack(
            clipBehavior: Clip.none,  // outer stack: allows shadow to overflow
            children: [
              // 0. Shadow layer rendered OUTSIDE the clipped glass,
              //    so Clip.hardEdge on the inner Stack doesn't eat it.
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(widget.cornerRadius),
                      boxShadow: [shadow],
                    ),
                  ),
                ),
              ),
              // 1. The clipped glass pill
              SizedBox.fromSize(
                size: _glassSize,
                child: Stack(
                  clipBehavior: Clip.hardEdge, // prevents blur leaking outside rounded corners
                  children: [

              // 2. iOS-style adaptive frosted tint
              // Light mode: subtle white veil so the blur reads as frosted glass
              // Dark mode: subtle dark veil so the glass has depth
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.overLight
                          ? Colors.white.withValues(alpha: 0.15)  // light frosted
                          : Colors.black.withValues(alpha: 0.10), // dark frosted
                      borderRadius:
                          BorderRadius.circular(widget.cornerRadius),
                    ),
                  ),
                ),
              ),

              // 4. Backdrop filter warp layer
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(widget.cornerRadius),
                  child: BackdropFilter(
                    filter: imageFilter,
                    child: ColorFiltered(
                      colorFilter: ColorFilter.matrix(<double>[
                        saturationVal,
                        0,
                        0,
                        0,
                        0,
                        0,
                        saturationVal,
                        0,
                        0,
                        0,
                        0,
                        0,
                        saturationVal,
                        0,
                        0,
                        0,
                        0,
                        0,
                        1,
                        0,
                      ]),
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ),

              // 5. Translucent white base layer – boosted for iOS frosted look
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(widget.cornerRadius),
                      color: widget.overLight
                          ? Colors.white.withValues(alpha: 0.14) // light frosted
                          : Colors.white.withValues(alpha: 0.06), // dark frosted
                    ),
                  ),
                ),
              ),

              // 6. Highlight linear reflection gradient
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.cornerRadius),
                    gradient: reflectionGradient,
                  ),
                ),
              ),

              // 7. Interactive Hover/Click highlight overlays
              if (widget.onClick != null) ...[
                Positioned.fill(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isHovered || _isPressed ? 0.5 : 0.0,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(widget.cornerRadius),
                        gradient: RadialGradient(
                          center: const Alignment(0, -1),
                          radius: 1.2,
                          colors: [
                            Colors.white.withValues(alpha: 0.5),
                            Colors.transparent,
                          ],
                        ),
                        backgroundBlendMode: BlendMode.overlay,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isPressed ? 0.5 : 0.0,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(widget.cornerRadius),
                        gradient: RadialGradient(
                          center: const Alignment(0, -1),
                          radius: 1.2,
                          colors: [
                            Colors.white.withValues(alpha: 1.0),
                            Colors.transparent,
                          ],
                        ),
                        backgroundBlendMode: BlendMode.overlay,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isHovered ? 0.4 : (_isPressed ? 0.8 : 0.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(widget.cornerRadius),
                        gradient: RadialGradient(
                          center: const Alignment(0, -1),
                          radius: 1.2,
                          colors: [
                            Colors.white.withValues(alpha: 1.0),
                            Colors.transparent,
                          ],
                        ),
                        backgroundBlendMode: BlendMode.overlay,
                      ),
                    ),
                  ),
                ),
              ],

              // 8. Gradient Border Layer 1 (Screen Blend, 20% Opacity)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: GradientBorderPainter(
                      gradient: borderGradient1,
                      width: 1.5,
                      radius: widget.cornerRadius,
                      blendMode: BlendMode.screen,
                      opacity: 0.2,
                    ),
                  ),
                ),
              ),

              // 9. Gradient Border Layer 2 (Overlay Blend, 100% Opacity)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: GradientBorderPainter(
                      gradient: borderGradient2,
                      width: 1.5,
                      radius: widget.cornerRadius,
                      blendMode: BlendMode.overlay,
                      opacity: 1.0,
                    ),
                  ),
                ),
              ),

              // 10. Foreground child content
              Padding(
                padding: widget.padding,
                child: DefaultTextStyle(
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                  child: widget.child,
                ),
              ),
              ],          // closes inner Stack children
              ),          // closes inner Stack
              ),          // closes SizedBox.fromSize
            ],            // closes outer Stack children (shadow + glass)
          ),              // closes outer Stack
        ),                // closes Transform
      ),                  // closes GestureDetector
    );                    // closes MouseRegion (return of _buildGlassContent)
  }
}

class GradientBorderPainter extends CustomPainter {
  GradientBorderPainter({
    required this.gradient,
    required this.width,
    required this.radius,
    required this.blendMode,
    required this.opacity,
  });

  final Gradient gradient;
  final double width;
  final double radius;
  final BlendMode blendMode;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..blendMode = blendMode
      ..color = Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0));

    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant GradientBorderPainter oldDelegate) {
    return oldDelegate.gradient != gradient ||
        oldDelegate.width != width ||
        oldDelegate.radius != radius ||
        oldDelegate.blendMode != blendMode ||
        oldDelegate.opacity != opacity;
  }
}
