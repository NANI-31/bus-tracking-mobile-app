import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of DriverLocalizations
/// returned by `DriverLocalizations.of(context)`.
///
/// Applications need to include `DriverLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'driver/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: DriverLocalizations.localizationsDelegates,
///   supportedLocales: DriverLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the DriverLocalizations.supportedLocales
/// property.
abstract class DriverLocalizations {
  DriverLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static DriverLocalizations? of(BuildContext context) {
    return Localizations.of<DriverLocalizations>(context, DriverLocalizations);
  }

  static const LocalizationsDelegate<DriverLocalizations> delegate = _DriverLocalizationsDelegate();

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
  /// **'Driver Dashboard'**
  String get dashboardTitle;

  /// No description provided for @welcomeDriver.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}'**
  String welcomeDriver(Object name);

  /// No description provided for @busSetupTab.
  ///
  /// In en, this message translates to:
  /// **'Bus Setup'**
  String get busSetupTab;

  /// No description provided for @liveTrackingTab.
  ///
  /// In en, this message translates to:
  /// **'Live Tracking'**
  String get liveTrackingTab;

  /// No description provided for @busRouteSelection.
  ///
  /// In en, this message translates to:
  /// **'Bus & Route Selection'**
  String get busRouteSelection;

  /// No description provided for @selectBusNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Select Bus Number'**
  String get selectBusNumberLabel;

  /// No description provided for @selectBusNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Choose your bus number'**
  String get selectBusNumberHint;

  /// No description provided for @selectRouteLabel.
  ///
  /// In en, this message translates to:
  /// **'Select Route'**
  String get selectRouteLabel;

  /// No description provided for @selectRouteHint.
  ///
  /// In en, this message translates to:
  /// **'Choose your route'**
  String get selectRouteHint;

  /// No description provided for @assignBusButton.
  ///
  /// In en, this message translates to:
  /// **'Assign Bus'**
  String get assignBusButton;

  /// No description provided for @busLabel.
  ///
  /// In en, this message translates to:
  /// **'Bus: {busNumber}'**
  String busLabel(Object busNumber);

  /// No description provided for @routeLabel.
  ///
  /// In en, this message translates to:
  /// **'Route: {routeName}'**
  String routeLabel(Object routeName);

  /// No description provided for @routeTypeDetails.
  ///
  /// In en, this message translates to:
  /// **'Type: {routeType} | {start} -> {end}'**
  String routeTypeDetails(Object end, Object routeType, Object start);

  /// No description provided for @removeAssignmentButton.
  ///
  /// In en, this message translates to:
  /// **'Remove Assignment'**
  String get removeAssignmentButton;

  /// No description provided for @newTripAssignment.
  ///
  /// In en, this message translates to:
  /// **'New Trip Assignment'**
  String get newTripAssignment;

  /// No description provided for @busNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Bus Number'**
  String get busNumberLabel;

  /// No description provided for @declineButton.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get declineButton;

  /// No description provided for @startTripButton.
  ///
  /// In en, this message translates to:
  /// **'START TRIP'**
  String get startTripButton;

  /// No description provided for @pleaseAssignBusFirst.
  ///
  /// In en, this message translates to:
  /// **'Please assign a bus first'**
  String get pleaseAssignBusFirst;

  /// No description provided for @locationSharingStarted.
  ///
  /// In en, this message translates to:
  /// **'Location sharing started'**
  String get locationSharingStarted;

  /// No description provided for @offRouteAlert.
  ///
  /// In en, this message translates to:
  /// **'⚠️ You are off route! ({distance}m away)'**
  String offRouteAlert(Object distance);

  /// No description provided for @etaToNextStop.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min to {stopName}'**
  String etaToNextStop(Object minutes, Object stopName);

  /// No description provided for @locationSharingStopped.
  ///
  /// In en, this message translates to:
  /// **'Location sharing stopped'**
  String get locationSharingStopped;

  /// No description provided for @busAssignedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Bus assigned successfully!'**
  String get busAssignedSuccess;

  /// No description provided for @assignBusError.
  ///
  /// In en, this message translates to:
  /// **'Failed to assign bus: {error}'**
  String assignBusError(Object error);

  /// No description provided for @busAssignmentRemoved.
  ///
  /// In en, this message translates to:
  /// **'Bus assignment removed'**
  String get busAssignmentRemoved;

  /// No description provided for @removeAssignmentError.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove assignment: {error}'**
  String removeAssignmentError(Object error);

  /// No description provided for @assignmentAccepted.
  ///
  /// In en, this message translates to:
  /// **'Assignment accepted!'**
  String get assignmentAccepted;

  /// No description provided for @acceptAssignmentError.
  ///
  /// In en, this message translates to:
  /// **'Failed to accept: {error}'**
  String acceptAssignmentError(Object error);

  /// No description provided for @assignmentDeclined.
  ///
  /// In en, this message translates to:
  /// **'Assignment declined'**
  String get assignmentDeclined;

  /// No description provided for @declineAssignmentError.
  ///
  /// In en, this message translates to:
  /// **'Failed to decline: {error}'**
  String declineAssignmentError(Object error);

  /// No description provided for @startPointMarker.
  ///
  /// In en, this message translates to:
  /// **'Start: {name}'**
  String startPointMarker(Object name);

  /// No description provided for @endPointMarker.
  ///
  /// In en, this message translates to:
  /// **'End: {name}'**
  String endPointMarker(Object name);

  /// No description provided for @stopPointMarker.
  ///
  /// In en, this message translates to:
  /// **'Stop {index}: {name}'**
  String stopPointMarker(Object index, Object name);

  /// No description provided for @stopSharingLocation.
  ///
  /// In en, this message translates to:
  /// **'Stop Sharing Location'**
  String get stopSharingLocation;

  /// No description provided for @startSharingLocation.
  ///
  /// In en, this message translates to:
  /// **'Start Sharing Location'**
  String get startSharingLocation;

  /// No description provided for @sharingStatusMessage.
  ///
  /// In en, this message translates to:
  /// **'Your location is being shared with students and teachers'**
  String get sharingStatusMessage;

  /// No description provided for @currentLocationStats.
  ///
  /// In en, this message translates to:
  /// **'Current: {lat}, {lng}'**
  String currentLocationStats(Object lat, Object lng);

  /// No description provided for @yourLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Your Location: {lat}, {lng}'**
  String yourLocationLabel(Object lat, Object lng);

  /// No description provided for @locationNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Location not available. Please enable location services.'**
  String get locationNotAvailable;

  /// No description provided for @busHeader.
  ///
  /// In en, this message translates to:
  /// **'Bus {busNumber}'**
  String busHeader(Object busNumber);
}

class _DriverLocalizationsDelegate extends LocalizationsDelegate<DriverLocalizations> {
  const _DriverLocalizationsDelegate();

  @override
  Future<DriverLocalizations> load(Locale locale) {
    return SynchronousFuture<DriverLocalizations>(lookupDriverLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'hi', 'te'].contains(locale.languageCode);

  @override
  bool shouldReload(_DriverLocalizationsDelegate old) => false;
}

DriverLocalizations lookupDriverLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return DriverLocalizationsEn();
    case 'hi': return DriverLocalizationsHi();
    case 'te': return DriverLocalizationsTe();
  }

  throw FlutterError(
    'DriverLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
