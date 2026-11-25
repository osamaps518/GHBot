import 'package:drift/drift.dart';

import '../auth/auth_session.dart';
import '../core/database.dart';
import '../foods/food.dart';
import 'entry.dart';

/// Sends diary entries to the server and stores what it answers
/// (docs/decisions.md, 31).
class FoodLogApi {
  const FoodLogApi(this._session);

  final AuthSession _session;

  /// Sends [entry] as it is now, and stores the server's answer in
  /// [database]. Throws an `ApiFailure` when the call should be tried again.
  Future<void> send(AppDatabase database, FoodLogEntry entry) async {
    final revision = await _session.put(
      '/me/food-log/entries/${entry.id}',
      _json(entry),
      (json) => json['revision'] as int,
    );
    if (revision != entry.revision) return;
    await (database.update(database.foodLogEntryTable)..where(
          (row) => row.id.equals(entry.id) & row.revision.equals(revision),
        ))
        .write(FoodLogEntryTableCompanion(sentRevision: Value(revision)));
  }
}

/// [entry] as the server reads it: grams and values as plain numbers with
/// 1 decimal (docs/decisions.md, 30).
Map<String, Object?> _json(FoodLogEntry entry) {
  Map<String, double> nutrients(Nutrients values) => {
    'calories': values.calories / 10,
    'protein': values.protein / 10,
    'carbs': values.carbs / 10,
    'fat': values.fat / 10,
  };
  return {
    'revision': entry.revision,
    'food_id': entry.foodId,
    'meal': entry.meal.name,
    'meal_name': entry.mealName,
    'diary_day': entry.diaryDay,
    'grams': entry.grams / 10,
    'logged_at': entry.loggedAt.toUtc().toIso8601String(),
    'per_100g': nutrients(entry.per100g),
    'totals': nutrients(entry.totals),
  };
}
