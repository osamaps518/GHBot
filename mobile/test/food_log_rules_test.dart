import 'package:flutter_test/flutter_test.dart';
import 'package:ghbot/food_log/entry.dart';
import 'package:ghbot/food_log/meal.dart';
import 'package:ghbot/foods/food.dart';

/// Decision 30's foods, in tenths: cooked white rice and olive oil.
const _rice = Nutrients(calories: 1300, protein: 27, carbs: 282, fat: 3);
const _oil = Nutrients(calories: 8840, protein: 0, carbs: 0, fat: 1000);

List<int> _values(Nutrients nutrients) => [
  nutrients.calories,
  nutrients.protein,
  nutrients.carbs,
  nutrients.fat,
];

FoodLogEntry _entry(
  String id,
  Meal meal,
  DateTime loggedAt, {
  String? mealName,
  Nutrients totals = _rice,
}) => FoodLogEntry(
  id: id,
  foodId: 'food-$id',
  meal: meal,
  mealName: mealName,
  diaryDay: '2026-11-23',
  grams: 1000,
  per100g: _rice,
  totals: totals,
  loggedAt: loggedAt,
);

LoggedFood _logged(FoodLogEntry entry) => LoggedFood(
  entry: entry,
  food: Food(
    id: entry.foodId,
    nameAr: 'أرز',
    nameEn: 'Rice',
    per100g: entry.per100g,
  ),
);

