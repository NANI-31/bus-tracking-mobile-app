import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/widgets/liquid_glass/background_capture_widget.dart';
import 'package:collegebus/widgets/liquid_glass/base_shader.dart';

/// Supported glassmorphism design variants.
enum GlassVariant {
  defaultStyle,
  card,
  header,
}

/// A standardized Glassmorphic container that uses central theme parameters from
/// [DesignSystemThemeExtension] and supports optional overrides, custom border radiuses,
/// circular shapes, and liquid glass shader integrations.
class GlassMorphicContainer extends StatelessWidget {
  final Widget? child;
  final GlassVariant variant;
  final double? blurSigma;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final BorderRadius? borderRadius;
  final BoxShape boxShape;
  final GlobalKey? backgroundKey;
  final BaseShader? shader;
  final double? width;
  final double? height;

  const GlassMorphicContainer({
    super.key,
    this.child,
    this.variant = GlassVariant.defaultStyle,
    this.blurSigma,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.borderRadius,
    this.boxShape = BoxShape.rectangle,
    this.backgroundKey,
    this.shader,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final designTheme = context.designTheme;

    // Resolve spec based on variant
    final GlassThemeSpec spec;
    switch (variant) {
      case GlassVariant.card:
        spec = designTheme.cardGlass;
        break;
      case GlassVariant.header:
        spec = designTheme.headerGlass;
        break;
      case GlassVariant.defaultStyle:
        spec = designTheme.defaultGlass;
        break;
    }

    final double effectiveBlur = blurSigma ?? spec.blurSigma;
    final Color effectiveBgColor = backgroundColor ?? spec.backgroundColor;
    final Color effectiveBorderColor = borderColor ?? spec.borderColor;

    // Use default border radius from theme extension glassDecoration if not overridden
    final BorderRadius effectiveRadius = borderRadius ??
        (boxShape == BoxShape.circle
            ? BorderRadius.zero
            : (designTheme.glassDecoration.borderRadius as BorderRadius? ?? BorderRadius.circular(24)));

    Widget buildDecorationContainer() {
      return Container(
        decoration: BoxDecoration(
          shape: boxShape,
          borderRadius: boxShape == BoxShape.circle ? null : effectiveRadius,
          color: effectiveBgColor,
          border: Border.all(
            color: effectiveBorderColor,
            width: borderWidth,
          ),
        ),
      );
    }

    Widget glassLayers;
    if (backgroundKey != null && shader != null) {
      glassLayers = Stack(
        children: [
          Positioned.fill(
            child: BackgroundCaptureWidget(
              width: width ?? double.infinity,
              height: height ?? double.infinity,
              backgroundKey: backgroundKey!,
              shader: shader!,
              borderRadius: boxShape == BoxShape.circle ? BorderRadius.circular(9999) : effectiveRadius,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned.fill(
            child: boxShape == BoxShape.circle
                ? ClipOval(
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: effectiveBlur, sigmaY: effectiveBlur),
                      child: buildDecorationContainer(),
                    ),
                  )
                : ClipRRect(
                    borderRadius: effectiveRadius,
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: effectiveBlur, sigmaY: effectiveBlur),
                      child: buildDecorationContainer(),
                    ),
                  ),
          ),
        ],
      );
    } else {
      glassLayers = boxShape == BoxShape.circle
          ? ClipOval(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: effectiveBlur, sigmaY: effectiveBlur),
                child: buildDecorationContainer(),
              ),
            )
          : ClipRRect(
              borderRadius: effectiveRadius,
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: effectiveBlur, sigmaY: effectiveBlur),
                child: buildDecorationContainer(),
              ),
            );
    }

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Positioned.fill(child: glassLayers),
          if (child != null) Positioned.fill(child: child!),
        ],
      ),
    );
  }
}
