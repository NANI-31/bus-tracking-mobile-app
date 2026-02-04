import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/features/bus/application/bus_provider.dart';
import 'package:collegebus/features/route/application/route_provider.dart';
import 'package:collegebus/features/route/domain/route_model.dart';
import 'package:collegebus/features/notification/services/notification_service.dart';
import 'package:collegebus/core/utils/app_logger.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'dart:async';

/// Notifier that monitors bus proximity and triggers alerts
class ProximityNotifier extends AsyncNotifier<void> {
  final Set<String> _notifiedKeys = {};

  @override
  FutureOr<void> build() {
    final user = ref.watch(currentUserProvider);
    if (user == null || user.collegeId.isEmpty) return null;

    final collegeId = user.collegeId;
    final preferredStop = user.preferredStop;

    // Watch bus locations
    final locationsAsync = ref.watch(collegeBusLocationsProvider(collegeId));
    // Watch routes
    final routesAsync = ref.watch(collegeRoutesProvider(collegeId));
    // Watch buses (to resolve numbers)
    final busesAsync = ref.watch(busListProvider);

    if (preferredStop == null) return null;

    locationsAsync.whenData((locations) {
      routesAsync.whenData((routes) {
        busesAsync.whenData((buses) {
          _checkProximity(
            locations,
            routes,
            buses,
            preferredStop,
            user.isPremium,
          );
        });
      });
    });

    return null;
  }

  void _checkProximity(
    List<BusLocationModel> locations,
    List<RouteModel> routes,
    List<BusModel> buses,
    String preferredStop,
    bool isPremium,
  ) {
    // Only Premium users go Proximity Alerts
    if (!isPremium) return;

    for (final loc in locations) {
      // Find the bus details to get its routeId
      final bus = buses.firstWhere(
        (b) => b.id == loc.busId,
        orElse: () => buses.firstWhere(
          (b) => b.busNumber == loc.busId,
          orElse: () => BusModel(
            id: '',
            busNumber: '',
            driverId: '',
            collegeId: '',
            createdAt: DateTime.now(),
          ),
        ),
      );

      if (bus.id.isEmpty) continue;
      final routeId = bus.routeId;
      if (routeId == null) continue;

      // Find the specific route for this bus
      final route = routes.firstWhere(
        (r) => r.id == routeId,
        orElse: () => routes[0],
      ); // Fallback or strict?

      // Double check if user's preferred stop is in this specific bus's route
      final allStops = [route.startPoint, ...route.stopPoints, route.endPoint];

      final userStopIndex = allStops.indexWhere((s) => s.name == preferredStop);
      if (userStopIndex == -1) continue;

      // Target stop is 2 stops before
      final targetStopIndex = userStopIndex - 2;
      if (targetStopIndex < 0) continue;

      final targetStop = allStops[targetStopIndex];

      // Calculate distance
      final distance = Geolocator.distanceBetween(
        loc.currentLocation.latitude,
        loc.currentLocation.longitude,
        targetStop.lat,
        targetStop.lng,
      );

      // Threshold: 300 meters
      if (distance < 300) {
        final today = DateTime.now().toIso8601String().split('T')[0];
        final notificationKey = '${today}_${loc.busId}_$targetStopIndex';

        if (!_notifiedKeys.contains(notificationKey)) {
          _notifiedKeys.add(notificationKey);

          final busDisplay = bus.busNumber.isNotEmpty
              ? bus.busNumber
              : 'Your bus';

          AppLogger.i(
            'Proximity Alert: Bus $busDisplay reached 2 stops before $preferredStop',
          );

          NotificationService.showProximityAlert(
            busNumber: busDisplay,
            stopName: preferredStop,
          );
        }
      }
    }
  }
}

final proximityAlertProvider = AsyncNotifierProvider<ProximityNotifier, void>(
  ProximityNotifier.new,
);
