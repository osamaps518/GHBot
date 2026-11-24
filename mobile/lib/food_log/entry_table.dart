import 'package:drift/drift.dart';

import 'entry.dart';
import 'meal.dart';

/// The trainee's diary entries. They are saved here first and the diary
/// reads only from here (docs/decisions.md, 32). Grams and all values are
/// whole tenths.
///
/// The diary reads one day at a time, so `diary_day` has an index.
@UseRowClass(FoodLogEntry, constructor: 'fromColumns')
@TableIndex(name: 'food_log_entries_diary_day', columns: {#diaryDay})
class FoodLogEntryTable extends Table {
  @override
  String get tableName => 'food_log_entries';

  TextColumn get id => text()();
  TextColumn get foodId => text()();
  TextColumn get meal => textEnum<Meal>()();
  TextColumn get mealName => text().nullable()();

  /// `YYYY-MM-DD` text: a diary day is a date, not a point in time.
  TextColumn get diaryDay => text()();
  IntColumn get grams => integer()();
  IntColumn get caloriesPer100g => integer().named('calories_per_100g')();
  IntColumn get proteinPer100g => integer().named('protein_per_100g')();
  IntColumn get carbsPer100g => integer().named('carbs_per_100g')();
  IntColumn get fatPer100g => integer().named('fat_per_100g')();
  IntColumn get calories => integer()();
  IntColumn get protein => integer()();
  IntColumn get carbs => integer()();
  IntColumn get fat => integer()();

  /// A point in time, stored in UTC.
  DateTimeColumn get loggedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
