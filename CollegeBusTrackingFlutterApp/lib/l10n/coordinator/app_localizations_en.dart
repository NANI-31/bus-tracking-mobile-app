// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class CoordinatorLocalizationsEn extends CoordinatorLocalizations {
  CoordinatorLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get dashboardTitle => 'Coordinator Dashboard';

  @override
  String get manageDrivers => 'Manage Drivers';

  @override
  String get manageRoutes => 'Manage Routes';

  @override
  String get manageBuses => 'Manage Buses';

  @override
  String get assignDriver => 'Assign Driver';

  @override
  String get approveDriver => 'Approve Driver';

  @override
  String get overview => 'Overview';

  @override
  String get drivers => 'Drivers';

  @override
  String get routes => 'Routes';

  @override
  String get buses => 'Buses';

  @override
  String get all => 'All';

  @override
  String get free => 'Free';

  @override
  String get running => 'Running';

  @override
  String get accepted => 'Accepted';

  @override
  String get assigned => 'Assigned';

  @override
  String get approvals => 'Approvals';

  @override
  String get pending => 'Pending';

  @override
  String get add => 'Add';

  @override
  String get delete => 'Delete';

  @override
  String get search => 'Search';

  @override
  String get addBusNumber => 'Add Bus Number';

  @override
  String get enterBusNumber => 'e.g., KA-01-AB-1234';

  @override
  String get busNumber => 'Bus Number';

  @override
  String get cancel => 'Cancel';

  @override
  String get deleteBusNumber => 'Delete Bus Number';

  @override
  String deleteConfirmation(Object busNumber) {
    return 'Are you sure you want to delete $busNumber?';
  }

  @override
  String get cannotDeleteAssigned => 'Cannot delete assigned bus number';

  @override
  String busAddedSuccess(Object busNumber) {
    return 'Bus number $busNumber added successfully';
  }

  @override
  String busDeletedSuccess(Object busNumber) {
    return 'Bus number $busNumber deleted';
  }

  @override
  String get noBusesFound => 'No buses found';

  @override
  String noBusesFoundMatching(Object query) {
    return 'No buses found matching \"$query\"';
  }

  @override
  String get addBusPrompt => 'Add bus numbers for drivers to select';

  @override
  String get noPendingApprovals => 'No pending account approvals';

  @override
  String get noDriversInCategory => 'No drivers in this category';

  @override
  String get unassigned => 'Unassigned';

  @override
  String get rejected => 'Rejected';

  @override
  String get createRoute => 'Create Route';

  @override
  String get editRoute => 'Edit Route';

  @override
  String get routeName => 'Route Name';

  @override
  String get routeType => 'Route Type';

  @override
  String get startPoint => 'Start Point';

  @override
  String get endPoint => 'End Point';

  @override
  String get stopPoint => 'Stop';

  @override
  String get pickup => 'Pickup';

  @override
  String get drop => 'Drop';

  @override
  String get addStop => 'Add Stop';

  @override
  String get save => 'Save';

  @override
  String get create => 'Create';

  @override
  String get edit => 'Edit';

  @override
  String get deleteRoute => 'Delete Route';

  @override
  String deleteRouteConfirmation(Object routeName) {
    return 'Are you sure you want to delete $routeName?';
  }

  @override
  String get routeDeletedSuccess => 'Route deleted successfully';

  @override
  String get noRoutesCreated => 'No routes created yet';

  @override
  String get createRoutesPrompt => 'Create routes for drivers to select';

  @override
  String get stops => 'Stops';

  @override
  String get systemOverview => 'System Overview';

  @override
  String get totalRoutes => 'Total Routes';

  @override
  String get activeBuses => 'Active Buses';

  @override
  String get pendingDrivers => 'Pending Drivers';

  @override
  String get busNumbers => 'Bus Numbers';
}
