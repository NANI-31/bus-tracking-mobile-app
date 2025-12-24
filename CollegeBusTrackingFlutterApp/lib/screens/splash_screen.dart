import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: VStack(
        [
          // App Logo
          Image.asset(
            'assets/images/upashtit-logo-new.png',
          ).box.width(150).height(150).make(),
          32.heightBox,
          // Horizontal loading bar
          LinearProgressIndicator(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.1),
            color: Theme.of(context).primaryColor,
            minHeight: 6,
          ).box.width(120).make(),
        ],
        alignment: MainAxisAlignment.center,
        crossAlignment: CrossAxisAlignment.center,
      ).centered(),
    );
  }
}