void main() {
  group("decision 30's worked examples", () {
    for (final (name, per100g, grams, expected) in [
      ('rice 150 g', _rice, 1500, [1950, 41, 423, 5]),
      ('oil 12.3 g', _oil, 123, [1087, 0, 0, 123]),
      ('rice 2.5 g', _rice, 25, [33, 1, 7, 0]),
    ]) {
      test(name, () {
        expect(_values(entryTotals(per100g, grams)), expected);
      });
    }

    test(
      'the day adds stored totals, then rounds half up to whole numbers',
      () {
        final day = Nutrients.sum([
          entryTotals(_rice, 1500),
          entryTotals(_oil, 123),
        ]);

        expect(_values(day), [3037, 41, 423, 128]);
        expect(
          [day.calories, day.protein, day.carbs, day.fat].map(roundTenths),
          [304, 4, 42, 13],
        );
      },
    );
  });

  group('the diary day starts at 4:00', () {
    test('3:59 belongs to the day before', () {
      expect(diaryDayOf(DateTime(2026, 3, 1, 3, 59)), '2026-02-28');
    });

    test('4:00 starts a new day', () {
      expect(diaryDayOf(DateTime(2026, 3, 1, 4)), '2026-03-01');
    });

    test('the next day starts at the next 4:00', () {
      expect(
        nextDayStart(DateTime(2026, 2, 28, 3, 59)),
        DateTime(2026, 2, 28, 4),
      );
      expect(nextDayStart(DateTime(2026, 2, 28, 4)), DateTime(2026, 3, 1, 4));
    });
  });

  group('meals', () {
    final morning = DateTime.utc(2026, 11, 23, 8);

    test('breakfast, lunch and dinner always show, extra meals after them '
        'in the order of their first entry', () {
      final meals = groupByMeal([
        _logged(_entry('1', Meal.extra, morning, mealName: 'Late snack')),
        _logged(_entry('2', Meal.lunch, morning)),
        _logged(
          _entry(
            '3',
            Meal.extra,
            morning.subtract(const Duration(hours: 1)),
            mealName: 'Pre-workout',
          ),
        ),
        _logged(
          _entry(
            '4',
            Meal.extra,
            morning.add(const Duration(hours: 1)),
            mealName: 'Late snack',
          ),
        ),
      ]);

      expect(meals.map((group) => group.meal), [
        const DiaryMeal(Meal.breakfast),
        const DiaryMeal(Meal.lunch),
        const DiaryMeal(Meal.dinner),
        const DiaryMeal(Meal.extra, 'Pre-workout'),
        const DiaryMeal(Meal.extra, 'Late snack'),
      ]);
      expect(meals[1].entries.map((logged) => logged.entry.id), ['2']);
      expect(meals[4].entries.map((logged) => logged.entry.id), ['1', '4']);
    });

    test('a newly named meal shows after the others until it has entries, '
        'then an extra meal with no entries is gone', () {
      final named = groupByMeal([], newMealNames: ['Pre-workout']);
      expect(named.last.meal, const DiaryMeal(Meal.extra, 'Pre-workout'));
      expect(named.last.entries, isEmpty);

      expect(groupByMeal([]).map((group) => group.meal), [
        const DiaryMeal(Meal.breakfast),
        const DiaryMeal(Meal.lunch),
        const DiaryMeal(Meal.dinner),
      ]);
    });

    test('naming a meal the day already has shows it once', () {
      final meals = groupByMeal(
        [_logged(_entry('1', Meal.extra, morning, mealName: 'Pre-workout'))],
        newMealNames: ['Pre-workout'],
      );

      expect(meals, hasLength(4));
      expect(meals.last.entries, hasLength(1));
    });

    test("a meal's calories add its entries' stored totals", () {
      final meals = groupByMeal([
        _logged(
          _entry('1', Meal.lunch, morning, totals: entryTotals(_rice, 1500)),
        ),
        _logged(
          _entry('2', Meal.lunch, morning, totals: entryTotals(_oil, 123)),
        ),
      ]);

      expect(meals[1].totals.calories, 3037);
    });

    for (final (typed, name) in [
      ('  Pre-workout ', 'Pre-workout'),
      ('   ', null),
      ('a' * 40, 'a' * 40),
      ('a' * 41, null),
    ]) {
      test('meal name "$typed" is ${name == null ? 'refused' : 'kept'}', () {
        expect(extraMealName(typed), name);
      });
    }
  });

  group("the server's checks before a save", () {
    final rice150 = entryTotals(_rice, 1500);
    const fatty = Nutrients(calories: 9000, protein: 1000, carbs: 0, fat: 0);

    for (final (name, meal, mealName, grams, per100g, totals, passes) in [
      ('rice, 150 g, lunch', Meal.lunch, null, 1500, _rice, rice150, true),
      (
        'the highest values',
        Meal.lunch,
        null,
        10,
        fatty,
        entryTotals(fatty, 10),
        true,
      ),
      ('no grams', Meal.lunch, null, 0, _rice, Nutrients.zero, false),
      (
        'over 5000 g',
        Meal.lunch,
        null,
        50001,
        _rice,
        entryTotals(_rice, 50001),
        false,
      ),
      (
        'over 900 kcal per 100 g',
        Meal.lunch,
        null,
        1000,
        const Nutrients(calories: 9001, protein: 0, carbs: 0, fat: 0),
        const Nutrients(calories: 9001, protein: 0, carbs: 0, fat: 0),
        false,
      ),
      (
        'over 100 g of a macro per 100 g',
        Meal.lunch,
        null,
        1000,
        const Nutrients(calories: 0, protein: 0, carbs: 1001, fat: 0),
        const Nutrients(calories: 0, protein: 0, carbs: 1001, fat: 0),
        false,
      ),
      (
        'a total one tenth off',
        Meal.lunch,
        null,
        1500,
        _rice,
        Nutrients(
          calories: rice150.calories,
          protein: rice150.protein + 1,
          carbs: rice150.carbs,
          fat: rice150.fat,
        ),
        false,
      ),
      (
        'an extra meal with a name',
        Meal.extra,
        'Pre-workout',
        1500,
        _rice,
        rice150,
        true,
      ),
      (
        'an extra meal without a name',
        Meal.extra,
        null,
        1500,
        _rice,
        rice150,
        false,
      ),
      (
        'an extra meal named with spaces only',
        Meal.extra,
        '  ',
        1500,
        _rice,
        rice150,
        false,
      ),
      (
        'an extra meal with 41 characters',
        Meal.extra,
        'a' * 41,
        1500,
        _rice,
        rice150,
        false,
      ),
      (
        'a NUL in the name',
        Meal.extra,
        'a\u0000b',
        1500,
        _rice,
        rice150,
        false,
      ),
      (
        'lunch with a name',
        Meal.lunch,
        'Pre-workout',
        1500,
        _rice,
        rice150,
        false,
      ),
    ]) {
      test('$name ${passes ? 'passes' : 'fails'}', () {
        expect(
          passesServerChecks(
            meal: meal,
            mealName: mealName,
            grams: grams,
            per100g: per100g,
            totals: totals,
          ),
          passes,
        );
      });
    }
  });
}
