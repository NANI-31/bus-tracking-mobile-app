import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class RiveSosIndicator extends StatelessWidget {
  final double size;
  final Color? color;
  final String? riveAsset;
  final String? artboard;

  const RiveSosIndicator({
    super.key,
    this.size = 24.0,
    this.color,
    this.riveAsset,
    this.artboard,
  });

  @override
  Widget build(BuildContext context) {
    // Default to the vehicles demo if none provided, or a generic pulse if we had one.
    final asset = riveAsset ?? 'https://cdn.rive.app/animations/vehicles.riv';
    final board = artboard ?? 'Truck';

    return SizedBox(
      width: size,
      height: size,
      child: asset.startsWith('http')
          ? RiveAnimation.network(
              asset,
              artboard: board,
              fit: BoxFit.contain,
              // We could add state machine logic here if the asset has one
            )
          : RiveAnimation.asset(asset, artboard: board, fit: BoxFit.contain),
    );
  }
}
