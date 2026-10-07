import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';

/// 1D Kalman Filter & Jitter Suppression for GPS Tracking.
///
/// Models spatial coordinates (latitude and longitude) independently with dynamic
/// variance estimation based on reported GPS accuracy and elapsed time.
///
/// Features:
/// 1. Kalman filtering on latitude and longitude to smooth coordinate noise.
/// 2. Speed gate: suppresses spurious GPS speeds (< 0.8 m/s ~ 2.9 km/h) to 0.0 when stationary.
/// 3. Heading stabilization: preserves last valid heading when stationary, preventing compass spin.
/// 4. Stationary damping: reduces process noise when stopped to prevent multipath drift.
class GpsKalmanFilter {
  /// Process noise intensity in meters per second (default 3.0 m/s for urban bus transit).
  final double processNoiseMps;

  /// Speed threshold below which the vehicle is considered stationary (default 0.8 m/s ~ 2.9 km/h).
  final double stationarySpeedThresholdMps;

  double? _lat;
  double? _lng;
  double _varianceLat = -1.0;
  double _varianceLng = -1.0;
  DateTime? _lastTimestamp;
  double _lastValidHeading = 0.0;

  GpsKalmanFilter({
    this.processNoiseMps = 3.0,
    this.stationarySpeedThresholdMps = 0.8,
  });

  /// Resets filter state (called on trip start, trip stop, or actor transitions).
  void reset() {
    _lat = null;
    _lng = null;
    _varianceLat = -1.0;
    _varianceLng = -1.0;
    _lastTimestamp = null;
    _lastValidHeading = 0.0;
  }

  /// Processes a raw [Position] fix and returns a smoothed, jitter-free [Position].
  Position filter(Position raw) {
    final now = raw.timestamp;
    final rawLat = raw.latitude;
    final rawLng = raw.longitude;
    final accuracy = raw.accuracy > 1.0 ? raw.accuracy : 1.0;

    // Convert meters to approximate degree scaling at current latitude
    const metersPerDegreeLat = 111320.0;
    final latRad = rawLat * math.pi / 180.0;
    final metersPerDegreeLng = 111320.0 * math.cos(latRad).abs().clamp(0.1, 1.0);

    // Measurement variance in degrees squared
    final rLat = math.pow(accuracy / metersPerDegreeLat, 2).toDouble();
    final rLng = math.pow(accuracy / metersPerDegreeLng, 2).toDouble();

    // ── Speed Gate ──────────────────────────────────────────────────────────
    // Stationary GPS chips fluctuate between 0.1 and 0.8 m/s due to satellite geometry.
    final isStationary = raw.speed < stationarySpeedThresholdMps;
    final effectiveSpeed = isStationary ? 0.0 : raw.speed;

    // ── Heading Stabilization ───────────────────────────────────────────────
    // When stationary, GPS bearing calculates chaotic angles from jitter vectors.
    // Preserve the last known heading when stationary or if raw heading is invalid (< 0).
    final effectiveHeading = (!isStationary && raw.heading >= 0)
        ? raw.heading
        : _lastValidHeading;
    if (!isStationary && raw.heading >= 0) {
      _lastValidHeading = raw.heading;
    }

    if (_lat == null || _lng == null || _varianceLat < 0 || _varianceLng < 0) {
      // First fix initialization
      _lat = rawLat;
      _lng = rawLng;
      _varianceLat = rLat;
      _varianceLng = rLng;
      _lastTimestamp = now;

      return Position(
        longitude: _lng!,
        latitude: _lat!,
        timestamp: now,
        accuracy: accuracy,
        altitude: raw.altitude,
        altitudeAccuracy: raw.altitudeAccuracy,
        heading: effectiveHeading,
        headingAccuracy: raw.headingAccuracy,
        speed: effectiveSpeed,
        speedAccuracy: raw.speedAccuracy,
        floor: raw.floor,
        isMocked: raw.isMocked,
      );
    }

    final dtSeconds = _lastTimestamp != null
        ? (now.difference(_lastTimestamp!).inMilliseconds / 1000.0).clamp(0.1, 10.0)
        : 1.0;
    _lastTimestamp = now;

    // Process noise Q (in degrees squared per second)
    // Reduce process noise when stationary to tighten the filter against drift
    final effectiveQ = isStationary ? (processNoiseMps * 0.2) : processNoiseMps;
    final qLat = dtSeconds * math.pow(effectiveQ / metersPerDegreeLat, 2);
    final qLng = dtSeconds * math.pow(effectiveQ / metersPerDegreeLng, 2);

    // 1. Time Update (Predict)
    _varianceLat += qLat;
    _varianceLng += qLng;

    // 2. Measurement Update (Correct)
    final kLat = _varianceLat / (_varianceLat + rLat);
    final kLng = _varianceLng / (_varianceLng + rLng);

    _lat = _lat! + kLat * (rawLat - _lat!);
    _lng = _lng! + kLng * (rawLng - _lng!);

    _varianceLat = (1.0 - kLat) * _varianceLat;
    _varianceLng = (1.0 - kLng) * _varianceLng;

    // Filtered accuracy in meters
    final filteredAccuracy = math.sqrt(_varianceLat) * metersPerDegreeLat;

    return Position(
      longitude: _lng!,
      latitude: _lat!,
      timestamp: now,
      accuracy: filteredAccuracy.clamp(1.0, accuracy),
      altitude: raw.altitude,
      altitudeAccuracy: raw.altitudeAccuracy,
      heading: effectiveHeading,
      headingAccuracy: raw.headingAccuracy,
      speed: effectiveSpeed,
      speedAccuracy: raw.speedAccuracy,
      floor: raw.floor,
      isMocked: raw.isMocked,
    );
  }
}
