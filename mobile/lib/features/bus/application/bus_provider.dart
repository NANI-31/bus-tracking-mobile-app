import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/features/coordinator/domain/assignment_log_model.dart';
import 'package:collegebus/core/providers/repository_providers.dart';
import 'package:collegebus/core/providers/socket_provider.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/core/constants/constants.dart';

/// Bus notifier for managing the list of buses
class BusNotifier extends AsyncNotifier<List<BusModel>> {
  @override
  Future<List<BusModel>> build() async {
    final repo = ref.watch(busRepositoryProvider);
    return await repo.getAllBuses();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }

  // Common operations that update state
  Future<void> createBus(BusModel bus) async {
    final repo = ref.read(busRepositoryProvider);
    await repo.createBus(bus);
    await refresh();
  }

  Future<void> updateBus(String busId, Map<String, dynamic> data) async {
    final repo = ref.read(busRepositoryProvider);
    await repo.updateBus(busId, data);
    ref.read(socketServiceProvider).sendBusListUpdate();
    await refresh();
  }

  Future<void> deleteBus(String busId) async {
    final repo = ref.read(busRepositoryProvider);
    await repo.deleteBus(busId);
    await refresh();
  }
}

/// Provider for the list of buses
final busListProvider = AsyncNotifierProvider<BusNotifier, List<BusModel>>(
  BusNotifier.new,
);

/// StreamProvider for buses in a specific college
final collegeBusesStreamProvider =
    StreamProvider.family<List<BusModel>, String>((ref, collegeId) {
      final repo = ref.watch(busRepositoryProvider);
      final socket = ref.read(socketServiceProvider);

      return Stream.multi((controller) async {
        Future<void> fetch() async {
          try {
            final buses = await repo.getAllBuses();
            final filtered = buses
                .where((b) => b.collegeId == collegeId && b.isActive)
                .toList();
            if (!controller.isClosed) controller.add(filtered);
          } catch (e) {
            if (!controller.isClosed) controller.addError(e);
          }
        }

        await fetch();
        final subscription = socket.busListUpdateStream.listen((_) => fetch());
        controller.onCancel = () => subscription.cancel();
      });
    });

/// StreamProvider for ALL buses in a specific college (including inactive)
final allCollegeBusesStreamProvider =
    StreamProvider.family<List<BusModel>, String>((ref, collegeId) {
      final repo = ref.watch(busRepositoryProvider);
      final socket = ref.read(socketServiceProvider);

      return Stream.multi((controller) async {
        Future<void> fetch() async {
          try {
            final buses = await repo.getAllBuses();
            final filtered = buses
                .where((b) => b.collegeId == collegeId)
                .toList();
            if (!controller.isClosed) controller.add(filtered);
          } catch (e) {
            if (!controller.isClosed) controller.addError(e);
          }
        }

        await fetch();
        final subscription = socket.busListUpdateStream.listen((_) => fetch());
        controller.onCancel = () => subscription.cancel();
      });
    });

