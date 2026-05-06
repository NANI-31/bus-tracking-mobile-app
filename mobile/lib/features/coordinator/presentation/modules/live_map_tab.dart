import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/features/bus/application/bus_provider.dart';
import 'package:collegebus/shared/widgets/incident_report_modal.dart';
import 'package:collegebus/shared/widgets/maps/live_bus_map.dart';

class LiveMapTab extends ConsumerWidget {
  final BusModel? selectedBus;

  const LiveMapTab({super.key, this.selectedBus});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final collegeId = user?.collegeId;

    if (collegeId == null) return const SizedBox.shrink();

    final buses = ref.watch(collegeBusesStreamProvider(collegeId)).value ?? [];

    return LiveBusMap(
      buses: buses,
      selectedBus: selectedBus,
      onBusTap: (bus) {
        IncidentReportModal.show(context, busId: bus.id);
      },
      showUserLocation: true,
    );
  }
}
