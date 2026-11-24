import 'package:drift/drift.dart';

import 'food.dart';

/// The foods the trainee has logged, so they can be logged again without a
/// connection (docs/decisions.md, 20). Values per 100 g are whole tenths.
@UseRowClass(Food, constructor: 'fromColumns')
class FoodTable extends Table {
  @override
  String get tableName => 'foods';

  TextColumn get id => text()();
  TextColumn get nameAr => text().nullable()();
  TextColumn get nameEn => text().nullable()();
  IntColumn get caloriesPer100g => integer().named('calories_per_100g')();
  IntColumn get proteinPer100g => integer().named('protein_per_100g')();
  IntColumn get carbsPer100g => integer().named('carbs_per_100g')();
  IntColumn get fatPer100g => integer().named('fat_per_100g')();

  @override
  Set<Column> get primaryKey => {id};
}
