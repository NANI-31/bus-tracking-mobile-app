// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class DriverLocalizationsEn extends DriverLocalizations {
  DriverLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get dashboardTitle => 'Driver Dashboard';

  @override
  String welcomeDriver(Object name) {
    return 'Welcome, $name';
  }

  @override
  String get busSetupTab => 'Bus Setup';

  @override
  String get liveTrackingTab => 'Live Tracking';

  @override
  String get busRouteSelection => 'Bus & Route Selection';

  @override
  String get selectBusNumberLabel => 'Select Bus Number';

  @override
  String get selectBusNumberHint => 'Choose your bus number';

  @override
  String get selectRouteLabel => 'Select Route';

  @override
  String get selectRouteHint => 'Choose your route';

  @override
  String get assignBusButton => 'Assign Bus';

  @override
  String busLabel(Object busNumber) {
    return 'Bus: $busNumber';
  }

  @override
  String routeLabel(Object routeName) {
    return 'Route: $routeName';
  }

  @override
  String routeTypeDetails(Object toStop, Object tripDirection, Object fromStop) {
    return 'Type: $tripDirection | $fromStop -> $toStop';
  }


  @override
  String get removeAssignmentButton => 'Remove Assignment';

  @override
  String get newTripAssignment => 'New Trip Assignment';

  @override
  String get busNumberLabel => 'Bus Number';

  @override
  String get declineButton => 'Decline';

  @override
  String get startTripButton => 'START TRIP';

  @override
  String get pleaseAssignBusFirst => 'Please assign a bus first';

  @override
  String get locationSharingStarted => 'Location sharing started';

  @override
  String offRouteAlert(Object distance) {
    return '⚠️ You are off route! (${distance}m away)';
  }

  @override
  String etaToNextStop(Object minutes, Object stopName) {
    return '$minutes min to $stopName';
  }

  @override
  String get locationSharingStopped => 'Location sharing stopped';

  @override
  String get busAssignedSuccess => 'Bus assigned successfully!';

  @override
  String assignBusError(Object error) {
    return 'Failed to assign bus: $error';
  }

  @override
  String get busAssignmentRemoved => 'Bus assignment removed';

  @override
  String removeAssignmentError(Object error) {
    return 'Failed to remove assignment: $error';
  }

  @override
  String get assignmentAccepted => 'Assignment accepted!';

  @override
  String acceptAssignmentError(Object error) {
    return 'Failed to accept: $error';
  }

  @override
  String get assignmentDeclined => 'Assignment declined';

  @override
  String declineAssignmentError(Object error) {
    return 'Failed to decline: $error';
  }

  @override
  String startPointMarker(Object name) {
    return 'Start: $name';
  }

  @override
  String endPointMarker(Object name) {
    return 'End: $name';
  }

  @override
  String stopPointMarker(Object index, Object name) {
    return 'Stop $index: $name';
  }

  @override
  String get stopSharingLocation => 'Stop Sharing Location';

  @override
  String get startSharingLocation => 'Start Sharing Location';

  @override
  String get sharingStatusMessage => 'Your location is being shared with students and teachers';

  @override
  String currentLocationStats(Object lat, Object lng) {
    return 'Current: $lat, $lng';
  }

  @override
  String yourLocationLabel(Object lat, Object lng) {
    return 'Your Location: $lat, $lng';
  }

  @override
  String get locationNotAvailable => 'Location not available. Please enable location services.';

  @override
  String get locationPermissionRequired => 'Location permission is required to start the trip. Please enable it in settings.';

  @override
  String get tripCompletedTitle => 'Trip Completed';

  @override
  String get tripCompletedMessage => 'Are you sure you want to complete this trip?';

  @override
  String get confirmComplete => 'Complete';

  @override
  String get cancel => 'Cancel';

  @override
  String busHeader(Object busNumber) {
    return 'Bus $busNumber';
  }
}






