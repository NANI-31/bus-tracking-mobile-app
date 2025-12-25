import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'forgot_password_localizations_en.dart';
import 'forgot_password_localizations_hi.dart';
import 'forgot_password_localizations_te.dart';

abstract class ForgotPasswordLocalizations {
  ForgotPasswordLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static ForgotPasswordLocalizations? of(BuildContext context) {
    return Localizations.of<ForgotPasswordLocalizations>(
      context,
      ForgotPasswordLocalizations,
    );
  }

  static const LocalizationsDelegate<ForgotPasswordLocalizations> delegate =
      _ForgotPasswordLocalizationsDelegate();

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

  String get forgotPasswordTitle;
  String get forgotPasswordDescription;
  String get emailAddress;
  String get sendResetLink;
  String get backToLogin;
  String get resetLinkSent;
  String get checkYourEmail;
  String get didntReceiveEmail;
  String get resendEmail;
  String get enterValidEmail;
}

class _ForgotPasswordLocalizationsDelegate
    extends LocalizationsDelegate<ForgotPasswordLocalizations> {
  const _ForgotPasswordLocalizationsDelegate();

  @override
  Future<ForgotPasswordLocalizations> load(Locale locale) {
    return SynchronousFuture<ForgotPasswordLocalizations>(
      lookupForgotPasswordLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'te'].contains(locale.languageCode);

  @override
  bool shouldReload(_ForgotPasswordLocalizationsDelegate old) => false;
}

ForgotPasswordLocalizations lookupForgotPasswordLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return ForgotPasswordLocalizationsEn();
    case 'hi':
      return ForgotPasswordLocalizationsHi();
    case 'te':
      return ForgotPasswordLocalizationsTe();
  }

  throw FlutterError(
    'ForgotPasswordLocalizations.delegate failed to load unsupported locale "$locale".',
  );
}
