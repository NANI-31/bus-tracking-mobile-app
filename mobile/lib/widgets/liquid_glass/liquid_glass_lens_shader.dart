import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'base_shader.dart';

class LiquidGlassLensShader extends BaseShader {
  LiquidGlassLensShader()
    : super(shaderAssetPath: 'shaders/liquid_glass_lens.frag');

  @override
  void updateShaderUniforms({
    required double width,
    required double height,
    required ui.Image? backgroundImage,
    double devicePixelRatio = 1.0,
  }) {
    if (!isLoaded) return;

    // FlutterFragCoord() returns LOGICAL pixel coordinates, so uResolution must
    // also be in logical pixels. The texture's UV space (0→1) maps to the
    // full image regardless of its physical-pixel count, so we do NOT
    // multiply by devicePixelRatio here.
    shader.setFloat(0, width);
    shader.setFloat(1, height);

    // Center the lens effect on the widget (logical coords)
    shader.setFloat(2, width / 2);
    shader.setFloat(3, height / 2);

    // Lens size – 10.0 fills the full UV (0→1) space on a wide nav bar.
    // With the aspect-ratio correction removed from the shader, the lens
    // envelope now fits the bar shape; effectRadius=5 → sizeMultiplier=0.04
    // → baseIntensity=4, which means roundedBox must be < 0.25 for the lens
    // to fire. At the bar corners (m2≈(±0.5, ±0.5)) roundedBox≈0.125 < 0.25 ✓
    shader.setFloat(4, 10.0);

    // Blur intensity – 0 keeps it purely refractive (sharp, iOS-like)
    shader.setFloat(5, 0.2);

    // Chromatic aberration / dispersion strength
    shader.setFloat(6, 0.1);

    // Set background texture (sampler index 0)
    if (backgroundImage != null &&
        backgroundImage.width > 0 &&
        backgroundImage.height > 0) {
      try {
        shader.setImageSampler(0, backgroundImage);
      } catch (e) {
        debugPrint('Error setting background texture: $e');
      }
    }
  }
}
