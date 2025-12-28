import 'package:collegebus/models/bus_model.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:collegebus/services/socket_service.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/services/api_service.dart';
import 'package:collegebus/widgets/common/common_map_view.dart';
import 'package:geolocator/geolocator.dart';
import 'package:collegebus/widgets/incident_report_modal.dart';

class LiveMapTab extends StatefulWidget {
  final List<BusModel> buses;
  const LiveMapTab({super.key, this.buses = const []});

  @override
  State<LiveMapTab> createState() => _LiveMapTabState();
}

class _LiveMapTabState extends State<LiveMapTab> {
  final Map<String, Marker> _markers = {};
  LatLng? _centerLocation;
  StreamSubscription? _locationSubscription;
  final String _mapStyle = ''; // Can load style if needed

  @override
  void initState() {
    super.initState();
    _initLocation();
    _fetchInitialLocations();
    _setupSocketListener();
  }

  Future<void> _fetchInitialLocations() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final collegeId = authService.currentUserModel?.collegeId;
      if (collegeId == null) return;

      final apiService = ApiService();
      final locations = await apiService.getCollegeBusLocations(collegeId);

      if (mounted) {
        for (var loc in locations) {
          _updateMarker({
            'busId': loc.busId,
            'location': {
              'lat': loc.currentLocation.latitude,
              'lng': loc.currentLocation.longitude,
            },
            'speed': loc.speed,
            'heading': loc.heading,
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching initial locations: $e');
    }
  }

  Future<void> _initLocation() async {
    try {
      // 1. Try last known position first (fastest)
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null && mounted) {
        setState(() {
          _centerLocation = LatLng(lastPos.latitude, lastPos.longitude);
        });
      }

      // 2. Try current position with a timeout
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
    } catch (e) {
      debugPrint('Error getting location: $e');
      // 3. Final Fallback if still null
      if (_centerLocation == null && mounted) {
        setState(() {
          // Default to Guntur area (near KKR & KSR Institute)
          _centerLocation = const LatLng(16.2345, 80.4567);
        });
      }
    }
  }

  void _setupSocketListener() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    _locationSubscription = socketService.locationUpdateStream.listen((data) {
      // data: { busId, location: { lat, lng }, speed, heading, ... }
      if (!mounted) return;
      _updateMarker(data);
    });
  }

  bool _isBusActive(String busId) {
    try {
      final bus = widget.buses.firstWhere((b) => b.id == busId);
      // Show if status suggests it's running. Adjust 'STARTED'/'IN_PROGRESS' based on backend.
      // Assuming 'STARTED' means trip started.
      return bus.status == 'STARTED' || bus.status == 'IN_PROGRESS';
    } catch (e) {
      // If bus not found in list, maybe show it anyway or hide?
      // Let's hide unknown buses to be safe, or show if actively emitting.
      // For now, let's assume we only want to show if we know it's active.
      return false;
    }
  }

  void _updateMarker(Map<String, dynamic> data) {
    try {
      final busId = data['busId'] as String;

      // FILTER: Only show active buses
      if (!_isBusActive(busId)) return;

      final loc = data['location'];
      final lat = (loc['lat'] as num).toDouble();
      final lng = (loc['lng'] as num).toDouble();
      final heading = (data['heading'] as num?)?.toDouble() ?? 0.0;

      // Ideally fetch bus details (number) from DataService cache or just show Bus ID
      // For now, let's use a generic marker or try to find bus number

      final marker = Marker(
        markerId: MarkerId(busId),
        position: LatLng(lat, lng),
        rotation: heading,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        infoWindow: InfoWindow(title: 'Bus ${data['busId']}'),
        onTap: () {
          IncidentReportModal.show(context, busId: busId);
        },
      );

      setState(() {
        _markers[busId] = marker;
      });
    } catch (e) {
      debugPrint('Error updating marker: $e');
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
      polylines: const {},
      onMapCreated: (controller) {},
      initialZoom: 12.0,
      mapStyle: _mapStyle,
    );
  }
}
