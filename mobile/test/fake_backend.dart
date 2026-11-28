import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:ghbot/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghbot/core/database.dart';
import 'package:ghbot/main.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Worked example A from #8: male, 30, 80 kg, 180 cm, moderate, lose.
const exampleTargets = {
  'calories': 2210,
  'protein_g': 176,
  'fat_g': 49,
  'carbs_g': 266,
  'maintenance_calories': 2760,
  'at_minimum': false,
  'above_tested_age': false,
  'goal': 'lose',
  'goal_adjustment_percent': -20,
  'custom': false,
  'macros_adjusted': false,
  'recommended': {
    'calories': 2210,
    'protein_g': 176,
    'fat_g': 49,
    'carbs_g': 266,
  },
};

/// Cooked white rice from decision 30, as `GET /foods` sends it.
const riceJson = {
  'id': 'rice',
  'name_ar': 'أرز أبيض مطبوخ',
  'name_en': 'Cooked white rice',
  'calories': 130.0,
  'protein': 2.7,
  'carbs': 28.2,
  'fat': 0.3,
  'barcode': null,
  'own': false,
  'revision': 0,
};

/// Olive oil from decision 30, as `GET /foods` sends it.
const oilJson = {
  'id': 'oil',
  'name_ar': 'زيت زيتون',
  'name_en': 'Olive oil',
  'calories': 884.0,
  'protein': 0.0,
  'carbs': 0.0,
  'fat': 100.0,
  'barcode': null,
  'own': false,
  'revision': 0,
};

/// A stand-in for the backend: dev tokens, one user's profile, targets and
/// custom targets, food search, own foods, and diary entries and their
/// pull. Custom targets and own foods are saved as sent: tests that need a
/// refusal answer it with [intercept].
class FakeBackend {
  /// The saved profile, as the backend's JSON. Null until one is saved.
  Map<String, Object?>? profile;
  Map<String, Object?> targets = exampleTargets;

  /// Every request the app sent, in order.
  final requests = <http.Request>[];

  /// While true, every request fails as if the server can't be reached.
  bool offline = false;

  /// While true, the server handles every request, but its answer is lost
  /// on the way back.
  bool loseAnswers = false;

  /// Answers a request before the normal routes when it returns a response.
  http.Response? Function(http.Request request)? intercept;

  /// While set, every PUT (a profile, an own food or a diary entry) and
  /// DELETE waits for it before answering, so a test can act while a save
  /// is pending.
  Completer<void>? holdSave;

  /// Holds one targets response with the values captured when requested,
  /// including a 404 when there was no profile then.
  Completer<void>? holdNextTargets;

  /// The catalog for `GET /foods`. A search answers the foods whose Arabic
  /// or English name contains the query, ignoring case.
  List<Map<String, Object?>> foods = [riceJson, oilJson];

  /// The trainees' own foods, by ID, as the server answers them, with the
  /// subject each belongs to in [_ownFoodOwners]. Only their owner finds
  /// them, before the catalog, and gets them in a pull.
  final ownFoods = <String, Map<String, Object?>>{};
  final _ownFoodOwners = <String, String>{};

  /// While set, a pull waits for it before answering what it read.
  Completer<void>? holdPull;

  /// Holds the answer to a search for a query until its completer completes.
  final holdSearches = <String, Completer<void>>{};

  /// The diary entries the server stores, by ID, as it answers them, with
  /// the subject each belongs to in [_entryOwners]. An entry a test puts
  /// here belongs to whoever sends it first.
  final entries = <String, Map<String, Object?>>{};
  final _entryOwners = <String, String>{};

  /// The server's clock for pulls: each change to an entry or a food takes
  /// the next tick. Rows a test put in [entries] or [foods] directly are at
  /// tick 0. A marker names the tick it was given at, and a pull returns
  /// the rows changed at or after it, so, like the server's 30-second
  /// margin, the last change before a marker comes again with the next pull.
  var _clock = 0;
  final _entryTicks = <String, int>{};
  final _foodTicks = <String, int>{};
  final _markers = <String, int>{};

  /// The subject each valid token was issued for.
  final _validTokens = <String, String>{};
  var _tokensIssued = 0;

  late final http.Client client = MockClient((request) async {
    final response = await _handle(request);
    if (loseAnswers) throw http.ClientException('Connection reset');
    return response;
  });

