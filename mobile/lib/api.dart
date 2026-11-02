import 'package:http/http.dart' as http;

import 'core/api_client.dart';
export 'core/api_failure.dart';
import 'auth/auth_session.dart';
import 'profiles/profile.dart';
import 'profiles/profiles_api.dart';
export 'profiles/profile.dart';

/// Transitional facade while profile and target calls move into modules.
class Api {
  // Callers pass `client:`; a private named parameter keeps the field private.
  Api({required http.Client client, required String baseUrl})
    : _client = ApiClient(client: client, baseUrl: baseUrl);

  final ApiClient _client;
  late final AuthSession _session = AuthSession(_client);

  Future<bool> restoreSignIn() => _session.restoreSignIn();
  Future<void> signIn(String name) => _session.signIn(name);

  late final _profiles = ProfilesApi(_client, _session);

  Future<Profile?> getProfile() => _profiles.getProfile();
  Future<void> putProfile(Profile profile) => _profiles.putProfile(profile);

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
  }) => _session.sendAuthorized(method, path, body: body);
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
