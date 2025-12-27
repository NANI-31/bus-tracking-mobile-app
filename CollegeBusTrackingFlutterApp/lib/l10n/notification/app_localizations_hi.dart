// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class NotificationLocalizationsHi extends NotificationLocalizations {
  NotificationLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get title => 'सूचनाएं';

  @override
  String get markAsRead => 'पढ़ा हुआ रूप में चिह्नित करें';

  @override
  String get clearAll => 'सभी साफ करें';

  @override
  String get emptyState => 'अभी तक कोई सूचना नहीं';

  @override
  String get newNotification => 'नई सूचना';

  @override
  String get driverAssigned => 'चालक नियुक्त किया गया';

  @override
  String get busOnRoute => 'बस मार्ग पर है';
}
