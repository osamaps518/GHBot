import 'package:drift/drift.dart';

import '../auth/auth_session.dart';
import '../core/database.dart';
import '../foods/food.dart';
import 'entry.dart';
import 'meal.dart';

/// Sends diary entries to the server and stores what it answers
/// (docs/decisions.md, 31).
class FoodLogApi {
  const FoodLogApi(this._session);

  final AuthSession _session;

  /// Sends [entry] as it is now, and stores the server's answer in
  /// [database]. Throws an `ApiFailure` when the call should be tried again.
  ///
  /// The answer is the copy the server kept. When it is the revision sent,
  /// the entry is marked sent. When it is another one, or deleted, the
  /// phone takes it. Either way, only if the entry is still the revision
  /// sent: a newer change waits for the next send.
  Future<void> send(AppDatabase database, FoodLogEntry entry) async {
    final kept = await _session.put(
      '/me/food-log/entries/${entry.id}',
      _json(entry),
      _KeptEntry.fromJson,
    );
    final table = database.foodLogEntryTable;
    Expression<bool> unchanged($FoodLogEntryTableTable row) =>
        row.id.equals(entry.id) & row.revision.equals(entry.revision);
    if (kept.deleted) {
      await (database.delete(table)..where(unchanged)).go();
    } else {
      await (database.update(table)..where(unchanged)).write(
        kept.revision == entry.revision
            ? FoodLogEntryTableCompanion(sentRevision: Value(kept.revision))
            : kept.columns!,
      );
    }
  }
}

/// The copy of an entry the server kept, from its answer.
class _KeptEntry {
  _KeptEntry.fromJson(Map<String, Object?> json)
    : revision = json['revision'] as int,
      deleted = json['deleted'] as bool,
      columns = json['deleted'] as bool ? null : _columns(json);

  final int revision;
  final bool deleted;

  /// The entry's columns as the server has them, marked sent. Null for a
  /// deleted entry, whose values the server doesn't send.
  final FoodLogEntryTableCompanion? columns;

  static FoodLogEntryTableCompanion _columns(Map<String, Object?> json) {
    int tenths(Object? number) => ((number as num) * 10).round();
    final per100g = json['per_100g'] as Map<String, Object?>;
    final totals = json['totals'] as Map<String, Object?>;
    final revision = json['revision'] as int;
    return FoodLogEntryTableCompanion(
      foodId: Value(json['food_id'] as String),
      meal: Value(Meal.values.byName(json['meal'] as String)),
      mealName: Value(json['meal_name'] as String?),
      diaryDay: Value(json['diary_day'] as String),
      grams: Value(tenths(json['grams'])),
      caloriesPer100g: Value(tenths(per100g['calories'])),
      proteinPer100g: Value(tenths(per100g['protein'])),
      carbsPer100g: Value(tenths(per100g['carbs'])),
      fatPer100g: Value(tenths(per100g['fat'])),
      calories: Value(tenths(totals['calories'])),
      protein: Value(tenths(totals['protein'])),
      carbs: Value(tenths(totals['carbs'])),
      fat: Value(tenths(totals['fat'])),
      loggedAt: Value(DateTime.parse(json['logged_at'] as String).toUtc()),
      revision: Value(revision),
      sentRevision: Value(revision),
    );
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
