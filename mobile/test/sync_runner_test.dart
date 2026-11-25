import 'dart:async';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghbot/auth/auth_session.dart';
import 'package:ghbot/core/api_client.dart';
import 'package:ghbot/core/database.dart';
import 'package:ghbot/core/sync_runner.dart';
import 'package:ghbot/food_log/meal.dart';
import 'package:ghbot/foods/food.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'fake_backend.dart';

/// Rice, 150 g, at lunch on 2026-11-23: decision 30's first worked example,
/// as the server stores it.
Map<String, Object?> _rice150Json(String id) => {
  'id': id,
  'deleted': false,
  'revision': 1,
  'food_id': 'rice',
  'meal': 'lunch',
  'meal_name': null,
  'diary_day': '2026-11-23',
  'grams': 150.0,
  'logged_at': '2026-11-23T10:00:00.000Z',
  'per_100g': {'calories': 130.0, 'protein': 2.7, 'carbs': 28.2, 'fat': 0.3},
  'totals': {'calories': 195.0, 'protein': 4.1, 'carbs': 42.3, 'fat': 0.5},
};

void main() {
  late FakeBackend backend;
  late AuthSession session;
  late AppDatabase database;
  late SyncRunner runner;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    backend = FakeBackend();
    session = AuthSession(
      ApiClient(client: backend.client, baseUrl: 'http://backend.test'),
    );
    await session.signIn('alice');
    database = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    runner = SyncRunner(
      session: session,
      userId: userIdFor('alice'),
      database: database,
    );
    addTearDown(database.close);
  });

  /// Logs rice into lunch on 2026-11-23 and returns the entry's ID.
  Future<String> logRice({int grams = 1500}) async {
    await database.logEntry(
      food: Food.fromJson(riceJson),
      meal: const DiaryMeal(Meal.lunch),
      grams: grams,
      loggedAt: DateTime.utc(2026, 11, 23, 10),
    );
    return (await database.unsentEntries()).last.id;
  }

  test('a lost answer leaves the entry unsent; the retry marks it sent and '
      'the server keeps one copy', () async {
    final id = await logRice();
    backend.loseAnswers = true;

    await runner.run();

    expect(backend.entries, {id: _rice150Json(id)});
    expect(await database.unsentEntries(), hasLength(1));

    backend.loseAnswers = false;
    await runner.run();

    expect(await database.unsentEntries(), isEmpty);
    expect(backend.entries, {id: _rice150Json(id)});
    expect(backend.entryRequests, hasLength(2));
  });

  test('offline, nothing is sent; online, the entry is', () async {
    final id = await logRice();
    backend.offline = true;

    await runner.run();

    expect(backend.entries, isEmpty);
    expect(await database.unsentEntries(), hasLength(1));

    backend.offline = false;
    await runner.run();

    expect(backend.entries, {id: _rice150Json(id)});
    expect(await database.unsentEntries(), isEmpty);
  });

  test('an edit made while the entry is being sent is sent next', () async {
    final id = await logRice();
    backend.holdSave = Completer();
    final sending = runner.run();
    await pumpEventQueue();

    await database.changeGrams(id, 2000);
    backend.holdSave!.complete();
    await sending;

    expect(await database.unsentEntries(), hasLength(1));
    await runner.run();
    expect(backend.entries[id], containsPair('grams', 200.0));
    expect(backend.entries[id], containsPair('revision', 2));
    expect(await database.unsentEntries(), isEmpty);
  });

  group('when the server kept another copy', () {
    test('the phone takes it', () async {
      final id = await logRice();
      backend.entries[id] = {
        ..._rice150Json(id),
        'revision': 3,
        'grams': 200.0,
        'totals': {
          'calories': 260.0,
          'protein': 5.4,
          'carbs': 56.4,
          'fat': 0.6,
        },
      };

      await runner.run();

      final entry =
          (await database.watchDiaryDay('2026-11-23').first).single.entry;
      expect(entry.grams, 2000);
      expect(entry.totals.calories, 2600);
      expect(entry.revision, 3);
      expect(await database.unsentEntries(), isEmpty);
    });

    test('a copy the server deleted leaves the phone too', () async {
      final id = await logRice();
      backend.entries[id] = {..._rice150Json(id), 'deleted': true};

      await runner.run();

      expect(await database.watchDiaryDay('2026-11-23').first, isEmpty);
      expect(await database.unsentEntries(), isEmpty);
    });

    test('the phone keeps its own if it changed since it was sent', () async {
      final id = await logRice();
      backend.entries[id] = {..._rice150Json(id), 'revision': 3};
      backend.holdSave = Completer();
      final sending = runner.run();
      await pumpEventQueue();

      await database.changeGrams(id, 2000);
      backend.holdSave!.complete();
      await sending;

      final entry =
          (await database.watchDiaryDay('2026-11-23').first).single.entry;
      expect(entry.grams, 2000);
      expect(entry.unsent, isTrue);
    });
  });
}
