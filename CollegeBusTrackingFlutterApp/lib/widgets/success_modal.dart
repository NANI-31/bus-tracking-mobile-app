import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';

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
      child: ZStack([
        // The Card
        VStack([
              10.heightBox,
              title.text
                  .size(20)
                  .bold
                  .color(const Color(0xFF2D3142))
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
              if (primaryActionText != null) ...[
                30.heightBox,
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
                        minimumSize: const Size(140, 48),
                      ),
                      child: primaryActionText!.text.size(16).semiBold.make(),
                    ).box.shadow
                    .withRounded(value: 30)
                    .color(baseColor.withOpacity(0.4))
                    .make(),
              ] else ...[
                20.heightBox, // Spacing if no button
              ],
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
      // Decorative Bubbles
      _bubble(size: 10, top: 10, left: 10, color: baseColor.withOpacity(0.5)),
      _bubble(size: 8, top: 70, right: 10, color: baseColor.withOpacity(0.6)),
      _bubble(size: 14, bottom: 0, left: 30, color: baseColor.withOpacity(0.4)),

      // Main Circle
      Icon(icon, size: 24, color: Colors.white)
          .centered()
          .box
          .height(40)
          .width(40)
          .color(baseColor.withOpacity(0.8)) // Solid icon bg
          .roundedFull
          .border(color: Colors.white, width: 2)
          .make()
          .centered()
          .box
          .height(80)
          .width(80)
          .color(baseColor.withOpacity(0.3))
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
