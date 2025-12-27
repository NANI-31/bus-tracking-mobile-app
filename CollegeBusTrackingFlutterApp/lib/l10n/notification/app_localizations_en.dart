// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class NotificationLocalizationsEn extends NotificationLocalizations {
  NotificationLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get title => 'Notifications';

  @override
  String get markAsRead => 'Mark as read';

  @override
  String get clearAll => 'Clear All';

  @override
  String get emptyState => 'No notifications yet';

  @override
  String get newNotification => 'New Notification';

  @override
  String get driverAssigned => 'Driver Assigned';

  @override
  String get busOnRoute => 'Bus on Route';
}
