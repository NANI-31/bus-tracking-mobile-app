import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collegebus/core/services/persistence_service.dart';
import 'package:collegebus/features/student/application/map_navigation_provider.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/features/route/domain/route_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MapNavigationNotifier Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'map_lat': 16.1234,
        'map_lng': 80.5678,
        'map_zoom': 15.0,
        'selected_bus_id': 'bus_123',
      });
      await PersistenceService.init();
    });

    test('initial state restores from PersistenceService', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(mapNavigationProvider);

      expect(state.centerLocation, isNotNull);
      expect(state.centerLocation!.latitude, closeTo(16.1234, 0.0001));
      expect(state.centerLocation!.longitude, closeTo(80.5678, 0.0001));
      expect(state.zoom, 15.0);
      expect(state.isFollowing, isTrue);
    });

    test('updateCamera updates state and PersistenceService', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(mapNavigationProvider.notifier);
      const target = LatLng(17.5555, 78.4444);
      notifier.updateCamera(target, 14.5);

      final state = container.read(mapNavigationProvider);
      expect(state.centerLocation, target);
      expect(state.zoom, 14.5);

      expect(PersistenceService.getDouble('map_lat'), 17.5555);
      expect(PersistenceService.getDouble('map_lng'), 78.4444);
      expect(PersistenceService.getDouble('map_zoom'), 14.5);
    });

    test('updateUserLocation sets center if null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Reset PersistenceService values so centerLocation builds as null
      SharedPreferences.setMockInitialValues({});
      PersistenceService.init();

      final emptyContainer = ProviderContainer();
      addTearDown(emptyContainer.dispose);

      var state = emptyContainer.read(mapNavigationProvider);
      expect(state.centerLocation, isNull);

      const userLoc = LatLng(16.9999, 80.9999);
      emptyContainer.read(mapNavigationProvider.notifier).updateUserLocation(userLoc);

      state = emptyContainer.read(mapNavigationProvider);
      expect(state.centerLocation, userLoc);
    });

    test('selectBus updates bus and activeRoute', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(mapNavigationProvider.notifier);
      final mockBus = BusModel(
        id: 'bus_999',
        busNumber: 'MH-12-3456',
        driverId: 'driver_abc',
        collegeId: 'college_abc',
        status: 'running',
        assignmentStatus: 'accepted',
        capacity: 40,
        createdAt: DateTime.now(),
      );
      final mockRoute = RouteModel(
        id: 'route_777',
        routeName: 'Route 1',
        routeType: 'pickup',
        startPoint: RoutePoint(name: 'Start', lat: 12.0, lng: 77.0),
        endPoint: RoutePoint(name: 'End', lat: 12.1, lng: 77.1),
        stopPoints: [],
        collegeId: 'college_abc',
        createdBy: 'admin',
        isActive: true,
        createdAt: DateTime.now(),
      );

      notifier.selectBus(mockBus, mockRoute);

      final state = container.read(mapNavigationProvider);
      expect(state.selectedBus, mockBus);
      expect(state.activeRoute, mockRoute);
      expect(state.isFollowing, isTrue);

      expect(PersistenceService.getSelectedBusId(), 'bus_999');
    });

    test('clearFilters resets selections and clears PersistenceService', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(mapNavigationProvider.notifier);
      notifier.updateFilters(
        selectedRouteType: () => 'pickup',
        selectedBusNumber: () => '12',
        selectedStop: () => 'Library',
      );

      notifier.clearFilters();

      final state = container.read(mapNavigationProvider);
      expect(state.selectedBus, isNull);
      expect(state.activeRoute, isNull);
      expect(state.selectedRouteType, isNull);
      expect(state.selectedBusNumber, isNull);
      expect(state.selectedStop, isNull);

      expect(PersistenceService.getSelectedBusId(), isNull);
    });
  });
}
