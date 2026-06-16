import 'package:flutter/material.dart';
import 'package:liquid_glass/background_capture_widget.dart';
import 'package:liquid_glass/liquid_glass_lens_shader.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liquid Glass Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const BackgroundCaptureDemo(),
    );
  }
}

class BackgroundCaptureDemo extends StatefulWidget {
  const BackgroundCaptureDemo({super.key});

  @override
  State<BackgroundCaptureDemo> createState() => _BackgroundCaptureDemoState();
}

class _BackgroundCaptureDemoState extends State<BackgroundCaptureDemo>
    with TickerProviderStateMixin {
  final GlobalKey backgroundKey = GlobalKey();
  late LiquidGlassLensShader liquidGlassLensShader = LiquidGlassLensShader()
    ..initialize();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildStaticImageBackground(),
    );
  }

  Widget _buildStaticImageBackground() {
    return Stack(
      children: [
        RepaintBoundary(
          key: backgroundKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Image.asset(
                  'assets/images/sample_1.png',
                  fit: BoxFit.cover,
                ),
                Image.asset(
                  'assets/images/sample_2.jpg',
                  fit: BoxFit.cover,
                ),
                Image.asset(
                  'assets/images/sample_3.jpg',
                  fit: BoxFit.cover,
                ),
              ],
            ),
          ),
        ),
        BackgroundCaptureWidget(
          width: 160,
          height: 160,
          initialPosition: Offset(0, 0),
          backgroundKey: backgroundKey,
          shader: liquidGlassLensShader,
          child: Center(
            child: Image.asset(
              'assets/images/photo.png',
              width: 72,
              height: 72,
            ),
          ),
        ),
      ],
    );
  }
}
