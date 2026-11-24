import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghbot/core/database.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

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

/// Upgrades each exported schema to every later one, and checks that the
/// cached profile and targets survive (docs/decisions.md, 24).
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
}
