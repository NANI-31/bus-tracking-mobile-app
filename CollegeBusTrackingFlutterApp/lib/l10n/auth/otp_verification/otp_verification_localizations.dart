import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'otp_verification_localizations_en.dart';
import 'otp_verification_localizations_hi.dart';
import 'otp_verification_localizations_te.dart';

abstract class OtpVerificationLocalizations {
  OtpVerificationLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static OtpVerificationLocalizations? of(BuildContext context) {
    return Localizations.of<OtpVerificationLocalizations>(
      context,
      OtpVerificationLocalizations,
    );
  }

  static const LocalizationsDelegate<OtpVerificationLocalizations> delegate =
      _OtpVerificationLocalizationsDelegate();

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

  String get otpVerificationTitle;
  String get otpVerificationDescription;
  String get enterOtp;
  String get verifyOtp;
  String get resendOtp;
  String get didntReceiveOtp;
  String get otpExpired;
  String get invalidOtp;
  String get otpSentSuccessfully;
  String get verifying;
  String get otpVerified;
  String get codeExpiresIn;
  String get seconds;
}

class _OtpVerificationLocalizationsDelegate
    extends LocalizationsDelegate<OtpVerificationLocalizations> {
  const _OtpVerificationLocalizationsDelegate();

  @override
  Future<OtpVerificationLocalizations> load(Locale locale) {
    return SynchronousFuture<OtpVerificationLocalizations>(
      lookupOtpVerificationLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'te'].contains(locale.languageCode);

  @override
  bool shouldReload(_OtpVerificationLocalizationsDelegate old) => false;
}

OtpVerificationLocalizations lookupOtpVerificationLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return OtpVerificationLocalizationsEn();
    case 'hi':
      return OtpVerificationLocalizationsHi();
    case 'te':
      return OtpVerificationLocalizationsTe();
  }

  throw FlutterError(
    'OtpVerificationLocalizations.delegate failed to load unsupported locale "$locale".',
  );
}
