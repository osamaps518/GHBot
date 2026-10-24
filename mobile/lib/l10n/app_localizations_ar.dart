// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'GHBot';

  @override
  String get backendReached => 'تم الوصول إلى الخادم';

  @override
  String get backendNotReached => 'تعذّر الوصول إلى الخادم';
}
