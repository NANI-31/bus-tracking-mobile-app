import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collegebus/features/notification/services/fcm_service.dart';
import 'package:collegebus/features/bus/services/location_service.dart';

/// The result of a location permission check.
enum LocationPermissionStatus {
  /// Permission is fully granted — map and GPS will work.
  granted,

  /// Permission was denied but can still be requested again.
  denied,

  /// User tapped "Never Allow". The app must send them to Settings.
  permanentlyDenied,
}

/// Centralised permission orchestrator.
///
/// All dashboards (student, coordinator, teacher, driver) should call methods on
/// this service instead of duplicating FCMService + LocationService calls.
/// This eliminates the risk of a new role silently missing a permission request.
class AppPermissionsService {
  final LocationService _locationService;

  AppPermissionsService(this._locationService);

  // ---------------------------------------------------------------------------
  // Status checks
  // ---------------------------------------------------------------------------

  /// Returns the current location permission status without requesting anything.
  Future<LocationPermissionStatus> checkLocationStatus() async {
    final status = await Permission.location.status;
    if (status.isGranted) return LocationPermissionStatus.granted;
    if (status.isPermanentlyDenied) {
      return LocationPermissionStatus.permanentlyDenied;
    }
    return LocationPermissionStatus.denied;
  }

  // ---------------------------------------------------------------------------
  // Basic permissions (student, coordinator, teacher)
  // ---------------------------------------------------------------------------

  /// Requests:
  ///   1. FCM notification permission
  ///   2. Foreground location permission
  ///
  /// Returns the resulting [LocationPermissionStatus].
  Future<LocationPermissionStatus> requestBasicPermissions() async {
    // 1. FCM notifications (silently ignored if the platform doesn't support it)
    try {
      await FCMService().requestPermission();
    } catch (_) {}

    // 2. Foreground location
    final status = await Permission.location.status;
    if (status.isGranted) return LocationPermissionStatus.granted;
    if (status.isPermanentlyDenied) {
      return LocationPermissionStatus.permanentlyDenied;
    }

    final result = await _locationService.requestLocationPermission();
    if (result) return LocationPermissionStatus.granted;

    // Re-check — may have become permanentlyDenied after the prompt
    final afterStatus = await Permission.location.status;
    if (afterStatus.isPermanentlyDenied) {
      return LocationPermissionStatus.permanentlyDenied;
    }
    return LocationPermissionStatus.denied;
  }

  // ---------------------------------------------------------------------------
  // Driver permissions (extends basic with background + mic + battery)
  // ---------------------------------------------------------------------------

  /// Requests the full driver permission set:
  ///   1. FCM notifications
  ///   2. Foreground location
  ///   3. Microphone (for voice messages)
  ///   4. Background location / "Allow all the time" (Android only)
  ///   5. Battery optimization exemption (Android only, one-time)
  ///
  /// The [context] is required for dialogs shown before requesting
  /// background location and battery exemption.
  Future<LocationPermissionStatus> requestDriverPermissions({
    required BuildContext context,
  }) async {
    // 1 & 2: Basic (FCM + foreground location)
    final basicResult = await requestBasicPermissions();
    // If foreground GPS is denied, skip the rest — they all depend on it.
    if (basicResult != LocationPermissionStatus.granted) return basicResult;

    // 3. Microphone
    try {
      final micStatus = await Permission.microphone.status;
      if (!micStatus.isGranted && !micStatus.isPermanentlyDenied) {
        await Permission.microphone.request();
      }
    } catch (_) {}

    // 4. Background location (Android 10+ only)
    if (defaultTargetPlatform == TargetPlatform.android) {
      if (!context.mounted) return LocationPermissionStatus.granted;
      await _requestBackgroundLocation(context);
    }

    // 5. Battery optimization exemption (Android, one-time)
    if (defaultTargetPlatform == TargetPlatform.android) {
      if (!context.mounted) return LocationPermissionStatus.granted;
      await _requestBatteryExemption(context);
    }

    return LocationPermissionStatus.granted;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<void> _requestBackgroundLocation(BuildContext context) async {
    final status = await Permission.locationAlways.status;
    if (status.isGranted) return;

    if (status.isPermanentlyDenied) {
      if (!context.mounted) return;
      final shouldOpen = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Background Location Required'),
          content: const Text(
            'To share your location when the screen is off, please open app '
            'Settings and set Location to "Allow all the time".',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Not now'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      if (shouldOpen == true) openAppSettings();
      return;
    }

    if (!context.mounted) return;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Background Location'),
        content: const Text(
          'Select "Allow all the time" on the next screen so students '
          'can track the bus even when your phone screen is off.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Skip'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (proceed == true) await Permission.locationAlways.request();
  }

  Future<void> _requestBatteryExemption(BuildContext context) async {
    final status = await Permission.ignoreBatteryOptimizations.status;
    if (status.isGranted) return;

    final prefs = await SharedPreferences.getInstance();
    final alreadyPrompted = prefs.getBool('battery_opt_prompted') ?? false;
    if (alreadyPrompted) return;
    await prefs.setBool('battery_opt_prompted', true);

    if (!context.mounted) return;
    final proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.battery_saver_rounded, color: Color(0xFF0097B2)),
            SizedBox(width: 10),
            Text('Keep GPS Running', style: TextStyle(fontSize: 17)),
          ],
        ),
        content: const Text(
          'To keep sending your location when the screen is off, '
          'please tap "Don\'t optimize" on the next screen.\n\n'
          'This prevents your phone\'s battery saver from stopping GPS tracking.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0097B2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (proceed == true) {
      await Permission.ignoreBatteryOptimizations.request();
    }
  }
}
