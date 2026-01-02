import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:collegebus/services/data_service.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:velocity_x/velocity_x.dart';

class SOSButton extends StatefulWidget {
  final LatLng? currentLocation;
  final String? busId;
  final String? routeId;

  const SOSButton({
    super.key,
    required this.currentLocation,
    this.busId,
    this.routeId,
  });

  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _triggerSOS();
        _reset();
      }
    });
  }

  void _reset() {
    _controller.reset();
    setState(() => _isPressed = false);
  }

  Future<void> _triggerSOS() async {
    HapticFeedback.heavyImpact(); // Strong vibration feedback

    if (widget.currentLocation == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot send SOS: Location unknown')),
        );
      }
      return;
    }

    try {
      final dataService = Provider.of<DataService>(context, listen: false);
      await dataService.sendSOS(
        busId: widget.busId,
        routeId: widget.routeId,
        lat: widget.currentLocation!.latitude,
        lng: widget.currentLocation!.longitude,
      );

      if (mounted) {
        // Success feedback
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'SOS ALERT SENT! Coordinators have been notified.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send SOS: $e'),
            backgroundColor: Colors.black,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
        HapticFeedback.selectionClick();
      },
      onTapUp: (_) => _reset(),
      onTapCancel: () => _reset(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse/Background Effect
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isPressed ? 90 : 80,
            height: _isPressed ? 90 : 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.error.withValues(alpha: 0.3),
            ),
          ),
          // Actual Button
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.error,
              boxShadow: [
                BoxShadow(
                  color: AppColors.error.withValues(alpha: 0.4),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sos_rounded, color: Colors.white, size: 32),
                Text(
                  'SOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Progress Indicator Ring
          if (_isPressed)
            SizedBox(
              width: 86,
              height: 86,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CircularProgressIndicator(
                    value: _controller.value,
                    strokeWidth: 6,
                    color: Colors.white,
                    backgroundColor: Colors.transparent,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
