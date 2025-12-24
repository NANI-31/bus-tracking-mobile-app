import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:velocity_x/velocity_x.dart';
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
      child: ZStack([
        // The Card
        VStack([
              10.heightBox,
              title.text
                  .size(20)
                  .bold
                  .color(const Color(0xFF2D3142)) // Dark grey like mockup
                  .letterSpacing(0.5)
                  .center
                  .make(),
              12.heightBox,
              message.text
                  .size(14)
                  .color(Colors.grey[500])
                  .heightRelaxed
                  .center
                  .make(),
              30.heightBox,
              // Pill Button
              ElevatedButton(
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
                child: primaryActionText.text.size(16).semiBold.make(),
              ).box.shadow.withRounded(value: 30).make(),
            ])
            .pLTRB(24, 60, 24, 32)
            .box
            .width(double.infinity)
            .color(Colors.white)
            .customRounded(BorderRadius.circular(30))
            .shadow2xl
            .make()
            .pOnly(top: 40),

        // The Floating Icon (Bubbles)
        _buildBubbleIcon().pOnly(top: 0),
      ], alignment: Alignment.center),
    );
  }

  Widget _buildBubbleIcon() {
    return ZStack([
      // Decorative Bubbles (Hardcoded positions for 'random' look)
      _bubble(size: 10, top: 10, left: 10, color: baseColor.withOpacity(0.5)),
      _bubble(size: 8, top: 70, right: 10, color: baseColor.withOpacity(0.6)),
      _bubble(size: 14, bottom: 0, left: 30, color: baseColor.withOpacity(0.4)),

      // Main Circle
      Icon(icon, size: 24, color: Colors.black87)
          .centered()
          .box
          .height(40)
          .width(40)
          .color(baseColor.withOpacity(0.2)) // Inner Circle
          .roundedFull
          .border(color: Colors.black87, width: 2)
          .make()
          .centered()
          .box
          .height(80)
          .width(80)
          .color(baseColor.withOpacity(0.3)) // Lighter BG
          .roundedFull
          .border(color: Colors.white, width: 4)
          .make(),
    ], alignment: Alignment.center).box.height(100).width(100).make();
  }

  Widget _bubble({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required Color color,
  }) {
    return VxBox()
        .height(size)
        .width(size)
        .color(color)
        .roundedFull
        .make()
        .positioned(top: top, bottom: bottom, left: left, right: right);
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
