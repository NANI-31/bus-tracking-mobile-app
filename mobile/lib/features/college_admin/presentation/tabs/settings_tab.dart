import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/features/settings/presentation/sos_sound_settings.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'College Settings',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSizes.paddingMedium),

          _GlassmorphicCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.school),
                  title: const Text('College Profile'),
                  subtitle: const Text(
                    'Update college name and domains',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Notification Preferences'),
                  subtitle: const Text(
                    'Configure college notifications',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.how_to_reg),
                  title: const Text('Approval Settings'),
                  subtitle: const Text(
                    'Auto-approve students, manual driver approval',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.paddingMedium),

          _GlassmorphicCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: const SosSoundSettings(),
            ),
          ),
          const SizedBox(height: AppSizes.paddingMedium),
        ],
      ),
    );
  }
}

class _GlassmorphicCard extends StatelessWidget {
  final Widget child;

  const _GlassmorphicCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: isDark ? 0.08 : 0.04),
            blurRadius: 20,
            spreadRadius: -4,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surface.withValues(alpha: 0.45)
                  : colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                width: 1.0,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
