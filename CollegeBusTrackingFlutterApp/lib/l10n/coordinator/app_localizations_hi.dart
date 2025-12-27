// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class CoordinatorLocalizationsHi extends CoordinatorLocalizations {
  CoordinatorLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get dashboardTitle => 'समन्वयक डैशबोर्ड';

  @override
  String get manageDrivers => 'चालक प्रबंधन';

  @override
  String get manageRoutes => 'मार्ग प्रबंधन';

  @override
  String get manageBuses => 'बस प्रबंधन';

  @override
  String get assignDriver => 'चालक असाइन करें';

  @override
  String get approveDriver => 'चालक को मंजूरी दें';

  @override
  String get overview => 'अवलोकन';

  @override
  String get drivers => 'चालक';

  @override
  String get routes => 'मार्ग';

  @override
  String get buses => 'बसें';

  @override
  String get all => 'सभी';

  @override
  String get free => 'मुक्त';

  @override
  String get running => 'चल रही';

  @override
  String get accepted => 'स्वीकृत';

  @override
  String get assigned => 'आवंटित';

  @override
  String get approvals => 'अनुमोदन';

  @override
  String get pending => 'लंबित';

  @override
  String get add => 'जोड़ें';

  @override
  String get delete => 'हटाएं';

  @override
  String get search => 'खोजें';

  @override
  String get addBusNumber => 'बस नंबर जोड़ें';

  @override
  String get enterBusNumber => 'उदाहरण, KA-01-AB-1234';

  @override
  String get busNumber => 'बस नंबर';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get deleteBusNumber => 'बस नंबर हटाएं';

  @override
  String deleteConfirmation(Object busNumber) {
    return 'क्या आप वाकई $busNumber को हटाना चाहते हैं?';
  }

  @override
  String get cannotDeleteAssigned => 'आवंटित बस नंबर को हटाया नहीं जा सकता';

  @override
  String busAddedSuccess(Object busNumber) {
    return 'बस नंबर $busNumber सफलतापूर्वक जोड़ा गया';
  }

  @override
  String busDeletedSuccess(Object busNumber) {
    return 'बस नंबर $busNumber हटा दिया गया';
  }

  @override
  String get noBusesFound => 'कोई बस नहीं मिली';

  @override
  String noBusesFoundMatching(Object query) {
    return '\"$query\" से मेल खाती कोई बस नहीं मिली';
  }

  @override
  String get addBusPrompt => 'चालकों के चयन के लिए बस नंबर जोड़ें';

  @override
  String get noPendingApprovals => 'कोई लंबित खाता अनुमोदन नहीं';

  @override
  String get noDriversInCategory => 'इस श्रेणी में कोई चालक नहीं';

  @override
  String get unassigned => 'अनसाइन किया गया';

  @override
  String get rejected => 'अस्वीकृत';

  @override
  String get createRoute => 'रूट बनाएं';

  @override
  String get editRoute => 'रूट संपादित करें';

  @override
  String get routeName => 'रूट का नाम';

  @override
  String get routeType => 'रूट का प्रकार';

  @override
  String get startPoint => 'शुरुआती बिंदु';

  @override
  String get endPoint => 'अंतिम बिंदु';

  @override
  String get stopPoint => 'स्टॉप';

  @override
  String get pickup => 'पिकअप';

  @override
  String get drop => 'ड्रॉप';

  @override
  String get addStop => 'स्टॉप जोड़ें';

  @override
  String get save => 'सहेजें';

  @override
  String get create => 'बनाएं';

  @override
  String get edit => 'संपादित करें';

  @override
  String get deleteRoute => 'रूट हटाएं';

  @override
  String deleteRouteConfirmation(Object routeName) {
    return 'क्या आप वाकई $routeName को हटाना चाहते हैं?';
  }

  @override
  String get routeDeletedSuccess => 'रूट सफलतापूर्वक हटा दिया गया';

  @override
  String get noRoutesCreated => 'अभी तक कोई रूट नहीं बनाया गया';

  @override
  String get createRoutesPrompt => 'चालकों के चयन के लिए रूट बनाएं';

  @override
  String get stops => 'स्टॉप';

  @override
  String get systemOverview => 'सिस्टम अवलोकन';

  @override
  String get totalRoutes => 'कुल रूट';

  @override
  String get activeBuses => 'सक्रिय बसें';

  @override
  String get pendingDrivers => 'लंबित चालक';

  @override
  String get busNumbers => 'बस नंबर';
}
