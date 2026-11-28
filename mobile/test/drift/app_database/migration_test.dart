import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghbot/core/database.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v3.dart' as v3;
import 'generated/schema_v4.dart' as v4;
import 'generated/schema_v5.dart' as v5;

const _profileV1 = v1.ProfileData(
  birthYear: 1996,
  birthMonth: 3,
  sex: 'female',
  heightCm: 167.5,
  weightKg: 63.25,
  activityLevel: 'lightlyActive',
  goal: 'gain',
);

const _targetsV1 = v1.TargetsData(
  calories: 2210,
  proteinG: 176,
  fatG: 49,
  carbsG: 266,
  maintenanceCalories: 2760,
  atMinimum: 1,
  aboveTestedAge: 0,
  goal: 'lose',
  goalAdjustmentPercent: -20,
);

const _riceV2 = v2.FoodsData(
  id: 'rice',
  nameAr: 'أرز أبيض مطبوخ',
  nameEn: 'Cooked white rice',
  caloriesPer100g: 1300,
  proteinPer100g: 27,
  carbsPer100g: 282,
  fatPer100g: 3,
);

const _entryV2 = v2.FoodLogEntriesData(
  id: 'entry-1',
  foodId: 'rice',
  meal: 'lunch',
  diaryDay: '2026-11-23',
  grams: 1500,
  caloriesPer100g: 1300,
  proteinPer100g: 27,
  carbsPer100g: 282,
  fatPer100g: 3,
  calories: 1950,
  protein: 41,
  carbs: 423,
  fat: 5,
  loggedAt: 1795435200,
);

const _riceV3 = v3.FoodsData(
  id: 'rice',
  nameAr: 'أرز أبيض مطبوخ',
  nameEn: 'Cooked white rice',
  caloriesPer100g: 1300,
  proteinPer100g: 27,
  carbsPer100g: 282,
  fatPer100g: 3,
);

const _entryV3 = v3.FoodLogEntriesData(
  id: 'entry-1',
  foodId: 'rice',
  meal: 'lunch',
  diaryDay: '2026-11-23',
  grams: 1500,
  caloriesPer100g: 1300,
  proteinPer100g: 27,
  carbsPer100g: 282,
  fatPer100g: 3,
  calories: 1950,
  protein: 41,
  carbs: 423,
  fat: 5,
  loggedAt: 1795435200,
  revision: 2,
  sentRevision: 1,
  deleted: 0,
  refused: 0,
);

const _targetsV3 = v3.TargetsData(
  calories: 2210,
  proteinG: 176,
  fatG: 49,
  carbsG: 266,
  maintenanceCalories: 2760,
  atMinimum: 0,
  aboveTestedAge: 1,
  goal: 'lose',
  goalAdjustmentPercent: -20,
);

const _riceV4 = v4.FoodsData(
  id: 'rice',
  nameAr: 'أرز أبيض مطبوخ',
  nameEn: 'Cooked white rice',
  caloriesPer100g: 1300,
  proteinPer100g: 27,
  carbsPer100g: 282,
  fatPer100g: 3,
);

const _entryV4 = v4.FoodLogEntriesData(
  id: 'entry-1',
  foodId: 'rice',
  meal: 'lunch',
  diaryDay: '2026-11-23',
  grams: 1500,
  caloriesPer100g: 1300,
  proteinPer100g: 27,
  carbsPer100g: 282,
  fatPer100g: 3,
  calories: 1950,
  protein: 41,
  carbs: 423,
  fat: 5,
  loggedAt: 1795435200,
  revision: 2,
  sentRevision: 1,
  deleted: 0,
  refused: 0,
);

const _customTargetsV4 = v4.TargetsData(
  calories: 2500,
  proteinG: 180,
  fatG: 70,
  carbsG: 283,
  maintenanceCalories: 2760,
  atMinimum: 0,
  aboveTestedAge: 0,
  goal: 'lose',
  goalAdjustmentPercent: -20,
  custom: 1,
  macrosAdjusted: 0,
  recommendedCalories: 2210,
  recommendedProteinG: 176,
  recommendedFatG: 49,
  recommendedCarbsG: 266,
);

