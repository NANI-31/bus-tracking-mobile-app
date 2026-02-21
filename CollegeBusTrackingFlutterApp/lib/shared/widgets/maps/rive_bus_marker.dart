import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

enum RiveTripStatus { idle, active, alert }

class RiveBusMarker extends StatefulWidget {
  final double rotation;
  final bool isMoving;
  final double speed;
  final RiveTripStatus status;
  final String? riveAsset;
  final String? artboard;

  const RiveBusMarker({
    super.key,
    required this.rotation,
    this.isMoving = false,
    this.speed = 0.0,
    this.status = RiveTripStatus.idle,
    this.riveAsset,
    this.artboard,
  });

  @override
  State<RiveBusMarker> createState() => _RiveBusMarkerState();
}

class _RiveBusMarkerState extends State<RiveBusMarker> {
  StateMachineController? _controller;
  SMIInput<bool>? _movingInput;
  SMIInput<double>? _speedInput;
  SMIInput<double>? _statusInput;

  void _onRiveInit(Artboard artboard) {
    _controller = StateMachineController.fromArtboard(
      artboard,
      'State Machine 1',
    );
    if (_controller != null) {
      artboard.addController(_controller!);
      _movingInput = _controller!.findInput<bool>('active');
      _speedInput = _controller!.findInput<double>('speed');
      _statusInput = _controller!.findInput<double>('status');

      _movingInput?.value = widget.isMoving;
      _speedInput?.value = widget.speed;
      _statusInput?.value = widget.status.index.toDouble();
    }
  }

  @override
  void didUpdateWidget(RiveBusMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isMoving != widget.isMoving) {
      _movingInput?.value = widget.isMoving;
    }
    if (oldWidget.speed != widget.speed) {
      _speedInput?.value = widget.speed;
    }
    if (oldWidget.status != widget.status) {
      _statusInput?.value = widget.status.index.toDouble();
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
    final asset =
        widget.riveAsset ?? 'https://cdn.rive.app/animations/vehicles.riv';
    // Use custom artboard or try to find a themed version
    final board = widget.artboard ?? (isDark ? 'Truck_Dark' : 'Truck');

    return Transform.rotate(
      angle: widget.rotation * 3.14159 / 180,
      child: SizedBox(
        width: 60,
        height: 60,
        child: asset.startsWith('http')
            ? RiveAnimation.network(
                asset,
                artboard: board,
                fit: BoxFit.contain,
                onInit: _onRiveInit,
              )
            : RiveAnimation.asset(
                asset,
                artboard: board,
                fit: BoxFit.contain,
                onInit: _onRiveInit,
              ),
      ),
    );
  }
}
