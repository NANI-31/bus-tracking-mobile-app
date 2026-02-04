import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/core/providers/service_providers.dart';

class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeService = ref.watch(localeServiceProvider);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.0,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: localeService.languageCode,
              dropdownColor: Colors.black.withOpacity(0.85),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white,
                size: 20,
              ),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  ref
                      .read(localeServiceProvider.notifier)
                      .setLocale(Locale(newValue));
                }
              },
              items: [
                DropdownMenuItem(
                  value: 'en',
                  child: HStack([
                    const Icon(Icons.language, color: Colors.white, size: 18),
                    8.widthBox,
                    'English'.text.white.semiBold.make(),
                  ]),
                ),
                DropdownMenuItem(
                  value: 'te',
                  child: HStack([
                    const Icon(Icons.language, color: Colors.white, size: 18),
                    8.widthBox,
                    'తెలుగు'.text.white.semiBold.make(),
                  ]),
                ),
                DropdownMenuItem(
                  value: 'hi',
                  child: HStack([
                    const Icon(Icons.language, color: Colors.white, size: 18),
                    8.widthBox,
                    'हिंदी'.text.white.semiBold.make(),
                  ]),
                ),
              ],
              selectedItemBuilder: (BuildContext context) {
                return ['en', 'te', 'hi'].map((String value) {
                  String label = 'English';
                  if (value == 'te') label = 'తెలుగు';
                  if (value == 'hi') label = 'हिंदी';
                  return HStack([
                    const Icon(Icons.language, color: Colors.white, size: 18),
                    8.widthBox,
                    label.text.white.semiBold.make(),
                  ]);
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}





