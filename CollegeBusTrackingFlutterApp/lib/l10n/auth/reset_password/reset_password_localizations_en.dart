import 'reset_password_localizations.dart';

class ResetPasswordLocalizationsEn extends ResetPasswordLocalizations {
  ResetPasswordLocalizationsEn() : super('en');

  @override
  String get resetPasswordTitle => 'Reset Password';

  @override
  String get resetPasswordDescription =>
      'Create a new password for your account';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get passwordUpdated => 'Password updated successfully!';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get passwordTooShort => 'Password must be at least 8 characters';

  @override
  String get passwordRequirements =>
      'Password must contain at least one uppercase letter, one lowercase letter, and one number';

  @override
  String get loginWithNewPassword => 'Login with New Password';

  @override
  String get enterNewPassword => 'Enter your new password';

  @override
  String get reenterPassword => 'Re-enter your password';
}
