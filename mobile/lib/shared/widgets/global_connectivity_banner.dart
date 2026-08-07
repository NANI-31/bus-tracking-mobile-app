import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/core/services/socket_service.dart';
import 'package:collegebus/core/providers/socket_provider.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


class GlobalConnectivityBanner extends ConsumerStatefulWidget {
  final Widget? child;
  const GlobalConnectivityBanner({super.key, this.child});

  /// Suppress the offline banner for [duration] starting now.
  /// Call from anywhere (e.g. driver dashboard on app resume) to prevent
  /// the misleading red flash during normal post-resume socket reconnection.
  static void suppress(Duration duration) {
    _suppressUntil = DateTime.now().add(duration);
  }

  static DateTime? _suppressUntil;

  @override
  ConsumerState<GlobalConnectivityBanner> createState() => _GlobalConnectivityBannerState();
}

class _GlobalConnectivityBannerState extends ConsumerState<GlobalConnectivityBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;

  bool _wasConnected = true;
  bool _showBanner = false;
  bool _isReconnectedState = false;
  Timer? _hideTimer;
  Timer? _gracePeriodTimer;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    _hideTimer?.cancel();
    _gracePeriodTimer?.cancel();
    super.dispose();
  }

  void _triggerSlideDown() {
    setState(() {
      _showBanner = true;
    });
    _slideController.forward();
  }

  void _triggerSlideUp() {
    _slideController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showBanner = false;
          _isReconnectedState = false;
        });
      }
    });
  }

  void _handleConnectionStateChange(bool isConnected) {
    if (isConnected) {
      if (!_wasConnected) {
        _wasConnected = true;
        _gracePeriodTimer?.cancel();
        _hideTimer?.cancel();

        setState(() {
          _isReconnectedState = true;
        });
        _triggerSlideDown();

        // Reconnected green banner stays for 2.5 seconds, then slides up
        _hideTimer = Timer(const Duration(milliseconds: 2500), () {
          if (mounted) {
            _triggerSlideUp();
          }
        });
      }
    } else {
      // Disconnected or connecting
      if (_wasConnected) {
        _wasConnected = false;
        _hideTimer?.cancel();

        // Add a grace period before showing the offline banner.
        // On resume from background, we extend the grace period to 6 s to
        // cover the normal socket reconnect window (avoids misleading flash).
        _gracePeriodTimer?.cancel();
        final isSuppressed = GlobalConnectivityBanner._suppressUntil != null &&
            DateTime.now().isBefore(GlobalConnectivityBanner._suppressUntil!);
        final graceDuration = isSuppressed
            ? const Duration(seconds: 6)
            : const Duration(seconds: 2);

        _gracePeriodTimer = Timer(graceDuration, () {
          final svc = ref.read(socketServiceProvider);
          debugPrint(
            '[Banner] 🚨 Grace period expired — showing banner. '
            'isConnected=${svc.isConnected} isConnecting=${svc.isConnecting}',
          );
          if (mounted && !svc.isConnected) {
            setState(() {
              _isReconnectedState = false;
            });
            _triggerSlideDown();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(isLoggedInProvider);
    if (!isLoggedIn) {
      _wasConnected = true;
      _gracePeriodTimer?.cancel();
      _hideTimer?.cancel();
      if (_showBanner) {
        _showBanner = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _slideController.reset();
          }
        });
      }
      return widget.child ?? const SizedBox.shrink();
    }

    // Safely listen for socket connection state transitions without side-effects in build()
    ref.listen<SocketService>(socketServiceProvider, (previous, next) {
      _handleConnectionStateChange(next.isConnected);
    });

    final socketService = ref.watch(socketServiceProvider);
    final isConnecting = socketService.isConnecting;



    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double bannerHeight = statusBarHeight + 28;

    // Setup style/text using AppStatusThemeExtension tokens so banner colors
    // respect light/dark mode without hardcoded hex literals.
    final statusTokens = context.appStatus;
    final Color startColor;
    final Color endColor;
    final String statusText;
    final Widget icon;

    if (_isReconnectedState) {
      startColor = statusTokens.reconnectedColor;
      endColor = statusTokens.reconnectedColor.withValues(alpha: 0.85);
      statusText = "Back Online";
      icon = const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 14);
    } else {
      startColor = statusTokens.disconnectedColor;
      endColor = statusTokens.disconnectedColor.withValues(alpha: 0.85);
      statusText = isConnecting ? "Connecting to server..." : "Offline. Retrying...";
      icon = const SizedBox(
        width: 10,
        height: 10,
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    return Stack(
      children: [
        if (widget.child != null) widget.child!,
        if (_showBanner)
          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              final offset = (1.0 - _slideAnimation.value) * -bannerHeight;
              return Positioned(
                top: offset,
                left: 0,
                right: 0,
                height: bannerHeight,
                child: Material(
                  elevation: 4,
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [startColor, endColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.only(top: statusBarHeight),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        icon,
                        const SizedBox(width: 8),
                        Text(
                          statusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// CachedPositionBanner
// ---------------------------------------------------------------------------

/// A subtle glassmorphic pill displayed at the bottom of a map `Stack` when
/// the socket is offline but a last-known bus position is available.
///
/// Mount this inside any map-tab `Stack` and pass the last-received [LatLng]
/// and [lastUpdateTime]. It hides itself automatically when the socket
/// reconnects.
///
/// Example:
/// ```dart
/// Stack(
///   children: [
///     LiveBusMap(...),
///     CachedPositionBanner(
///       lastKnownPosition: _liveBusLocation,
///       lastUpdateTime: _lastSocketUpdate,
///       bottomOffset: 80.0,
///     ),
///   ],
/// )
/// ```
class CachedPositionBanner extends ConsumerWidget {
  final LatLng? lastKnownPosition;
  final DateTime? lastUpdateTime;

  /// Distance from the bottom of the `Stack` to the banner (used to sit
  /// above bottom navigation bars or control panels).
  final double bottomOffset;

  const CachedPositionBanner({
    super.key,
    required this.lastKnownPosition,
    this.lastUpdateTime,
    this.bottomOffset = 80.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Granular select: only rebuild when isConnected changes.
    final isConnected = ref.watch(
      socketServiceProvider.select((s) => s.isConnected),
    );

    // Hide when online or when we have no cached position to show.
    if (isConnected || lastKnownPosition == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusTokens = context.appStatus;

    final String ageLabel;
    if (lastUpdateTime != null) {
      final diff = DateTime.now().difference(lastUpdateTime!);
      if (diff.inSeconds < 60) {
        ageLabel = '${diff.inSeconds}s ago';
      } else if (diff.inMinutes < 60) {
        ageLabel = '${diff.inMinutes} min ago';
      } else {
        ageLabel = '${diff.inHours}h ago';
      }
    } else {
      ageLabel = 'last known';
    }

    return Positioned(
      left: 16,
      right: 16,
      bottom: bottomOffset,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          // Glassmorphic tint with amber accent border to signal stale state
          color: isDark
              ? Colors.black.withValues(alpha: 0.65)
              : Colors.white.withValues(alpha: 0.80),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: statusTokens.delayColor.withValues(alpha: 0.60),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on_rounded,
              size: 16,
              color: statusTokens.delayColor,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Cached position \u00B7 $ageLabel',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.90)
                      : Colors.black.withValues(alpha: 0.75),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  statusTokens.delayColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

