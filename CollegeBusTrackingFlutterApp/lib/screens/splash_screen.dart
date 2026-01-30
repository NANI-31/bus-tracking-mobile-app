import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            SizedBox(
              width: 180,
              height: 180,
              child: Image.asset(
                'assets/images/upashtit-logo-new.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 32),
            // Horizontal loading bar
            SizedBox(
              width: 140,
              child: LinearProgressIndicator(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.1),
                color: Theme.of(context).primaryColor,
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
