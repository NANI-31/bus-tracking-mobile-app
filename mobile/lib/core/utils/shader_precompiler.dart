import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class ShaderPrecompiler {
  static final Map<String, ui.FragmentProgram> _cache = {};

  static final List<String> shaderAssets = [
    'shaders/liquid_glass.frag',
    'shaders/shimmer.frag',
    'shaders/refraction.frag',
    'shaders/liquid_glass_lens.frag',
  ];

  static Future<void> precompileAll() async {
    debugPrint('ShaderPrecompiler: Starting shader pre-compilation...');
    final List<Future<void>> compileTasks = [];

    for (final asset in shaderAssets) {
      compileTasks.add(
        ui.FragmentProgram.fromAsset(asset).then((program) {
          _cache[asset] = program;
          debugPrint('ShaderPrecompiler: Pre-compiled $asset successfully.');
        }).catchError((e) {
          debugPrint('ShaderPrecompiler: Failed to pre-compile $asset: $e');
        }),
      );
    }

    await Future.wait(compileTasks);
    debugPrint('ShaderPrecompiler: All shaders pre-compiled.');
  }

  static ui.FragmentProgram? getProgram(String assetPath) {
    return _cache[assetPath];
  }

  static bool hasProgram(String assetPath) => _cache.containsKey(assetPath);
}
