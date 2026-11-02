import 'package:http/http.dart' as http;

import 'core/api_client.dart';
export 'core/api_failure.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Talks to the backend. The only place that knows URLs, headers and tokens.
///
/// Dev sign-in (docs/decisions.md, 17): the name is the token subject. We
/// store the name, not the token, because tokens last 15 minutes. A token is
/// fetched on the first call after each start, and again on a 401.
class Api {
  // Callers pass `client:`; a private named parameter keeps the field private.
  Api({required http.Client client, required String baseUrl})
    : _client = ApiClient(client: client, baseUrl: baseUrl);

  final ApiClient _client;
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
    return Profile.fromJson(_client.decode(response));
  }

  Future<void> putProfile(Profile profile) async {
    _client.decode(await _authorized('PUT', '/me/profile', body: profile.toJson()));
  }

  /// Today's targets, or null before onboarding.
  Future<Targets?> getTargets() async {
    final response = await _authorized('GET', '/me/targets');
    if (response.statusCode == 404) return null;
    return Targets.fromJson(_client.decode(response));
  }

  Future<http.Response> _authorized(
    String method,
    String path, {
    Object? body,
  }) async {
    final token = _currentToken();
    final response = await _client.send(method, path, body: body, token: await token);
    if (response.statusCode != 401) return response;
    // Calls made in parallel share one new token.
    if (identical(_token, token)) _token = null;
    return _client.send(method, path, body: body, token: await _currentToken());
  }

  Future<String> _currentToken() =>
      _token ??= _requestToken(_subject!)
          .catchError((Object error, StackTrace stack) {
            _token = null;
            Error.throwWithStackTrace(error, stack);
          });

  Future<String> _requestToken(String subject) async {
    final response = await _client.send('POST', '/dev/token', body: {'subject': subject});
    return _client.decode(response)['access_token'] as String;
  }

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
