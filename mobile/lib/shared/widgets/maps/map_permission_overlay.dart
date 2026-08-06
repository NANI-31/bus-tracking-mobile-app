import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:collegebus/core/services/app_permissions_service.dart';

/// Wraps any map widget and shows a graceful overlay when location permission
/// is [LocationPermissionStatus.denied] or [LocationPermissionStatus.permanentlyDenied].
///
/// Usage:
/// ```dart
/// MapPermissionOverlay(
///   permissionsService: ref.read(appPermissionsServiceProvider),
///   child: CommonMapView(...),
/// )
/// ```
class MapPermissionOverlay extends StatefulWidget {
  final AppPermissionsService permissionsService;
  final Widget child;

  const MapPermissionOverlay({
    super.key,
    required this.permissionsService,
    required this.child,
  });

  @override
  State<MapPermissionOverlay> createState() => _MapPermissionOverlayState();
}

class _MapPermissionOverlayState extends State<MapPermissionOverlay> {
  LocationPermissionStatus _status = LocationPermissionStatus.granted;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final status = await widget.permissionsService.checkLocationStatus();
    // DIAGNOSTIC: Shows whether the overlay is blocking the map or passing through.
    // If you see "BLOCKED" repeatedly the OS hasn't registered the permission grant.
    debugPrint('[MapPermissionOverlay] Permission check result: $status '
        '(${status == LocationPermissionStatus.granted ? "MAP SHOWN ✅" : "BLOCKED ⛔"})');
    if (mounted) {
      setState(() {
        _status = status;
        _loading = false;
      });
    }
  }

  Future<void> _onAllowTapped() async {
    setState(() => _loading = true);
    final result = await widget.permissionsService.requestBasicPermissions();
    if (mounted) {
      setState(() {
        _status = result;
        _loading = false;
      });
    }
  }

  Future<void> _onOpenSettingsTapped() async {
    await openAppSettings();
    // Re-check after user returns from settings
    await _checkStatus();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      // While checking, show the map skeleton placeholder
      return const _MapPlaceholder(child: CircularProgressIndicator());
    }

    if (_status == LocationPermissionStatus.granted) {
      return widget.child;
    }

    return _MapPlaceholder(
      child: _PermissionCard(
        isPermanentlyDenied:
            _status == LocationPermissionStatus.permanentlyDenied,
        onAllow: _onAllowTapped,
        onOpenSettings: _onOpenSettingsTapped,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

class _MapPlaceholder extends StatelessWidget {
  final Widget child;
  const _MapPlaceholder({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFE8F0FE),
      child: Center(child: child),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final bool isPermanentlyDenied;
  final VoidCallback onAllow;
  final VoidCallback onOpenSettings;

  const _PermissionCard({
    required this.isPermanentlyDenied,
    required this.onAllow,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.08),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF0097B2).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_off_rounded,
              size: 32,
              color: Color(0xFF0097B2),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            'Location Access Required',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 10),

          // Description
          Text(
            isPermanentlyDenied
                ? 'Location access was permanently denied. Please open app '
                    'Settings and enable "Location" to use the map.'
                : 'This map needs your location to show buses near you. '
                    'Please allow location access to continue.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // Buttons
          if (isPermanentlyDenied)
            _ActionButton(
              label: 'Open Settings',
              icon: Icons.settings_rounded,
              onTap: onOpenSettings,
            )
          else ...[
            _ActionButton(
              label: 'Allow Location',
              icon: Icons.my_location_rounded,
              onTap: onAllow,
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: onOpenSettings,
              child: Text(
                'Open Settings instead',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0097B2),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
