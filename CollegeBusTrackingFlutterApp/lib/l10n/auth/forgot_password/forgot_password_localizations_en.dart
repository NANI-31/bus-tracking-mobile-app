import 'forgot_password_localizations.dart';

class ForgotPasswordLocalizationsEn extends ForgotPasswordLocalizations {
  ForgotPasswordLocalizationsEn() : super('en');

  @override
  String get forgotPasswordTitle => 'Forgot Password';

  @override
  String get forgotPasswordDescription =>
      'Enter your email address and we\'ll send you a link to reset your password.';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get resetLinkSent => 'Password reset link sent to your email!';

  @override
  String get checkYourEmail => 'Check your email';

  @override
  String get didntReceiveEmail => 'Didn\'t receive the email?';

  @override
  String get resendEmail => 'Resend Email';

  @override
  String get enterValidEmail => 'Please enter a valid email address';
}
