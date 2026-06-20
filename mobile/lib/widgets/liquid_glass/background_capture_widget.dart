import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'base_shader.dart';
import 'shader_painter.dart';

/// A widget that captures the rendered scene behind it (via [backgroundKey])
/// and feeds the cropped pixels to a [BaseShader] to produce a real-time
/// refractive / glassmorphic background.
///
/// Unlike the original demo version this widget is **not draggable** — it is
/// designed to fill the background of a floating navigation bar.
///
/// ## Coordinate flow
/// 1. `boundary.toImage(pixelRatio: dpr)` – full physical capture of the
///    RepaintBoundary (safe in all build modes, unlike `debugLayer`).
/// 2. The nav-bar rect inside that image is computed from global → local
///    coordinate transforms and multiplied by DPR.
/// 3. `Canvas.drawImageRect` crops the relevant slice.
/// 4. The cropped image is passed to the shader; its physical dimensions
///    exactly match the `physicalW × physicalH` uniforms, so UVs align.
class BackgroundCaptureWidget extends StatefulWidget {
  const BackgroundCaptureWidget({
    super.key,
    required this.child,
    required this.width,
    required this.height,
    required this.shader,
    required this.backgroundKey,
    this.captureInterval = const Duration(milliseconds: 16),
    this.borderRadius = BorderRadius.zero,
  });

  /// The widget tree rendered on top of the glass effect.
  final Widget child;

  /// Logical width / height of this widget (i.e. the nav-bar dock size).
  final double width;
  final double height;

  /// Key attached to the [RepaintBoundary] that wraps the background content.
  final GlobalKey backgroundKey;

  /// The initialised shader to apply.
  final BaseShader shader;

  /// How often to re-capture the background (≈60 fps at 16 ms).
  final Duration captureInterval;

  /// Corner radius applied to the clipping rect.
  final BorderRadius borderRadius;

  @override
  State<BackgroundCaptureWidget> createState() =>
      _BackgroundCaptureWidgetState();
}

class _BackgroundCaptureWidgetState extends State<BackgroundCaptureWidget> {
  Timer? _timer;
  bool _isCapturing = false;
  ui.Image? _capturedBackground;

