import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of CoordinatorLocalizations
/// returned by `CoordinatorLocalizations.of(context)`.
///
/// Applications need to include `CoordinatorLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'coordinator/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: CoordinatorLocalizations.localizationsDelegates,
///   supportedLocales: CoordinatorLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the CoordinatorLocalizations.supportedLocales
/// property.
abstract class CoordinatorLocalizations {
  CoordinatorLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static CoordinatorLocalizations? of(BuildContext context) {
    return Localizations.of<CoordinatorLocalizations>(context, CoordinatorLocalizations);
  }

  static const LocalizationsDelegate<CoordinatorLocalizations> delegate = _CoordinatorLocalizationsDelegate();

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
  /// **'Coordinator Dashboard'**
  String get dashboardTitle;

  /// No description provided for @manageDrivers.
  ///
  /// In en, this message translates to:
  /// **'Manage Drivers'**
  String get manageDrivers;

  /// No description provided for @manageRoutes.
  ///
  /// In en, this message translates to:
  /// **'Manage Routes'**
  String get manageRoutes;

  /// No description provided for @manageBuses.
  ///
  /// In en, this message translates to:
  /// **'Manage Buses'**
  String get manageBuses;

  /// No description provided for @assignDriver.
  ///
  /// In en, this message translates to:
  /// **'Assign Driver'**
  String get assignDriver;

  /// No description provided for @approveDriver.
  ///
  /// In en, this message translates to:
  /// **'Approve Driver'**
  String get approveDriver;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @drivers.
  ///
  /// In en, this message translates to:
  /// **'Drivers'**
  String get drivers;

  /// No description provided for @routes.
  ///
  /// In en, this message translates to:
  /// **'Routes'**
  String get routes;

  /// No description provided for @buses.
  ///
  /// In en, this message translates to:
  /// **'Buses'**
  String get buses;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @running.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get running;

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// No description provided for @assigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get assigned;

  /// No description provided for @approvals.
  ///
  /// In en, this message translates to:
  /// **'Approvals'**
  String get approvals;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @addBusNumber.
  ///
  /// In en, this message translates to:
  /// **'Add Bus Number'**
  String get addBusNumber;

  /// No description provided for @enterBusNumber.
  ///
  /// In en, this message translates to:
  /// **'e.g., KA-01-AB-1234'**
  String get enterBusNumber;

  /// No description provided for @busNumber.
  ///
  /// In en, this message translates to:
  /// **'Bus Number'**
  String get busNumber;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @deleteBusNumber.
  ///
  /// In en, this message translates to:
  /// **'Delete Bus Number'**
  String get deleteBusNumber;

  /// No description provided for @deleteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {busNumber}?'**
  String deleteConfirmation(Object busNumber);

  /// No description provided for @cannotDeleteAssigned.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete assigned bus number'**
  String get cannotDeleteAssigned;

  /// No description provided for @busAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Bus number {busNumber} added successfully'**
  String busAddedSuccess(Object busNumber);

  /// No description provided for @busDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Bus number {busNumber} deleted'**
  String busDeletedSuccess(Object busNumber);

  /// No description provided for @noBusesFound.
  ///
  /// In en, this message translates to:
  /// **'No buses found'**
  String get noBusesFound;

  /// No description provided for @noBusesFoundMatching.
  ///
  /// In en, this message translates to:
  /// **'No buses found matching \"{query}\"'**
  String noBusesFoundMatching(Object query);

  /// No description provided for @addBusPrompt.
  ///
  /// In en, this message translates to:
  /// **'Add bus numbers for drivers to select'**
  String get addBusPrompt;

  /// No description provided for @noPendingApprovals.
  ///
  /// In en, this message translates to:
  /// **'No pending account approvals'**
  String get noPendingApprovals;

  /// No description provided for @noDriversInCategory.
  ///
  /// In en, this message translates to:
  /// **'No drivers in this category'**
  String get noDriversInCategory;

  /// No description provided for @unassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get unassigned;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @createRoute.
  ///
  /// In en, this message translates to:
  /// **'Create Route'**
  String get createRoute;

  /// No description provided for @editRoute.
  ///
  /// In en, this message translates to:
  /// **'Edit Route'**
  String get editRoute;

  /// No description provided for @routeName.
  ///
  /// In en, this message translates to:
  /// **'Route Name'**
  String get routeName;

  /// No description provided for @routeType.
  ///
  /// In en, this message translates to:
  /// **'Route Type'**
  String get routeType;

  /// No description provided for @startPoint.
  ///
  /// In en, this message translates to:
  /// **'Start Point'**
  String get startPoint;

  /// No description provided for @endPoint.
  ///
  /// In en, this message translates to:
  /// **'End Point'**
  String get endPoint;

  /// No description provided for @stopPoint.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopPoint;

  /// No description provided for @pickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get pickup;

  /// No description provided for @drop.
  ///
  /// In en, this message translates to:
  /// **'Drop'**
  String get drop;

  /// No description provided for @addStop.
  ///
  /// In en, this message translates to:
  /// **'Add Stop'**
  String get addStop;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @deleteRoute.
  ///
  /// In en, this message translates to:
  /// **'Delete Route'**
  String get deleteRoute;

  /// No description provided for @deleteRouteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {routeName}?'**
  String deleteRouteConfirmation(Object routeName);

  /// No description provided for @routeDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Route deleted successfully'**
  String get routeDeletedSuccess;

  /// No description provided for @noRoutesCreated.
  ///
  /// In en, this message translates to:
  /// **'No routes created yet'**
  String get noRoutesCreated;

  /// No description provided for @createRoutesPrompt.
  ///
  /// In en, this message translates to:
  /// **'Create routes for drivers to select'**
  String get createRoutesPrompt;

  /// No description provided for @stops.
  ///
  /// In en, this message translates to:
  /// **'Stops'**
  String get stops;

  /// No description provided for @systemOverview.
  ///
  /// In en, this message translates to:
  /// **'System Overview'**
  String get systemOverview;

  /// No description provided for @totalRoutes.
  ///
  /// In en, this message translates to:
  /// **'Total Routes'**
  String get totalRoutes;

  /// No description provided for @activeBuses.
  ///
  /// In en, this message translates to:
  /// **'Active Buses'**
  String get activeBuses;

  /// No description provided for @pendingDrivers.
  ///
  /// In en, this message translates to:
  /// **'Pending Drivers'**
  String get pendingDrivers;

  /// No description provided for @busNumbers.
  ///
  /// In en, this message translates to:
  /// **'Bus Numbers'**
  String get busNumbers;
}

class _CoordinatorLocalizationsDelegate extends LocalizationsDelegate<CoordinatorLocalizations> {
  const _CoordinatorLocalizationsDelegate();

  @override
  Future<CoordinatorLocalizations> load(Locale locale) {
    return SynchronousFuture<CoordinatorLocalizations>(lookupCoordinatorLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'hi', 'te'].contains(locale.languageCode);

  @override
  bool shouldReload(_CoordinatorLocalizationsDelegate old) => false;
}

CoordinatorLocalizations lookupCoordinatorLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return CoordinatorLocalizationsEn();
    case 'hi': return CoordinatorLocalizationsHi();
    case 'te': return CoordinatorLocalizationsTe();
  }

  throw FlutterError(
    'CoordinatorLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
