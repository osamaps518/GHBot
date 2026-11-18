import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghbot/core/database.dart';
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
}
