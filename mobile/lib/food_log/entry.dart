import '../core/typed_number.dart';
import '../foods/food.dart';
import 'meal.dart';

/// The hour the diary day starts on the phone's clock: an entry logged
/// before 4:00 belongs to the day before (decision 34).
const dayStartHour = 4;

/// The diary day of [localTime], as `YYYY-MM-DD`.
///
/// The day before is found on the calendar, not by subtracting hours, so a
/// daylight saving change can't move it.
String diaryDayOf(DateTime localTime) {
  final day = localTime.hour < dayStartHour
      ? DateTime.utc(localTime.year, localTime.month, localTime.day - 1)
      : DateTime.utc(localTime.year, localTime.month, localTime.day);
  return dayOfDate(day);
}

/// The calendar day of [date], as `YYYY-MM-DD`, such as a day chosen in
/// the date picker.
String dayOfDate(DateTime date) => DateTime.utc(
  date.year,
  date.month,
  date.day,
).toIso8601String().substring(0, 10);

/// [day] (`YYYY-MM-DD`) moved by [days] on the calendar, back when
/// negative.
String addDays(String day, int days) {
  final date = DateTime.parse(day);
  return dayOfDate(DateTime.utc(date.year, date.month, date.day + days));
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
/// to tenths, all in integers (decision 30). [grams] is in tenths.
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

/// Whether the server would accept an entry with these values (#60): grams
/// greater than 0 and at most 5000, at most 900 kcal and 100 g of each macro
/// per 100 g, a name of 1 to 40 characters only for an extra meal, and
/// totals that match the grams. The phone checks before every save
/// (decision 31). All numbers are in tenths.
bool passesServerChecks({
  required Meal meal,
  required String? mealName,
  required int grams,
  required Nutrients per100g,
  required Nutrients totals,
}) {
  bool inRange(int value, int max) => value >= 0 && value <= max;
  final nameFits = meal == Meal.extra
      ? mealName != null &&
            mealName.runes.length <= 40 &&
            mealName.trim().isNotEmpty &&
            !mealName.contains('\u0000')
      : mealName == null;
  final expected = entryTotals(per100g, grams);
  return grams > 0 &&
      grams <= 50000 &&
      inRange(per100g.calories, 9000) &&
      inRange(per100g.protein, 1000) &&
      inRange(per100g.carbs, 1000) &&
      inRange(per100g.fat, 1000) &&
      nameFits &&
      totals.calories == expected.calories &&
      totals.protein == expected.protein &&
      totals.carbs == expected.carbs &&
      totals.fat == expected.fat;
}

/// One food logged into a meal, with the values it was logged with
/// (decision 21). [grams] and all values are in tenths.
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
