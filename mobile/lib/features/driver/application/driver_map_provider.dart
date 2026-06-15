import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/route/domain/route_model.dart';
import 'package:collegebus/core/services/directions_service.dart';
import 'package:collegebus/core/services/directions_result.dart';

class DriverMapState {
  final RouteModel? selectedRoute;
  final DirectionsResult? directionsResult;
  final String? loadedRouteId;
  final bool isLoading;

  const DriverMapState({
    this.selectedRoute,
    this.directionsResult,
    this.loadedRouteId,
    this.isLoading = false,
  });

  DriverMapState copyWith({
    RouteModel? Function()? selectedRoute,
    DirectionsResult? Function()? directionsResult,
    String? Function()? loadedRouteId,
    bool? isLoading,
  }) {
    return DriverMapState(
      selectedRoute: selectedRoute != null ? selectedRoute() : this.selectedRoute,
      directionsResult: directionsResult != null ? directionsResult() : this.directionsResult,
      loadedRouteId: loadedRouteId != null ? loadedRouteId() : this.loadedRouteId,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class DriverMapNotifier extends StateNotifier<DriverMapState> {
  DriverMapNotifier() : super(const DriverMapState());

  final _directionsService = DirectionsService();

  Future<void> loadRouteOverlay(RouteModel route) async {
    if (state.loadedRouteId == route.id) return;
    
    state = state.copyWith(
      isLoading: true,
      selectedRoute: () => route,
    );

    try {
      final result = await _directionsService.getDirectionsForRoute(route);
      state = state.copyWith(
        directionsResult: () => result,
        loadedRouteId: () => route.id,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(
        directionsResult: () => null,
        loadedRouteId: () => null,
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