  /// Stores [entry] as [subject]'s, as if they sent it from another phone.
  void storeEntry(String subject, Map<String, Object?> entry) {
    final id = entry['id']! as String;
    entries[id] = entry;
    _entryOwners[id] = subject;
    _entryTicks[id] = ++_clock;
  }

  /// Replaces the catalog food with [food]'s ID, as when the catalog is
  /// fixed.
  void changeFood(Map<String, Object?> food) {
    foods = [
      for (final old in foods)
        if (old['id'] == food['id']) food else old,
    ];
    _foodTicks[food['id']! as String] = ++_clock;
  }

  /// Makes every token issued so far invalid, as when they expire. Tokens last
  /// 15 minutes; the app may stay open longer.
  void expireTokens() => _validTokens.clear();

  Iterable<http.Request> requestsTo(String method, String path) => requests
      .where((request) => request.method == method && request.url.path == path);

  /// The PUT and DELETE calls for diary entries.
  Iterable<http.Request> get entryRequests => requests.where(
    (request) => request.url.path.startsWith('/me/food-log/entries/'),
  );

  /// The PUT calls for own foods.
  Iterable<http.Request> get ownFoodRequests =>
      requests.where((request) => request.url.path.startsWith('/me/foods/'));

  /// The catalog foods and [subject]'s own foods, own first.
  List<Map<String, Object?>> _visibleFoods(String subject) => [
    for (final MapEntry(key: id, value: food) in ownFoods.entries)
      if (_ownFoodOwners[id] == subject) food,
    ...foods,
  ];

  Future<http.Response> _handle(http.Request request) async {
    requests.add(request);
    if (request.method case 'PUT' || 'DELETE') await holdSave?.future;
    if (offline) throw http.ClientException('Connection refused');
    final intercepted = intercept?.call(request);
    if (intercepted != null) return intercepted;

    final route = '${request.method} ${request.url.path}';
    if (route == 'POST /dev/token') {
      final subject = (jsonDecode(request.body) as Map)['subject'];
      final token = 'token-$subject-${++_tokensIssued}';
      _validTokens[token] = subject as String;
      return _json({'access_token': token, 'token_type': 'bearer'});
    }

    final token = request.headers['authorization']?.replaceFirst('Bearer ', '');
    final subject = _validTokens[token];
    if (subject == null) {
      return _json({'detail': 'Not authenticated'}, 401);
    }
    final entryId = RegExp(r'^/me/food-log/entries/([^/]+)$')
        .firstMatch(request.url.path)?[1];
    if (entryId != null) return _entry(request, entryId, subject);
    final foodId = RegExp(r'^/me/foods/([^/]+)$')
        .firstMatch(request.url.path)?[1];
    if (foodId != null && request.method == 'PUT') {
      return _ownFood(request, foodId, subject);
    }
    switch (route) {
      case 'GET /me':
        return _json({
          'id': userIdFor(subject),
          'created_at': accountCreatedAt,
        });
      case 'GET /me/food-log/changes':
        return _changes(request, subject);
      case 'GET /me/profile':
        final saved = profile;
        return saved == null ? _notFound() : _json(saved);
      case 'PUT /me/profile':
        final created = profile == null;
        profile = (jsonDecode(request.body) as Map).cast<String, Object?>();
        return _json(profile, created ? 201 : 200);
      case 'GET /foods':
        final query = request.url.queryParameters['q']!.toLowerCase();
        await holdSearches[query]?.future;
        return _json([
          for (final food in _visibleFoods(subject))
            if ([
              food['name_ar'],
              food['name_en'],
            ].any((name) => '$name'.toLowerCase().contains(query)))
              food,
        ]);
      case 'GET /me/targets':
        final snapshot = profile == null
            ? null
            : Map<String, Object?>.of(targets);
        final hold = holdNextTargets;
        if (hold != null) {
          holdNextTargets = null;
          await hold.future;
        }
        return snapshot == null ? _notFound() : _json(snapshot);
      case 'PUT /me/targets/custom':
        final sent = (jsonDecode(request.body) as Map).cast<String, Object?>();
        targets = {
          ...targets,
          ...sent,
          'at_minimum': false,
          'custom': true,
          'macros_adjusted': false,
        };
        return _json(targets);
      case 'DELETE /me/targets/custom':
        targets = {
          ...targets,
          ...targets['recommended']! as Map<String, Object?>,
          'at_minimum': false,
          'custom': false,
          'macros_adjusted': false,
        };
        return _json(targets);
    }
    return _notFound();
  }

