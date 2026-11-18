import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghbot/core/database.dart';
import 'package:ghbot/main.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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
};

/// A stand-in for the backend: dev tokens, one user's profile, and targets.
class FakeBackend {
  /// The saved profile, as the backend's JSON. Null until one is saved.
  Map<String, Object?>? profile;
  Map<String, Object?> targets = exampleTargets;

  /// Every request the app sent, in order.
  final requests = <http.Request>[];

  /// While true, every request fails as if the server can't be reached.
  bool offline = false;

  /// Answers a request before the normal routes when it returns a response.
  http.Response? Function(http.Request request)? intercept;

  /// While set, `PUT /me/profile` waits for it before answering, so a test
  /// can act while a save is pending.
  Completer<void>? holdSave;

  /// Holds one targets response with the values captured when requested.
  Completer<void>? holdNextTargets;

  /// The subject each valid token was issued for.
  final _validTokens = <String, String>{};
  var _tokensIssued = 0;

  late final http.Client client = MockClient(_handle);

  /// Makes every token issued so far invalid, as when they expire.
  void expireTokens() => _validTokens.clear();

  Iterable<http.Request> requestsTo(String method, String path) => requests
      .where((request) => request.method == method && request.url.path == path);

  Future<http.Response> _handle(http.Request request) async {
    requests.add(request);
    if (request.method == 'PUT') await holdSave?.future;
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
    switch (route) {
      case 'GET /me':
        return _json({'id': userIdFor(subject)});
      case 'GET /me/profile':
        final saved = profile;
        return saved == null ? _notFound() : _json(saved);
      case 'PUT /me/profile':
        final created = profile == null;
        profile = (jsonDecode(request.body) as Map).cast<String, Object?>();
        return _json(profile, created ? 201 : 200);
      case 'GET /me/targets':
        if (profile == null) return _notFound();
        final snapshot = Map<String, Object?>.of(targets);
        final hold = holdNextTargets;
        if (hold != null) {
          holdNextTargets = null;
          await hold.future;
        }
        return _json(snapshot);
    }
    return _notFound();
  }
}

/// The user ID the fake backend gives a name.
String userIdFor(String name) => 'id-$name';

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

  AppDatabase open(String userId) =>
      AppDatabase(NativeDatabase(File('${_folder.path}/$userId.sqlite')));
}

/// Starts the app on a phone-sized screen. [storedName] is the name saved by
/// an earlier sign-in, with its ID unless [storedId] is false (an install
/// from before IDs were stored); without a name, this is a fresh install.
/// [storage] starts empty unless given.
Future<void> pumpApp(
  WidgetTester tester,
  FakeBackend backend, {
  String? storedName,
  bool storedId = true,
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
        if (ageWarningSeen) 'age_warning_seen': true,
      });
  await restartApp(tester, backend, storage ?? PhoneStorage());
}

/// Starts a new app, as after closing it. What the last one stored stays.
Future<void> restartApp(
  WidgetTester tester,
  FakeBackend backend,
  PhoneStorage storage,
) async {
  await tester.pumpWidget(
    GhbotApp(
      key: UniqueKey(),
      client: backend.client,
      apiBaseUrl: 'http://backend.test',
      openDatabase: storage.open,
    ),
  );
  await tester.pumpAndSettle();
}
