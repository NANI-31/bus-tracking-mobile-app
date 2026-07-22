import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/route/domain/route_model.dart';
import 'package:collegebus/core/services/directions_service.dart';
import 'package:collegebus/core/services/directions_result.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Builds a lightweight content fingerprint from the route's stop coordinates.
// The ID alone is not enough — when a coordinator edits stop points the ID
// is unchanged but the geometry is different.  Including all lat/lng values
// means any coordinate change invalidates the cached DirectionsResult.
// ─────────────────────────────────────────────────────────────────────────────
String _routeFingerprint(RouteModel route) {
  final buffer = StringBuffer(route.id);
  buffer.write('|${route.startPoint.lat},${route.startPoint.lng}');
  for (final s in route.stopPoints) {
    buffer.write('|${s.lat},${s.lng}');
  }
  buffer.write('|${route.endPoint.lat},${route.endPoint.lng}');
  return buffer.toString();
}

class DriverMapState {
  final RouteModel? selectedRoute;
  final DirectionsResult? directionsResult;
  // Kept for backward-compat; also used to detect same-ID re-assignments.
  final String? loadedRouteId;
  // Content-aware cache key: invalidated whenever stop coordinates change.
  final String? loadedRouteFingerprint;
  final bool isLoading;

  const DriverMapState({
    this.selectedRoute,
    this.directionsResult,
    this.loadedRouteId,
    this.loadedRouteFingerprint,
    this.isLoading = false,
  });

  DriverMapState copyWith({
    RouteModel? Function()? selectedRoute,
    DirectionsResult? Function()? directionsResult,
    String? Function()? loadedRouteId,
    String? Function()? loadedRouteFingerprint,
    bool? isLoading,
  }) {
    return DriverMapState(
      selectedRoute: selectedRoute != null ? selectedRoute() : this.selectedRoute,
      directionsResult: directionsResult != null ? directionsResult() : this.directionsResult,
      loadedRouteId: loadedRouteId != null ? loadedRouteId() : this.loadedRouteId,
      loadedRouteFingerprint: loadedRouteFingerprint != null
          ? loadedRouteFingerprint()
          : this.loadedRouteFingerprint,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class DriverMapNotifier extends StateNotifier<DriverMapState> {
  DriverMapNotifier() : super(const DriverMapState());

  final _directionsService = DirectionsService();

  Future<void> loadRouteOverlay(RouteModel route) async {
    final fingerprint = _routeFingerprint(route);

    // Skip only when BOTH the ID and all coordinates are identical to the
    // last successful fetch.  Editing any stop point changes the fingerprint
    // and forces a fresh Directions API call even for the same route ID.
    if (state.loadedRouteFingerprint == fingerprint) return;

    state = state.copyWith(
      isLoading: true,
      selectedRoute: () => route,
    );

    try {
      final result = await _directionsService.getDirectionsForRoute(route);
      state = state.copyWith(
        directionsResult: () => result,
        loadedRouteId: () => route.id,
        loadedRouteFingerprint: () => fingerprint,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(
        directionsResult: () => null,
        loadedRouteId: () => null,
        loadedRouteFingerprint: () => null,
        isLoading: false,
      );
    }
  }

  void setSelectedRoute(RouteModel? route) {
    if (route == null) {
      clear();
    } else {
      state = state.copyWith(selectedRoute: () => route);
      loadRouteOverlay(route);
    }
  }

  void clear() {
    state = const DriverMapState();
  }
}

final driverMapStateProvider =
    StateNotifierProvider<DriverMapNotifier, DriverMapState>((ref) {
  return DriverMapNotifier();
});
