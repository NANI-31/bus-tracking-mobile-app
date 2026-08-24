import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/features/coordinator/domain/assignment_log_model.dart';
import 'package:collegebus/core/providers/repository_providers.dart';
import 'package:collegebus/core/providers/socket_provider.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';

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
        final subscription1 = socket.busListUpdateStream.listen((_) => fetch());
        final subscription2 = socket.busUpdateStream.listen((_) => fetch());
        
        controller.onCancel = () {
          subscription1.cancel();
          subscription2.cancel();
        };
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

/// In-memory cache of the latest locations for each bus (keyed by busId),
/// to ensure that when providers are remounted (e.g. on tab switches),
/// the last known positions are delivered immediately rather than waiting for the next socket tick.
final Map<String, BusLocationModel> _lastKnownLocations = {};

/// StreamProvider for real-time bus locations in a specific college
final collegeBusLocationsProvider =
    StreamProvider.family<List<BusLocationModel>, String>((ref, collegeId) {
      final socket = ref.read(socketServiceProvider);

      return Stream.multi((controller) async {
        // Pre-seed from cache if available to prevent blank screens/flashing on tab switch
        List<BusLocationModel> currentLocations = _lastKnownLocations.values
            .where((loc) => loc.collegeId == collegeId)
            .toList();

        if (currentLocations.isNotEmpty && !controller.isClosed) {
          controller.add(List.from(currentLocations));
        }

        final sub1 = socket.locationUpdateStream.listen((data) {
          if (data['collegeId'] == collegeId) {
            final busId = data['busId'];
            final newLoc = BusLocationModel.fromMap(data, busId);

            // Cache the location
            _lastKnownLocations[busId] = newLoc;

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

        final sub2 = socket.busUpdateStream.listen((data) {
          final busId = data['id'] ?? data['busId'];
          final status = data['status'];
          if (status == 'not-running') {
            _lastKnownLocations.remove(busId);
            currentLocations.removeWhere((l) => l.busId == busId);
            if (!controller.isClosed) {
              controller.add(List.from(currentLocations));
            }
          }
        });

        controller.onCancel = () {
          sub1.cancel();
          sub2.cancel();
        };

        final user = ref.read(currentUserProvider);
        final isAuthorized = user != null;

        if (isAuthorized) {
          try {
            final repo = ref.watch(busRepositoryProvider);
            final apiLocations = await repo.getCollegeBusLocations(collegeId);
            currentLocations = List.from(apiLocations);

            // Update cache with REST API fetched locations
            for (final loc in apiLocations) {
              _lastKnownLocations[loc.busId] = loc;
            }

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
    // Deliver cached location immediately
    if (_lastKnownLocations.containsKey(busId)) {
      if (!controller.isClosed) controller.add(_lastKnownLocations[busId]);
    }

    try {
      final location = await repo.getBusLocation(busId);
      if (location != null) {
        _lastKnownLocations[busId] = location;
      }
      if (!controller.isClosed) controller.add(location);
    } catch (_) {}

    final sub1 = socket.locationUpdateStream.listen((data) {
      if (data['busId'] == busId) {
        final newLoc = BusLocationModel.fromMap(data, busId);
        _lastKnownLocations[busId] = newLoc;
        if (!controller.isClosed) controller.add(newLoc);
      }
    });

    final sub2 = socket.busUpdateStream.listen((data) {
      final id = data['id'] ?? data['busId'];
      final status = data['status'];
      if (id == busId && status == 'not-running') {
        _lastKnownLocations.remove(busId);
        if (!controller.isClosed) controller.add(null);
      }
    });

    controller.onCancel = () {
      sub1.cancel();
      sub2.cancel();
    };
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
        // Pre-seed from cache if available
        List<BusLocationModel> currentLocations = _lastKnownLocations.values.toList();

        if (currentLocations.isNotEmpty && !controller.isClosed) {
          controller.add(List.from(currentLocations));
        }

        final sub1 = socket.locationUpdateStream.listen((data) {
          final busId = data['busId'];
          final newLoc = BusLocationModel.fromMap(data, busId);

          // Update cache
          _lastKnownLocations[busId] = newLoc;

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

        final sub2 = socket.busUpdateStream.listen((data) {
          final busId = data['id'] ?? data['busId'];
          final status = data['status'];
          if (status == 'not-running') {
            _lastKnownLocations.remove(busId);
            currentLocations.removeWhere((l) => l.busId == busId);
            if (!controller.isClosed) {
              controller.add(List.from(currentLocations));
            }
          }
        });

        controller.onCancel = () {
          sub1.cancel();
          sub2.cancel();
        };

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
              // Update cache
              _lastKnownLocations[loc.busId] = loc;

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
/// actually differs — preventing downstream widgets from rebuilding on every
/// GPS tick when the set of active bus IDs has NOT changed.
///
/// Widgets that only need to know "which buses are live" should watch this
/// instead of [collegeBusLocationsProvider] to avoid unnecessary rebuilds.
///
/// NOTE: We intentionally do NOT gate on `bus.status != 'not-running'` here.
/// [collegeBusLocationsProvider] already removes a bus from the live-location
/// set when it receives a `bus_updated` socket event with `status == 'not-running'`.
/// Adding a second status check causes false negatives: the DB `status` field
/// can lag behind active GPS broadcasting (e.g. driver starts sharing before
/// the backend write completes), making buses invisible to students even though
/// they are actively transmitting. The sole source of truth for "is this bus
/// live right now" is the presence of a location entry in [collegeBusLocationsProvider].
final studentLiveBusIdsProvider =
    Provider.family<Set<String>, String>((ref, collegeId) {
      final liveLocations =
          ref.watch(collegeBusLocationsProvider(collegeId)).valueOrNull ?? [];
      final buses =
          ref.watch(collegeBusesStreamProvider(collegeId)).valueOrNull ?? [];

      // Only require accepted assignment — status is managed by the socket stream.
      final acceptedBusIds = buses
          .where((b) => b.assignmentStatus == 'accepted')
          .map((b) => b.id)
          .toSet();

      return liveLocations
          .map((loc) => loc.busId)
          .where((id) => acceptedBusIds.contains(id))
          .toSet();
    });

/// Provider for active teacher override requests (for coordinators)
final teacherOverrideRequestsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
      final repo = ref.watch(busRepositoryProvider);
      final socket = ref.watch(socketServiceProvider);

      return Stream.multi((controller) async {
        DateTime? lastFetch;
        Future<void> fetch() async {
          final now = DateTime.now();
          if (lastFetch != null && now.difference(lastFetch!).inMilliseconds < 1500) {
            return;
          }
          lastFetch = now;
          try {
            final requests = await repo.getTeacherOverrideRequests();
            if (!controller.isClosed) controller.add(requests);
          } catch (e) {
            if (!controller.isClosed) controller.addError(e);
          }
        }

        await fetch();

        final sub1 = socket.busListUpdateStream.listen((_) => fetch());
        final sub2 = socket.busUpdateStream.listen((_) => fetch());

        controller.onCancel = () {
          sub1.cancel();
          sub2.cancel();
        };
      });

    });
