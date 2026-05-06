import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/route/domain/route_model.dart';
import 'package:collegebus/features/schedule/domain/schedule_model.dart';
import 'package:collegebus/core/providers/repository_providers.dart';
import 'package:collegebus/core/providers/socket_provider.dart';

/// Notifier for managing the list of routes
class RouteNotifier extends AsyncNotifier<List<RouteModel>> {
  @override
  Future<List<RouteModel>> build() async {
    // This is a global fetch, family providers are better for specific colleges
    // but for the sake of having a central notifier for mutations:
    return []; // Will be populated by specific fetchers or handled via family
  }

  Future<void> createRoute(RouteModel route) async {
    final repo = ref.read(routeRepositoryProvider);
    final socket = ref.read(socketServiceProvider);
    await repo.createRoute(route);
    socket.sendRouteListUpdate();
  }

  Future<void> updateRoute(String routeId, Map<String, dynamic> data) async {
    final repo = ref.read(routeRepositoryProvider);
    final socket = ref.read(socketServiceProvider);
    await repo.updateRoute(routeId, data);
    socket.sendRouteListUpdate();
  }

  Future<void> deleteRoute(String routeId) async {
    final repo = ref.read(routeRepositoryProvider);
    final socket = ref.read(socketServiceProvider);
    await repo.deleteRoute(routeId);
    socket.sendRouteListUpdate();
  }
}

/// Provider for route mutations
final routeMutatorProvider =
    AsyncNotifierProvider<RouteNotifier, List<RouteModel>>(RouteNotifier.new);

/// StreamProvider for routes of a specific college
final collegeRoutesProvider = StreamProvider.family<List<RouteModel>, String>((
  ref,
  collegeId,
) {
  final repo = ref.watch(routeRepositoryProvider);
  final socket = ref.watch(socketServiceProvider);

  return Stream.multi((controller) async {
    Future<void> fetch() async {
      try {
        final routes = await repo.getRoutesByCollege(collegeId);
        if (!controller.isClosed) controller.add(routes);
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    await fetch();
    final subscription = socket.routeListUpdateStream.listen((_) => fetch());
    controller.onCancel = () => subscription.cancel();
  });
});

/// StreamProvider for schedules of a specific college
final collegeSchedulesProvider =
    StreamProvider.family<List<ScheduleModel>, String>((ref, collegeId) {
      final repo = ref.watch(scheduleRepositoryProvider);
      final socket = ref.read(socketServiceProvider);

      return Stream.multi((controller) async {
        Future<void> fetch() async {
          try {
            final schedules = await repo.getSchedulesByCollege(collegeId);
            if (!controller.isClosed) controller.add(schedules);
          } catch (e) {
            if (!controller.isClosed) controller.addError(e);
          }
        }

        await fetch();
        // Using routeListUpdateStream as a fallback for now if scheduleSpecific doesn't exist
        final subscription = socket.routeListUpdateStream.listen(
          (_) => fetch(),
        );
        controller.onCancel = () => subscription.cancel();
      });
    });
