import 'dart:async';
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/features/bus/application/bus_provider.dart';
import 'package:collegebus/widgets/common/common_map_view.dart';
import 'package:collegebus/core/utils/map_marker_helper.dart';

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

class LiveBusMapState extends ConsumerState<LiveBusMap>
    with TickerProviderStateMixin {
  final Map<String, Marker> _markers = {};
  // Cache locations to handle updates
  final Map<String, BusLocationModel> _liveLocations = {};

  // Animation maps
  final Map<String, AnimationController> _animationControllers = {};
  final Map<String, LatLng> _animatedLocations = {};
  final Map<String, double> _animatedRotations = {};

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

  BitmapDescriptor? _busIcon;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _loadCustomMarker();

    // Catch current location state immediately after first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user?.collegeId != null) {
        final currentLocs = ref
            .read(collegeBusLocationsProvider(user!.collegeId))
            .value;
        if (currentLocs != null && currentLocs.isNotEmpty) {
          for (var loc in currentLocs) {
            _handleLocationUpdate(loc);
          }
        }
      }
    });
  }

  Future<void> _loadCustomMarker() async {
    try {
      // Clear cache to pick up any size changes
      MapMarkerHelper.clearCache();
      final icon = await MapMarkerHelper.createBusMarker();
      debugPrint('[LiveBusMap] Custom bus marker loaded successfully');
      if (mounted) {
        setState(() {
          _busIcon = icon;
        });
        _rebuildMarkers();
      }
    } catch (e) {
      debugPrint('[LiveBusMap] Error creating custom marker: $e');
    }
  }

  @override
  void didUpdateWidget(LiveBusMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.buses != widget.buses ||
        oldWidget.selectedBus != widget.selectedBus) {
      _rebuildMarkers();

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

  void _handleLocationUpdate(BusLocationModel nextLoc) {
    final busId = nextLoc.busId;
    final prevLoc = _liveLocations[busId];

    // 1. Timestamp out-of-order check
    if (prevLoc != null && nextLoc.timestamp.isBefore(prevLoc.timestamp)) {
      debugPrint('Ignoring stale location update for bus $busId');
      return;
    }

    _liveLocations[busId] = nextLoc;

    final startPos = _animatedLocations[busId] ?? nextLoc.currentLocation;
    final endPos = nextLoc.currentLocation;
    final startRot = _animatedRotations[busId] ?? nextLoc.heading ?? 0.0;
    final endRot = nextLoc.heading ?? startRot;

    // 2. Initialize or obtain AnimationController
    var controller = _animationControllers[busId];
    if (controller == null) {
      controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000),
      );
      _animationControllers[busId] = controller;
      _animatedLocations[busId] = startPos;
      _animatedRotations[busId] = startRot;

      controller.addListener(() {
        if (mounted) {
          final t = controller!.value;
          setState(() {
            _animatedLocations[busId] = LatLng(
              lerpDouble(startPos.latitude, endPos.latitude, t)!,
              lerpDouble(startPos.longitude, endPos.longitude, t)!,
            );
            _animatedRotations[busId] = lerpDouble(startRot, endRot, t)!;
            _rebuildMarkers();
          });
        }
      });
    } else {
      // Re-target existing animation
      controller.stop();
      // Simple way: Clear listener and recreate or just reset targets
      // Since we use the local state startPos/endPos in the listener closure,
      // we should recreate it or use a more dynamic closure.
      controller.dispose();
      controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000),
      );
      _animationControllers[busId] = controller;

      controller.addListener(() {
        if (mounted) {
          final t = controller!.value;
          setState(() {
            _animatedLocations[busId] = LatLng(
              lerpDouble(startPos.latitude, endPos.latitude, t)!,
              lerpDouble(startPos.longitude, endPos.longitude, t)!,
            );
            _animatedRotations[busId] = lerpDouble(startRot, endRot, t)!;
            _rebuildMarkers();
          });
        }
      });
    }

    controller.forward(from: 0.0);

    // Auto-center if following
    if (_isFollowing && widget.selectedBus?.id == busId) {
      _animateToBus(widget.selectedBus!);
    }
  }

  void _rebuildMarkers() {
    final Map<String, Marker> newMarkers = {};

    for (var bus in widget.buses) {
      // If bus reached destination or is not running, stop showing it as "live"
      if (bus.status == 'not-running' || bus.assignmentStatus == 'unassigned') {
        // Clear caches for this bus to ensure it disappears
        _liveLocations.remove(bus.id);
        _animatedLocations.remove(bus.id);
        _animationControllers[bus.id]?.dispose();
        _animationControllers.remove(bus.id);
        continue;
      }

      final pos =
          _animatedLocations[bus.id] ?? _liveLocations[bus.id]?.currentLocation;
      if (pos != null) {
        final rot =
            _animatedRotations[bus.id] ??
            _liveLocations[bus.id]?.heading ??
            0.0;
        final marker = _createMarker(bus, pos, rot);
        newMarkers[bus.id] = marker;
      }
    }

    _markers.clear();
    _markers.addAll(newMarkers);
  }

  // Removed _updateScreenPositions for Rive

  Marker _createMarker(BusModel bus, LatLng pos, double rotation) {
    return Marker(
      markerId: MarkerId(bus.id),
      position: pos,
      rotation: rotation,
      icon:
          _busIcon ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      anchor: const Offset(0.5, 0.5),
      infoWindow: InfoWindow(
        title: 'Bus ${bus.busNumber}',
        snippet: bus.status,
      ),
      onTap: () => widget.onBusTap?.call(bus),
    );
  }

  // Removed _deriveTripStatus for Rive

  void _animateToBus(BusModel bus) {
    final pos =
        _animatedLocations[bus.id] ?? _liveLocations[bus.id]?.currentLocation;
    if (pos != null && _mapController != null) {
      _isProgrammaticMove = true;
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(pos, 17.0)).then(
        (_) {
          // Reset flag after animation completes/starts
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) _isProgrammaticMove = false;
          });
        },
      );
    }
  }

  @override
  void dispose() {
    for (var controller in _animationControllers.values) {
      controller.dispose();
    }
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
              _handleLocationUpdate(loc);
            }
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
          onCameraMove: (position) {
            // No longer updating screen positions
          },
          onCameraIdle: () {
            // No longer updating screen positions
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

        // Rive Marker Overlay Removed
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
