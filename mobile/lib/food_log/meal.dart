import '../foods/food.dart';
import '../l10n/app_localizations.dart';
import 'entry.dart';

/// The server's meal codes.
enum Meal { breakfast, lunch, dinner, extra }

/// A diary day (`YYYY-MM-DD`) as the diary shows it, such as "Monday,
/// November 23".
String diaryDateText(AppLocalizations l10n, String day) {
  final date = DateTime.parse(day);
  return l10n.diaryDate(
    l10n.weekdayName('${date.weekday}'),
    '${date.day}',
    l10n.monthName('${date.month}'),
  );
}

/// A meal on a day: breakfast, lunch, dinner, or an extra meal with its
/// name. Two extra meals with the same name on the same day are one meal.
class DiaryMeal {
  const DiaryMeal(this.meal, [this.name]);

  final Meal meal;

  /// Set only for [Meal.extra].
  final String? name;

  /// The name to show: the trainee's own for an extra meal.
  String label(AppLocalizations l10n) => name ?? l10n.mealName(meal.name);

  @override
  bool operator ==(Object other) =>
      other is DiaryMeal && other.meal == meal && other.name == name;

  @override
  int get hashCode => Object.hash(meal, name);
}

/// A meal and its entries, in the order they were logged.
class MealGroup {
  const MealGroup(this.meal, this.entries);

  final DiaryMeal meal;
  final List<LoggedFood> entries;

  Nutrients get totals =>
      Nutrients.sum(entries.map((logged) => logged.entry.totals));
}

/// Groups a day's [entries] by meal: breakfast, lunch and dinner always,
/// then each extra meal in the order of its first entry. An extra meal
/// exists only through its entries, except the [newMealNames] the trainee
/// named on this screen, which come last until their first entry is saved.
List<MealGroup> groupByMeal(
  List<LoggedFood> entries, {
  List<String> newMealNames = const [],
}) {
  final sorted = [...entries]
    ..sort((a, b) {
      final byTime = a.entry.loggedAt.compareTo(b.entry.loggedAt);
      return byTime != 0 ? byTime : a.entry.id.compareTo(b.entry.id);
    });
  final groups = <DiaryMeal, List<LoggedFood>>{
    for (final meal in [Meal.breakfast, Meal.lunch, Meal.dinner])
      DiaryMeal(meal): [],
  };
  for (final logged in sorted) {
    final meal = DiaryMeal(logged.entry.meal, logged.entry.mealName);
    groups.putIfAbsent(meal, () => []).add(logged);
  }
  for (final name in newMealNames) {
    groups.putIfAbsent(DiaryMeal(Meal.extra, name), () => []);
  }
  return [
    for (final MapEntry(:key, :value) in groups.entries) MealGroup(key, value),
  ];
}

/// The name typed for an extra meal, trimmed, or null when it isn't 1 to 40
/// characters or holds a NUL character (the server's rules). Characters are
/// counted as the server counts them, by code point.
String? extraMealName(String typed) {
  final name = typed.trim();
  final length = name.runes.length;
  return length >= 1 && length <= 40 && !name.contains('\u0000') ? name : null;
}
