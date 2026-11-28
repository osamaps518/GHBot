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
  String goalAdjustment(String goal, String percent) {
    String _temp0 = intl.Intl.selectLogic(goal, {
      'lose': '$percent% less',
      'maintain': 'No change',
      'gain': '$percent% more',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get minimumNote =>
      'We\'ve set your target at the safe minimum. For a lower intake, talk to a doctor or dietitian.';

  @override
  String get raisedToMinimum => 'Raised to the safe minimum';

  @override
  String get customBadge => 'Custom';

  @override
  String customTargetsNote(String calories) {
    return 'You set these targets yourself, so they don\'t change when you edit your info. Your recommended target is now $calories calories.';
  }

  @override
  String get macrosAdjustedNote =>
      'Your custom calories are below the safe minimum, so we raised them to it and adjusted your protein, carbs and fat. For a lower intake, talk to a doctor or dietitian.';

  @override
  String get howWeCalculatedRecommended =>
      'How we calculated your recommended targets';

  @override
  String get editTargets => 'Edit targets';

  @override
  String targetsFieldLabel(String field) {
    String _temp0 = intl.Intl.selectLogic(field, {
      'calories': 'Calories',
      'protein': 'Protein',
      'carbs': 'Carbs',
      'fat': 'Fat',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String recommendedValue(String field, String value) {
    String _temp0 = intl.Intl.selectLogic(field, {
      'calories': 'Recommended: $value kcal',
      'other': 'Recommended: $value g',
    });
    return '$_temp0';
  }

  @override
  String macroCaloriesLine(String calories) {
    return 'Protein, carbs and fat give $calories kcal.';
  }

  @override
  String macrosTooFar(String calories, String difference) {
    return 'Protein, carbs and fat give $calories kcal, $difference away from your calories. Bring the numbers closer, to under 100 kcal apart.';
  }

  @override
  String get saveNeedsInternet => 'Saving needs an internet connection';

  @override
  String macrosApartTitle(String difference) {
    return 'The numbers are $difference kcal apart';
  }

  @override
  String macrosApartBody(String calories, String macroCalories) {
    return 'You entered $calories kcal, but protein, carbs and fat give $macroCalories kcal. You can fix the numbers or save them as they are.';
  }

  @override
  String get keepNumbers => 'Save as they are';

  @override
  String get fixNumbers => 'Fix the numbers';

  @override
  String get errorCaloriesRange => 'Enter a whole number up to 6000';

  @override
  String errorGramsRange(String max) {
    return 'Enter a whole number from 0 to $max';
  }

  @override
  String get editMyInfo => 'Edit my info';

  @override
  String get ageWarning =>
      'Our calorie estimates were tested on adults up to age 78, so they may be less accurate for you. Please check with your doctor before starting a new diet or training plan.';

  @override
  String get understandButton => 'I understand';

  @override
  String searchTitle(String meal) {
    return 'Add to $meal';
  }

  @override
  String get searchHint => 'Search for a food in Arabic or English';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get recentlyLogged => 'Recently logged';

  @override
  String get per100g => 'per 100 g';

  @override
  String get caloriesUnit => 'kcal';

  @override
  String get searchOffline =>
      'Couldn\'t connect, so only foods you\'ve logged before show here. Finding other foods needs a connection.';

  @override
  String noResultsTitle(String query) {
    return 'No results for “$query”';
  }

  @override
  String get noResultsBody => 'Try another name, or type it in Arabic.';

  @override
  String mealName(String meal) {
    String _temp0 = intl.Intl.selectLogic(meal, {
      'breakfast': 'Breakfast',
      'lunch': 'Lunch',
      'dinner': 'Dinner',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String caloriesPer100g(String calories) {
    return '$calories kcal per 100 g';
  }

  @override
  String get amount => 'Amount';

  @override
  String get less => 'Less';

  @override
  String get more => 'More';

  @override
  String get meal => 'Meal';

  @override
  String logButton(String meal) {
    return 'Add to $meal';
  }

  @override
  String get errorGrams =>
      'Enter an amount above 0 and up to 5000 g, with at most 1 decimal.';

  @override
  String get today => 'Today';

  @override
  String weekdayName(String weekday) {
    String _temp0 = intl.Intl.selectLogic(weekday, {
      '1': 'Monday',
      '2': 'Tuesday',
      '3': 'Wednesday',
      '4': 'Thursday',
      '5': 'Friday',
      '6': 'Saturday',
      '7': 'Sunday',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String diaryDate(String weekday, String day, String month) {
    return '$weekday, $month $day';
  }

  @override
  String get caloriesLeft => 'kcal left';

  @override
  String get caloriesOver => 'kcal over your target';

  @override
  String eatenOfTarget(String eaten, String target) {
    return 'You\'ve eaten $eaten of $target kcal';
  }

  @override
  String get targetsButton => 'Targets';

  @override
  String macroOfTarget(String target) {
    return 'of $target g';
  }

  @override
  String get noEntries => 'Nothing logged yet.';

  @override
  String get addFood => 'Add food';

  @override
  String get addMeal => 'Add meal';

  @override
  String get extraMealName => 'Meal name';

  @override
  String get extraMealHint =>
      'The meal stays on your day once you add its first food.';

  @override
  String get errorMealName => 'Enter a name of 1 to 40 characters.';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String deleteEntryTitle(String food) {
    return 'Delete $food?';
  }

  @override
  String deleteEntryBody(String meal, String date, String calories) {
    return 'It will be removed from $meal on $date, and $calories kcal will come off the day\'s total. This can\'t be undone.';
  }

  @override
  String waitingToSync(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count entries are waiting to sync. They\'ll be sent when you\'re connected.',
      one:
          '1 entry is waiting to sync. It will be sent when you\'re connected.',
    );
    return '$_temp0';
  }

  @override
  String get waitingToSyncEntry => 'Waiting to sync';

  @override
  String refusedNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count entries weren\'t saved on the server. Tap each one to fix it.',
      one: '1 entry wasn\'t saved on the server. Tap it to fix it.',
    );
    return '$_temp0';
  }

  @override
  String get entryRefused => 'Not accepted. Tap to fix it.';

  @override
  String get entryRefusedAlert =>
      'The server didn\'t accept this entry, so it\'s saved only on your phone. Change it or delete it.';
}
