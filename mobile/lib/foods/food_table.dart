import 'package:drift/drift.dart';

import 'food.dart';

/// The foods the trainee has logged, so they can be logged again without a
/// connection (decision 20), and the trainee's own foods. Values per 100 g
/// are whole tenths.
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

  /// The trainee's own food, which only they see (#65).
  BoolColumn get own => boolean().withDefault(const Constant(false))();
  TextColumn get barcode => text().nullable()();

  /// The server's revision for a catalog food, which is 0. An own food made
  /// on the phone starts at 1 (decision 31).
  IntColumn get revision => integer().withDefault(const Constant(0))();

  /// The last revision the server confirmed, 0 if never.
  IntColumn get sentRevision => integer().withDefault(const Constant(0))();

  /// The server refused the row itself; it isn't sent again until changed.
  BoolColumn get refused => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
