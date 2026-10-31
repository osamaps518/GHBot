// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'GHBot';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get signInBody =>
      'This is a development build. Type a name. The same name brings you back to the same account.';

  @override
  String get signInName => 'Name';

  @override
  String get continueButton => 'Continue';

  @override
  String get profileTitle => 'Your details';

  @override
  String get profileSubtitle => 'We use them to calculate your daily targets.';

  @override
  String get birthMonth => 'Birth month';

  @override
  String get birthYear => 'Birth year';

  @override
  String monthName(String month) {
    String _temp0 = intl.Intl.selectLogic(month, {
      '1': 'January',
      '2': 'February',
      '3': 'March',
      '4': 'April',
      '5': 'May',
      '6': 'June',
      '7': 'July',
      '8': 'August',
      '9': 'September',
      '10': 'October',
      '11': 'November',
      '12': 'December',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get sex => 'Sex';

  @override
  String get sexMale => 'Male';

  @override
  String get sexFemale => 'Female';

  @override
  String get sexHint => 'Used only to estimate your energy needs.';

  @override
  String get height => 'Height (cm)';

  @override
  String get weight => 'Weight (kg)';

  @override
  String get activityLevel => 'Activity level';

  @override
  String get activityChoose => 'Choose your level';

  @override
  String activityName(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'sedentary': 'Sedentary',
      'lightly_active': 'Lightly active',
      'moderately_active': 'Moderately active',
      'very_active': 'Very active',
      'extremely_active': 'Extremely active',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String activityDescription(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'sedentary': 'Desk job, little or no exercise',
      'lightly_active': 'Light exercise 1–3 days/week',
      'moderately_active': 'Training 3–5 days/week',
      'very_active': 'Hard training 6–7 days/week',
      'extremely_active': 'Hard daily training plus a physical job',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get activityHint => 'If unsure, pick the lower one.';

  @override
  String get goal => 'Goal';

  @override
  String goalName(String goal) {
    String _temp0 = intl.Intl.selectLogic(goal, {
      'lose': 'Lose',
      'maintain': 'Maintain',
      'gain': 'Gain',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get calculateButton => 'Calculate my targets';

  @override
  String get errorChooseOne => 'Choose one.';

  @override
  String get errorHeight => 'Enter a height between 130 and 220 cm.';

  @override
  String get errorWeight => 'Enter a weight between 35 and 250 kg.';

  @override
  String get errorAge => 'Your age must be between 18 and 100.';

  @override
  String get errorCheckDetails => 'Check your details and try again.';

  @override
  String get errorConnection =>
      'Couldn\'t connect. Check your internet and try again.';

  @override
  String get errorGeneral => 'Something went wrong. Try again.';

  @override
  String get retry => 'Retry';

  @override
  String get targetsTitle => 'Your daily targets';

  @override
  String get caloriesPerDay => 'calories a day';

  @override
  String get protein => 'Protein';

  @override
  String get carbs => 'Carbs';

  @override
  String get fat => 'Fat';

  @override
  String get gramsUnit => 'g';

  @override
  String shareOfCalories(String percent) {
    return '$percent% of calories';
  }

  @override
  String get howWeCalculated => 'How we calculated this';

  @override
  String get maintenanceCalories => 'Maintenance calories';

  @override
  String goalRow(String goal) {
    String _temp0 = intl.Intl.selectLogic(goal, {
      'lose': 'Goal: lose weight',
      'maintain': 'Goal: maintain weight',
      'gain': 'Goal: gain weight',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String goalAdjustment(String goal) {
    String _temp0 = intl.Intl.selectLogic(goal, {
      'lose': '20% less',
      'maintain': 'No change',
      'gain': '10% more',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get minimumNote =>
      'We\'ve set your target at the safe minimum. For a lower intake, talk to a doctor or dietitian.';

  @override
  String get editMyInfo => 'Edit my info';
}
