// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Telugu (`te`).
class DriverLocalizationsTe extends DriverLocalizations {
  DriverLocalizationsTe([String locale = 'te']) : super(locale);

  @override
  String get dashboardTitle => 'డ్రైవర్ డ్యాష్‌బోర్డ్';

  @override
  String welcomeDriver(Object name) {
    return 'స్వాగతం, $name';
  }

  @override
  String get busSetupTab => 'బస్సు సెటప్';

  @override
  String get liveTrackingTab => 'లైవ్ ట్రాకింగ్';

  @override
  String get busRouteSelection => 'బస్ & రూట్ ఎంపిక';

  @override
  String get selectBusNumberLabel => 'బస్ నంబర్ ఎంచుకోండి';

  @override
  String get selectBusNumberHint => 'మీ బస్ నంబర్‌ని ఎంచుకోండి';

  @override
  String get selectRouteLabel => 'రూట్ ఎంచుకోండి';

  @override
  String get selectRouteHint => 'మీ రూట్‌ని ఎంచుకోండి';

  @override
  String get assignBusButton => 'బస్ కేటాయించండి';

  @override
  String busLabel(Object busNumber) {
    return 'బస్సు: $busNumber';
  }

  @override
  String routeLabel(Object routeName) {
    return 'రూట్: $routeName';
  }

  @override
  String routeTypeDetails(Object end, Object routeType, Object start) {
    return 'రకం: $routeType | $start -> $end';
  }

  @override
  String get removeAssignmentButton => 'అసైన్‌మెంట్ తొలగించండి';

  @override
  String get newTripAssignment => 'కొత్త ట్రిప్ అసైన్‌మెంట్';

  @override
  String get busNumberLabel => 'బస్ నంబర్';

  @override
  String get declineButton => 'తిరస్కరించు';

  @override
  String get startTripButton => 'ట్రిప్ ప్రారంభించు';

  @override
  String get pleaseAssignBusFirst => 'దయచేసి ముందుగా బస్సును కేటాయించండి';

  @override
  String get locationSharingStarted => 'లొకేషన్ షేరింగ్ ప్రారంభమైంది';

  @override
  String offRouteAlert(Object distance) {
    return '⚠️ మీరు రూట్ నుండి బయట ఉన్నారు! (${distance}m దూరంలో)';
  }

  @override
  String etaToNextStop(Object minutes, Object stopName) {
    return '$stopName కు $minutes నిమిషాలు';
  }

  @override
  String get locationSharingStopped => 'లొకేషన్ షేరింగ్ ఆగిపోయింది';

  @override
  String get busAssignedSuccess => 'బస్సు విజయవంతంగా కేటాయించబడింది!';

  @override
  String assignBusError(Object error) {
    return 'బస్సును కేటాయించడంలో విఫలమైంది: $error';
  }

  @override
  String get busAssignmentRemoved => 'బస్ అసైన్‌మెంట్ తొలగించబడింది';

  @override
  String removeAssignmentError(Object error) {
    return 'అసైన్‌మెంట్‌ని తొలగించడంలో విఫలమైంది: $error';
  }

  @override
  String get assignmentAccepted => 'అసైన్‌మెంట్ ఆమోదించబడింది!';

  @override
  String acceptAssignmentError(Object error) {
    return 'ఆమోదించడంలో విఫలమైంది: $error';
  }

  @override
  String get assignmentDeclined => 'అసైన్‌మెంట్ తిరస్కరించబడింది';

  @override
  String declineAssignmentError(Object error) {
    return 'తిరస్కరించడంలో విఫలమైంది: $error';
  }

  @override
  String startPointMarker(Object name) {
    return 'ప్రారంభం: $name';
  }

  @override
  String endPointMarker(Object name) {
    return 'ముగింపు: $name';
  }

  @override
  String stopPointMarker(Object index, Object name) {
    return 'స్టాప్ $index: $name';
  }

  @override
  String get stopSharingLocation => 'లొకేషన్ షేరింగ్ ఆపు';

  @override
  String get startSharingLocation => 'లొకేషన్ షేరింగ్ ప్రారంభించు';

  @override
  String get sharingStatusMessage => 'మీ లొకేషన్ విద్యార్థులు మరియు ఉపాధ్యాయులతో షేర్ చేయబడుతోంది';

  @override
  String currentLocationStats(Object lat, Object lng) {
    return 'ప్రస్తుత: $lat, $lng';
  }

  @override
  String yourLocationLabel(Object lat, Object lng) {
    return 'మీ లొకేషన్: $lat, $lng';
  }

  @override
  String get locationNotAvailable => 'లొకేషన్ అందుబాటులో లేదు. దయచేసి లొకేషన్ సేవలను ప్రారంభించండి.';

  @override
  String busHeader(Object busNumber) {
    return 'బస్సు $busNumber';
  }
}
