import 'reset_password_localizations.dart';

class ResetPasswordLocalizationsHi extends ResetPasswordLocalizations {
  ResetPasswordLocalizationsHi() : super('hi');

  @override
  String get resetPasswordTitle => 'पासवर्ड रीसेट करें';

  @override
  String get resetPasswordDescription =>
      'अपने खाते के लिए एक नया पासवर्ड बनाएं';

  @override
  String get newPassword => 'नया पासवर्ड';

  @override
  String get confirmPassword => 'पासवर्ड की पुष्टि करें';

  @override
  String get resetPassword => 'पासवर्ड रीसेट करें';

  @override
  String get passwordUpdated => 'पासवर्ड सफलतापूर्वक अपडेट हो गया!';

  @override
  String get passwordMismatch => 'पासवर्ड मेल नहीं खाते';

  @override
  String get passwordTooShort => 'पासवर्ड कम से कम 8 अक्षरों का होना चाहिए';

  @override
  String get passwordRequirements =>
      'पासवर्ड में कम से कम एक बड़ा अक्षर, एक छोटा अक्षर और एक संख्या होनी चाहिए';

  @override
  String get loginWithNewPassword => 'नए पासवर्ड से लॉगिन करें';

  @override
  String get enterNewPassword => 'अपना नया पासवर्ड दर्ज करें';

  @override
  String get reenterPassword => 'अपना पासवर्ड पुनः दर्ज करें';
}
