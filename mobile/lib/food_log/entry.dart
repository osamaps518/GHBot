import '../core/typed_number.dart';
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

/// When the diary day after the one at [localTime] starts.
DateTime nextDayStart(DateTime localTime) {
  final todayStart = DateTime(
    localTime.year,
    localTime.month,
    localTime.day,
    dayStartHour,
  );
  return localTime.isBefore(todayStart)
      ? todayStart
      : DateTime(
          localTime.year,
          localTime.month,
          localTime.day + 1,
          dayStartHour,
        );
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

/// Typed grams in tenths, or null unless they are greater than 0, at most
/// 5000 and have at most 1 decimal: the server's rules (#60).
int? parseGrams(String typed) {
  final match = RegExp(r'^(\d{1,6})(?:\.(\d)?0*)?$')
      .firstMatch(westernNumberText(typed));
  if (match == null) return null;
  final tenths = int.parse(match[1]!) * 10 + int.parse(match[2] ?? '0');
  return tenths > 0 && tenths <= 50000 ? tenths : null;
}

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
    this.revision = 1,
    this.sentRevision = 0,
    this.deleted = false,
    this.refused = false,
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
    required this.revision,
    required this.sentRevision,
    required this.deleted,
    required this.refused,
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

  /// 1 when logged, plus 1 on every change and on delete.
  final int revision;

  /// The last revision the server confirmed, 0 if never.
  final int sentRevision;
  final bool deleted;

  /// The server refused this row; it waits for the trainee to change or
  /// delete it.
  final bool refused;

  /// The phone has a change the server hasn't confirmed yet and will send.
  bool get unsent => revision > sentRevision && !refused;
}

/// An entry and its food, as the diary shows them.
class LoggedFood {
  const LoggedFood({required this.entry, required this.food});

  final FoodLogEntry entry;
  final Food food;
}