/// StreamProvider for bus numbers of a specific college
final busNumbersProvider = StreamProvider.family<List<String>, String>((
  ref,
  collegeId,
) {
  final repo = ref.watch(collegeRepositoryProvider);
  final socket = ref.watch(socketServiceProvider);

  return Stream.multi((controller) async {
    Future<void> fetch() async {
      try {
        final numbers = await repo.getBusNumbers(collegeId);
        if (!controller.isClosed) controller.add(numbers);
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    await fetch();
    final subscription = socket.busListUpdateStream.listen((_) => fetch());
    controller.onCancel = () => subscription.cancel();
  });
});

/// StreamProvider for real-time bus locations in a specific college
final collegeBusLocationsProvider =
    StreamProvider.family<List<BusLocationModel>, String>((ref, collegeId) {
      final socket = ref.read(socketServiceProvider);

      return Stream.multi((controller) async {
        List<BusLocationModel> currentLocations = [];

        final subscription = socket.locationUpdateStream.listen((data) {
          if (data['collegeId'] == collegeId) {
            final busId = data['busId'];
            final newLoc = BusLocationModel.fromMap(data, busId);
            final index = currentLocations.indexWhere((l) => l.busId == busId);
            if (index != -1) {
              currentLocations[index] = newLoc;
            } else {
              currentLocations.add(newLoc);
            }
            if (!controller.isClosed) {
              controller.add(List.from(currentLocations));
            }
          }
        });

        controller.onCancel = () => subscription.cancel();

        final user = ref.read(currentUserProvider);
        final isAuthorized = user != null &&
            user.role != UserRole.student &&
            user.role != UserRole.parent &&
            user.role != UserRole.teacher;

        if (isAuthorized) {
          try {
            final repo = ref.watch(busRepositoryProvider);
            final apiLocations = await repo.getCollegeBusLocations(collegeId);
            currentLocations = List.from(apiLocations);
            if (!controller.isClosed) controller.add(currentLocations);
          } catch (e) {
            // initial fetch error handled by stream
          }
        }
      });
    });

/// StreamProvider for a specific bus location
final busLocationProvider = StreamProvider.family<BusLocationModel?, String>((
  ref,
  busId,
) {
  final repo = ref.watch(busRepositoryProvider);
  final socket = ref.watch(socketServiceProvider);

  return Stream.multi((controller) async {
    try {
      final location = await repo.getBusLocation(busId);
      if (!controller.isClosed) controller.add(location);
    } catch (_) {}

    final subscription = socket.locationUpdateStream.listen((data) {
      if (data['busId'] == busId) {
        controller.add(BusLocationModel.fromMap(data, busId));
      }
    });
    controller.onCancel = () => subscription.cancel();
  });
});

/// Provider for assignment logs of a bus
final busAssignmentLogsProvider =
    FutureProvider.family<List<AssignmentLogModel>, String>((ref, busId) async {
      final repo = ref.watch(busRepositoryProvider);
      return await repo.getAssignmentLogsByBus(busId);
    });

/// StreamProvider for a specific driver's assigned bus
final driverBusProvider = StreamProvider.family<BusModel?, String>((
  ref,
  driverId,
) {
  final socket = ref.watch(socketServiceProvider);

  return Stream.multi((controller) async {
    Future<void> fetch() async {
      try {
        final repo = ref.watch(busRepositoryProvider);
        final bus = await repo.getBusByDriver(driverId);
        if (!controller.isClosed) controller.add(bus);
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    await fetch();
    final sub1 = socket.busListUpdateStream.listen((_) => fetch());
    final sub2 = socket.busUpdateStream.listen((_) => fetch());
    // NEW: Listen for direct notifications to ensure immediate refresh
    final sub3 = socket.notificationStream.listen((data) {
      final type = data['type'] as String?;
      if (type == 'DRIVER_ASSIGNED') {
        fetch();
      }
    });

    controller.onCancel = () {
      sub1.cancel();
      sub2.cancel();
      sub3.cancel();
    };
  });
});

/// StreamProvider for real-time bus locations globally (across all colleges)
final globalBusLocationsProvider =
    StreamProvider<List<BusLocationModel>>((ref) {
      final socket = ref.read(socketServiceProvider);
      final repo = ref.watch(busRepositoryProvider);

      return Stream.multi((controller) async {
        List<BusLocationModel> currentLocations = [];

        final subscription = socket.locationUpdateStream.listen((data) {
          final busId = data['busId'];
          final newLoc = BusLocationModel.fromMap(data, busId);
          final index = currentLocations.indexWhere((l) => l.busId == busId);
          if (index != -1) {
            currentLocations[index] = newLoc;
          } else {
            currentLocations.add(newLoc);
          }
          if (!controller.isClosed) {
            controller.add(List.from(currentLocations));
          }
        });

        controller.onCancel = () => subscription.cancel();

        try {
          // Fetch all buses first
          final buses = await repo.getAllBuses();
          
          // Get unique college IDs
          final collegeIds = buses.map((b) => b.collegeId).toSet().toList();
          
          // Fetch locations in parallel for all colleges
          final locationResults = await Future.wait(
            collegeIds.map((cid) => repo.getCollegeBusLocations(cid))
          );
          
          for (final locs in locationResults) {
            for (final loc in locs) {
              final idx = currentLocations.indexWhere((l) => l.busId == loc.busId);
              if (idx != -1) {
                currentLocations[idx] = loc;
              } else {
                currentLocations.add(loc);
              }
            }
          }
          
          if (!controller.isClosed) controller.add(List.from(currentLocations));
        } catch (e) {
          // Fallback if initial fetch fails; rely solely on live socket stream
        }
      });
    });
/// Pre-computed set of live bus IDs for a college (P1.1 perf fix).
///
/// Derived from [collegeBusLocationsProvider] so it is updated by the socket
/// stream. Using a [Provider] (not a [StreamProvider]) here means Riverpod
/// will memoize the result and only propagate a change when the Set value
/// actually differs \u2014 preventing downstream widgets from rebuilding on every
/// GPS tick when the set of active bus IDs has NOT changed.
///
/// Widgets that only need to know "which buses are live" should watch this
/// instead of [collegeBusLocationsProvider] to avoid unnecessary rebuilds.
final studentLiveBusIdsProvider =
    Provider.family<Set<String>, String>((ref, collegeId) {
      final liveLocations =
          ref.watch(collegeBusLocationsProvider(collegeId)).valueOrNull ?? [];
      return liveLocations.map((loc) => loc.busId).toSet();
    });
