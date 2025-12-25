import 'otp_verification_localizations.dart';

class OtpVerificationLocalizationsTe extends OtpVerificationLocalizations {
  OtpVerificationLocalizationsTe() : super('te');

  @override
  String get otpVerificationTitle => 'OTP ధృవీకరణ';

  @override
  String get otpVerificationDescription =>
      'మీ ఫోన్/ఇమెయిల్‌కు పంపిన 6-అంకెల కోడ్‌ను నమోదు చేయండి';

  @override
  String get enterOtp => 'OTP నమోదు చేయండి';

  @override
  String get verifyOtp => 'OTP ధృవీకరించండి';

  @override
  String get resendOtp => 'OTP మళ్లీ పంపండి';

  @override
  String get didntReceiveOtp => 'కోడ్ రాలేదా?';

  @override
  String get otpExpired => 'OTP గడువు ముగిసింది. దయచేసి కొత్తది అభ్యర్థించండి.';

  @override
  String get invalidOtp => 'చెల్లని OTP. దయచేసి మళ్లీ ప్రయత్నించండి.';

  @override
  String get otpSentSuccessfully => 'OTP విజయవంతంగా పంపబడింది!';

  @override
  String get verifying => 'ధృవీకరిస్తోంది...';

  @override
  String get otpVerified => 'OTP విజయవంతంగా ధృవీకరించబడింది!';

  @override
  String get codeExpiresIn => 'కోడ్ గడువు ముగుస్తుంది';

  @override
  String get seconds => 'సెకన్లు';
}
