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

  /// No description provided for @raisedToMinimum.
  ///
  /// In ar, this message translates to:
  /// **'رُفع إلى الحد الأدنى الآمن'**
  String get raisedToMinimum;

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

  /// Food search title.
  ///
  /// In ar, this message translates to:
  /// **'إضافة إلى {meal}'**
  String searchTitle(String meal);

  /// No description provided for @searchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن طعام بالعربية أو الإنجليزية'**
  String get searchHint;

  /// No description provided for @clearSearch.
  ///
  /// In ar, this message translates to:
  /// **'مسح البحث'**
  String get clearSearch;

  /// Above the foods shown before typing, newest first.
  ///
  /// In ar, this message translates to:
  /// **'سجّلتها مؤخرًا'**
  String get recentlyLogged;

  /// No description provided for @per100g.
  ///
  /// In ar, this message translates to:
  /// **'لكل 100 غ'**
  String get per100g;

  /// After a calorie number, as in 130 سعرة.
  ///
  /// In ar, this message translates to:
  /// **'سعرة'**
  String get caloriesUnit;

  /// Search without a connection filters only the foods kept on the phone (decision 20).
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الاتصال، لذا تظهر هنا الأطعمة التي سجّلتها من قبل فقط. البحث في بقية الأطعمة يحتاج إلى اتصال.'**
  String get searchOffline;

  /// No description provided for @noResultsTitle.
  ///
  /// In ar, this message translates to:
  /// **'لم نجد «{query}»'**
  String noResultsTitle(String query);

  /// No description provided for @noResultsBody.
  ///
  /// In ar, this message translates to:
  /// **'جرّب اسمًا آخر أو اكتبه بالإنجليزية.'**
  String get noResultsBody;

  /// No description provided for @mealName.
  ///
  /// In ar, this message translates to:
  /// **'{meal, select, breakfast{الفطور} lunch{الغداء} dinner{العشاء} other{}}'**
  String mealName(String meal);

  /// No description provided for @caloriesPer100g.
  ///
  /// In ar, this message translates to:
  /// **'{calories} سعرة لكل 100 غ'**
  String caloriesPer100g(String calories);

  /// No description provided for @amount.
  ///
  /// In ar, this message translates to:
  /// **'الكمية'**
  String get amount;

  /// The − button: 10 g less.
  ///
  /// In ar, this message translates to:
  /// **'أقل'**
  String get less;

  /// The + button: 10 g more.
  ///
  /// In ar, this message translates to:
  /// **'أكثر'**
  String get more;

  /// No description provided for @meal.
  ///
  /// In ar, this message translates to:
  /// **'الوجبة'**
  String get meal;

  /// Saves the entry.
  ///
  /// In ar, this message translates to:
  /// **'إضافة إلى {meal}'**
  String logButton(String meal);

  /// The server's grams rules: greater than 0, at most 5000, at most 1 decimal.
  ///
  /// In ar, this message translates to:
  /// **'أدخل كمية أكبر من 0 حتى 5000 غ، بمنزلة عشرية واحدة على الأكثر.'**
  String get errorGrams;

  /// No description provided for @today.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get today;

  /// No description provided for @weekdayName.
  ///
  /// In ar, this message translates to:
  /// **'{weekday, select, 1{الاثنين} 2{الثلاثاء} 3{الأربعاء} 4{الخميس} 5{الجمعة} 6{السبت} 7{الأحد} other{}}'**
  String weekdayName(String weekday);

  /// The diary day under Today, such as الاثنين، 23 تشرين الثاني.
  ///
  /// In ar, this message translates to:
  /// **'{weekday}، {day} {month}'**
  String diaryDate(String weekday, String day, String month);

  /// Under the calories left today, in the ring.
  ///
  /// In ar, this message translates to:
  /// **'سعرة متبقية'**
  String get caloriesLeft;

  /// Under the calories eaten beyond the target, in the ring.
  ///
  /// In ar, this message translates to:
  /// **'سعرة فوق هدفك'**
  String get caloriesOver;

  /// No description provided for @eatenOfTarget.
  ///
  /// In ar, this message translates to:
  /// **'تناولت {eaten} من {target} سعرة'**
  String eatenOfTarget(String eaten, String target);

  /// Opens the targets screen from the diary.
  ///
  /// In ar, this message translates to:
  /// **'الأهداف'**
  String get targetsButton;

  /// Under a macro's grams eaten today.
  ///
  /// In ar, this message translates to:
  /// **'من {target} غ'**
  String macroOfTarget(String target);

  /// No description provided for @noEntries.
  ///
  /// In ar, this message translates to:
  /// **'لم تُسجّل شيئًا بعد.'**
  String get noEntries;

  /// No description provided for @addFood.
  ///
  /// In ar, this message translates to:
  /// **'إضافة طعام'**
  String get addFood;

  /// No description provided for @addMeal.
  ///
  /// In ar, this message translates to:
  /// **'إضافة وجبة'**
  String get addMeal;

  /// No description provided for @extraMealName.
  ///
  /// In ar, this message translates to:
  /// **'اسم الوجبة'**
  String get extraMealName;

  /// An extra meal exists only through its entries (#59).
  ///
  /// In ar, this message translates to:
  /// **'تظهر الوجبة في يومك حين تضيف إليها أول طعام.'**
  String get extraMealHint;

  /// No description provided for @errorMealName.
  ///
  /// In ar, this message translates to:
  /// **'اكتب اسمًا من 1 إلى 40 حرفًا.'**
  String get errorMealName;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// Saves a changed entry.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// Deletes an entry, after the confirmation dialog.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete;

  /// No description provided for @deleteEntryTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف {food}؟'**
  String deleteEntryTitle(String food);

  /// No description provided for @deleteEntryBody.
  ///
  /// In ar, this message translates to:
  /// **'ستُحذف من {meal} يوم {date}، وتُطرح {calories} سعرة من مجموع اليوم. لا يمكن التراجع عن الحذف.'**
  String deleteEntryBody(String meal, String date, String calories);

  /// On the diary while entries on the phone haven't reached the server.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{إدخال واحد بانتظار المزامنة. سيُرسل حين يتوفّر الاتصال.} =2{إدخالان بانتظار المزامنة. سيُرسلان حين يتوفّر الاتصال.} few{{count} إدخالات بانتظار المزامنة. ستُرسل حين يتوفّر الاتصال.} many{{count} إدخالًا بانتظار المزامنة. ستُرسل حين يتوفّر الاتصال.} other{{count} إدخال بانتظار المزامنة. ستُرسل حين يتوفّر الاتصال.}}'**
  String waitingToSync(int count);

  /// Read out for the clock next to an entry the server hasn't confirmed.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار المزامنة'**
  String get waitingToSyncEntry;

  /// On the diary while the day has entries the server refused (#61).
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{لم يُحفظ إدخال واحد على الخادم. اضغط عليه لإصلاحه.} =2{لم يُحفظ إدخالان على الخادم. اضغط على كل منهما لإصلاحه.} few{لم تُحفظ {count} إدخالات على الخادم. اضغط على كل منها لإصلاحه.} many{لم يُحفظ {count} إدخالًا على الخادم. اضغط على كل منها لإصلاحه.} other{لم يُحفظ {count} إدخال على الخادم. اضغط على كل منها لإصلاحه.}}'**
  String refusedNote(int count);

  /// Under a refused entry on the diary, in place of its grams.
  ///
  /// In ar, this message translates to:
  /// **'لم يُقبل. اضغط لإصلاحه.'**
  String get entryRefused;

  /// At the top of the entry screen for a refused entry.
  ///
  /// In ar, this message translates to:
  /// **'لم يقبل الخادم هذا الإدخال، فهو محفوظ على هاتفك فقط. عدّله أو احذفه.'**
  String get entryRefusedAlert;
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
