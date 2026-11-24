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
}
