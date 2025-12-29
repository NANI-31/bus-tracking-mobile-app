import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/services/data_service.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/widgets/common/common_map_view.dart';

class LiveBusMap extends StatefulWidget {
  final List<BusModel> buses;
  final BusModel? selectedBus;
  final Function(BusModel)? onBusTap;
  final String? mapStyle;
  final bool showUserLocation;
  final Function(GoogleMapController)? onMapCreated;

  // Optional: Function to build custom markers if the default logic isn't enough
  // For now, we'll implement standard logic inside.

  const LiveBusMap({
    super.key,
    required this.buses,
    this.selectedBus,
    this.onBusTap,
    this.mapStyle,
    this.showUserLocation = true,
    this.onMapCreated,
  });

  @override
  State<LiveBusMap> createState() => _LiveBusMapState();
}

class _LiveBusMapState extends State<LiveBusMap> {
  final Map<String, Marker> _markers = {};
  // Cache locations to handle updates
  final Map<String, BusLocationModel> _liveLocations = {};

  LatLng? _centerLocation;
  StreamSubscription? _locationSubscription;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _setupLocationStream();
  }

  @override
  void didUpdateWidget(LiveBusMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.buses != widget.buses ||
        oldWidget.selectedBus != widget.selectedBus) {
      _updateAllMarkers();
      if (widget.selectedBus != null &&
          widget.selectedBus != oldWidget.selectedBus) {
        _animateToBus(widget.selectedBus!);
      }
    }
  }

  void _setupLocationStream() {
    final dataService = Provider.of<DataService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final collegeId = authService.currentUserModel?.collegeId;

    if (collegeId != null) {
      _locationSubscription = dataService
          .getCollegeBusLocationsStream(collegeId)
          .listen((locations) {
            if (!mounted) return;
            for (var loc in locations) {
              _liveLocations[loc.busId] = loc;
            }
            _updateAllMarkers();
          });
    }
  }

  Future<void> _initLocation() async {
    try {
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null && mounted) {
        setState(() {
          _centerLocation = LatLng(lastPos.latitude, lastPos.longitude);
        });
      }
      if (widget.showUserLocation) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 5),
          ),
        );
        if (mounted) {
          setState(() {
            _centerLocation = LatLng(pos.latitude, pos.longitude);
          });
        }
      }
    } catch (e) {
      // Fallback
      if (_centerLocation == null && mounted) {
        setState(() {
          _centerLocation = const LatLng(16.2345, 80.4567);
        });
      }
    }
  }

  void _updateAllMarkers() {
    final Map<String, Marker> newMarkers = {};

    // Iterate through the buses passed to the widget (filtered list)
    for (var bus in widget.buses) {
      if (_liveLocations.containsKey(bus.id)) {
        final loc = _liveLocations[bus.id]!;
        final marker = _createMarker(bus, loc);
        newMarkers[bus.id] = marker;
      }
    }

    setState(() {
      _markers.clear();
      _markers.addAll(newMarkers);
    });
  }

  Marker _createMarker(BusModel bus, BusLocationModel loc) {
    // We can use StudentMapHelper or simple logic.
    // Let's use simple logic for commonality, or import helper if complex icons needed.
    // Given the requirement "make the map code as common", simpler is better for now unless specific UI requested.
    // However, StudentMapHelper has rotation/custom icons. Let's try to simulate that.

    return Marker(
      markerId: MarkerId(bus.id),
      position: loc.currentLocation,
      rotation: 0.0, // Stable icon, ignores driver heading
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      // Ideal: Use StudentMapHelper.getBusIcon() if available/refactored
      infoWindow: InfoWindow(
        title: 'Bus ${bus.busNumber}',
        snippet: bus.status,
      ),
      onTap: () => widget.onBusTap?.call(bus),
    );
  }

  void _animateToBus(BusModel bus) {
    if (_liveLocations.containsKey(bus.id) && _mapController != null) {
      final loc = _liveLocations[bus.id]!;
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(loc.currentLocation, 16.0),
      );
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_centerLocation == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return CommonMapView(
      currentLocation: _centerLocation!,
      markers: _markers.values.toSet(),
      polylines: const {}, // Pass polylines if we assume route drawing later
      onMapCreated: (controller) {
        _mapController = controller;
        widget.onMapCreated?.call(controller);
      },
      initialZoom: 14.0,
      mapStyle: widget.mapStyle,
    );
  }
}
