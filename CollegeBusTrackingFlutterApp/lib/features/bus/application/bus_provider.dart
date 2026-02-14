import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/features/coordinator/domain/assignment_log_model.dart';
import 'package:collegebus/core/providers/api_provider.dart';
import 'package:collegebus/core/providers/socket_provider.dart';

/// Bus notifier for managing the list of buses
class BusNotifier extends AsyncNotifier<List<BusModel>> {
  @override
  Future<List<BusModel>> build() async {
    final api = ref.watch(apiServiceProvider);
    return await api.getAllBuses();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }

  // Common operations that update state
  Future<void> createBus(BusModel bus) async {
    final api = ref.read(apiServiceProvider);
    await api.createBus(bus);
    await refresh();
  }

  Future<void> updateBus(String busId, Map<String, dynamic> data) async {
    final api = ref.read(apiServiceProvider);
    await api.updateBus(busId, data);
    ref.read(socketServiceProvider).sendBusListUpdate();
    await refresh();
  }

  Future<void> deleteBus(String busId) async {
    final api = ref.read(apiServiceProvider);
    await api.deleteBus(busId);
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
      final api = ref.watch(apiServiceProvider);
      final socket = ref.read(socketServiceProvider);

      return Stream.multi((controller) async {
        Future<void> fetch() async {
          try {
            final buses = await api.getAllBuses();
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
      final api = ref.watch(apiServiceProvider);
      final socket = ref.read(socketServiceProvider);

      return Stream.multi((controller) async {
        Future<void> fetch() async {
          try {
            final buses = await api.getAllBuses();
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
  final api = ref.watch(apiServiceProvider);
  final socket = ref.watch(socketServiceProvider);

  return Stream.multi((controller) async {
    Future<void> fetch() async {
      try {
        final numbers = await api.getBusNumbers(collegeId);
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
      final api = ref.watch(apiServiceProvider);
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

        try {
          final apiLocations = await api.getCollegeBusLocations(collegeId);
          currentLocations = List.from(apiLocations);
          if (!controller.isClosed) controller.add(currentLocations);
        } catch (e) {
          // initial fetch error handled by stream
        }
      });
    });

/// StreamProvider for a specific bus location
final busLocationProvider = StreamProvider.family<BusLocationModel?, String>((
  ref,
  busId,
) {
  final api = ref.watch(apiServiceProvider);
  final socket = ref.watch(socketServiceProvider);

  return Stream.multi((controller) async {
    try {
      final location = await api.getBusLocation(busId);
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
      final api = ref.watch(apiServiceProvider);
      return await api.getAssignmentLogsByBus(busId);
    });

/// StreamProvider for a specific driver's assigned bus
final driverBusProvider = StreamProvider.family<BusModel?, String>((
  ref,
  driverId,
) {
  final api = ref.watch(apiServiceProvider);
  final socket = ref.watch(socketServiceProvider);

  return Stream.multi((controller) async {
    Future<void> fetch() async {
      try {
        final bus = await api.getBusByDriver(driverId);
        if (!controller.isClosed) controller.add(bus);
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
