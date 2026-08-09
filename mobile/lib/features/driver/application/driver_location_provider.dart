import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DriverLocationState {
  final LatLng? currentLocation;
  final double heading;
  final double speed;
  final String? nextStopETA;
  final bool isSharing;
  final int? offRouteDistance;

  /// True when a teacher location override is active and the driver's GPS
  /// emission has been paused. [isSharing] remains true during the pause so
  /// that auto-resume works when the override ends.
  final bool isOverridePaused;

  const DriverLocationState({
    this.currentLocation,
    this.heading = 0.0,
    this.speed = 0.0,
    this.nextStopETA,
    this.isSharing = false,
    this.offRouteDistance,
    this.isOverridePaused = false,
  });

  DriverLocationState copyWith({
    LatLng? currentLocation,
    double? heading,
    double? speed,
    String? nextStopETA,
    bool? isSharing,
    int? offRouteDistance,
    bool clearOffRoute = false,
    bool? isOverridePaused,
  }) {
    return DriverLocationState(
      currentLocation: currentLocation ?? this.currentLocation,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
      nextStopETA: nextStopETA ?? this.nextStopETA,
      isSharing: isSharing ?? this.isSharing,
      offRouteDistance: clearOffRoute ? null : (offRouteDistance ?? this.offRouteDistance),
      isOverridePaused: isOverridePaused ?? this.isOverridePaused,
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
    state = state.copyWith(
      isSharing: sharing,
      clearOffRoute: !sharing,
      // Clear override pause when sharing is fully stopped (e.g. logout / trip end)
      isOverridePaused: sharing ? null : false,
    );
  }

  /// Pauses or resumes GPS emission due to a teacher override.
  /// Does NOT change [isSharing] so the driver's session stays alive.
  void updateOverridePaused(bool paused) {
    state = state.copyWith(isOverridePaused: paused);
  }

  void updateOffRouteDistance(int? distance) {
    if (distance == null) {
      state = state.copyWith(clearOffRoute: true);
    } else {
      state = state.copyWith(offRouteDistance: distance);
    }
  }

  void clear() {
    state = const DriverLocationState();
  }
}


final driverLocationProvider =
    StateNotifierProvider<DriverLocationNotifier, DriverLocationState>((ref) {
  return DriverLocationNotifier();
});
