import 'forgot_password_localizations.dart';

class ForgotPasswordLocalizationsHi extends ForgotPasswordLocalizations {
  ForgotPasswordLocalizationsHi() : super('hi');

  @override
  String get forgotPasswordTitle => 'पासवर्ड भूल गए';

  @override
  String get forgotPasswordDescription =>
      'अपना ईमेल पता दर्ज करें और हम आपको पासवर्ड रीसेट करने के लिए एक लिंक भेजेंगे।';

  @override
  String get emailAddress => 'ईमेल पता';

  @override
  String get sendResetLink => 'रीसेट लिंक भेजें';

  @override
  String get backToLogin => 'लॉगिन पर वापस जाएं';

  @override
  String get resetLinkSent => 'पासवर्ड रीसेट लिंक आपके ईमेल पर भेजा गया!';

  @override
  String get checkYourEmail => 'अपना ईमेल जांचें';

  @override
  String get didntReceiveEmail => 'ईमेल नहीं मिला?';

  @override
  String get resendEmail => 'ईमेल पुनः भेजें';

  @override
  String get enterValidEmail => 'कृपया एक वैध ईमेल पता दर्ज करें';
}
