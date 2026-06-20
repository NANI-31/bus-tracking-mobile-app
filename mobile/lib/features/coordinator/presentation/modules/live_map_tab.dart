import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/features/bus/application/bus_provider.dart';
import 'package:collegebus/shared/widgets/incident_report_modal.dart';
import 'package:collegebus/shared/widgets/maps/live_bus_map.dart';
import 'package:collegebus/shared/widgets/navigation/curved_bottom_nav_bar.dart';

class LiveMapTab extends ConsumerStatefulWidget {
  final BusModel? selectedBus;

  const LiveMapTab({super.key, this.selectedBus});

  @override
  ConsumerState<LiveMapTab> createState() => _LiveMapTabState();
}

class _LiveMapTabState extends ConsumerState<LiveMapTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Mandatory for KeepAlive
    
    final user = ref.watch(currentUserProvider);
    final collegeId = user?.collegeId;

    if (collegeId == null) return const SizedBox.shrink();

    final buses = ref.watch(collegeBusesStreamProvider(collegeId)).valueOrNull ?? [];

    return LiveBusMap(
      buses: buses,
      selectedBus: widget.selectedBus,
      onBusTap: (bus) {
        IncidentReportModal.show(context, busId: bus.id);
      },
      showUserLocation: true,
      bottomPadding: widget.selectedBus != null ? 180.0 : CurvedBottomNavBar.clearance(context),
    );
  }
}
