import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of StudentLocalizations
/// returned by `StudentLocalizations.of(context)`.
///
/// Applications need to include `StudentLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'student/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: StudentLocalizations.localizationsDelegates,
///   supportedLocales: StudentLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the StudentLocalizations.supportedLocales
/// property.
abstract class StudentLocalizations {
  StudentLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static StudentLocalizations? of(BuildContext context) {
    return Localizations.of<StudentLocalizations>(context, StudentLocalizations);
  }

  static const LocalizationsDelegate<StudentLocalizations> delegate = _StudentLocalizationsDelegate();

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

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Student Dashboard'**
  String get dashboardTitle;

  /// No description provided for @myBus.
  ///
  /// In en, this message translates to:
  /// **'My Bus'**
  String get myBus;

  /// No description provided for @trackBus.
  ///
  /// In en, this message translates to:
  /// **'Track Bus'**
  String get trackBus;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @busDetails.
  ///
  /// In en, this message translates to:
  /// **'Bus Details'**
  String get busDetails;

  /// No description provided for @driverName.
  ///
  /// In en, this message translates to:
  /// **'Driver Name'**
  String get driverName;

  /// No description provided for @contactNumber.
  ///
  /// In en, this message translates to:
  /// **'Contact Number'**
  String get contactNumber;

  /// No description provided for @noBusAssigned.
  ///
  /// In en, this message translates to:
  /// **'No bus assigned'**
  String get noBusAssigned;

  /// No description provided for @routes.
  ///
  /// In en, this message translates to:
  /// **'Routes'**
  String get routes;

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
}

class _StudentLocalizationsDelegate extends LocalizationsDelegate<StudentLocalizations> {
  const _StudentLocalizationsDelegate();

  @override
  Future<StudentLocalizations> load(Locale locale) {
    return SynchronousFuture<StudentLocalizations>(lookupStudentLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'hi', 'te'].contains(locale.languageCode);

  @override
  bool shouldReload(_StudentLocalizationsDelegate old) => false;
}

StudentLocalizations lookupStudentLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return StudentLocalizationsEn();
    case 'hi': return StudentLocalizationsHi();
    case 'te': return StudentLocalizationsTe();
  }

  throw FlutterError(
    'StudentLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
