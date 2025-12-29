import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:collegebus/utils/app_logger.dart';

class LocationService {
  StreamSubscription<Position>? _positionStreamSubscription;
  final StreamController<LatLng> _locationController =
      StreamController<LatLng>.broadcast();

  Stream<LatLng> get locationStream => _locationController.stream;

  Future<bool> requestLocationPermission() async {
    final permission = await Permission.location.request();
    return permission.isGranted;
  }

  Future<bool> checkLocationPermission() async {
    final permission = await Permission.location.status;
    return permission.isGranted;
  }

  Future<LatLng?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are not enabled
        return null;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Permissions are denied
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Permissions are permanently denied
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      AppLogger.e('Error getting location: $e');
      return null;
    }
  }

  Future<LatLng?> getLastKnownLocation() async {
    try {
      // On web, getLastKnownPosition is not supported
      // Fall back to getCurrentPosition instead
      if (kIsWeb) {
        return await getCurrentLocation();
      }

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      final position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        return LatLng(position.latitude, position.longitude);
      }
      return null;
    } catch (e) {
      AppLogger.e('Error getting last known location: $e');
      // On error, try to get current location as fallback
      return await getCurrentLocation();
    }
  }

  Future<void> startLocationTracking({
    required Function(Position) onLocationUpdate,
    int intervalSeconds = 10,
  }) async {
    try {
      // Stop any existing tracking first
      stopLocationTracking();

      final hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        final granted = await requestLocationPermission();
        if (!granted) return;
      }

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      );

      _positionStreamSubscription =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen(
            (Position position) {
              final latLng = LatLng(position.latitude, position.longitude);
              // print('DEBUG: Location update received: ${latLng.latitude}, ${latLng.longitude}');
              _locationController.add(latLng);
              onLocationUpdate(position);
            },
            onError: (error) {
              AppLogger.e('DEBUG: Location stream error: $error');
            },
            onDone: () {
              AppLogger.w('DEBUG: Location stream completed');
            },
          );

      AppLogger.i('DEBUG: Location tracking started successfully');
    } catch (e) {
      AppLogger.e('DEBUG: Error starting location tracking: $e');
      // Location tracking failed, but app can continue
    }
  }

  void stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    AppLogger.i('DEBUG: Location tracking stopped');
  }

  bool get isTracking {
    return _positionStreamSubscription != null;
  }

  Future<double> calculateDistance(LatLng start, LatLng end) async {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  Future<double> calculateBearing(LatLng start, LatLng end) async {
    return Geolocator.bearingBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  void dispose() {
    stopLocationTracking();
    _locationController.close();
  }
}