  @override
  void initState() {
    super.initState();
    // First capture after the first frame is rendered.
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureBackground());
    _startCapture();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _capturedBackground?.dispose();
    super.dispose();
  }

  void _startCapture() {
    _timer = Timer.periodic(widget.captureInterval, (_) {
      if (mounted && !_isCapturing) _captureBackground();
    });
  }

  /// Returns true only when both [Offset] components are finite (not NaN / Infinity).
  /// During map camera animations the render tree transforms can momentarily
  /// produce invalid values — this guard lets us skip those frames safely.
  static bool _isFiniteOffset(Offset o) =>
      o.dx.isFinite && o.dy.isFinite;

  Future<void> _captureBackground() async {
    if (_isCapturing || !mounted) return;
    _isCapturing = true;

    try {
      // ── 1. Locate the RepaintBoundary render object ─────────────────────
      final backgroundContext = widget.backgroundKey.currentContext;
      if (backgroundContext == null) return;

      RenderRepaintBoundary? boundary;
      final renderObject = backgroundContext.findRenderObject();
      if (renderObject is RenderRepaintBoundary) {
        boundary = renderObject;
      } else if (renderObject != null) {
        // Walk up the ancestor tree to find the nearest RenderRepaintBoundary
        backgroundContext.visitAncestorElements((element) {
          final ro = element.renderObject;
          if (ro is RenderRepaintBoundary) {
            boundary = ro;
            return false; // Stop traversal
          }
          return true;
        });
      }

      final ourBox = context.findRenderObject() as RenderBox?;

      final resolvedBoundary = boundary;
      if (resolvedBoundary == null) return;

      if (!resolvedBoundary.attached ||
          ourBox == null ||
          !ourBox.hasSize ||
          !ourBox.attached) {
        return;
      }

      if (!resolvedBoundary.hasSize || widget.width <= 0 || widget.height <= 0) {
        return;
      }

      // Safeguard: do not capture if the repaint boundary is currently dirty (needs layout or paint),
      // as calling toImage() on a dirty RenderObject throws an assertion error in debug mode.
      bool needsLayoutOrPaint = false;
      assert(() {
        if (resolvedBoundary.debugNeedsLayout || resolvedBoundary.debugNeedsPaint) {
          needsLayoutOrPaint = true;
        }
        return true;
      }());
      if (needsLayoutOrPaint) {
        return;
      }

      // ── 2. Capture the full boundary at device pixel density ─────────────
      // boundary.toImage() is the public, mode-safe API (works in
      // debug / profile / release, unlike debugLayer which throws in release).
      final double dpr = MediaQuery.of(context).devicePixelRatio;
      final ui.Image fullImage = await resolvedBoundary.toImage(pixelRatio: dpr);

      // ── 3. Compute the nav-bar rect inside the captured image ────────────
      // IMPORTANT: We must use boundary.globalToLocal() for BOTH corners of
      // our widget's rect. Using ourBox.localToGlobal() + boundary.globalToLocal()
      // introduces a device-specific asymmetry: on some devices (especially those
      // with display cutouts, non-standard DPRs, or different system UI padding),
      // localToGlobal and globalToLocal traverse different ancestor transform
      // chains, causing the computed crop to point at the wrong vertical region.
      // This makes the texture appear to scroll in the OPPOSITE direction when the
      // page scrolls.
      //
      // Solution: call boundary.globalToLocal() on the global positions of our
      // widget's four corners directly — this is a single, symmetric transform.
      final Offset ourGlobalTopLeft = ourBox.localToGlobal(Offset.zero);
      final Offset ourGlobalBottomRight = ourBox.localToGlobal(
        Offset(widget.width, widget.height),
      );
      // Transform both points into the boundary's local (logical) coordinate space.
      final Offset localTopLeft = resolvedBoundary.globalToLocal(ourGlobalTopLeft);
      final Offset localBottomRight = resolvedBoundary.globalToLocal(
        ourGlobalBottomRight,
      );

      // Guard: during map camera animations (move / idle transition) the render
      // tree transforms can be momentarily invalid, producing Infinity or NaN.
      // Bail out silently — the next timer tick will retry with a valid transform.
      if (!_isFiniteOffset(ourGlobalTopLeft) ||
          !_isFiniteOffset(ourGlobalBottomRight) ||
          !_isFiniteOffset(localTopLeft) ||
          !_isFiniteOffset(localBottomRight)) {
        fullImage.dispose();
        return;
      }

      // Clamp to integer physical pixels. Do NOT negate or offset — the boundary
      // local coords already point to the exact pixels we need to crop.
      final int cropLeft = (localTopLeft.dx * dpr).round().clamp(
        0,
        fullImage.width,
      );
      final int cropTop = (localTopLeft.dy * dpr).round().clamp(
        0,
        fullImage.height,
      );
      final int cropRight = (localBottomRight.dx * dpr).round().clamp(
        0,
        fullImage.width,
      );
      final int cropBottom = (localBottomRight.dy * dpr).round().clamp(
        0,
        fullImage.height,
      );

      final int cropW = cropRight - cropLeft;
      final int cropH = cropBottom - cropTop;

      if (cropW <= 0 || cropH <= 0) {
        fullImage.dispose();
        return;
      }

      // ── 4. Crop to exactly the nav-bar region ────────────────────────────
      // drawImageRect maps the src rect of fullImage to the dst rect of a
      // fresh canvas — effectively cropping it.
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, cropW.toDouble(), cropH.toDouble()),
      );
      canvas.drawImageRect(
        fullImage,
        Rect.fromLTRB(
          cropLeft.toDouble(),
          cropTop.toDouble(),
          cropRight.toDouble(),
          cropBottom.toDouble(),
        ),
        Rect.fromLTWH(0, 0, cropW.toDouble(), cropH.toDouble()),
        Paint(),
      );
      final ui.Picture picture = recorder.endRecording();
      final ui.Image croppedImage = await picture.toImage(cropW, cropH);

      // Dispose intermediates
      fullImage.dispose();
      picture.dispose();

      if (mounted) {
        setState(() {
          _capturedBackground?.dispose();
          _capturedBackground = croppedImage;
        });
      } else {
        croppedImage.dispose();
      }
    } catch (e) {
      debugPrint('[BackgroundCaptureWidget] capture error: $e');
    } finally {
      if (mounted) _isCapturing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double dpr = MediaQuery.of(context).devicePixelRatio;

    Widget content;
    if (widget.shader.isLoaded && _capturedBackground != null) {
      // The cropped image physical dimensions = cropW × cropH
      //   = (widget.width * dpr) × (widget.height * dpr)
      // which exactly matches physicalW × physicalH passed as uResolution.
      // So FlutterFragCoord() / uResolution → (0,0)–(1,1) aligns with the
      // texture UVs → correct lens distortion, no zoom artifact.
      widget.shader.updateShaderUniforms(
        width: widget.width,
        height: widget.height,
        backgroundImage: _capturedBackground,
        devicePixelRatio: dpr,
      );
      content = CustomPaint(
        size: Size(widget.width, widget.height),
        painter: ShaderPainter(widget.shader.shader),
        child: widget.child,
      );
    } else {
      // Fallback: frosted glass while shader / first capture is pending.
      content = ClipRRect(
        borderRadius: widget.borderRadius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            color: Colors.white.withValues(alpha: 0.10),
            child: widget.child,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: content,
      ),
    );
  }
}
