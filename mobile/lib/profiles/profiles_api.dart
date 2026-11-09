import '../auth/auth_session.dart';
import 'profile.dart';

class ProfilesApi {
  const ProfilesApi(this._session);

  final AuthSession _session;

  /// The saved profile, or null before onboarding.
  Future<Profile?> getProfile() =>
      _session.get<Profile>('/me/profile', Profile.fromJson, absentOn404: true);

  Future<void> putProfile(Profile profile) async {
    await _session.put('/me/profile', profile.toJson());
  }
}
