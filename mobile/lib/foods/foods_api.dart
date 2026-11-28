import 'package:drift/drift.dart';

import '../auth/auth_session.dart';
import '../core/api_failure.dart';
import '../core/database.dart';
import 'food.dart';

class FoodsApi {
  const FoodsApi(this._session);

  final AuthSession _session;

  /// The server's best matches for [query], in Arabic or English
  /// (decision 29).
  Future<List<Food>> search(String query) => _session.getList(
    '/foods?q=${Uri.encodeQueryComponent(query)}',
    Food.fromJson,
  );

  /// Sends the own food [food] as it is now, and stores the server's
  /// answer in [database], by the rules entries follow (decision 31).
  /// Throws an `ApiFailure` when the call should be tried again: any
  /// failure but a refusal.
  ///
  /// The answer is the copy the server kept: the phone takes it, marked
  /// sent, even at the revision sent, but only if the food is still the
  /// revision sent. A 422 or 409 is the server refusing the food itself: it
  /// is marked refused and isn't sent again until the trainee changes it.
  Future<void> send(AppDatabase database, Food food) async {
    final table = database.foodTable;
    Expression<bool> unchanged($FoodTableTable row) =>
        row.id.equals(food.id) & row.revision.equals(food.revision);
    final Food kept;
    try {
      kept = await _session.put(
        '/me/foods/${food.id}',
        _json(food),
        Food.fromJson,
      );
    } on ApiFailure catch (failure) {
      if (failure case ValidationFailure() || ServerFailure(statusCode: 409)) {
        await (database.update(table)..where(unchanged)).write(
          const FoodTableCompanion(refused: Value(true)),
        );
        return;
      }
      rethrow;
    }
    await (database.update(table)..where(unchanged)).write(foodRow(kept));
  }
}

/// [food] as the server reads it: values as plain numbers with 1 decimal
/// (decision 30).
Map<String, Object?> _json(Food food) => {
  'revision': food.revision,
  'name_ar': food.nameAr,
  'name_en': food.nameEn,
  'calories': food.per100g.calories / 10,
  'protein': food.per100g.protein / 10,
  'carbs': food.per100g.carbs / 10,
  'fat': food.per100g.fat / 10,
  'barcode': food.barcode,
};
