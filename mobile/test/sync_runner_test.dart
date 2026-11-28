import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart'
    show
        ApplyInterceptorConnection,
        DatabaseConnection,
        QueryExecutor,
        QueryInterceptor,
        driftRuntimeOptions;
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

  /// A body for a 422 or 409 answer.
  const refusal = {
    'detail': [
      {'type': 'value_error'},
    ],
  };

  for (final status in [422, 409]) {
    test('a $status for a revision changed since it was sent leaves the new '
        'revision unrefused, and it is sent next', () async {
      final id = await logRice();
      answerEntries(status, refusal);
      backend.holdSave = Completer();
      final sending = runner.run();
      await pumpEventQueue();

      await database.changeGrams(id, 2000);
      backend.holdSave!.complete();
      await sending;

      final entry = (await database.unsentEntries()).single;
      expect(entry.revision, 2);
      expect(entry.refused, isFalse);

      backend.intercept = null;
      await runner.run();

      expect(backend.entries[id], containsPair('revision', 2));
      expect(await database.unsentEntries(), isEmpty);
    });

    test('a $status refuses the entry: it is marked and not sent again '
        'until it changes', () async {
      final id = await logRice();
      answerEntries(status, refusal);

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

  for (final status in [409, 422]) {
    test('a delete refused with $status leaves the phone and is not sent '
        "again; another user's row stays as it was", () async {
      final id = await logRice();
      if (status == 409) {
        final bob = AuthSession(
          ApiClient(client: backend.client, baseUrl: 'http://backend.test'),
        );
        await bob.signIn('bob');
        await bob.put(
          '/me/food-log/entries/$id',
          _rice150Json(id),
          (json) => json,
        );
      } else {
        answerEntries(status, refusal);
      }
      await database.deleteEntry(id);

      await runner.run();
      await runner.run();

      expect(
        backend.entryRequests.where((request) => request.method == 'DELETE'),
        hasLength(1),
      );
      expect(await database.select(database.foodLogEntryTable).get(), isEmpty);
      if (status == 409) expect(backend.entries[id], _rice150Json(id));
    });
  }

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
      expect(backend.requestsTo('GET', '/me/food-log/changes'), isEmpty);
    },
  );

  for (final deleted in [false, true]) {
    test('a ${deleted ? 'DELETE' : 'PUT'} whose token expires while another '
        "user signs in is not sent again with that user's token", () async {
      final id = await logRice();
      if (deleted) await database.deleteEntry(id);
      backend.holdSave = Completer();
      final sending = runner.run();
      await pumpEventQueue();

      backend.expireTokens();
      await session.signIn('bob');
      backend.holdSave!.complete();
      await sending;

      expect(backend.entryRequests, hasLength(1));
      expect(
        backend.entryRequests.single.headers['authorization'],
        startsWith('Bearer token-alice-'),
      );
      expect(backend.entries, isEmpty);
      expect(await database.unsentEntries(), hasLength(1));
    });
  }

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

  group('pulling', () {
    /// The pulls the runner made.
    Iterable<http.Request> pulls() =>
        backend.requestsTo('GET', '/me/food-log/changes');

    test("a run brings down the server's entries and their foods; the next "
        'one sends back the marker it got', () async {
      backend.storeEntry('alice', _rice150Json('from-another-phone'));

      await runner.run();

      final logged = (await database.watchDiaryDay('2026-11-23').first).single;
      expect(logged.entry.id, 'from-another-phone');
      expect(logged.entry.totals.calories, 1950);
      expect(logged.entry.unsent, isFalse);
      expect(logged.food.name('en'), 'Cooked white rice');
      expect(pulls().single.url.query, isEmpty);

      // The stand-in refuses a marker it didn't give, and its markers have
      // a `+`, which a hand-built query would turn into a space.
      backend.storeEntry('alice', _rice150Json('later'));
      await runner.run();

      expect(pulls().last.url.queryParameters['since'], contains('+'));
      expect(await database.watchDiaryDay('2026-11-23').first, hasLength(2));
    });

    test('a run sends first, then pulls; after a failed send, the pull '
        'waits for the next run', () async {
      await logRice();
      answerEntries(500, {'detail': 'Internal Server Error'});

      await runner.run();
      expect(pulls(), isEmpty);

      backend.intercept = null;
      await runner.run();

      expect(backend.requests.reversed.take(2).map((r) => r.method), [
        'GET',
        'PUT',
      ]);
    });

    /// Sends a logged entry, then holds the next run's pull while [change]
    /// runs on the phone, and answers it with the server's copy as
    /// [serverCopy] makes it. Returns the entry's ID.
    Future<String> changeDuringPull(
      Map<String, Object?> Function(String id) serverCopy,
      Future<void> Function(String id) change,
    ) async {
      final id = await logRice();
      await runner.run();
      backend
        ..storeEntry('alice', serverCopy(id))
        ..holdPull = Completer();
      final pulling = runner.run();
      await pumpEventQueue();

      await change(id);
      backend.holdPull!.complete();
      await pulling;
      return id;
    }

    test("a pull doesn't overwrite a change the phone hasn't sent", () async {
      await changeDuringPull(
        (id) => {..._rice150Json(id), 'revision': 3, 'grams': 200.0},
        (id) => database.changeGrams(id, 2500),
      );

      final entry =
          (await database.watchDiaryDay('2026-11-23').first).single.entry;
      expect(entry.grams, 2500);
      expect(entry.unsent, isTrue);
    });

    test("a pull doesn't overwrite a refused entry", () async {
      final id = await logRice();
      answerEntries(422, refusal);
      await runner.run();
      backend
        ..intercept = null
        ..storeEntry('alice', {
          ..._rice150Json(id),
          'revision': 2,
          'grams': 200.0,
        });

      await runner.run();

      final entry =
          (await database.watchDiaryDay('2026-11-23').first).single.entry;
      expect(entry.grams, 1500);
      expect(entry.refused, isTrue);
    });

    test("a pull doesn't bring back an entry deleted on the phone, and the "
        'delete is sent next', () async {
      final id = await changeDuringPull(_rice150Json, database.deleteEntry);

      expect(await database.watchDiaryDay('2026-11-23').first, isEmpty);
      await runner.run();
      expect(backend.entries[id], containsPair('deleted', true));
    });

    test('an entry the server deleted leaves the phone, even with a change '
        'not sent yet', () async {
      await changeDuringPull(
        (id) => {..._rice150Json(id), 'deleted': true},
        (id) => database.changeGrams(id, 2500),
      );

      expect(await database.select(database.foodLogEntryTable).get(), isEmpty);
    });

    test('a fixed catalog food replaces the copy on the phone; entries keep '
        'the values they were logged with', () async {
      await logRice();
      await runner.run();
      backend.changeFood({...riceJson, 'calories': 140.0});

      await runner.run();

      final logged = (await database.watchDiaryDay('2026-11-23').first).single;
      expect(logged.food.per100g.calories, 1400);
      expect(logged.entry.per100g.calories, 1300);
      expect(logged.entry.totals.calories, 1950);
    });

    test('an entry pulled with a food the phone lacks shows in the diary, '
        "though the food didn't change", () async {
      await logRice();
      await runner.run();
      backend.storeEntry('alice', {
        ..._rice150Json('from-another-phone'),
        'food_id': 'oil',
        'grams': 10.0,
        'per_100g': {
          'calories': 884.0,
          'protein': 0.0,
          'carbs': 0.0,
          'fat': 100.0,
        },
        'totals': {'calories': 88.4, 'protein': 0.0, 'carbs': 0.0, 'fat': 10.0},
      });

      await runner.run();

      final diary = await database.watchDiaryDay('2026-11-23').first;
      expect(diary.map((logged) => logged.food.name('en')), [
        'Cooked white rice',
        'Olive oil',
      ]);
    });

    test('a pull whose answer is lost keeps the old marker, and the next one '
        'asks again from it', () async {
      await runner.run();
      backend
        ..storeEntry('alice', _rice150Json('later'))
        ..loseAnswers = true;

      await runner.run();
      backend.loseAnswers = false;
      await runner.run();

      final [_, lost, again] = pulls().toList();
      expect(again.url.query, isNotEmpty);
      expect(again.url.query, lost.url.query);
      expect(await database.watchDiaryDay('2026-11-23').first, hasLength(1));
    });

    test(
      "a pull answered after another user's sign-in stores nothing",
      () async {
        backend
          ..storeEntry('alice', _rice150Json('from-another-phone'))
          ..holdPull = Completer();
        final pulling = runner.run();
        await pumpEventQueue();

        await session.signIn('bob');
        backend.holdPull!.complete();
        await pulling;

        expect(await database.watchDiaryDay('2026-11-23').first, isEmpty);
        expect(await database.select(database.pullMarkerTable).get(), isEmpty);
      },
    );

    test("a pull isn't sent when another user signs in while the phone reads "
        'its marker', () async {
      await database.close();
      final markerRead = _HoldMarkerRead();
      database = AppDatabase(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ).interceptWith(markerRead),
      );
      addTearDown(database.close);
      runner = SyncRunner(
        session: session,
        userId: userIdFor('alice'),
        database: database,
      );
      final pulling = runner.run();
      await markerRead.started.future;

      await session.signIn('bob');
      markerRead.release.complete();
      await pulling;

      expect(pulls(), isEmpty);
    });

    test("a phone whose change lost to another phone's at the same revision "
        "takes the server's copy, and keeps it", () async {
      // Two phones means two databases at once, which Drift warns about.
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      addTearDown(
        () => driftRuntimeOptions.dontWarnAboutMultipleDatabases = false,
      );
      final id = await logRice();
      await runner.run();
      final otherSession = AuthSession(
        ApiClient(client: backend.client, baseUrl: 'http://backend.test'),
      );
      await otherSession.signIn('alice');
      final otherDatabase = AppDatabase(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      );
      addTearDown(otherDatabase.close);
      final otherRunner = SyncRunner(
        session: otherSession,
        userId: userIdFor('alice'),
        database: otherDatabase,
      );
      await otherRunner.run();

      await database.changeGrams(id, 2000);
      await otherDatabase.changeGrams(id, 2500);
      await runner.run();
      await otherRunner.run();

      Future<void> expectServerCopy() async {
        final entry = (await otherDatabase.watchDiaryDay('2026-11-23').first)
            .single
            .entry;
        expect(entry.grams, 2000);
        expect(entry.totals.calories, 2600);
        expect(entry.revision, 2);
        expect(entry.sentRevision, 2);
        expect(await otherDatabase.unsentEntries(), isEmpty);
      }

      await expectServerCopy();
      await otherRunner.run();
      await expectServerCopy();
    });

    testWidgets('the rows each pull brings again start no more runs', (
      tester,
    ) async {
      await database.close();
      await startAsAlice();
      runner.start();
      await logRice();
      await tester.pump(const Duration(seconds: 10));
      final settled = pulls().length;

      // Like the server inside its 30-second margin, the stand-in sends the
      // last change again with every pull. Writing it would start the 2 s
      // timer, and so another pull, again and again.
      await tester.pump(const Duration(minutes: 1));

      expect(pulls(), hasLength(settled));
      expect(backend.entries, hasLength(1));
      await runner.close();
    });
  });
}

/// Holds the first read of the pull marker: [started] completes when it
/// begins, and it goes on when [release] completes.
class _HoldMarkerRead extends QueryInterceptor {
  final started = Completer<void>();
  final release = Completer<void>();

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    if (statement.contains('pull_marker') && !started.isCompleted) {
      started.complete();
      await release.future;
    }
    return executor.runSelect(statement, args);
  }
}
