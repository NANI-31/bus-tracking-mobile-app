import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DriverLocationState {
  final LatLng? currentLocation;
  final double heading;
  final double speed;
  final String? nextStopETA;
  final bool isSharing;

  const DriverLocationState({
    this.currentLocation,
    this.heading = 0.0,
    this.speed = 0.0,
    this.nextStopETA,
    this.isSharing = false,
  });

  DriverLocationState copyWith({
    LatLng? currentLocation,
    double? heading,
    double? speed,
    String? nextStopETA,
    bool? isSharing,
  }) {
    return DriverLocationState(
      currentLocation: currentLocation ?? this.currentLocation,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
      nextStopETA: nextStopETA ?? this.nextStopETA,
      isSharing: isSharing ?? this.isSharing,
    );
  }
}

class DriverLocationNotifier extends StateNotifier<DriverLocationState> {
  DriverLocationNotifier() : super(const DriverLocationState());

  void updateLocation(LatLng location, {double heading = 0.0, double speed = 0.0}) {
    state = state.copyWith(
      currentLocation: location,
      heading: heading,
      speed: speed,
    );
  }

  void updateETA(String? eta) {
    state = state.copyWith(nextStopETA: eta);
  }

  void updateSharing(bool sharing) {
    state = state.copyWith(isSharing: sharing);
  }

  void clear() {
    state = const DriverLocationState();
  }
}

final driverLocationProvider =
    StateNotifierProvider<DriverLocationNotifier, DriverLocationState>((ref) {
  return DriverLocationNotifier();
});
