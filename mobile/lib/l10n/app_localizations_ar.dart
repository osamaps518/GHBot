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
  String get editMyInfo => 'تعديل معلوماتي';

  @override
  String get ageWarning =>
      'جُرّبت تقديراتنا للسعرات على بالغين حتى عمر 78 سنة، لذا قد تكون أقل دقة في حالتك. يُرجى استشارة طبيبك قبل البدء بحمية أو برنامج تمارين جديد.';

  @override
  String get understandButton => 'فهمت';
}
