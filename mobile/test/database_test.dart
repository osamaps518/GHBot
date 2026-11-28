import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghbot/core/database.dart';
import 'package:ghbot/food_log/meal.dart';
import 'package:ghbot/foods/food.dart';
import 'package:ghbot/profiles/profile.dart';
import 'package:ghbot/targets/targets.dart';

const _profile = Profile(
  birthYear: 1996,
  birthMonth: 3,
  sex: Sex.female,
  heightCm: 167.5,
  weightKg: 63.25,
  activityLevel: ActivityLevel.lightlyActive,
  goal: Goal.gain,
);

const _targets = Targets(
  calories: 2210,
  proteinG: 176,
  fatG: 49,
  carbsG: 266,
  maintenanceCalories: 2760,
  atMinimum: true,
  aboveTestedAge: true,
  goal: Goal.lose,
  goalAdjustmentPercent: -20,
  custom: true,
  macrosAdjusted: true,
  recommendedCalories: 1990,
  recommendedProteinG: 150,
  recommendedFatG: 44,
  recommendedCarbsG: 240,
);

List<Object> _targetsValues(Targets targets) => [
  targets.calories,
  targets.proteinG,
  targets.fatG,
  targets.carbsG,
  targets.maintenanceCalories,
  targets.atMinimum,
  targets.aboveTestedAge,
  targets.goal,
  targets.goalAdjustmentPercent,
  targets.custom,
  targets.macrosAdjusted,
  targets.recommendedCalories,
  targets.recommendedProteinG,
  targets.recommendedFatG,
  targets.recommendedCarbsG,
];

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
  });
  tearDown(() => database.close());

  test('nothing is stored at first', () async {
    expect(await database.readProfileAndTargets(), isNull);
  });

  test('stored profile and targets read back the same', () async {
    await database.storeProfileAndTargets(_profile, _targets);

    final stored = (await database.readProfileAndTargets())!;
    expect(stored.profile.toJson(), _profile.toJson());
    expect(_targetsValues(stored.targets), _targetsValues(_targets));
  });

  test('storing again replaces what was stored', () async {
    await database.storeProfileAndTargets(_profile, _targets);
    const changed = Profile(
      birthYear: 1990,
      birthMonth: 12,
      sex: Sex.male,
      heightCm: 180,
      weightKg: 80,
      activityLevel: ActivityLevel.sedentary,
      goal: Goal.maintain,
    );

    await database.storeProfileAndTargets(changed, _targets);

    final stored = (await database.readProfileAndTargets())!;
    expect(stored.profile.toJson(), changed.toJson());
  });

  test('an entry the server would refuse is not saved', () async {
    const tooRich = Food(
      id: 'too-rich',
      nameAr: null,
      nameEn: 'Too rich',
      per100g: Nutrients(calories: 9010, protein: 0, carbs: 0, fat: 1000),
    );

    await expectLater(
      database.logEntry(
        food: tooRich,
        meal: const DiaryMeal(Meal.lunch),
        grams: 1000,
        loggedAt: DateTime.utc(2026, 11, 23, 12),
      ),
      throwsArgumentError,
    );

    expect(await database.watchDiaryDay('2026-11-23').first, isEmpty);
  });

  test("a changed amount uses the entry's stored values, even after the "
      "food's values have changed", () async {
    const rice = Food(
      id: 'rice',
      nameAr: null,
      nameEn: 'Cooked white rice',
      per100g: Nutrients(calories: 1300, protein: 27, carbs: 282, fat: 3),
    );
    await database.logEntry(
      food: rice,
      meal: const DiaryMeal(Meal.lunch),
      grams: 1500,
      loggedAt: DateTime(2026, 11, 23, 12),
    );
    await database.storeFood(
      const Food(
        id: 'rice',
        nameAr: null,
        nameEn: 'Cooked white rice',
        per100g: Nutrients(calories: 1500, protein: 30, carbs: 300, fat: 10),
      ),
    );
    final logged = (await database.watchDiaryDay('2026-11-23').first).single;

    await database.changeGrams(logged.entry.id, 2005);

    final changed = (await database.watchDiaryDay('2026-11-23').first).single;
    expect(changed.entry.grams, 2005);
    final totals = changed.entry.totals;
    expect(
      [totals.calories, totals.protein, totals.carbs, totals.fat],
      [2607, 54, 565, 6],
    );
    expect(changed.entry.revision, 2);
  });

  test('a deleted entry leaves the diary and the recent foods', () async {
    await database.logEntry(
      food: const Food(
        id: 'rice',
        nameAr: null,
        nameEn: 'Cooked white rice',
        per100g: Nutrients(calories: 1300, protein: 27, carbs: 282, fat: 3),
      ),
      meal: const DiaryMeal(Meal.lunch),
      grams: 1500,
      loggedAt: DateTime(2026, 11, 23, 12),
    );
    final logged = (await database.watchDiaryDay('2026-11-23').first).single;

    await database.deleteEntry(logged.entry.id);

    expect(await database.watchDiaryDay('2026-11-23').first, isEmpty);
    expect(await database.watchRecentFoods().first, isEmpty);
  });

  test("a moved entry leaves the old day's totals and joins the new day's, "
      'in the same meal', () async {
    await database.logEntry(
      food: const Food(
        id: 'rice',
        nameAr: null,
        nameEn: 'Cooked white rice',
        per100g: Nutrients(calories: 1300, protein: 27, carbs: 282, fat: 3),
      ),
      meal: const DiaryMeal(Meal.lunch),
      grams: 1500,
      loggedAt: DateTime(2026, 11, 23, 12),
    );
    await database.logEntry(
      food: const Food(
        id: 'oil',
        nameAr: null,
        nameEn: 'Olive oil',
        per100g: Nutrients(calories: 8840, protein: 0, carbs: 0, fat: 1000),
      ),
      meal: const DiaryMeal(Meal.extra, 'Pre-workout'),
      grams: 123,
      loggedAt: DateTime(2026, 11, 22, 12),
    );
    Future<List<int>> dayTotals(String day) async {
      final entries = await database.watchDiaryDay(day).first;
      final totals = Nutrients.sum(
        entries.map((logged) => logged.entry.totals),
      );
      return [totals.calories, totals.protein, totals.carbs, totals.fat];
    }

    final oil = (await database.watchDiaryDay('2026-11-22').first).single;
    await database.moveEntry(oil.entry.id, '2026-11-23');

    expect(await dayTotals('2026-11-22'), [0, 0, 0, 0]);
    expect(await dayTotals('2026-11-23'), [3037, 41, 423, 128]);
    final moved = (await database.watchDiaryDay('2026-11-23').first)
        .singleWhere((logged) => logged.entry.id == oil.entry.id)
        .entry;
    expect(
      [moved.meal, moved.mealName, moved.grams, moved.revision],
      [Meal.extra, 'Pre-workout', 123, 2],
    );

    await database.moveEntry(oil.entry.id, '2026-11-23');

    final again = (await database.unsentEntries()).singleWhere(
      (entry) => entry.id == oil.entry.id,
    );
    expect(again.revision, 2);
  });
}
