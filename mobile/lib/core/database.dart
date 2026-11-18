import 'package:drift/drift.dart';

import '../profiles/profile.dart';
import '../profiles/profile_table.dart';
import '../targets/targets.dart';
import '../targets/targets_table.dart';

part 'database.g.dart';

/// One user's data on the phone, in its own file (docs/decisions.md, 25).
@DriftDatabase(tables: [ProfileTable, TargetsTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  /// The stored profile and targets, or null when nothing is stored.
  Future<({Profile profile, Targets targets})?> readProfileAndTargets() async {
    final profile = await select(profileTable).getSingleOrNull();
    final targets = await select(targetsTable).getSingleOrNull();
    if (profile == null || targets == null) return null;
    return (profile: profile, targets: targets);
  }

  /// Replaces what is stored with [profile] and [targets], both or neither.
  Future<void> storeProfileAndTargets(Profile profile, Targets targets) =>
      transaction(() async {
        await delete(profileTable).go();
        await delete(targetsTable).go();
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
}