  /// Answers `PUT` and `DELETE /me/food-log/entries/{id}` as the server does
  /// (docs/decisions.md, 31): a higher revision replaces an active entry, a
  /// delete is final and recorded even for an unknown ID, and every answer
  /// is the stored entry. Another subject's ID answers 409, and a food the
  /// subject can't see answers 422.
  http.Response _entry(http.Request request, String id, String subject) {
    final stored = entries[id];
    final owner = _entryOwners.putIfAbsent(id, () => subject);
    if (owner != subject) {
      return _json({'detail': 'Entry belongs to another user'}, 409);
    }
    if (request.method == 'DELETE') {
      if (stored?['deleted'] != true) _entryTicks[id] = ++_clock;
      return _json(
        entries[id] = stored == null
            ? {
                'id': id,
                'revision': 0,
                'deleted': true,
                for (final field in [
                  'food_id',
                  'meal',
                  'meal_name',
                  'diary_day',
                  'grams',
                  'logged_at',
                  'per_100g',
                  'totals',
                ])
                  field: null,
              }
            : {...stored, 'deleted': true},
      );
    }
    final sent = (jsonDecode(request.body) as Map).cast<String, Object?>();
    if (stored != null &&
        (stored['deleted'] == true ||
            (stored['revision'] as int) >= (sent['revision'] as int))) {
      return _json(stored);
    }
    if (!_visibleFoods(subject).any((food) => food['id'] == sent['food_id'])) {
      return _json({
        'detail': [
          {'type': 'food_not_visible'},
        ],
      }, 422);
    }
    entries[id] = {'id': id, 'deleted': false, ...sent};
    _entryTicks[id] = ++_clock;
    return _json(entries[id], stored == null ? 201 : 200);
  }

  /// Answers `PUT /me/foods/{id}` as the server does (docs/decisions.md,
  /// 31): a higher revision replaces the subject's own food, and every
  /// answer is the stored food. A catalog food's or another subject's ID
  /// answers 409.
  http.Response _ownFood(http.Request request, String id, String subject) {
    final owner = _ownFoodOwners.putIfAbsent(id, () => subject);
    if (owner != subject || foods.any((food) => food['id'] == id)) {
      return _json({'detail': 'Food ID is not owned'}, 409);
    }
    final stored = ownFoods[id];
    final sent = (jsonDecode(request.body) as Map).cast<String, Object?>();
    if (stored != null &&
        (stored['revision'] as int) >= (sent['revision'] as int)) {
      return _json(stored);
    }
    ownFoods[id] = {'id': id, ...sent, 'own': true};
    _foodTicks[id] = ++_clock;
    return _json(ownFoods[id], stored == null ? 201 : 200);
  }

  /// Answers `GET /me/food-log/changes` as the server does
  /// (docs/decisions.md, 31): the subject's entries changed at or after the
  /// marker, deleted ones too, the changed foods they use, their changed
  /// own foods, used or not, the foods of the entries it answers, changed
  /// or not, and the next marker. The marker has a `+`, as the server's
  /// can. Without one, it answers everything; a marker it didn't give gets
  /// 422.
  Future<http.Response> _changes(http.Request request, String subject) async {
    final since = request.url.queryParameters['since'];
    final from = since == null ? 0 : _markers[since];
    if (from == null) {
      return _json({
        'detail': [
          {'type': 'datetime_from_date_parsing'},
        ],
      }, 422);
    }
    final marker = DateTime.utc(2026, 11, 28)
        .add(Duration(seconds: _clock))
        .toIso8601String()
        .replaceFirst('Z', '+00:00');
    _markers[marker] = _clock;
    final owned = [
      for (final id in entries.keys)
        if (_entryOwners[id] == subject) id,
    ];
    int tick(String id) => _entryTicks[id] ?? 0;
    final changed = [
      for (final id in owned)
        if (tick(id) >= from) id,
    ]..sort((a, b) => tick(a) != tick(b) ? tick(a) - tick(b) : a.compareTo(b));
    final used = {for (final id in owned) entries[id]!['food_id']};
    final pulled = {for (final id in changed) entries[id]!['food_id']};
    final body = {
      'entries': [for (final id in changed) entries[id]],
      'foods': [
        for (final food in _visibleFoods(subject))
          if (pulled.contains(food['id']) ||
              ((used.contains(food['id']) || food['own'] == true) &&
                  (_foodTicks[food['id']] ?? 0) >= from))
            food,
      ]..sort((a, b) => '${a['id']}'.compareTo('${b['id']}')),
      'next_marker': marker,
    };
    await holdPull?.future;
    return _json(body);
  }
}