/// Upgrades each exported schema to every later one, and checks that the
/// cached profile and targets survive (docs/decisions.md, 24), and the
/// diary too.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('each upgrade gives the exported schema', () {
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      for (final toVersion in versions.skip(i + 1)) {
        test('from $fromVersion to $toVersion', () async {
          final schema = await verifier.schemaAt(fromVersion);
          final db = AppDatabase(schema.newConnection());
          await verifier.migrateAndValidate(db, toVersion);
          await db.close();
        });
      }
    }
  });

  test('upgrading from 1 to 2 keeps the profile and targets', () async {
    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insert(oldDb.profile, _profileV1);
        batch.insert(oldDb.targets, _targetsV1);
      },
      validateItems: (newDb) async {
        expect(
          (await newDb.select(newDb.profile).getSingle()).toJson(),
          _profileV1.toJson(),
        );
        expect(
          (await newDb.select(newDb.targets).getSingle()).toJson(),
          _targetsV1.toJson(),
        );
      },
    );
  });

  test('upgrading from 2 to 3 keeps the entries, each waiting to be sent '
      'for the first time', () async {
    await verifier.testWithDataIntegrity(
      oldVersion: 2,
      newVersion: 3,
      createOld: v2.DatabaseAtV2.new,
      createNew: v3.DatabaseAtV3.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insert(oldDb.foods, _riceV2);
        batch.insert(oldDb.foodLogEntries, _entryV2);
      },
      validateItems: (newDb) async {
        final entry = await newDb.select(newDb.foodLogEntries).getSingle();
        expect(entry.toJson(), {
          ..._entryV2.toJson(),
          'revision': 1,
          'sentRevision': 0,
          'deleted': 0,
          'refused': 0,
        });
      },
    );
  });

  test('upgrading from 3 to 4 keeps the entries, and the targets as '
      'recommended ones', () async {
    await verifier.testWithDataIntegrity(
      oldVersion: 3,
      newVersion: 4,
      createOld: v3.DatabaseAtV3.new,
      createNew: v4.DatabaseAtV4.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insert(oldDb.foods, _riceV3);
        batch.insert(oldDb.foodLogEntries, _entryV3);
        batch.insert(oldDb.targets, _targetsV3);
      },
      validateItems: (newDb) async {
        expect(
          (await newDb.select(newDb.foodLogEntries).getSingle()).toJson(),
          _entryV3.toJson(),
        );
        expect((await newDb.select(newDb.targets).getSingle()).toJson(), {
          ..._targetsV3.toJson(),
          'custom': 0,
          'macrosAdjusted': 0,
          'recommendedCalories': 2210,
          'recommendedProteinG': 176,
          'recommendedFatG': 49,
          'recommendedCarbsG': 266,
        });
      },
    );
  });

  test('upgrading from 4 to 5 keeps the entries and targets, with no pull '
      'marker, so the first pull brings everything', () async {
    await verifier.testWithDataIntegrity(
      oldVersion: 4,
      newVersion: 5,
      createOld: v4.DatabaseAtV4.new,
      createNew: v5.DatabaseAtV5.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insert(oldDb.foods, _riceV4);
        batch.insert(oldDb.foodLogEntries, _entryV4);
        batch.insert(oldDb.targets, _customTargetsV4);
      },
      validateItems: (newDb) async {
        expect(
          (await newDb.select(newDb.foodLogEntries).getSingle()).toJson(),
          _entryV4.toJson(),
        );
        expect(
          (await newDb.select(newDb.targets).getSingle()).toJson(),
          _customTargetsV4.toJson(),
        );
        expect(await newDb.select(newDb.pullMarker).get(), isEmpty);
      },
    );
  });
}
