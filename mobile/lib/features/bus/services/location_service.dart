import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:collegebus/core/utils/app_logger.dart';
import 'package:collegebus/core/services/persistence_service.dart';

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

  Future<bool> requestBackgroundLocationPermission() async {
    final permission = await Permission.locationAlways.request();
    return permission.isGranted;
  }

  Future<bool> checkBackgroundLocationPermission() async {
    final permission = await Permission.locationAlways.status;
    return permission.isGranted;
  }

  Future<bool> requestIgnoreBatteryOptimizations() async {
    final permission = await Permission.ignoreBatteryOptimizations.request();
    return permission.isGranted;
  }

  Future<bool> checkIgnoreBatteryOptimizations() async {
    final permission = await Permission.ignoreBatteryOptimizations.status;
    return permission.isGranted;
  }

  Future<void> _requestBackgroundAndBatteryExemptions() async {
    try {
      final bgPrompted = PersistenceService.getBool('background_location_prompted') ?? false;
      if (!bgPrompted) {
        if (!await checkBackgroundLocationPermission()) {
          await requestBackgroundLocationPermission();
        }
        await PersistenceService.setBool('background_location_prompted', true);
      }
      
      final batteryPrompted = PersistenceService.getBool('battery_exempt_prompted') ?? false;
      if (!batteryPrompted) {
        if (!await checkIgnoreBatteryOptimizations()) {
          await requestIgnoreBatteryOptimizations();
        }
        await PersistenceService.setBool('battery_exempt_prompted', true);
      }
    } catch (e) {
      AppLogger.w('[LocationService] Failed to request background/battery exemptions: $e');
    }
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
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
        return LatLng(position.latitude, position.longitude);
      } catch (innerError) {
        AppLogger.w('Timeout or error getting current position, trying last known: $innerError');
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          return LatLng(lastKnown.latitude, lastKnown.longitude);
        }
        rethrow;
      }
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

  DateTime? _lastEmitTime;
  static const int _minUpdateIntervalMs = 1000; // Min 1 second between updates

  Future<void> startLocationTracking({
    required Function(Position) onLocationUpdate,
    int intervalSeconds = 10,
    /// Drop any GPS fix whose horizontal accuracy is worse than this threshold.
    /// The Android FLP and iOS Core Location both populate `Position.accuracy`
    /// with the 68%-confidence radius in meters. Rejecting high-error positions
    /// prevents the bus marker from jumping around near buildings or tunnels.
    /// Default: 25 m.  Set to double.infinity to disable the filter.
    double accuracyThresholdMeters = 25.0,
  }) async {
    try {
      // Stop any existing tracking first
      stopLocationTracking();

      final hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        final granted = await requestLocationPermission();
        if (!granted) return;
      }

      // Request background location and ignore battery optimizations exemptions
      await _requestBackgroundAndBatteryExemptions();

      // Increased distanceFilter for battery efficiency
      LocationSettings locationSettings;

      if (defaultTargetPlatform == TargetPlatform.android) {
        // Note: forceLocationManager:true is intentionally NOT set because it
        // bypasses the Fused Location Provider (FLP) which is what backs the
        // foreground service. Without FLP, Android kills location delivery as
        // soon as the screen turns off even with a persistent notification.
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
          intervalDuration: const Duration(seconds: 3),
          // The foreground service notification keeps the process alive in
          // background and when the screen is off.
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationTitle: "Bus Tracking Active",
            notificationText: "Your location is being shared with students.",
            enableWakeLock: true,
            enableWifiLock: true,
          ),
        );
      } else if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        locationSettings = AppleSettings(
          accuracy: LocationAccuracy.high,
          activityType: ActivityType.automotiveNavigation,
          distanceFilter: 5,
          // These two are REQUIRED for iOS background delivery.
          // Without them, Core Location pauses updates when app is suspended.
          // Note: pausesLocationUpdatesAutomatically is a native CoreLocation
          // property but is not exposed by geolocator_apple 2.3.x.
          allowBackgroundLocationUpdates: true,
          showBackgroundLocationIndicator: true,
        );
      } else {
        locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        );
      }

      _positionStreamSubscription =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen(
            (Position position) {
              final now = DateTime.now();

              // ── Accuracy guard ───────────────────────────────────────────
              // Reject positions whose horizontal accuracy is worse than the
              // configured threshold. This prevents the bus icon from jumping
              // around due to GPS noise near buildings, tunnels, or indoors.
              if (position.accuracy > accuracyThresholdMeters) {
                AppLogger.d(
                  '[LocationService] Skipped low-accuracy fix: '
                  '${position.accuracy.toStringAsFixed(1)} m '
                  '(threshold ${accuracyThresholdMeters.toStringAsFixed(0)} m)',
                );
                return;
              }

              // Time-based throttle: only emit if >= 3 seconds since last update
              if (_lastEmitTime != null) {
                final elapsed = now.difference(_lastEmitTime!).inMilliseconds;
                if (elapsed < _minUpdateIntervalMs) {
                  // Skip this update to save battery
                  return;
                }
              }

              _lastEmitTime = now;
              final latLng = LatLng(position.latitude, position.longitude);
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
