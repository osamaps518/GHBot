import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../food_log/entry.dart';
import '../food_log/entry_table.dart';
import '../food_log/meal.dart';
import '../food_log/pull_marker_table.dart';
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

/// One user's data on the phone, in its own file (decision 25).
@DriftDatabase(
  tables: [
    ProfileTable,
    TargetsTable,
    FoodTable,
    FoodLogEntryTable,
    PullMarkerTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 5;

  /// Each step brings the file from one exported schema (`drift_schemas/`)
  /// to the next. Version 2 adds the foods and the diary. Version 3 adds
  /// what sending entries needs (decision 31); entries logged before it are
  /// unsent. Version 4 adds custom targets (decision 37); targets stored
  /// before it are recommended ones, so they are their own recommended
  /// values. SQLite can't add a column without a default, so the step copies
  /// the table with the new columns filled in. Version 5 adds the pull marker
  /// (decision 31); with none stored, the first pull brings everything.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: stepByStep(
      from1To2: (m, schema) async {
        await m.createTable(schema.foods);
        await m.createTable(schema.foodLogEntries);
        await m.createIndex(schema.foodLogEntriesDiaryDay);
      },
      from2To3: (m, schema) async {
        final entries = schema.foodLogEntries;
        await m.addColumn(entries, entries.revision);
        await m.addColumn(entries, entries.sentRevision);
        await m.addColumn(entries, entries.deleted);
        await m.addColumn(entries, entries.refused);
      },
      from3To4: (m, schema) async {
        final targets = schema.targets;
        await m.alterTable(
          TableMigration(
            targets,
            columnTransformer: {
              targets.custom: const Constant(0),
              targets.macrosAdjusted: const Constant(0),
              targets.recommendedCalories: targets.calories,
              targets.recommendedProteinG: targets.proteinG,
              targets.recommendedFatG: targets.fatG,
              targets.recommendedCarbsG: targets.carbsG,
            },
            newColumns: [
              targets.custom,
              targets.macrosAdjusted,
              targets.recommendedCalories,
              targets.recommendedProteinG,
              targets.recommendedFatG,
              targets.recommendedCarbsG,
            ],
          ),
        );
      },
      from4To5: (m, schema) async {
        await m.createTable(schema.pullMarker);
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
            custom: targets.custom,
            macrosAdjusted: targets.macrosAdjusted,
            recommendedCalories: targets.recommendedCalories,
            recommendedProteinG: targets.recommendedProteinG,
            recommendedFatG: targets.recommendedFatG,
            recommendedCarbsG: targets.recommendedCarbsG,
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
  /// ignoring case. This is the search without a connection (decision 20).
  ///
  /// The names are compared in Dart: SQLite's `LIKE` ignores case only for
  /// A to Z, so "CRÉME" wouldn't find "Créme". The phone keeps only the foods
  /// the trainee has logged, so reading them all is cheap.
  Future<List<Food>> searchStoredFoods(String query) async {
    final typed = query.toLowerCase();
    bool matches(String? name) =>
        name != null && name.toLowerCase().contains(typed);
    final foods = await (select(
      foodTable,
    )..orderBy([(food) => OrderingTerm.asc(food.id)])).get();
    return [
      for (final food in foods)
        if (matches(food.nameAr) || matches(food.nameEn)) food,
    ];
  }

  /// Logs [grams] (in tenths) of [food] into [meal] on [diaryDay]
  /// (`YYYY-MM-DD`), with totals calculated on the phone (decision 33), and
  /// keeps the food for offline search. Both or neither are saved.
  ///
  /// The entry's ID is a UUIDv7, made here. [diaryDay] is the day the diary
  /// shows, which can be before [loggedAt]'s (decision 34). Throws an
  /// [ArgumentError] and saves nothing when the server would refuse the
  /// entry.
  Future<void> logEntry({
    required Food food,
    required DiaryMeal meal,
    required int grams,
    required String diaryDay,
    required DateTime loggedAt,
  }) => transaction(() async {
    final totals = entryTotals(food.per100g, grams);
    _checkForServer(meal.meal, meal.name, grams, food.per100g, totals);
    await storeFood(food);
    await into(foodLogEntryTable).insert(
      FoodLogEntryTableCompanion.insert(
        id: const Uuid().v7(),
        foodId: food.id,
        meal: meal.meal,
        mealName: Value(meal.name),
        diaryDay: diaryDay,
        grams: grams,
        caloriesPer100g: food.per100g.calories,
        proteinPer100g: food.per100g.protein,
        carbsPer100g: food.per100g.carbs,
        fatPer100g: food.per100g.fat,
        calories: totals.calories,
        protein: totals.protein,
        carbs: totals.carbs,
        fat: totals.fat,
        loggedAt: loggedAt.toUtc(),
      ),
    );
  });

  /// Changes an entry's grams (in tenths). The totals are calculated from
  /// the entry's own values per 100 g, not its food's current ones
  /// (decisions 21 and 30). The change raises the revision and
  /// clears a refusal, so the entry is sent again. Throws an
  /// [ArgumentError] and changes nothing when the server would refuse it.
  /// An entry sync removed meanwhile, because the server deleted it, stays
  /// removed.
  Future<void> changeGrams(String entryId, int grams) => transaction(() async {
    final entry = await (select(
      foodLogEntryTable,
    )..where((row) => row.id.equals(entryId))).getSingleOrNull();
    if (entry == null) return;
    final totals = entryTotals(entry.per100g, grams);
    _checkForServer(entry.meal, entry.mealName, grams, entry.per100g, totals);
    await (update(
      foodLogEntryTable,
    )..where((row) => row.id.equals(entryId))).write(
      FoodLogEntryTableCompanion(
        grams: Value(grams),
        calories: Value(totals.calories),
        protein: Value(totals.protein),
        carbs: Value(totals.carbs),
        fat: Value(totals.fat),
        revision: Value(entry.revision + 1),
        refused: const Value(false),
      ),
    );
  });

  /// Marks an entry deleted and raises its revision; the diary hides it.
  /// The row stays until the server confirms the delete. Like a change, it
  /// clears a refusal, so the delete is sent.
  Future<void> deleteEntry(String entryId) =>
      (update(foodLogEntryTable)..where((row) => row.id.equals(entryId))).write(
        FoodLogEntryTableCompanion.custom(
          revision: foodLogEntryTable.revision + const Constant(1),
          deleted: const Constant(true),
          refused: const Constant(false),
        ),
      );

  /// Moves an entry to [diaryDay] (`YYYY-MM-DD`), in the same meal. Only
  /// its diary day changes. Like a change, it raises the revision and
  /// clears a refusal, so the entry is sent again (decision 34). Moving an
  /// entry to the day it is on changes nothing.
  Future<void> moveEntry(String entryId, String diaryDay) =>
      (update(foodLogEntryTable)..where(
            (row) =>
                row.id.equals(entryId) & row.diaryDay.equals(diaryDay).not(),
          ))
          .write(
            FoodLogEntryTableCompanion.custom(
              diaryDay: Variable(diaryDay),
              revision: foodLogEntryTable.revision + const Constant(1),
              refused: const Constant(false),
            ),
          );

  /// The entries with a change the server hasn't confirmed, deleted ones
  /// too, in the order they were logged.
  Future<List<FoodLogEntry>> unsentEntries() =>
      (select(foodLogEntryTable)
            ..where((row) => _unsent)
            ..orderBy([
              (row) => OrderingTerm.asc(row.loggedAt),
              (row) => OrderingTerm.asc(row.id),
            ]))
          .get();

  /// How many entries [unsentEntries] has. The stream sends again after
  /// every change.
  Stream<int> watchUnsentCount() {
    final count = foodLogEntryTable.id.count();
    return (selectOnly(foodLogEntryTable)
          ..addColumns([count])
          ..where(_unsent))
        .map((row) => row.read(count)!)
        .watchSingle();
  }

  /// An entry with a change the server hasn't confirmed and will be sent.
  Expression<bool> get _unsent =>
      foodLogEntryTable.revision.isBiggerThan(foodLogEntryTable.sentRevision) &
      foodLogEntryTable.refused.not();

  /// Throws an [ArgumentError] when the server would refuse an entry with
  /// these values.
  void _checkForServer(
    Meal meal,
    String? mealName,
    int grams,
    Nutrients per100g,
    Nutrients totals,
  ) {
    if (!passesServerChecks(
      meal: meal,
      mealName: mealName,
      grams: grams,
      per100g: per100g,
      totals: totals,
    )) {
      throw ArgumentError('The server would refuse this entry.');
    }
  }

  /// The entries of [diaryDay] (`YYYY-MM-DD`) with their foods, in the
  /// order they were logged, without deleted ones. The stream sends again
  /// after every change.
  Stream<List<LoggedFood>> watchDiaryDay(String diaryDay) {
    final query =
        select(foodLogEntryTable).join([
            innerJoin(
              foodTable,
              foodTable.id.equalsExp(foodLogEntryTable.foodId),
            ),
          ])
          ..where(
            foodLogEntryTable.diaryDay.equals(diaryDay) &
                foodLogEntryTable.deleted.not(),
          )
          ..orderBy([
            OrderingTerm.asc(foodLogEntryTable.loggedAt),
            OrderingTerm.asc(foodLogEntryTable.id),
          ]);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          LoggedFood(
            entry: row.readTable(foodLogEntryTable),
            food: row.readTable(foodTable),
          ),
      ],
    );
  }

  /// The 20 foods logged most recently, newest first, each with the grams
  /// and calories (in tenths) it was last logged with. Deleted entries
  /// don't count.
  ///
  /// `logged_at` is stored in whole seconds, so two entries can share it.
  /// Like the diary, entries are ordered by `logged_at` and then by ID, which
  /// is a UUIDv7 and grows with time. `ROW_NUMBER()` numbers each food's
  /// entries newest first, and row 1 is the latest one.
  Stream<List<({Food food, int grams, int calories})>> watchRecentFoods() =>
      customSelect(
        'SELECT foods.*, latest.grams, latest.calories '
        'FROM ('
        'SELECT food_id, id, grams, calories, logged_at, '
        'ROW_NUMBER() OVER ('
        'PARTITION BY food_id ORDER BY logged_at DESC, id DESC'
        ') AS newest '
        'FROM food_log_entries WHERE NOT deleted'
        ') AS latest '
        'JOIN foods ON foods.id = latest.food_id '
        'WHERE latest.newest = 1 '
        'ORDER BY latest.logged_at DESC, latest.id DESC '
        'LIMIT 20',
        readsFrom: {foodTable, foodLogEntryTable},
      ).watch().map(
        (rows) => [
          for (final row in rows)
            (
              food: foodTable.map(row.data),
              grams: row.read<int>('grams'),
              calories: row.read<int>('calories'),
            ),
        ],
      );
}
