import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'auth_signup_localizations_en.dart';
import 'auth_signup_localizations_hi.dart';
import 'auth_signup_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of SignupLocalizations
/// returned by `SignupLocalizations.of(context)`.
///
/// Applications need to include `SignupLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'signup/auth_signup_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: SignupLocalizations.localizationsDelegates,
///   supportedLocales: SignupLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the SignupLocalizations.supportedLocales
/// property.
abstract class SignupLocalizations {
  SignupLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static SignupLocalizations? of(BuildContext context) {
    return Localizations.of<SignupLocalizations>(context, SignupLocalizations);
  }

  static const LocalizationsDelegate<SignupLocalizations> delegate = _SignupLocalizationsDelegate();

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

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @joinToTrack.
  ///
  /// In en, this message translates to:
  /// **'Join to track your college bus in real-time.'**
  String get joinToTrack;

  /// No description provided for @whoAreYou.
  ///
  /// In en, this message translates to:
  /// **'Who are you?'**
  String get whoAreYou;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. John Doe'**
  String get fullNameHint;

  /// No description provided for @rollNumber.
  ///
  /// In en, this message translates to:
  /// **'Roll Number / ID'**
  String get rollNumber;

  /// No description provided for @rollNumberHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 21CSE102'**
  String get rollNumberHint;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @emailAddressHint.
  ///
  /// In en, this message translates to:
  /// **'john@example.com'**
  String get emailAddressHint;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @phoneNumberHint.
  ///
  /// In en, this message translates to:
  /// **'+1 234 567 8900'**
  String get phoneNumberHint;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @collegeName.
  ///
  /// In en, this message translates to:
  /// **'College Name'**
  String get collegeName;

  /// No description provided for @collegeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your college name'**
  String get collegeHint;

  /// No description provided for @personalEmailDetected.
  ///
  /// In en, this message translates to:
  /// **'Personal Email Detected'**
  String get personalEmailDetected;

  /// No description provided for @personalEmailMessage.
  ///
  /// In en, this message translates to:
  /// **'You are using a personal email address. Your account will need to be approved before you can access the app.'**
  String get personalEmailMessage;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @registrationSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Registration Successful'**
  String get registrationSuccessful;

  /// No description provided for @registrationSuccessfulMsg.
  ///
  /// In en, this message translates to:
  /// **'Registration Successful. Please Login.'**
  String get registrationSuccessfulMsg;

  /// No description provided for @loginNow.
  ///
  /// In en, this message translates to:
  /// **'Login Now'**
  String get loginNow;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get genericError;

  /// No description provided for @roleStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get roleStudent;

  /// No description provided for @roleTeacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get roleTeacher;

  /// No description provided for @roleDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get roleDriver;

  /// No description provided for @roleParent.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get roleParent;

  /// No description provided for @roleBusCoordinator.
  ///
  /// In en, this message translates to:
  /// **'Bus Coordinator'**
  String get roleBusCoordinator;

  /// No description provided for @roleCoordinatorDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage routes & schedules'**
  String get roleCoordinatorDescription;

  /// No description provided for @college.
  ///
  /// In en, this message translates to:
  /// **'College'**
  String get college;

  /// No description provided for @selectCollege.
  ///
  /// In en, this message translates to:
  /// **'Select your college'**
  String get selectCollege;

  /// No description provided for @pleaseSelectCollege.
  ///
  /// In en, this message translates to:
  /// **'Please select your college'**
  String get pleaseSelectCollege;

  /// No description provided for @collegeDomains.
  ///
  /// In en, this message translates to:
  /// **'College domains'**
  String get collegeDomains;

  /// No description provided for @emailId.
  ///
  /// In en, this message translates to:
  /// **'Email ID'**
  String get emailId;

  /// No description provided for @domain.
  ///
  /// In en, this message translates to:
  /// **'Domain'**
  String get domain;

  /// No description provided for @enterEmailId.
  ///
  /// In en, this message translates to:
  /// **'Enter email id'**
  String get enterEmailId;

  /// No description provided for @enterDomain.
  ///
  /// In en, this message translates to:
  /// **'Enter domain'**
  String get enterDomain;

  /// No description provided for @invalidDomain.
  ///
  /// In en, this message translates to:
  /// **'Invalid domain'**
  String get invalidDomain;
}

class _SignupLocalizationsDelegate extends LocalizationsDelegate<SignupLocalizations> {
  const _SignupLocalizationsDelegate();

  @override
  Future<SignupLocalizations> load(Locale locale) {
    return SynchronousFuture<SignupLocalizations>(lookupSignupLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'hi', 'te'].contains(locale.languageCode);

  @override
  bool shouldReload(_SignupLocalizationsDelegate old) => false;
}

SignupLocalizations lookupSignupLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return SignupLocalizationsEn();
    case 'hi': return SignupLocalizationsHi();
    case 'te': return SignupLocalizationsTe();
  }

  throw FlutterError(
    'SignupLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
