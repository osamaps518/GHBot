import 'package:drift/drift.dart';

import 'profile.dart';

/// The last profile the server sent, so the app opens without a connection.
/// One row at most.
@UseRowClass(Profile)
class ProfileTable extends Table {
  @override
  String get tableName => 'profile';

  IntColumn get birthYear => integer()();
  IntColumn get birthMonth => integer()();
  TextColumn get sex => textEnum<Sex>()();
  RealColumn get heightCm => real()();
  RealColumn get weightKg => real()();
  TextColumn get activityLevel => textEnum<ActivityLevel>()();
  TextColumn get goal => textEnum<Goal>()();
}
