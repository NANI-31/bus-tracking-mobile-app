import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';

class LogoutLoadingDialog extends StatelessWidget {
  const LogoutLoadingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        content: HStack([
          const CircularProgressIndicator(),
          20.widthBox,
          "Logging out...".text.size(16).make(),
        ]).p12(),
      ),
    );
  }

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LogoutLoadingDialog(),
    );
  }

  static void hide(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }
}
