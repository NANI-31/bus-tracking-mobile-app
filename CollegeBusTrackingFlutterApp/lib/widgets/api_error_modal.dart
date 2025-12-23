import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:collegebus/utils/constants.dart';

class ApiErrorModal extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color
  baseColor; // The main theme color (Red for error, Green for success)
  final String primaryActionText;
  final VoidCallback onPrimaryAction;
  final String? secondaryActionText;
  final VoidCallback? onSecondaryAction;

  const ApiErrorModal({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.baseColor,
    required this.primaryActionText,
    required this.onPrimaryAction,
    this.secondaryActionText,
    this.onSecondaryAction,
  });

  static void show({
    required BuildContext context,
    required dynamic error,
    VoidCallback? onRetry,
  }) {
    final content = _mapErrorToContent(context, error, onRetry);

    showDialog(
      context: context,
      barrierDismissible: true, // Allow clicking outside
      builder: (context) => ApiErrorModal(
        title: content.title,
        message: content.message,
        icon: content.icon,
        baseColor: content.iconColor,
        primaryActionText: content.primaryActionText,
        onPrimaryAction: content.onPrimaryAction,
        secondaryActionText: content.secondaryActionText,
        onSecondaryAction: content.onSecondaryAction,
      ),
    );
  }

  static _ErrorContent _mapErrorToContent(
    BuildContext context,
    dynamic error,
    VoidCallback? onRetry,
  ) {
    int? statusCode;
    String? serverMessage;

    // Handle String errors
    if (error is String) {
      return _ErrorContent(
        title: 'Notice',
        message: error,
        icon: Icons.info_outline_rounded,
        iconColor: Colors.blueAccent,
        primaryActionText: 'OK',
        onPrimaryAction: () => Navigator.pop(context),
      );
    }

    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError) {
        return _ErrorContent(
          title: 'Connection Lost',
          message: 'No internet connection. Please check your settings.',
          icon: Icons.wifi_off_rounded,
          iconColor: Colors.orange,
          primaryActionText: 'Retry',
          onPrimaryAction: () {
            Navigator.pop(context);
            onRetry?.call();
          },
        );
      }
      statusCode = error.response?.statusCode;
      if (error.response?.data is Map &&
          error.response?.data['message'] != null) {
        serverMessage = error.response?.data['message'];
      }
    }

    switch (statusCode) {
      case 500:
        return _ErrorContent(
          title: 'Server Error',
          message: 'Something went wrong on our end. Please try again.',
          icon: Icons.dns_rounded,
          iconColor: const Color(0xFFFF8A80), // Soft Red
          primaryActionText: 'Retry',
          onPrimaryAction: () {
            Navigator.pop(context);
            onRetry?.call();
          },
        );
      case 400:
      case 409:
        return _ErrorContent(
          title: 'Oops!',
          message:
              serverMessage ??
              'Information seems incorrect. Please check again.',
          icon: Icons.close_rounded,
          iconColor: const Color(0xFFFF8A80), // Soft Red matches design
          primaryActionText: 'Try Changes',
          onPrimaryAction: () => Navigator.pop(context),
        );
      case 401:
        return _ErrorContent(
          title: 'Expired',
          message: 'Your session has expired. Please log in again.',
          icon: Icons.lock_open_rounded,
          iconColor: Colors.orangeAccent,
          primaryActionText: 'Log In',
          onPrimaryAction: () {
            Navigator.pop(context);
            context.go('/login');
          },
        );
      case 403:
        return _ErrorContent(
          title: 'Restricted',
          message: serverMessage ?? 'You don’t have permission to do this.',
          icon: Icons.block_rounded,
          iconColor: Colors.redAccent,
          primaryActionText: 'Go Back',
          onPrimaryAction: () => Navigator.pop(context),
        );
      default:
        // Generic Fallback
        final defaultMsg = error?.toString().replaceAll('Exception: ', '');
        return _ErrorContent(
          title: 'Error',
          message: serverMessage ?? (defaultMsg ?? 'Something went wrong.'),
          icon: Icons.close_rounded,
          iconColor: const Color(0xFFFF8A80), // Soft Red
          primaryActionText: 'Try Again',
          onPrimaryAction: () {
            Navigator.pop(context);
            onRetry?.call();
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent, // Important for custom shape
      elevation: 0,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              24,
              60,
              24,
              32,
            ), // Top padding for icon
            margin: const EdgeInsets.only(top: 40), // Space for top icon
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142), // Dark grey like mockup
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                // Pill Button
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: baseColor.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: onPrimaryAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: baseColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 14,
                      ),
                      shape: const StadiumBorder(),
                      elevation: 0,
                      minimumSize: const Size(140, 48), // Minimal width
                    ),
                    child: Text(
                      primaryActionText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // The Floating Icon (Bubbles)
          Positioned(top: 0, child: _buildBubbleIcon()),
        ],
      ),
    );
  }

  Widget _buildBubbleIcon() {
    return SizedBox(
      height: 100,
      width: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Decorative Bubbles (Hardcoded positions for 'random' look)
          _bubble(
            size: 10,
            top: 10,
            left: 10,
            color: baseColor.withOpacity(0.5),
          ),
          _bubble(
            size: 8,
            top: 70,
            right: 10,
            color: baseColor.withOpacity(0.6),
          ),
          _bubble(
            size: 14,
            bottom: 0,
            left: 30,
            color: baseColor.withOpacity(0.4),
          ),

          // Main Circle
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              color: baseColor.withOpacity(0.3), // Lighter BG
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Center(
              child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: baseColor.withOpacity(0.2), // Inner Circle
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.black87,
                    width: 2,
                  ), // The stylized border
                ),
                child: Center(
                  child: Icon(icon, size: 24, color: Colors.black87),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _ErrorContent {
  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;
  final String primaryActionText;
  final VoidCallback onPrimaryAction;
  final String? secondaryActionText;
  final VoidCallback? onSecondaryAction;

  _ErrorContent({
    required this.title,
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.primaryActionText,
    required this.onPrimaryAction,
    this.secondaryActionText,
    this.onSecondaryAction,
  });
}
