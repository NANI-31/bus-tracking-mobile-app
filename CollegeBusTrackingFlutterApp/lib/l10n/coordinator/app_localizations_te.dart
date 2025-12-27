// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Telugu (`te`).
class CoordinatorLocalizationsTe extends CoordinatorLocalizations {
  CoordinatorLocalizationsTe([String locale = 'te']) : super(locale);

  @override
  String get dashboardTitle => 'కోఆర్డినేటర్ డాష్‌బోర్డ్';

  @override
  String get manageDrivers => 'డ్రైవర్లను నిర్వహించండి';

  @override
  String get manageRoutes => 'మార్గాలను నిర్వహించండి';

  @override
  String get manageBuses => 'బస్సులను నిర్వహించండి';

  @override
  String get assignDriver => 'డ్రైవర్‌ను కేటాయించండి';

  @override
  String get approveDriver => 'డ్రైవర్‌ను ఆమోదించండి';

  @override
  String get overview => 'అవలోకనం';

  @override
  String get drivers => 'డ్రైవర్లు';

  @override
  String get routes => 'మార్గాలు';

  @override
  String get buses => 'బస్సులు';

  @override
  String get all => 'అన్నీ';

  @override
  String get free => 'ఖాళీ';

  @override
  String get running => 'నడుస్తున్న';

  @override
  String get accepted => 'ఆమోదించబడింది';

  @override
  String get assigned => 'కేటాయించబడింది';

  @override
  String get approvals => 'ఆమోదాలు';

  @override
  String get pending => 'పెండింగ్‌లో ఉంది';

  @override
  String get add => 'జోడించు';

  @override
  String get delete => 'తొలగించు';

  @override
  String get search => 'శోధించు';

  @override
  String get addBusNumber => 'బస్సు సంఖ్యను జోడించు';

  @override
  String get enterBusNumber => 'ఉదాహరణ, KA-01-AB-1234';

  @override
  String get busNumber => 'బస్సు సంఖ్య';

  @override
  String get cancel => 'రద్దు చేయి';

  @override
  String get deleteBusNumber => 'బస్సు సంఖ్యను తొలగించు';

  @override
  String deleteConfirmation(Object busNumber) {
    return 'మీరు ఖచ్చితంగా $busNumber ను తొలగించాలనుకుంటున్నారా?';
  }

  @override
  String get cannotDeleteAssigned => 'కేటాయించిన బస్సు సంఖ్యను తొలగించలేము';

  @override
  String busAddedSuccess(Object busNumber) {
    return 'బస్సు సంఖ్య $busNumber విజయవంతంగా జోడించబడింది';
  }

  @override
  String busDeletedSuccess(Object busNumber) {
    return 'బస్సు సంఖ్య $busNumber తొలగించబడింది';
  }

  @override
  String get noBusesFound => 'బస్సులు కనుగొనబడలేదు';

  @override
  String noBusesFoundMatching(Object query) {
    return '\"$query\" కు సరిపోలే బస్సులు ఏవీ కనుగొనబడలేదు';
  }

  @override
  String get addBusPrompt => 'డ్రైవర్లను ఎంచుకోవడానికి బస్సు సంఖ్యలను జోడించండి';

  @override
  String get noPendingApprovals => 'పెండింగ్ ఖాతా ఆమోదాలు లేవు';

  @override
  String get noDriversInCategory => 'ఈ వర్గంలో డ్రైవర్లు లేరు';

  @override
  String get unassigned => 'కేటాయించబడలేదు';

  @override
  String get rejected => 'తిరస్కరించబడింది';

  @override
  String get createRoute => 'రూట్‌ని సృష్టించండి';

  @override
  String get editRoute => 'రూట్‌ని సవరించండి';

  @override
  String get routeName => 'రూట్ పేరు';

  @override
  String get routeType => 'రూట్ రకం';

  @override
  String get startPoint => 'ప్రారంభ స్థానం';

  @override
  String get endPoint => 'ముగింపు స్థానం';

  @override
  String get stopPoint => 'స్టాప్';

  @override
  String get pickup => 'పికప్';

  @override
  String get drop => 'డ్రాప్';

  @override
  String get addStop => 'స్టాప్ జోడించండి';

  @override
  String get save => 'సేవ్ చేయండి';

  @override
  String get create => 'సృష్టించండి';

  @override
  String get edit => 'సవరించండి';

  @override
  String get deleteRoute => 'రూట్‌ని తొలగించండి';

  @override
  String deleteRouteConfirmation(Object routeName) {
    return 'మీరు ఖచ్చితంగా $routeName ని తొలగించాలనుకుంటున్నారా?';
  }

  @override
  String get routeDeletedSuccess => 'రూట్ విజయవంతంగా తొలగించబడింది';

  @override
  String get noRoutesCreated => 'ఇంకా రూట్‌లు సృష్టించబడలేదు';

  @override
  String get createRoutesPrompt => 'డ్రైవర్లను ఎంచుకోవడానికి రూట్‌లను సృష్టించండి';

  @override
  String get stops => 'నిలుపుదల';

  @override
  String get systemOverview => 'సిస్టమ్ అవలోకనం';

  @override
  String get totalRoutes => 'మొత్తం రూట్‌లు';

  @override
  String get activeBuses => 'యాక్టివ్ బస్సులు';

  @override
  String get pendingDrivers => 'పెండింగ్ డ్రైవర్లు';

  @override
  String get busNumbers => 'బస్సు సంఖ్యలు';
}
