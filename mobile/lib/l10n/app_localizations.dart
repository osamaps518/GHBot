import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ar, this message translates to:
  /// **'GHBot'**
  String get appTitle;

  /// No description provided for @signInTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get signInTitle;

  /// Dev sign-in screen: the name is the account, there is no password.
  ///
  /// In ar, this message translates to:
  /// **'هذه نسخة للتطوير. اكتب اسمًا، وسيعيدك الاسم نفسه إلى الحساب نفسه.'**
  String get signInBody;

  /// No description provided for @signInName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get signInName;

  /// No description provided for @continueButton.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get continueButton;

  /// No description provided for @profileTitle.
  ///
  /// In ar, this message translates to:
  /// **'معلوماتك'**
  String get profileTitle;

  /// No description provided for @profileSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'نستخدمها لحساب أهدافك اليومية.'**
  String get profileSubtitle;

  /// No description provided for @birthMonth.
  ///
  /// In ar, this message translates to:
  /// **'شهر الميلاد'**
  String get birthMonth;

  /// No description provided for @birthYear.
  ///
  /// In ar, this message translates to:
  /// **'سنة الميلاد'**
  String get birthYear;

  /// Month names in the birth month picker, Levantine names.
  ///
  /// In ar, this message translates to:
  /// **'{month, select, 1{كانون الثاني} 2{شباط} 3{آذار} 4{نيسان} 5{أيار} 6{حزيران} 7{تموز} 8{آب} 9{أيلول} 10{تشرين الأول} 11{تشرين الثاني} 12{كانون الأول} other{}}'**
  String monthName(String month);

  /// No description provided for @sex.
  ///
  /// In ar, this message translates to:
  /// **'الجنس'**
  String get sex;

  /// No description provided for @sexMale.
  ///
  /// In ar, this message translates to:
  /// **'ذكر'**
  String get sexMale;

  /// No description provided for @sexFemale.
  ///
  /// In ar, this message translates to:
  /// **'أنثى'**
  String get sexFemale;

  /// Under the sex field, from #8 answer 6.
  ///
  /// In ar, this message translates to:
  /// **'نستخدمه فقط لتقدير احتياجك من الطاقة.'**
  String get sexHint;

  /// No description provided for @height.
  ///
  /// In ar, this message translates to:
  /// **'الطول (سم)'**
  String get height;

  /// No description provided for @weight.
  ///
  /// In ar, this message translates to:
  /// **'الوزن (كغ)'**
  String get weight;

  /// No description provided for @activityLevel.
  ///
  /// In ar, this message translates to:
  /// **'مستوى النشاط'**
  String get activityLevel;

  /// No description provided for @activityChoose.
  ///
  /// In ar, this message translates to:
  /// **'اختر مستواك'**
  String get activityChoose;

  /// No description provided for @activityName.
  ///
  /// In ar, this message translates to:
  /// **'{level, select, sedentary{قليل الحركة} lightly_active{نشاط خفيف} moderately_active{نشاط متوسط} very_active{نشاط عالٍ} extremely_active{نشاط عالٍ جدًا} other{}}'**
  String activityName(String level);

  /// One line under each activity level, from #8 answer 10.
  ///
  /// In ar, this message translates to:
  /// **'{level, select, sedentary{عمل مكتبي، وتمرين قليل أو بدون تمرين} lightly_active{تمرين خفيف 1 إلى 3 أيام في الأسبوع} moderately_active{تمرين 3 إلى 5 أيام في الأسبوع} very_active{تمرين قوي 6 إلى 7 أيام في الأسبوع} extremely_active{تمرين قوي كل يوم مع عمل بدني} other{}}'**
  String activityDescription(String level);

  /// Under the activity level field, from #8 answer 10.
  ///
  /// In ar, this message translates to:
  /// **'إن لم تكن متأكدًا، اختر المستوى الأقل.'**
  String get activityHint;

  /// No description provided for @goal.
  ///
  /// In ar, this message translates to:
  /// **'الهدف'**
  String get goal;

  /// No description provided for @goalName.
  ///
  /// In ar, this message translates to:
  /// **'{goal, select, lose{خسارة الوزن} maintain{المحافظة} gain{زيادة الوزن} other{}}'**
  String goalName(String goal);

  /// No description provided for @calculateButton.
  ///
  /// In ar, this message translates to:
  /// **'احسب أهدافي'**
  String get calculateButton;

  /// No description provided for @errorChooseOne.
  ///
  /// In ar, this message translates to:
  /// **'اختر واحدًا.'**
  String get errorChooseOne;

  /// No description provided for @errorHeight.
  ///
  /// In ar, this message translates to:
  /// **'أدخل طولًا بين 130 و220 سم.'**
  String get errorHeight;

  /// No description provided for @errorWeight.
  ///
  /// In ar, this message translates to:
  /// **'أدخل وزنًا بين 35 و250 كغ.'**
  String get errorWeight;

  /// No description provided for @errorAge.
  ///
  /// In ar, this message translates to:
  /// **'يجب أن يكون عمرك بين 18 و100 سنة.'**
  String get errorAge;

  /// Shown when the server rejects the form for a reason the app didn't check.
  ///
  /// In ar, this message translates to:
  /// **'تحقّق من معلوماتك وحاول مرة أخرى.'**
  String get errorCheckDetails;

  /// Connection failure or timeout. Doesn't say 'no internet': a down server looks the same.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الاتصال. تحقّق من الإنترنت وحاول مرة أخرى.'**
  String get errorConnection;

  /// No description provided for @errorGeneral.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ. حاول مرة أخرى.'**
  String get errorGeneral;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'أعد المحاولة'**
  String get retry;

  /// No description provided for @targetsTitle.
  ///
  /// In ar, this message translates to:
  /// **'أهدافك اليومية'**
  String get targetsTitle;

  /// No description provided for @caloriesPerDay.
  ///
  /// In ar, this message translates to:
  /// **'سعرة حرارية في اليوم'**
  String get caloriesPerDay;

  /// No description provided for @protein.
  ///
  /// In ar, this message translates to:
  /// **'بروتين'**
  String get protein;

  /// No description provided for @carbs.
  ///
  /// In ar, this message translates to:
  /// **'كربوهيدرات'**
  String get carbs;

  /// No description provided for @fat.
  ///
  /// In ar, this message translates to:
  /// **'دهون'**
  String get fat;

  /// No description provided for @gramsUnit.
  ///
  /// In ar, this message translates to:
  /// **'غ'**
  String get gramsUnit;

  /// No description provided for @shareOfCalories.
  ///
  /// In ar, this message translates to:
  /// **'{percent}% من السعرات'**
  String shareOfCalories(String percent);

  /// No description provided for @howWeCalculated.
  ///
  /// In ar, this message translates to:
  /// **'كيف حسبنا هذا'**
  String get howWeCalculated;

  /// No description provided for @maintenanceCalories.
  ///
  /// In ar, this message translates to:
  /// **'سعرات المحافظة على وزنك'**
  String get maintenanceCalories;

  /// No description provided for @goalRow.
  ///
  /// In ar, this message translates to:
  /// **'{goal, select, lose{هدف خسارة الوزن} maintain{هدف المحافظة على الوزن} gain{هدف زيادة الوزن} other{}}'**
  String goalRow(String goal);

  /// How the goal changes maintenance calories.
  ///
  /// In ar, this message translates to:
  /// **'{goal, select, lose{أقل بـ {percent}%} maintain{بدون تغيير} gain{أكثر بـ {percent}%} other{}}'**
  String goalAdjustment(String goal, String percent);

  /// Shown when the target was raised to the minimum, from #8 answer 13.
  ///
  /// In ar, this message translates to:
  /// **'حدّدنا هدفك عند الحد الأدنى الآمن. إذا أردت سعرات أقل، فاستشر طبيبًا أو أخصائي تغذية.'**
  String get minimumNote;

  /// No description provided for @editMyInfo.
  ///
  /// In ar, this message translates to:
  /// **'تعديل معلوماتي'**
  String get editMyInfo;

  /// Shown once, before the targets, to users older than 78, from #33.
  ///
  /// In ar, this message translates to:
  /// **'جُرّبت تقديراتنا للسعرات على بالغين حتى عمر 78 سنة، لذا قد تكون أقل دقة في حالتك. يُرجى استشارة طبيبك قبل البدء بحمية أو برنامج تمارين جديد.'**
  String get ageWarning;

  /// No description provided for @understandButton.
  ///
  /// In ar, this message translates to:
  /// **'فهمت'**
  String get understandButton;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
