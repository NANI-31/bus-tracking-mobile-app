import 'package:flutter/material.dart';

class WelcomeSection extends StatelessWidget {
  final String userName;

  const WelcomeSection({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Good Morning, $userName",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          "Your bus status for today",
          style: TextStyle(
            fontSize: 16,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
