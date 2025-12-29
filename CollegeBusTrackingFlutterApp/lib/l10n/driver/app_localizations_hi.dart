// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class DriverLocalizationsHi extends DriverLocalizations {
  DriverLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get dashboardTitle => 'ड्राइवर डैशबोर्ड';

  @override
  String welcomeDriver(Object name) {
    return 'स्वागत है, $name';
  }

  @override
  String get busSetupTab => 'बस सेटअप';

  @override
  String get liveTrackingTab => 'लाइव ट्रैकिंग';

  @override
  String get busRouteSelection => 'बस और रूट चयन';

  @override
  String get selectBusNumberLabel => 'बस नंबर चुनें';

  @override
  String get selectBusNumberHint => 'अपना बस नंबर चुनें';

  @override
  String get selectRouteLabel => 'रूट चुनें';

  @override
  String get selectRouteHint => 'अपना रूट चुनें';

  @override
  String get assignBusButton => 'बस असाइन करें';

  @override
  String busLabel(Object busNumber) {
    return 'बस: $busNumber';
  }

  @override
  String routeLabel(Object routeName) {
    return 'रूट: $routeName';
  }

  @override
  String routeTypeDetails(Object end, Object routeType, Object start) {
    return 'प्रकार: $routeType | $start -> $end';
  }

  @override
  String get removeAssignmentButton => 'असाइनमेंट हटाएं';

  @override
  String get newTripAssignment => 'नई ट्रिप असाइनमेंट';

  @override
  String get busNumberLabel => 'बस नंबर';

  @override
  String get declineButton => 'अस्वीकार करें';

  @override
  String get startTripButton => 'ट्रिप शुरू करें';

  @override
  String get pleaseAssignBusFirst => 'कृपया पहले एक बस असाइन करें';

  @override
  String get locationSharingStarted => 'लोकेशन शेयरिंग शुरू हो गई';

  @override
  String offRouteAlert(Object distance) {
    return '⚠️ आप रूट से बाहर हैं! (${distance}m दूर)';
  }

  @override
  String etaToNextStop(Object minutes, Object stopName) {
    return '$stopName के लिए $minutes मिनट';
  }

  @override
  String get locationSharingStopped => 'लोकेशन शेयरिंग बंद हो गई';

  @override
  String get busAssignedSuccess => 'बस सफलतापूर्वक असाइन की गई!';

  @override
  String assignBusError(Object error) {
    return 'बस असाइन करने में विफल: $error';
  }

  @override
  String get busAssignmentRemoved => 'बस असाइनमेंट हटा दिया गया';

  @override
  String removeAssignmentError(Object error) {
    return 'असाइनमेंट हटाने में विफल: $error';
  }

  @override
  String get assignmentAccepted => 'असाइनमेंट स्वीकार कर लिया गया!';

  @override
  String acceptAssignmentError(Object error) {
    return 'स्वीकार करने में विफल: $error';
  }

  @override
  String get assignmentDeclined => 'असाइनमेंट अस्वीकार कर दिया गया';

  @override
  String declineAssignmentError(Object error) {
    return 'अस्वीकार करने में विफल: $error';
  }

  @override
  String startPointMarker(Object name) {
    return 'प्रारंभ: $name';
  }

  @override
  String endPointMarker(Object name) {
    return 'अंत: $name';
  }

  @override
  String stopPointMarker(Object index, Object name) {
    return 'स्टॉप $index: $name';
  }

  @override
  String get stopSharingLocation => 'लोकेशन शेयरिंग रोकें';

  @override
  String get startSharingLocation => 'लोकेशन शेयरिंग शुरू करें';

  @override
  String get sharingStatusMessage => 'आपकी लोकेशन छात्रों और शिक्षकों के साथ साझा की जा रही है';

  @override
  String currentLocationStats(Object lat, Object lng) {
    return 'वर्तमान: $lat, $lng';
  }

  @override
  String yourLocationLabel(Object lat, Object lng) {
    return 'आपकी लोकेशन: $lat, $lng';
  }

  @override
  String get locationNotAvailable => 'लोकेशन उपलब्ध नहीं है। कृपया लोकेशन सेवाएं सक्षम करें।';

  @override
  String busHeader(Object busNumber) {
    return 'बस $busNumber';
  }
}
