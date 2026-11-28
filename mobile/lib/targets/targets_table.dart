import 'package:drift/drift.dart';

import '../profiles/profile.dart';
import 'targets.dart';

/// The last targets the server sent, so the app opens without a connection.
/// One row at most.
@UseRowClass(Targets)
class TargetsTable extends Table {
  @override
  String get tableName => 'targets';

  IntColumn get calories => integer()();
  IntColumn get proteinG => integer()();
  IntColumn get fatG => integer()();
  IntColumn get carbsG => integer()();
  IntColumn get maintenanceCalories => integer()();
  BoolColumn get atMinimum => boolean()();
  BoolColumn get aboveTestedAge => boolean()();
  TextColumn get goal => textEnum<Goal>()();
  IntColumn get goalAdjustmentPercent => integer()();
  BoolColumn get custom => boolean()();
  BoolColumn get macrosAdjusted => boolean()();
  IntColumn get recommendedCalories => integer()();
  IntColumn get recommendedProteinG => integer()();
  IntColumn get recommendedFatG => integer()();
  IntColumn get recommendedCarbsG => integer()();
}
