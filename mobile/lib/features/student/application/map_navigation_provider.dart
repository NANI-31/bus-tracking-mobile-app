import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/features/route/domain/route_model.dart';
import 'package:collegebus/core/services/persistence_service.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/features/bus/application/bus_provider.dart';
import 'package:collegebus/features/route/application/route_provider.dart';

class MapNavigationState {
  final LatLng? centerLocation;
  final double zoom;
  final BusModel? selectedBus;
  final RouteModel? activeRoute;
  final String? selectedRouteType;
  final String? selectedBusNumber;
  final String? selectedStop;
  final bool isFollowing;

  const MapNavigationState({
    this.centerLocation,
    this.zoom = 17.0,
    this.selectedBus,
    this.activeRoute,
    this.selectedRouteType,
    this.selectedBusNumber,
    this.selectedStop,
    this.isFollowing = true,
  });

  MapNavigationState copyWith({
    LatLng? Function()? centerLocation,
    double? zoom,
    BusModel? Function()? selectedBus,
    RouteModel? Function()? activeRoute,
    String? Function()? selectedRouteType,
    String? Function()? selectedBusNumber,
    String? Function()? selectedStop,
    bool? isFollowing,
  }) {
    return MapNavigationState(
      centerLocation: centerLocation != null ? centerLocation() : this.centerLocation,
      zoom: zoom ?? this.zoom,
      selectedBus: selectedBus != null ? selectedBus() : this.selectedBus,
      activeRoute: activeRoute != null ? activeRoute() : this.activeRoute,
      selectedRouteType: selectedRouteType != null ? selectedRouteType() : this.selectedRouteType,
      selectedBusNumber: selectedBusNumber != null ? selectedBusNumber() : this.selectedBusNumber,
      selectedStop: selectedStop != null ? selectedStop() : this.selectedStop,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}

class MapNavigationNotifier extends Notifier<MapNavigationState> {
  @override
  MapNavigationState build() {
    final double? savedLat = PersistenceService.getDouble('map_lat');
    final double? savedLng = PersistenceService.getDouble('map_lng');
    final double? savedZoom = PersistenceService.getDouble('map_zoom');
    
    LatLng? initialCenter;
    if (savedLat != null && savedLng != null) {
      initialCenter = LatLng(savedLat, savedLng);
    }

    // Listen to college buses stream provider to reactively validate/clear selection
    final user = ref.watch(currentUserProvider);
    final collegeId = user?.collegeId;
    if (collegeId != null) {
      ref.listen(collegeBusesStreamProvider(collegeId), (previous, next) {
        final buses = next.valueOrNull;
        if (buses != null && state.selectedBus != null) {
          final selectedBusId = state.selectedBus!.id;
          final updatedBus = buses.cast<BusModel?>().firstWhere(
            (b) => b!.id == selectedBusId,
            orElse: () => null,
          );
          if (updatedBus == null || updatedBus.assignmentStatus != 'accepted') {
            selectBus(null, null);
          } else if (updatedBus.routeId != state.selectedBus!.routeId ||
                     updatedBus.assignmentStatus != state.selectedBus!.assignmentStatus ||
                     updatedBus.status != state.selectedBus!.status) {
            // Update selected bus details if they changed
            final targetRouteId = updatedBus.routeId ?? updatedBus.defaultRouteId;
            final routes = ref.read(collegeRoutesProvider(collegeId)).valueOrNull ?? [];
            final newActiveRoute = targetRouteId != null
                ? routes.cast<RouteModel?>().firstWhere(
                    (r) => r!.id == targetRouteId,
                    orElse: () => null,
                  )
                : null;
            state = state.copyWith(
              selectedBus: () => updatedBus,
              activeRoute: () => newActiveRoute,
            );
          }
        }
      });
    }

    return MapNavigationState(
      centerLocation: initialCenter,
      zoom: savedZoom ?? 17.0,
      isFollowing: true,
    );
  }

  void updateCamera(LatLng center, double zoom) {
    state = state.copyWith(
      centerLocation: () => center,
      zoom: zoom,
    );
    PersistenceService.setDouble('map_lat', center.latitude);
    PersistenceService.setDouble('map_lng', center.longitude);
    PersistenceService.setDouble('map_zoom', zoom);
  }

  void updateUserLocation(LatLng userLoc) {
    if (state.centerLocation == null) {
      state = state.copyWith(centerLocation: () => userLoc);
    }
  }

  void selectBus(BusModel? bus, RouteModel? route) {
    state = state.copyWith(
      selectedBus: () => bus,
      activeRoute: () => route,
      isFollowing: true,
    );
    final user = ref.read(currentUserProvider);
    if (bus != null) {
      PersistenceService.setSelectedBusId(bus.id, user?.id);
    } else {
      PersistenceService.removeSelectedBusId(user?.id);
    }
  }

  void updateFilters({
    String? Function()? selectedRouteType,
    String? Function()? selectedBusNumber,
    String? Function()? selectedStop,
  }) {
    state = state.copyWith(
      selectedRouteType: selectedRouteType,
      selectedBusNumber: selectedBusNumber,
      selectedStop: selectedStop,
    );
  }

  void clearFilters() {
    state = state.copyWith(
      selectedStop: () => null,
      selectedBusNumber: () => null,
      selectedRouteType: () => null,
      selectedBus: () => null,
      activeRoute: () => null,
    );
    final user = ref.read(currentUserProvider);
    PersistenceService.removeSelectedBusId(user?.id);
  }

  void setFollowing(bool following) {
    state = state.copyWith(isFollowing: following);
  }
}

final mapNavigationProvider = NotifierProvider<MapNavigationNotifier, MapNavigationState>(
  MapNavigationNotifier.new,
);
