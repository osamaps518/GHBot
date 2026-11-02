import '../auth/auth_session.dart';
import '../core/api_client.dart';
import 'profile.dart';

class ProfilesApi {
  const ProfilesApi(this._client, this._session);

  final ApiClient _client;
  final AuthSession _session;

  /// The saved profile, or null before onboarding.
  Future<Profile?> getProfile() async {
    final response = await _session.sendAuthorized('GET', '/me/profile');
    if (response.statusCode == 404) return null;
    return Profile.fromJson(_client.decode(response));
  }

  Future<void> putProfile(Profile profile) async {
    _client.decode(
      await _session.sendAuthorized(
        'PUT',
        '/me/profile',
        body: profile.toJson(),
      ),
    );
  }
}
