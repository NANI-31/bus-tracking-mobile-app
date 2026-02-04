import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/features/bus/application/bus_provider.dart';
import 'package:collegebus/widgets/common/common_map_view.dart';

class LiveBusMap extends ConsumerStatefulWidget {
  final List<BusModel> buses;
  final BusModel? selectedBus;
  final Function(BusModel)? onBusTap;

  final bool showUserLocation;
  final Function(GoogleMapController)? onMapCreated;
  final double bottomPadding;

  const LiveBusMap({
    super.key,
    required this.buses,
    this.selectedBus,
    this.onBusTap,

    this.showUserLocation = true,
    this.onMapCreated,
    this.bottomPadding = 0.0,
  });

  @override
  ConsumerState<LiveBusMap> createState() => LiveBusMapState();
}

class LiveBusMapState extends ConsumerState<LiveBusMap> {
  final Map<String, Marker> _markers = {};
  // Cache locations to handle updates
  final Map<String, BusLocationModel> _liveLocations = {};

  LatLng? _centerLocation;
  GoogleMapController? _mapController;

  // Smart centering logic
  bool _isFollowing = true;
  bool _isProgrammaticMove = false;

  void resumeFollowing() {
    if (mounted) {
      setState(() => _isFollowing = true);
      if (widget.selectedBus != null) {
        _animateToBus(widget.selectedBus!);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void didUpdateWidget(LiveBusMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.buses != widget.buses ||
        oldWidget.selectedBus != widget.selectedBus) {
      _updateAllMarkers();

      // If a new bus is selected, or initial selection, reset following
      if (widget.selectedBus != null &&
          widget.selectedBus != oldWidget.selectedBus) {
        _isFollowing = true;
        _animateToBus(widget.selectedBus!);
      }
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

    // Auto-center if following
    if (_isFollowing && widget.selectedBus != null) {
      _animateToBus(widget.selectedBus!);
    }
  }

  Marker _createMarker(BusModel bus, BusLocationModel loc) {
    return Marker(
      markerId: MarkerId(bus.id),
      position: loc.currentLocation,
      rotation: 0.0,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
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
      _isProgrammaticMove = true;
      _mapController!
          .animateCamera(CameraUpdate.newLatLngZoom(loc.currentLocation, 17.0))
          .then((_) {
            // Reset flag after animation completes/starts
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted) _isProgrammaticMove = false;
            });
          });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final collegeId = user?.collegeId;

    if (collegeId != null) {
      ref.listen<AsyncValue<List<BusLocationModel>>>(
        collegeBusLocationsProvider(collegeId),
        (previous, next) {
          next.whenData((locations) {
            for (var loc in locations) {
              _liveLocations[loc.busId] = loc;
            }
            _updateAllMarkers();
          });
        },
      );
    }

    if (_centerLocation == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        CommonMapView(
          currentLocation: _centerLocation!,
          markers: _markers.values.toSet(),
          polylines: const {},
          onMapCreated: (controller) {
            _mapController = controller;
            widget.onMapCreated?.call(controller);
          },
          onCameraMoveStarted: () {
            if (!_isProgrammaticMove) {
              // User gesture detected
              if (_isFollowing) {
                setState(() => _isFollowing = false);
              }
            }
          },
          initialZoom: 17.0,

          myLocationEnabled: widget.showUserLocation,
          myLocationButtonEnabled: widget.showUserLocation,
          bottomPadding: widget.bottomPadding,
        ),
        if (!_isFollowing && widget.selectedBus != null)
          Positioned(
            bottom: 20 + widget.bottomPadding,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton.extended(
                onPressed: resumeFollowing,
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.gps_fixed),
                label: const Text("Recenter Bus"),
              ),
            ),
          ),
      ],
    );
  }
}





