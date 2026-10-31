import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Talks to the backend. The only place that knows URLs, headers and tokens.
///
/// Dev sign-in (docs/decisions.md, 17): the name is the token subject. We
/// store the name, not the token, because tokens last 15 minutes. A token is
/// fetched on the first call after each start, and again on a 401.
class Api {
  // Callers pass `client:`; a private named parameter keeps the field private.
  Api({required this._client, required String baseUrl})
    : _baseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), '');

  final http.Client _client;
  final String _baseUrl;
  final _preferences = SharedPreferencesAsync();
  static const _subjectKey = 'dev_subject';

  String? _subject;
  Future<String>? _token;

  /// Loads the name from an earlier sign-in. False on a fresh install.
  Future<bool> restoreSignIn() async {
    _subject = await _preferences.getString(_subjectKey);
    return _subject != null;
  }

  Future<void> signIn(String name) async {
    final token = await _requestToken(name);
    await _preferences.setString(_subjectKey, name);
    _subject = name;
    _token = Future.value(token);
  }

  /// The saved profile, or null before onboarding.
  Future<Profile?> getProfile() async {
    final response = await _authorized('GET', '/me/profile');
    if (response.statusCode == 404) return null;
    return Profile.fromJson(_decode(response));
  }

  Future<void> putProfile(Profile profile) async {
    _decode(await _authorized('PUT', '/me/profile', body: profile.toJson()));
  }

  /// Today's targets, or null before onboarding.
  Future<Targets?> getTargets() async {
    final response = await _authorized('GET', '/me/targets');
    if (response.statusCode == 404) return null;
    return Targets.fromJson(_decode(response));
  }

  Future<http.Response> _authorized(
    String method,
    String path, {
    Object? body,
  }) async {
    final token = _currentToken();
    final response = await _send(method, path, body, await token);
    if (response.statusCode != 401) return response;
    // Calls made in parallel share one new token.
    if (identical(_token, token)) _token = null;
    return _send(method, path, body, await _currentToken());
  }

  Future<String> _currentToken() =>
      _token ??= _requestToken(_subject!)
          .catchError((Object error, StackTrace stack) {
            _token = null;
            Error.throwWithStackTrace(error, stack);
          });

  Future<String> _requestToken(String subject) async {
    final response = await _send('POST', '/dev/token', {'subject': subject});
    return _decode(response)['access_token'] as String;
  }

  Future<http.Response> _send(
    String method,
    String path,
    Object? body, [
    String? token,
  ]) async {
    final request = http.Request(method, Uri.parse('$_baseUrl$path'));
    if (token != null) request.headers['authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['content-type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    try {
      return await _client
          .send(request)
          .then(http.Response.fromStream)
          // Without a timeout, an unreachable address can spin for minutes.
          // It covers the body too: a stream can stall after its headers.
          .timeout(const Duration(seconds: 5));
    } on TimeoutException {
      throw const ConnectionFailure();
    } on http.ClientException {
      throw const ConnectionFailure();
    }
  }

  Map<String, Object?> _decode(http.Response response) {
    if (response.statusCode == 422) {
      throw ValidationFailure([
        for (final error in (jsonDecode(response.body) as Map)['detail'])
          (error as Map)['type'] as String,
      ]);
    }
    if (response.statusCode >= 300) throw ServerFailure(response.statusCode);
    return (jsonDecode(response.body) as Map).cast();
  }
}

/// A failed backend call.
sealed class ApiFailure implements Exception {
  const ApiFailure();
}

/// The backend couldn't be reached, or didn't answer within 5 seconds.
class ConnectionFailure extends ApiFailure {
  const ConnectionFailure();
}

/// The backend rejected the request body. [types] are the errors' codes,
/// such as `age_out_of_range`.
class ValidationFailure extends ApiFailure {
  const ValidationFailure(this.types);
  final List<String> types;
}

/// Any other unexpected status.
class ServerFailure extends ApiFailure {
  const ServerFailure(this.statusCode);
  final int statusCode;
}

enum Sex { male, female }

/// The backend's codes, in order from least to most active.
enum ActivityLevel {
  sedentary('sedentary'),
  lightlyActive('lightly_active'),
  moderatelyActive('moderately_active'),
  veryActive('very_active'),
  extremelyActive('extremely_active');

  const ActivityLevel(this.code);
  final String code;
}

enum Goal { lose, maintain, gain }

class Profile {
  const Profile({
    required this.birthYear,
    required this.birthMonth,
    required this.sex,
    required this.heightCm,
    required this.weightKg,
    required this.activityLevel,
    required this.goal,
  });

  factory Profile.fromJson(Map<String, Object?> json) => Profile(
    birthYear: json['birth_year'] as int,
    birthMonth: json['birth_month'] as int,
    sex: Sex.values.byName(json['sex'] as String),
    heightCm: (json['height_cm'] as num).toDouble(),
    weightKg: (json['weight_kg'] as num).toDouble(),
    activityLevel: ActivityLevel.values.firstWhere(
      (level) => level.code == json['activity_level'],
    ),
    goal: Goal.values.byName(json['goal'] as String),
  );

  final int birthYear;
  final int birthMonth;
  final Sex sex;
  final double heightCm;
  final double weightKg;
  final ActivityLevel activityLevel;
  final Goal goal;

  Map<String, Object?> toJson() => {
    'birth_year': birthYear,
    'birth_month': birthMonth,
    'sex': sex.name,
    'height_cm': heightCm,
    'weight_kg': weightKg,
    'activity_level': activityLevel.code,
    'goal': goal.name,
  };
}

class Targets {
  const Targets({
    required this.calories,
    required this.proteinG,
    required this.fatG,
    required this.carbsG,
    required this.maintenanceCalories,
    required this.atMinimum,
  });

  factory Targets.fromJson(Map<String, Object?> json) => Targets(
    calories: json['calories'] as int,
    proteinG: json['protein_g'] as int,
    fatG: json['fat_g'] as int,
    carbsG: json['carbs_g'] as int,
    maintenanceCalories: json['maintenance_calories'] as int,
    atMinimum: json['at_minimum'] as bool,
  );

  final int calories;
  final int proteinG;
  final int fatG;
  final int carbsG;
  final int maintenanceCalories;
  final bool atMinimum;
}
