import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:collegebus/core/router/router.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/core/services/persistence_service.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';

/// Modal dialog presented when user session expires or token becomes invalid.
/// Smoothly informs the user and redirects them back to the Login screen.
class SessionExpiryDialog extends StatelessWidget {
  final VoidCallback? onConfirm;

  const SessionExpiryDialog({super.key, this.onConfirm});

  static bool _isShowing = false;

  /// Display the session expiry modal.
  /// Uses [context] if passed, or falls back to [rootNavigatorKey.currentContext].
  static Future<void> show({BuildContext? context, VoidCallback? onConfirm}) async {
    if (_isShowing) return;
    if (AuthNotifier.isExplicitLoggingOut) return;

    final token = PersistenceService.getAuthToken();
    if (token == null || token.isEmpty) return;

    final ctx = context ?? rootNavigatorKey.currentContext;
    if (ctx == null) return;

    _isShowing = true;
    try {
      await showDialog(
        context: ctx,
        barrierDismissible: false,
        builder: (dialogCtx) => SessionExpiryDialog(onConfirm: onConfirm),
      );
    } finally {
      _isShowing = false;
    }
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.08),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing Lock Icon Container
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEA580C), Color(0xFFDC2626)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.35),
                        blurRadius: 16,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_clock_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  'Session Expired',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                // Description
                Text(
                  'Your session has expired or your security token is no longer valid. Please sign in again to continue.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.7)
                        : const Color(0xFF475569),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Primary Action Button (Log In)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pop();
                      if (onConfirm != null) {
                        onConfirm!();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Log In Again',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
