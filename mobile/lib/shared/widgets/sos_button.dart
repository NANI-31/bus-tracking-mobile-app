import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rive/rive.dart';
import 'package:collegebus/core/providers/repository_providers.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/shared/widgets/api_error_modal.dart';
import 'package:collegebus/shared/widgets/success_modal.dart';

class SOSButton extends ConsumerStatefulWidget {
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
  ConsumerState<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends ConsumerState<SOSButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;
  
  StateMachineController? _riveController;
  SMIInput<bool>? _activeInput;

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

  void _onRiveInit(Artboard artboard) {
    _riveController = StateMachineController.fromArtboard(
      artboard,
      'State Machine 1',
    );
    if (_riveController != null) {
      artboard.addController(_riveController!);
      _activeInput = _riveController!.findInput<bool>('active') ?? 
                     _riveController!.findInput<bool>('pressed');
      _activeInput?.value = _isPressed;
    }
  }

  void _reset() {
    _controller.reset();
    setState(() {
      _isPressed = false;
      _activeInput?.value = false;
    });
  }

  Future<void> _triggerSOS() async {
    HapticFeedback.heavyImpact(); // Strong vibration feedback

    if (widget.currentLocation == null) {
      if (mounted) {
        ApiErrorModal.show(
          context: context,
          error: 'Cannot send SOS: Location unknown',
        );
      }
      return;
    }

    try {
      final repo = ref.read(incidentRepositoryProvider);
      await repo.sendSOS(
        busId: widget.busId,
        routeId: widget.routeId,
        lat: widget.currentLocation!.latitude,
        lng: widget.currentLocation!.longitude,
      );

      if (mounted) {
        // Success feedback
        HapticFeedback.mediumImpact();
        SuccessModal.show(
          context: context,
          title: 'SOS Alert Sent',
          message: 'SOS ALERT SENT! Coordinators have been notified.',
          primaryActionText: 'OK',
        );
      }
    } catch (e) {
      if (mounted) {
        ApiErrorModal.show(
          context: context,
          error: 'Failed to send SOS: $e',
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
        setState(() {
          _isPressed = true;
          _activeInput?.value = true;
        });
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
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipOval(
                  child: RiveAnimation.network(
                    'https://cdn.rive.app/animations/vehicles.riv',
                    artboard: 'Truck',
                    fit: BoxFit.cover,
                    onInit: _onRiveInit,
                  ),
                ),
                ClipOval(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.25),
                  ),
                ),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sos_rounded, color: Colors.white, size: 28),
                    Text(
                      'SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
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
                    strokeWidth: 6.0,
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
