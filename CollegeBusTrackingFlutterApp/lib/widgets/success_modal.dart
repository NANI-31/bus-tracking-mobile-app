import 'package:flutter/material.dart';

class SuccessModal extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color baseColor;
  final VoidCallback? onPrimaryAction;
  final String? primaryActionText;

  const SuccessModal({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.check_rounded,
    this.baseColor = const Color(0xFF95E08E), // Soft Green from mockup
    this.onPrimaryAction,
    this.primaryActionText,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    int? autoCloseDurationSeconds,
    IconData? icon,
    VoidCallback? onPrimaryAction,
    String? primaryActionText,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SuccessModal(
        title: title,
        message: message,
        icon: icon ?? Icons.check_rounded,
        onPrimaryAction: onPrimaryAction,
        primaryActionText: primaryActionText,
      ),
    );

    if (autoCloseDurationSeconds != null) {
      await Future.delayed(Duration(seconds: autoCloseDurationSeconds));
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
            margin: const EdgeInsets.only(top: 40),
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
                    color: Color(0xFF2D3142),
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
                if (primaryActionText != null) ...[
                  const SizedBox(height: 30),
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
                        minimumSize: const Size(140, 48),
                      ),
                      child: Text(
                        primaryActionText!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 20), // Spacing if no button
                ],
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
          // Decorative Bubbles
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
              color: baseColor.withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Center(
              child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: baseColor.withOpacity(0.8), // Solid icon bg
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(child: Icon(icon, size: 24, color: Colors.white)),
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
