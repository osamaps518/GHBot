import '../foods/food.dart';
import 'meal.dart';

/// The diary day starts at 4:00 on the phone's clock, so a late snack at
/// 1:30 still belongs to the evening before (docs/decisions.md, 34).
const dayStartHour = 4;

/// The diary day of [localTime], as `YYYY-MM-DD`.
///
/// The day before is found on the calendar, not by subtracting hours, so a
/// daylight saving change can't move it.
String diaryDayOf(DateTime localTime) {
  final day = localTime.hour < dayStartHour
      ? DateTime.utc(localTime.year, localTime.month, localTime.day - 1)
      : DateTime.utc(localTime.year, localTime.month, localTime.day);
  return day.toIso8601String().substring(0, 10);
}

/// An entry's totals: each value per 100 g × grams ÷ 100, rounded half up
/// to tenths, all in integers (docs/decisions.md, 30). [grams] is in tenths.
Nutrients entryTotals(Nutrients per100g, int grams) {
  int total(int valuePer100g) => (valuePer100g * grams + 500) ~/ 1000;
  return Nutrients(
    calories: total(per100g.calories),
    protein: total(per100g.protein),
    carbs: total(per100g.carbs),
    fat: total(per100g.fat),
  );
}

/// [tenths] rounded half up to a whole number, for display.
int roundTenths(int tenths) => (tenths + 5) ~/ 10;

/// One food logged into a meal, with the values it was logged with
/// (docs/decisions.md, 21). [grams] and all values are in tenths.
class FoodLogEntry {
  const FoodLogEntry({
    required this.id,
    required this.foodId,
    required this.meal,
    required this.mealName,
    required this.diaryDay,
    required this.grams,
    required this.per100g,
    required this.totals,
    required this.loggedAt,
  });

  /// Builds an entry from a `food_log_entries` row.
  FoodLogEntry.fromColumns({
    required this.id,
    required this.foodId,
    required this.meal,
    required this.mealName,
    required this.diaryDay,
    required this.grams,
    required int caloriesPer100g,
    required int proteinPer100g,
    required int carbsPer100g,
    required int fatPer100g,
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
    required this.loggedAt,
  }) : per100g = Nutrients(
         calories: caloriesPer100g,
         protein: proteinPer100g,
         carbs: carbsPer100g,
         fat: fatPer100g,
       ),
       totals = Nutrients(
         calories: calories,
         protein: protein,
         carbs: carbs,
         fat: fat,
       );

  final String id;
  final String foodId;
  final Meal meal;

  /// Set only for [Meal.extra].
  final String? mealName;

  /// `YYYY-MM-DD`, from [diaryDayOf].
  final String diaryDay;
  final int grams;
  final Nutrients per100g;
  final Nutrients totals;
  final DateTime loggedAt;
}

/// An entry and its food, as the diary shows them.
class LoggedFood {
  const LoggedFood({required this.entry, required this.food});

  final FoodLogEntry entry;
  final Food food;
}
