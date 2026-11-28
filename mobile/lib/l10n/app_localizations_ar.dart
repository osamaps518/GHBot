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
  String get signInTitle => 'تسجيل الدخول';

  @override
  String get signInBody =>
      'هذه نسخة للتطوير. اكتب اسمًا، وسيعيدك الاسم نفسه إلى الحساب نفسه.';

  @override
  String get signInName => 'الاسم';

  @override
  String get continueButton => 'متابعة';

  @override
  String get profileTitle => 'معلوماتك';

  @override
  String get profileSubtitle => 'نستخدمها لحساب أهدافك اليومية.';

  @override
  String get birthMonth => 'شهر الميلاد';

  @override
  String get birthYear => 'سنة الميلاد';

  @override
  String monthName(String month) {
    String _temp0 = intl.Intl.selectLogic(month, {
      '1': 'كانون الثاني',
      '2': 'شباط',
      '3': 'آذار',
      '4': 'نيسان',
      '5': 'أيار',
      '6': 'حزيران',
      '7': 'تموز',
      '8': 'آب',
      '9': 'أيلول',
      '10': 'تشرين الأول',
      '11': 'تشرين الثاني',
      '12': 'كانون الأول',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get sex => 'الجنس';

  @override
  String get sexMale => 'ذكر';

  @override
  String get sexFemale => 'أنثى';

  @override
  String get sexHint => 'نستخدمه فقط لتقدير احتياجك من الطاقة.';

  @override
  String get height => 'الطول (سم)';

  @override
  String get weight => 'الوزن (كغ)';

  @override
  String get activityLevel => 'مستوى النشاط';

  @override
  String get activityChoose => 'اختر مستواك';

  @override
  String activityName(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'sedentary': 'قليل الحركة',
      'lightly_active': 'نشاط خفيف',
      'moderately_active': 'نشاط متوسط',
      'very_active': 'نشاط عالٍ',
      'extremely_active': 'نشاط عالٍ جدًا',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String activityDescription(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'sedentary': 'عمل مكتبي، وتمرين قليل أو بدون تمرين',
      'lightly_active': 'تمرين خفيف 1 إلى 3 أيام في الأسبوع',
      'moderately_active': 'تمرين 3 إلى 5 أيام في الأسبوع',
      'very_active': 'تمرين قوي 6 إلى 7 أيام في الأسبوع',
      'extremely_active': 'تمرين قوي كل يوم مع عمل بدني',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get activityHint => 'إن لم تكن متأكدًا، اختر المستوى الأقل.';

  @override
  String get goal => 'الهدف';

  @override
  String goalName(String goal) {
    String _temp0 = intl.Intl.selectLogic(goal, {
      'lose': 'خسارة الوزن',
      'maintain': 'المحافظة',
      'gain': 'زيادة الوزن',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get calculateButton => 'احسب أهدافي';

  @override
  String get errorChooseOne => 'اختر واحدًا.';

  @override
  String get errorHeight => 'أدخل طولًا بين 130 و220 سم.';

  @override
  String get errorWeight => 'أدخل وزنًا بين 35 و250 كغ.';

  @override
  String get errorAge => 'يجب أن يكون عمرك بين 18 و100 سنة.';

  @override
  String get errorCheckDetails => 'تحقّق من معلوماتك وحاول مرة أخرى.';

  @override
  String get errorConnection =>
      'تعذّر الاتصال. تحقّق من الإنترنت وحاول مرة أخرى.';

  @override
  String get errorGeneral => 'حدث خطأ. حاول مرة أخرى.';

  @override
  String get retry => 'أعد المحاولة';

  @override
  String get targetsTitle => 'أهدافك اليومية';

  @override
  String get caloriesPerDay => 'سعرة حرارية في اليوم';

  @override
  String get protein => 'بروتين';

  @override
  String get carbs => 'كربوهيدرات';

  @override
  String get fat => 'دهون';

  @override
  String get gramsUnit => 'غ';

  @override
  String shareOfCalories(String percent) {
    return '$percent% من السعرات';
  }

  @override
  String get howWeCalculated => 'كيف حسبنا هذا';

  @override
  String get maintenanceCalories => 'سعرات المحافظة على وزنك';

  @override
  String goalRow(String goal) {
    String _temp0 = intl.Intl.selectLogic(goal, {
      'lose': 'هدف خسارة الوزن',
      'maintain': 'هدف المحافظة على الوزن',
      'gain': 'هدف زيادة الوزن',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String goalAdjustment(String goal, String percent) {
    String _temp0 = intl.Intl.selectLogic(goal, {
      'lose': 'أقل بـ $percent%',
      'maintain': 'بدون تغيير',
      'gain': 'أكثر بـ $percent%',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get minimumNote =>
      'حدّدنا هدفك عند الحد الأدنى الآمن. إذا أردت سعرات أقل، فاستشر طبيبًا أو أخصائي تغذية.';

  @override
  String get raisedToMinimum => 'رُفع إلى الحد الأدنى الآمن';

  @override
  String get customBadge => 'مخصّصة';

  @override
  String customTargetsNote(String calories) {
    return 'حدّدت هذه الأهداف بنفسك، فلا تتغيّر حين تعدّل معلوماتك. الأهداف الموصى بها لك الآن $calories سعرة.';
  }

  @override
  String get macrosAdjustedNote =>
      'سعراتك المخصّصة أقل من الحد الأدنى الآمن، فرفعناها إليه وعدّلنا البروتين والكربوهيدرات والدهون. إذا أردت سعرات أقل، فاستشر طبيبًا أو أخصائي تغذية.';

  @override
  String get howWeCalculatedRecommended => 'كيف حسبنا الأهداف الموصى بها';

  @override
  String get editTargets => 'تعديل الأهداف';

  @override
  String targetsFieldLabel(String field) {
    String _temp0 = intl.Intl.selectLogic(field, {
      'calories': 'السعرات',
      'protein': 'البروتين',
      'carbs': 'الكربوهيدرات',
      'fat': 'الدهون',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String recommendedValue(String field, String value) {
    String _temp0 = intl.Intl.selectLogic(field, {
      'calories': 'الموصى بها: $value سعرة',
      'protein': 'الموصى به: $value غ',
      'other': 'الموصى بها: $value غ',
    });
    return '$_temp0';
  }

  @override
  String macroCaloriesLine(String calories) {
    return 'البروتين والكربوهيدرات والدهون تعطي $calories سعرة.';
  }

  @override
  String macrosTooFar(String calories, String difference) {
    return 'البروتين والكربوهيدرات والدهون تعطي $calories سعرة، أي بفرق $difference عن السعرات. قرّب الأرقام ليصبح الفرق أقل من 100 سعرة.';
  }

  @override
  String get saveNeedsInternet => 'الحفظ يحتاج إلى الإنترنت';

  @override
  String macrosApartTitle(String difference) {
    return 'الأرقام مختلفة بـ $difference سعرة';
  }

  @override
  String macrosApartBody(String calories, String macroCalories) {
    return 'أدخلت $calories سعرة، لكن البروتين والكربوهيدرات والدهون تعطي $macroCalories سعرة. يمكنك تعديل الأرقام أو حفظها كما هي.';
  }

  @override
  String get keepNumbers => 'حفظ كما هي';

  @override
  String get fixNumbers => 'تعديل الأرقام';

  @override
  String get errorCaloriesRange => 'أدخل عددًا صحيحًا حتى 6000';

  @override
  String errorGramsRange(String max) {
    return 'أدخل عددًا صحيحًا من 0 إلى $max';
  }

  @override
  String get editMyInfo => 'تعديل معلوماتي';

  @override
  String get ageWarning =>
      'جُرّبت تقديراتنا للسعرات على بالغين حتى عمر 78 سنة، لذا قد تكون أقل دقة في حالتك. يُرجى استشارة طبيبك قبل البدء بحمية أو برنامج تمارين جديد.';

  @override
  String get understandButton => 'فهمت';

  @override
  String searchTitle(String meal) {
    return 'إضافة إلى $meal';
  }

  @override
  String get searchHint => 'ابحث عن طعام بالعربية أو الإنجليزية';

  @override
  String get clearSearch => 'مسح البحث';

  @override
  String get recentlyLogged => 'سجّلتها مؤخرًا';

  @override
  String get per100g => 'لكل 100 غ';

  @override
  String get caloriesUnit => 'سعرة';

  @override
  String get searchOffline =>
      'تعذّر الاتصال، لذا تظهر هنا الأطعمة التي سجّلتها من قبل فقط. البحث في بقية الأطعمة يحتاج إلى اتصال.';

  @override
  String noResultsTitle(String query) {
    return 'لم نجد «$query»';
  }

  @override
  String get noResultsBody => 'جرّب اسمًا آخر أو اكتبه بالإنجليزية.';

  @override
  String mealName(String meal) {
    String _temp0 = intl.Intl.selectLogic(meal, {
      'breakfast': 'الفطور',
      'lunch': 'الغداء',
      'dinner': 'العشاء',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String caloriesPer100g(String calories) {
    return '$calories سعرة لكل 100 غ';
  }

  @override
  String get amount => 'الكمية';

  @override
  String get less => 'أقل';

  @override
  String get more => 'أكثر';

  @override
  String get meal => 'الوجبة';

  @override
  String logButton(String meal) {
    return 'إضافة إلى $meal';
  }

  @override
  String get errorGrams =>
      'أدخل كمية أكبر من 0 حتى 5000 غ، بمنزلة عشرية واحدة على الأكثر.';

  @override
  String get today => 'اليوم';

  @override
  String weekdayName(String weekday) {
    String _temp0 = intl.Intl.selectLogic(weekday, {
      '1': 'الاثنين',
      '2': 'الثلاثاء',
      '3': 'الأربعاء',
      '4': 'الخميس',
      '5': 'الجمعة',
      '6': 'السبت',
      '7': 'الأحد',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String diaryDate(String weekday, String day, String month) {
    return '$weekday، $day $month';
  }

  @override
  String get caloriesLeft => 'سعرة متبقية';

  @override
  String get caloriesOver => 'سعرة فوق هدفك';

  @override
  String eatenOfTarget(String eaten, String target) {
    return 'تناولت $eaten من $target سعرة';
  }

  @override
  String get targetsButton => 'الأهداف';

  @override
  String macroOfTarget(String target) {
    return 'من $target غ';
  }

  @override
  String get noEntries => 'لم تُسجّل شيئًا بعد.';

  @override
  String get addFood => 'إضافة طعام';

  @override
  String get addMeal => 'إضافة وجبة';

  @override
  String get extraMealName => 'اسم الوجبة';

  @override
  String get extraMealHint => 'تظهر الوجبة في يومك حين تضيف إليها أول طعام.';

  @override
  String get errorMealName => 'اكتب اسمًا من 1 إلى 40 حرفًا.';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get delete => 'حذف';

  @override
  String deleteEntryTitle(String food) {
    return 'حذف $food؟';
  }

  @override
  String deleteEntryBody(String meal, String date, String calories) {
    return 'ستُحذف من $meal يوم $date، وتُطرح $calories سعرة من مجموع اليوم. لا يمكن التراجع عن الحذف.';
  }

  @override
  String waitingToSync(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count إدخال بانتظار المزامنة. ستُرسل حين يتوفّر الاتصال.',
      many: '$count إدخالًا بانتظار المزامنة. ستُرسل حين يتوفّر الاتصال.',
      few: '$count إدخالات بانتظار المزامنة. ستُرسل حين يتوفّر الاتصال.',
      two: 'إدخالان بانتظار المزامنة. سيُرسلان حين يتوفّر الاتصال.',
      one: 'إدخال واحد بانتظار المزامنة. سيُرسل حين يتوفّر الاتصال.',
    );
    return '$_temp0';
  }

  @override
  String get waitingToSyncEntry => 'بانتظار المزامنة';

  @override
  String refusedNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'لم يُحفظ $count إدخال على الخادم. اضغط على كل منها لإصلاحه.',
      many: 'لم يُحفظ $count إدخالًا على الخادم. اضغط على كل منها لإصلاحه.',
      few: 'لم تُحفظ $count إدخالات على الخادم. اضغط على كل منها لإصلاحه.',
      two: 'لم يُحفظ إدخالان على الخادم. اضغط على كل منهما لإصلاحه.',
      one: 'لم يُحفظ إدخال واحد على الخادم. اضغط عليه لإصلاحه.',
    );
    return '$_temp0';
  }

  @override
  String get entryRefused => 'لم يُقبل. اضغط لإصلاحه.';

  @override
  String get entryRefusedAlert =>
      'لم يقبل الخادم هذا الإدخال، فهو محفوظ على هاتفك فقط. عدّله أو احذفه.';
}
