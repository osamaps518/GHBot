import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../food_log/entry.dart';
import '../food_log/entry_table.dart';
import '../food_log/meal.dart';
import '../foods/food.dart';
import '../foods/food_table.dart';
import '../profiles/profile.dart';
import '../profiles/profile_table.dart';
import '../targets/targets.dart';
import '../targets/targets_table.dart';
import 'database.steps.dart';

part 'database.g.dart';

/// Opens `<userId>.sqlite` in `user_data/` under the app support folder.
AppDatabase openUserDatabase(String userId) => AppDatabase(
  driftDatabase(
    name: userId,
    native: DriftNativeOptions(
      databaseDirectory: () async =>
          '${(await getApplicationSupportDirectory()).path}/user_data',
    ),
  ),
);

/// One user's data on the phone, in its own file (docs/decisions.md, 25).
@DriftDatabase(
  tables: [ProfileTable, TargetsTable, FoodTable, FoodLogEntryTable],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 2;

  /// Each step brings the file from one exported schema (`drift_schemas/`)
  /// to the next. Version 2 adds the foods and the diary.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: stepByStep(
      from1To2: (m, schema) async {
        await m.createTable(schema.foods);
        await m.createTable(schema.foodLogEntries);
        await m.createIndex(schema.foodLogEntriesDiaryDay);
      },
    ),
  );

  /// The stored profile and targets, or null when nothing is stored.
  Future<({Profile profile, Targets targets})?> readProfileAndTargets() async {
    final profile = await select(profileTable).getSingleOrNull();
    final targets = await select(targetsTable).getSingleOrNull();
    if (profile == null || targets == null) return null;
    return (profile: profile, targets: targets);
  }

  /// Removes the stored profile and targets.
  Future<void> clearProfileAndTargets() => transaction(() async {
    await delete(profileTable).go();
    await delete(targetsTable).go();
  });

  /// Replaces what is stored with [profile] and [targets], both or neither.
  Future<void> storeProfileAndTargets(Profile profile, Targets targets) =>
      transaction(() async {
        await clearProfileAndTargets();
        await into(profileTable).insert(
          ProfileTableCompanion.insert(
            birthYear: profile.birthYear,
            birthMonth: profile.birthMonth,
            sex: profile.sex,
            heightCm: profile.heightCm,
            weightKg: profile.weightKg,
            activityLevel: profile.activityLevel,
            goal: profile.goal,
          ),
        );
        await into(targetsTable).insert(
          TargetsTableCompanion.insert(
            calories: targets.calories,
            proteinG: targets.proteinG,
            fatG: targets.fatG,
            carbsG: targets.carbsG,
            maintenanceCalories: targets.maintenanceCalories,
            atMinimum: targets.atMinimum,
            aboveTestedAge: targets.aboveTestedAge,
            goal: targets.goal,
            goalAdjustmentPercent: targets.goalAdjustmentPercent,
          ),
        );
      });

  /// Adds [food] to the phone's foods, or updates the copy stored before.
  Future<void> storeFood(Food food) => into(foodTable).insertOnConflictUpdate(
    FoodTableCompanion.insert(
      id: food.id,
      nameAr: Value(food.nameAr),
      nameEn: Value(food.nameEn),
      caloriesPer100g: food.per100g.calories,
      proteinPer100g: food.per100g.protein,
      carbsPer100g: food.per100g.carbs,
      fatPer100g: food.per100g.fat,
    ),
  );

  /// The phone's foods whose Arabic or English name contains [query],
  /// ignoring case. This is the search without a connection
  /// (docs/decisions.md, 20); `%` and `_` in [query] are plain text.
  Future<List<Food>> searchStoredFoods(String query) {
    final escaped = query.replaceAllMapped(
      RegExp(r'[\\%_]'),
      (match) => '\\${match[0]}',
    );
    final pattern = '%$escaped%';
    return (select(foodTable)
          ..where(
            (food) =>
                food.nameAr.like(pattern, escapeChar: r'\') |
                food.nameEn.like(pattern, escapeChar: r'\'),
          )
          ..orderBy([(food) => OrderingTerm.asc(food.id)]))
        .get();
  }
}
