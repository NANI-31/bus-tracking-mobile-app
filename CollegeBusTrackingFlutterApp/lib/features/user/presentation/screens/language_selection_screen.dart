import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/core/providers/service_providers.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/features/user/application/user_provider.dart';
import 'package:collegebus/l10n/common/app_localizations.dart' as common_l10n;

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = common_l10n.CommonLocalizations.of(context)!;
    final locale = ref.watch(localeServiceProvider);
    final currentCode = locale.languageCode;

    final languages = [
      {'code': 'en', 'name': l10n.english, 'nativeName': 'English'},
      {'code': 'te', 'name': l10n.telugu, 'nativeName': 'తెలుగు'},
      {'code': 'hi', 'name': l10n.hindi, 'nativeName': 'हिंदी'},
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.language),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
      ),
      body: VStack([
        16.heightBox,
        "Select your preferred language".text
            .size(16)
            .color(
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            )
            .make()
            .pSymmetric(h: 16),
        24.heightBox,
        ListView.separated(
          itemCount: languages.length,
          separatorBuilder: (context, index) => 12.heightBox,
          itemBuilder: (context, index) {
            final lang = languages[index];
            final code = lang['code']!;
            final isSelected = currentCode == code;

            return _buildLanguageCard(
              context,
              ref,
              code,
              lang['name']!,
              lang['nativeName']!,
              isSelected,
            );
          },
        ).expand(),
      ]).p(16),
    );
  }

  Widget _buildLanguageCard(
    BuildContext context,
    WidgetRef ref,
    String code,
    String name,
    String nativeName,
    bool isSelected,
  ) {
    return VxBox(
          child: HStack([
            VStack([
              nativeName.text
                  .size(18)
                  .bold
                  .color(
                    isSelected
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).colorScheme.onSurface,
                  )
                  .make(),
              4.heightBox,
              name.text
                  .size(14)
                  .color(
                    Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  )
                  .make(),
            ]).expand(),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: Theme.of(context).primaryColor,
                size: 28,
              ),
          ]),
        )
        .color(Theme.of(context).cardColor)
        .shadowSm
        .roundedLg
        .p16
        .border(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.transparent,
          width: 2,
        )
        .make()
        .onInkTap(() async {
          // 1. Update Locale locally
          ref.read(localeServiceProvider.notifier).setLocale(Locale(code));

          // 2. Update User Preference on Server
          final user = ref.read(currentUserProvider);
          if (user != null) {
            await ref.read(userListProvider.notifier).updateUser(user.id, {
              'language': code,
            });
          }

          // Optional: Pop back or stay? Usually selection pops back or shows visual confirmation
          // For now, let's keep it on screen so user sees the change
        });
  }
}
