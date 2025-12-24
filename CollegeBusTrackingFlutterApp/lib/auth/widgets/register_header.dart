import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:velocity_x/velocity_x.dart';

class RegisterHeader extends StatelessWidget {
  const RegisterHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return ZStack(
      [
        // Background Image
        // Background Image
        Container(
          width: double.infinity,
          height: 260,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: CachedNetworkImageProvider(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuBJItvO1MgqjYaxS_PfHAyRmbVhVWYpLXUl8F4KCUTCh4_c_itizw_oquqb5HY7la0sDtQ9HLqA9IKUFzmL9yULoXzIOVLeIiVFwpzx7XqL_ng2ylqv2J4hwd0Wagvhyv0X064b8Wu7tjLGDgW-LzwRaTxVYYiGQ3xOn4_5_D9WaLw5NxQGPXhSz3MyyVKu1tGRPOrYtRkoT9yWxa5T_CXnz-wUJcVF79QNONhwV87nLeP3Efjd81tkpq0g8l5qKG7lfyr5aQ4jC25B',
              ),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Theme.of(
                    context,
                  ).scaffoldBackgroundColor.withValues(alpha: 0.2),
                  Theme.of(context).scaffoldBackgroundColor,
                ],
                stops: const [0.0, 0.4, 0.8, 1.0],
              ),
            ),
          ),
        ),

        // Floating Icon Card
        VxBox(
              child: Icon(
                Icons.location_on_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            )
            .color(Theme.of(context).colorScheme.surface)
            .rounded
            .withShadow([
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ])
            .size(70, 70)
            .make()
            .positioned(bottom: -35),

        // Back Button Overlay
        CircleAvatar(
          backgroundColor: Colors.white.withOpacity(0.2),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.go('/login'),
          ),
        ).positioned(top: 50, left: 16),
      ],
      alignment: Alignment.bottomCenter,
      clip: Clip.none,
    );
  }
}