/// The user ID the fake backend gives a name.
String userIdFor(String name) => 'id-$name';

/// When the fake backend says every account was created, as `GET /me`
/// sends it.
const accountCreatedAt = '2026-01-05T09:30:00.123456Z';

http.Response _json(Object? body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

http.Response _notFound() => _json({'detail': 'Not Found'}, 404);

/// The profile the first-launch test fills in, as the backend stores it.
Map<String, Object?> savedProfile({String goal = 'lose'}) => {
  'birth_year': DateTime.now().year - 30,
  'birth_month': 3,
  'sex': 'male',
  'height_cm': 180.0,
  'weight_kg': 80.0,
  'activity_level': 'moderately_active',
  'goal': goal,
};

/// The phone's app storage for one test: each user's database file in a
/// temporary folder, so a restarted app finds what the last one stored.
class PhoneStorage {
  PhoneStorage() {
    addTearDown(() => _folder.deleteSync(recursive: true));
  }

  final _folder = Directory.systemTemp.createTempSync('ghbot_test_');

  /// Streams close at once, so the diary leaves no timer behind when a test
  /// closes the app.
  AppDatabase open(String userId) => AppDatabase(
    DatabaseConnection(
      NativeDatabase(File('${_folder.path}/$userId.sqlite')),
      closeStreamsSynchronously: true,
    ),
  );
}

/// Starts the app on a phone-sized screen. [storedName] is the name saved by
/// an earlier sign-in, with its ID unless [storedId] is false (an install
/// from before IDs were stored) and when its account was created unless
/// [storedCreatedAt] is false (from before that was stored); without a name,
/// this is a fresh install. [storage] starts empty unless given.
Future<void> pumpApp(
  WidgetTester tester,
  FakeBackend backend, {
  String? storedName,
  bool storedId = true,
  bool storedCreatedAt = true,
  bool ageWarningSeen = false,
  PhoneStorage? storage,
}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.withData({
        'dev_subject': ?storedName,
        if (storedName != null && storedId) 'user_id': userIdFor(storedName),
        if (storedName != null && storedCreatedAt)
          'user_created_at': accountCreatedAt,
        if (storedName != null && ageWarningSeen)
          'age_warning_seen_${userIdFor(storedName)}': true,
      });
  await restartApp(tester, backend, storage ?? PhoneStorage());
}

/// Closes the app, if one is open, and starts a new one. What the last one
/// stored stays. Closing first lets the old app close its database before
/// the new one opens a database.
Future<void> restartApp(
  WidgetTester tester,
  FakeBackend backend,
  PhoneStorage storage,
) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
    GhbotApp(
      client: backend.client,
      apiBaseUrl: 'http://backend.test',
      openDatabase: storage.open,
    ),
  );
  await tester.pumpAndSettle();
}

/// Stores [name], its ID and when its account was created as the signed-in
/// user for the next start, or forgets the user when [name] is null. There
/// is no sign-out yet, so tests switch users this way.
Future<void> storeSignedInUser(String? name) async {
  final preferences = SharedPreferencesAsync();
  if (name == null) {
    await preferences.remove('dev_subject');
    await preferences.remove('user_id');
    await preferences.remove('user_created_at');
  } else {
    await preferences.setString('dev_subject', name);
    await preferences.setString('user_id', userIdFor(name));
    await preferences.setString('user_created_at', accountCreatedAt);
  }
}

/// Opens the targets from the diary, unless they are open already.
Future<void> openTargets(WidgetTester tester) async {
  final english = lookupAppLocalizations(const Locale('en'));
  if (find.text(english.editMyInfo).evaluate().isNotEmpty) return;
  await tester.tap(find.text(english.targetsButton));
  await tester.pumpAndSettle();
}

/// Opens Edit my info from the diary, through the targets.
Future<void> editMyInfo(WidgetTester tester) async {
  await openTargets(tester);
  final edit = find.text(lookupAppLocalizations(const Locale('en')).editMyInfo);
  await tester.ensureVisible(edit);
  await tester.tap(edit);
  await tester.pumpAndSettle();
}
