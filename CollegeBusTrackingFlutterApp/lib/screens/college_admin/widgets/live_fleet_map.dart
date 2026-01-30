import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/services/admin/college_admin_service.dart';
import 'package:collegebus/widgets/maps/live_bus_map.dart';

class LiveFleetMap extends StatefulWidget {
  final List<BusModel> buses;
  final String collegeId;

  const LiveFleetMap({super.key, required this.buses, required this.collegeId});

  @override
  State<LiveFleetMap> createState() => _LiveFleetMapState();
}

class _LiveFleetMapState extends State<LiveFleetMap> {
  BusModel? _selectedBus;
  GoogleMapController? _mapController;
  final GlobalKey<LiveBusMapState> _mapStateKey = GlobalKey<LiveBusMapState>();

  @override
  Widget build(BuildContext context) {
    if (widget.buses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_bus_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No active buses in fleet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        LiveBusMap(
          key: _mapStateKey,
          buses: widget.buses,
          selectedBus: _selectedBus,
          showUserLocation: true,
          onMapCreated: (controller) => _mapController = controller,
          onBusTap: (bus) {
            setState(() {
              _selectedBus = bus;
            });
            _mapStateKey.currentState?.resumeFollowing();
          },
        ),

        // Selected Bus Info Card
        if (_selectedBus != null)
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: const Icon(
                            Icons.directions_bus,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bus ${_selectedBus!.busNumber}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Status: ${_selectedBus!.status}',
                              style: TextStyle(
                                color: _selectedBus!.status == 'on-time'
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _selectedBus = null),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Fleet Overview Fab
        Positioned(
          top: 16,
          right: 16,
          child: FloatingActionButton.small(
            onPressed: _zoomToFitFleet,
            backgroundColor: Colors.white,
            child: const Icon(Icons.zoom_out_map, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  void _zoomToFitFleet() {
    if (_mapController == null || widget.buses.isEmpty) return;

    final caService = Provider.of<CollegeAdminService>(context, listen: false);
    final locations = caService.fleetLocations.values
        .where((l) => widget.buses.any((b) => b.id == l.busId))
        .toList();

    if (locations.isEmpty) return;

    double minLat = locations.first.currentLocation.latitude;
    double maxLat = locations.first.currentLocation.latitude;
    double minLng = locations.first.currentLocation.longitude;
    double maxLng = locations.first.currentLocation.longitude;

    for (var loc in locations) {
      if (loc.currentLocation.latitude < minLat)
        minLat = loc.currentLocation.latitude;
      if (loc.currentLocation.latitude > maxLat)
        maxLat = loc.currentLocation.latitude;
      if (loc.currentLocation.longitude < minLng)
        minLng = loc.currentLocation.longitude;
      if (loc.currentLocation.longitude > maxLng)
        maxLng = loc.currentLocation.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50.0,
      ),
    );
  }
}
