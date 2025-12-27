import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of CommonLocalizations
/// returned by `CommonLocalizations.of(context)`.
///
/// Applications need to include `CommonLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'common/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: CommonLocalizations.localizationsDelegates,
///   supportedLocales: CommonLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the CommonLocalizations.supportedLocales
/// property.
abstract class CommonLocalizations {
  CommonLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static CommonLocalizations? of(BuildContext context) {
    return Localizations.of<CommonLocalizations>(context, CommonLocalizations);
  }

  static const LocalizationsDelegate<CommonLocalizations> delegate = _CommonLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('te')
  ];

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @accountInfo.
  ///
  /// In en, this message translates to:
  /// **'Account Information'**
  String get accountInfo;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @collegeId.
  ///
  /// In en, this message translates to:
  /// **'College ID'**
  String get collegeId;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @busStop.
  ///
  /// In en, this message translates to:
  /// **'Bus Stop'**
  String get busStop;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @bottomNavigation.
  ///
  /// In en, this message translates to:
  /// **'Bottom Navigation'**
  String get bottomNavigation;

  /// No description provided for @accountSecurity.
  ///
  /// In en, this message translates to:
  /// **'Account & Security'**
  String get accountSecurity;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsConditions;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @yourCurrentAccessLevel.
  ///
  /// In en, this message translates to:
  /// **'Your current access level'**
  String get yourCurrentAccessLevel;

  /// No description provided for @institutionIdentifier.
  ///
  /// In en, this message translates to:
  /// **'Institution identifier'**
  String get institutionIdentifier;

  /// No description provided for @contactNumberForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Contact number for updates'**
  String get contactNumberForUpdates;

  /// No description provided for @receiveAlerts.
  ///
  /// In en, this message translates to:
  /// **'Receive alerts about bus arrival'**
  String get receiveAlerts;

  /// No description provided for @managePreferredPickup.
  ///
  /// In en, this message translates to:
  /// **'Manage your preferred pickup point'**
  String get managePreferredPickup;

  /// No description provided for @toggleDarkLight.
  ///
  /// In en, this message translates to:
  /// **'Toggle dark or light theme'**
  String get toggleDarkLight;

  /// No description provided for @enableModernNav.
  ///
  /// In en, this message translates to:
  /// **'Enable modern mobile navigation'**
  String get enableModernNav;

  /// No description provided for @updateCredentials.
  ///
  /// In en, this message translates to:
  /// **'Update your login credentials'**
  String get updateCredentials;

  /// No description provided for @dataHandling.
  ///
  /// In en, this message translates to:
  /// **'How we handle your data'**
  String get dataHandling;

  /// No description provided for @legalUsageRequirements.
  ///
  /// In en, this message translates to:
  /// **'Legal usage requirements'**
  String get legalUsageRequirements;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get chooseLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @telugu.
  ///
  /// In en, this message translates to:
  /// **'Telugu'**
  String get telugu;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @privacyPriority.
  ///
  /// In en, this message translates to:
  /// **'Privacy is our priority.'**
  String get privacyPriority;

  /// No description provided for @informationWeCollect.
  ///
  /// In en, this message translates to:
  /// **'Information We Collect'**
  String get informationWeCollect;

  /// No description provided for @informationWeCollectDesc.
  ///
  /// In en, this message translates to:
  /// **'We collect information to provide better services to all our users. This includes your location for live tracking, your profile details, and usage data to improve the app performance.'**
  String get informationWeCollectDesc;

  /// No description provided for @howWeUseInformation.
  ///
  /// In en, this message translates to:
  /// **'How We Use Information'**
  String get howWeUseInformation;

  /// No description provided for @howWeUseInformationDesc.
  ///
  /// In en, this message translates to:
  /// **'We use the information we collect to provide, maintain, and improve our services, and to develop new ones. Live location is only shared with relevant authorities for safety and tracking purposes.'**
  String get howWeUseInformationDesc;

  /// No description provided for @dataSecurity.
  ///
  /// In en, this message translates to:
  /// **'Data Security'**
  String get dataSecurity;

  /// No description provided for @dataSecurityDesc.
  ///
  /// In en, this message translates to:
  /// **'We work hard to protect our users from unauthorized access to or unauthorized alteration, disclosure or destruction of information we hold.'**
  String get dataSecurityDesc;

  /// No description provided for @changesToPolicy.
  ///
  /// In en, this message translates to:
  /// **'Changes to Policy'**
  String get changesToPolicy;

  /// No description provided for @changesToPolicyDesc.
  ///
  /// In en, this message translates to:
  /// **'Our Privacy Policy may change from time to time. We will post any privacy policy changes on this page.'**
  String get changesToPolicyDesc;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last Updated: December 2025'**
  String get lastUpdated;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @agreementToTerms.
  ///
  /// In en, this message translates to:
  /// **'Agreement to Terms'**
  String get agreementToTerms;

  /// No description provided for @agreementToTermsDesc.
  ///
  /// In en, this message translates to:
  /// **'By accessing the Upasthit application, you agree to be bound by these terms of service, all applicable laws and regulations, and agree that you are responsible for compliance with any applicable local laws.'**
  String get agreementToTermsDesc;

  /// No description provided for @userResponsibility.
  ///
  /// In en, this message translates to:
  /// **'User Responsibility'**
  String get userResponsibility;

  /// No description provided for @userResponsibilityDesc.
  ///
  /// In en, this message translates to:
  /// **'Users are responsible for maintaining the confidentiality of their account and password. You are responsible for all activities that occur under your account.'**
  String get userResponsibilityDesc;

  /// No description provided for @serviceAvailability.
  ///
  /// In en, this message translates to:
  /// **'Service Availability'**
  String get serviceAvailability;

  /// No description provided for @serviceAvailabilityDesc.
  ///
  /// In en, this message translates to:
  /// **'We strive to maintain high availability of the tracking service, but we do not guarantee uninterrupted service due to potential network or technical issues.'**
  String get serviceAvailabilityDesc;

  /// No description provided for @governingLaw.
  ///
  /// In en, this message translates to:
  /// **'Governing Law'**
  String get governingLaw;

  /// No description provided for @governingLawDesc.
  ///
  /// In en, this message translates to:
  /// **'These terms and conditions are governed by and construed in accordance with the local laws and you irrevocably submit to the exclusive jurisdiction of the courts in that State or location.'**
  String get governingLawDesc;
}

class _CommonLocalizationsDelegate extends LocalizationsDelegate<CommonLocalizations> {
  const _CommonLocalizationsDelegate();

  @override
  Future<CommonLocalizations> load(Locale locale) {
    return SynchronousFuture<CommonLocalizations>(lookupCommonLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'hi', 'te'].contains(locale.languageCode);

  @override
  bool shouldReload(_CommonLocalizationsDelegate old) => false;
}

CommonLocalizations lookupCommonLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return CommonLocalizationsEn();
    case 'hi': return CommonLocalizationsHi();
    case 'te': return CommonLocalizationsTe();
  }

  throw FlutterError(
    'CommonLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
