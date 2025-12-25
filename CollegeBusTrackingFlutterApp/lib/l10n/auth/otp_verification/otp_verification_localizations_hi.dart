import 'otp_verification_localizations.dart';

class OtpVerificationLocalizationsHi extends OtpVerificationLocalizations {
  OtpVerificationLocalizationsHi() : super('hi');

  @override
  String get otpVerificationTitle => 'ओटीपी सत्यापन';

  @override
  String get otpVerificationDescription =>
      'अपने फोन/ईमेल पर भेजा गया 6-अंकों का कोड दर्ज करें';

  @override
  String get enterOtp => 'ओटीपी दर्ज करें';

  @override
  String get verifyOtp => 'ओटीपी सत्यापित करें';

  @override
  String get resendOtp => 'ओटीपी पुनः भेजें';

  @override
  String get didntReceiveOtp => 'कोड नहीं मिला?';

  @override
  String get otpExpired =>
      'ओटीपी की समय सीमा समाप्त हो गई है। कृपया नया अनुरोध करें।';

  @override
  String get invalidOtp => 'अमान्य ओटीपी। कृपया पुनः प्रयास करें।';

  @override
  String get otpSentSuccessfully => 'ओटीपी सफलतापूर्वक भेजा गया!';

  @override
  String get verifying => 'सत्यापित हो रहा है...';

  @override
  String get otpVerified => 'ओटीपी सफलतापूर्वक सत्यापित हो गया!';

  @override
  String get codeExpiresIn => 'कोड की समय सीमा';

  @override
  String get seconds => 'सेकंड';
}
