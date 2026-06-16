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

  Future<void> _captureBackground() async {
    if (_isCapturing || !mounted) return;
    _isCapturing = true;

    try {
      // ── 1. Locate the RepaintBoundary render object ─────────────────────
      final boundary = widget.backgroundKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;

      final ourBox = context.findRenderObject() as RenderBox?;

      if (boundary == null ||
          !boundary.attached ||
          ourBox == null ||
          !ourBox.hasSize ||
          !ourBox.attached) {
        return;
      }

      if (!boundary.hasSize || widget.width <= 0 || widget.height <= 0) {
        return;
      }

      // ── 2. Capture the full boundary at device pixel density ─────────────
      // boundary.toImage() is the public, mode-safe API (works in
      // debug / profile / release, unlike debugLayer which throws in release).
      final double dpr = MediaQuery.of(context).devicePixelRatio;
      final ui.Image fullImage = await boundary.toImage(pixelRatio: dpr);

      // ── 3. Compute the nav-bar rect inside the captured image ────────────
      // Convert our widget's top-left and bottom-right from global space into
      // the boundary's local space, then scale to physical pixels.
      final Offset globalTopLeft = ourBox.localToGlobal(Offset.zero);
      final Offset localTopLeft = boundary.globalToLocal(globalTopLeft);

      final int cropLeft =
          (localTopLeft.dx * dpr).round().clamp(0, fullImage.width);
      final int cropTop =
          (localTopLeft.dy * dpr).round().clamp(0, fullImage.height);
      final int cropRight =
          ((localTopLeft.dx + widget.width) * dpr).round().clamp(0, fullImage.width);
      final int cropBottom =
          ((localTopLeft.dy + widget.height) * dpr).round().clamp(0, fullImage.height);

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
