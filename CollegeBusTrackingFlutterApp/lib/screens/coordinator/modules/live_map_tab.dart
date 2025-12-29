import 'package:collegebus/models/bus_model.dart';
import 'package:flutter/material.dart';
import 'package:collegebus/widgets/incident_report_modal.dart';
import 'package:collegebus/widgets/maps/live_bus_map.dart';

class LiveMapTab extends StatelessWidget {
  final List<BusModel> buses;
  final BusModel? selectedBus;

  const LiveMapTab({super.key, this.buses = const [], this.selectedBus});

  @override
  Widget build(BuildContext context) {
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
