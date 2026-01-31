import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/sos/domain/sos_model.dart';
import 'package:collegebus/core/providers/api_provider.dart';
import 'package:collegebus/core/providers/socket_provider.dart';

/// StreamProvider for active SOS alerts in a specific college
final activeSosProvider = StreamProvider.family<List<SosModel>, String>((
  ref,
  collegeId,
) {
  final api = ref.watch(apiServiceProvider);
  final socket = ref.watch(socketServiceProvider);

  return Stream.multi((controller) async {
    List<SosModel> currentAlerts = [];

    Future<void> fetch() async {
      try {
        final rawAlerts = await api.getActiveSos(collegeId);
        currentAlerts = rawAlerts.map((m) => SosModel.fromMap(m)).toList();
        if (!controller.isClosed) controller.add(List.from(currentAlerts));
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    await fetch();

    final alertSub = socket.sosAlertStream.listen((data) {
      final sos = SosModel.fromMap(data);
      if (sos.collegeId == collegeId) {
        // Avoid duplicates if already in list
        if (!currentAlerts.any((s) => s.sosId == sos.sosId)) {
          currentAlerts.insert(0, sos);
          if (!controller.isClosed) controller.add(List.from(currentAlerts));
        }
      }
    });

    final resolvedSub = socket.sosResolvedStream.listen((data) {
      final sosId = data['sos_id'];
      final removed = currentAlerts.any((s) => s.sosId == sosId);
      if (removed) {
        currentAlerts.removeWhere((s) => s.sosId == sosId);
        if (!controller.isClosed) controller.add(List.from(currentAlerts));
      }
    });

    controller.onCancel = () {
      alertSub.cancel();
      resolvedSub.cancel();
    };
  });
});

/// StreamProvider for online driver IDs in a specific college
final onlineDriversProvider = StreamProvider.family<Set<String>, String>((
  ref,
  collegeId,
) {
  final socket = ref.watch(socketServiceProvider);
  final Set<String> onlineIds = {};

  return Stream.multi((controller) {
    final sub = socket.driverStatusStream.listen((data) {
      final driverId = data['driverId'];
      final status = data['status'];
      // Note: We might need to verify collegeId if the server doesn't filter perfectly
      // but assuming socket joinCollege filters the room.
      if (status == 'online') {
        onlineIds.add(driverId);
      } else {
        onlineIds.remove(driverId);
      }
      if (!controller.isClosed) controller.add(Set.from(onlineIds));
    });

    controller.onCancel = () => sub.cancel();

    // Initial state is empty, or we could fetch from API if available
    controller.add(Set.from(onlineIds));
  });
});
