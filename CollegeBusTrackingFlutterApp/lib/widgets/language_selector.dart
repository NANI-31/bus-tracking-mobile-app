import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/services/locale_service.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleService>(
      builder: (context, localeService, _) => ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: localeService.locale.languageCode,
                dropdownColor: Colors.black.withValues(alpha: 0.85),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    localeService.setLocale(Locale(newValue));
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
                      4.widthBox,
                    ]);
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
