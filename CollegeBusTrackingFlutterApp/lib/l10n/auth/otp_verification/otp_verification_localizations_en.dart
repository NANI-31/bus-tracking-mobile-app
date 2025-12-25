import 'otp_verification_localizations.dart';

class OtpVerificationLocalizationsEn extends OtpVerificationLocalizations {
  OtpVerificationLocalizationsEn() : super('en');

  @override
  String get otpVerificationTitle => 'OTP Verification';

  @override
  String get otpVerificationDescription =>
      'Enter the 6-digit code sent to your phone/email';

  @override
  String get enterOtp => 'Enter OTP';

  @override
  String get verifyOtp => 'Verify OTP';

  @override
  String get resendOtp => 'Resend OTP';

  @override
  String get didntReceiveOtp => 'Didn\'t receive the code?';

  @override
  String get otpExpired => 'OTP has expired. Please request a new one.';

  @override
  String get invalidOtp => 'Invalid OTP. Please try again.';

  @override
  String get otpSentSuccessfully => 'OTP sent successfully!';

  @override
  String get verifying => 'Verifying...';

  @override
  String get otpVerified => 'OTP verified successfully!';

  @override
  String get codeExpiresIn => 'Code expires in';

  @override
  String get seconds => 'seconds';
}
