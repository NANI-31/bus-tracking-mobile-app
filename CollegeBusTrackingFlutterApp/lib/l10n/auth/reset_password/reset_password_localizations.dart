import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'reset_password_localizations_en.dart';
import 'reset_password_localizations_hi.dart';
import 'reset_password_localizations_te.dart';

abstract class ResetPasswordLocalizations {
  ResetPasswordLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static ResetPasswordLocalizations? of(BuildContext context) {
    return Localizations.of<ResetPasswordLocalizations>(
      context,
      ResetPasswordLocalizations,
    );
  }

  static const LocalizationsDelegate<ResetPasswordLocalizations> delegate =
      _ResetPasswordLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('te'),
  ];

  String get resetPasswordTitle;
  String get resetPasswordDescription;
  String get newPassword;
  String get confirmPassword;
  String get resetPassword;
  String get passwordUpdated;
  String get passwordMismatch;
  String get passwordTooShort;
  String get passwordRequirements;
  String get loginWithNewPassword;
  String get enterNewPassword;
  String get reenterPassword;
}

class _ResetPasswordLocalizationsDelegate
    extends LocalizationsDelegate<ResetPasswordLocalizations> {
  const _ResetPasswordLocalizationsDelegate();

  @override
  Future<ResetPasswordLocalizations> load(Locale locale) {
    return SynchronousFuture<ResetPasswordLocalizations>(
      lookupResetPasswordLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'te'].contains(locale.languageCode);

  @override
  bool shouldReload(_ResetPasswordLocalizationsDelegate old) => false;
}

ResetPasswordLocalizations lookupResetPasswordLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return ResetPasswordLocalizationsEn();
    case 'hi':
      return ResetPasswordLocalizationsHi();
    case 'te':
      return ResetPasswordLocalizationsTe();
  }

  throw FlutterError(
    'ResetPasswordLocalizations.delegate failed to load unsupported locale "$locale".',
  );
}
