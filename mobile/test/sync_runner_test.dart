import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghbot/auth/auth_session.dart';
import 'package:ghbot/core/api_client.dart';
import 'package:ghbot/core/database.dart';
import 'package:ghbot/core/sync_runner.dart';
import 'package:ghbot/food_log/meal.dart';
import 'package:ghbot/foods/food.dart';
import 'package:http/http.dart' as http;
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

  /// Alice signed in, her empty database, and a runner for her. A
  /// `testWidgets` test calls this again in its body: calls to the fake
  /// backend made outside fake time never finish inside it.
  Future<void> startAsAlice() async {
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
  }

  setUp(startAsAlice);

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

  /// Answers every entry call with [status] and [body].
  void answerEntries(int status, [Object? body = const {'detail': 'No'}]) {
    backend.intercept = (request) =>
        request.url.path.startsWith('/me/food-log/entries/')
        ? http.Response(jsonEncode(body), status)
        : null;
  }

  for (final status in [422, 409]) {
    test('a $status refuses the entry: it is marked and not sent again '
        'until it changes', () async {
      final id = await logRice();
      answerEntries(status, {
        'detail': [
          {'type': 'value_error'},
        ],
      });

      await runner.run();
      await runner.run();

      expect(backend.entryRequests, hasLength(1));
      final entry =
          (await database.watchDiaryDay('2026-11-23').first).single.entry;
      expect(entry.refused, isTrue);
      expect(await database.unsentEntries(), isEmpty);

      backend.intercept = null;
      await database.changeGrams(id, 2000);
      await runner.run();

      expect(backend.entries[id], containsPair('grams', 200.0));
      expect(await database.unsentEntries(), isEmpty);
    });
  }

  for (final (failure, status, body) in [
    ('a server error', 500, {'detail': 'Internal Server Error'}),
    ('a sign-in failure', 401, {'detail': 'Not authenticated'}),
    ('an unexpected answer', 200, ['not', 'an', 'entry']),
  ]) {
    test('$failure is tried again', () async {
      await logRice();
      answerEntries(status, body);

      await runner.run();
      await runner.run();

      expect(backend.entryRequests, hasLength(status == 401 ? 4 : 2));
      expect(await database.unsentEntries(), hasLength(1));
    });
  }

  test('an entry deleted before it was ever sent is still deleted on the '
      'server, since its first send may have arrived', () async {
    final id = await logRice();
    await database.deleteEntry(id);

    await runner.run();

    expect(backend.entryRequests.single.method, 'DELETE');
    expect(backend.entries[id], containsPair('deleted', true));
    expect(await database.unsentEntries(), isEmpty);
  });

  test('a sent entry that is deleted is deleted on the server', () async {
    final id = await logRice();
    await runner.run();
    await database.deleteEntry(id);

    await runner.run();

    expect(backend.entries[id], containsPair('deleted', true));
    expect(await database.unsentEntries(), isEmpty);
  });

  test(
    "one user's entries are never sent with another user's sign-in",
    () async {
      final first = await logRice();
      await logRice(grams: 2000);
      backend.holdSave = Completer();
      final sending = runner.run();
      await pumpEventQueue();

      await session.signIn('bob');
      backend.holdSave!.complete();
      await sending;
      await runner.run();

      expect(backend.entryRequests, hasLength(1));
      expect(backend.entries.keys, [first]);
    },
  );

  test('one run at a time: runs asked for during a run make one more run '
      'after it', () async {
    final id = await logRice();
    backend.holdSave = Completer();
    final first = runner.run();
    await pumpEventQueue();

    await database.changeGrams(id, 2000);
    final second = runner.run();
    final third = runner.run();
    await pumpEventQueue();
    expect(backend.entryRequests, hasLength(1));

    backend.holdSave!.complete();
    await Future.wait([first, second, third]);
    expect(backend.entryRequests, hasLength(2));
    expect(backend.entries[id], containsPair('revision', 2));
  });

  testWidgets('after a failed run it tries again in 30 s, doubling up to '
      '5 min, and starts over after a run that succeeds', (tester) async {
    Future<void> expectTriesAfter(int seconds, int tries) async {
      await tester.pump(Duration(seconds: seconds));
      expect(backend.entryRequests, hasLength(tries));
    }

    await database.close();
    await startAsAlice();
    await logRice();
    backend.offline = true;
    await runner.run();
    expect(backend.entryRequests, hasLength(1));

    await expectTriesAfter(29, 1);
    await expectTriesAfter(1, 2);
    await expectTriesAfter(59, 2);
    await expectTriesAfter(1, 3);
    await expectTriesAfter(120, 4);
    await expectTriesAfter(240, 5);
    await expectTriesAfter(299, 5);
    await expectTriesAfter(1, 6);
    await expectTriesAfter(300, 7);

    backend.offline = false;
    await expectTriesAfter(300, 8);
    expect(await database.unsentEntries(), isEmpty);
    await expectTriesAfter(600, 8);

    await logRice();
    backend.offline = true;
    await runner.run();
    await expectTriesAfter(30, 10);

    await runner.close();
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
