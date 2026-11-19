import '../auth/auth_session.dart';
import 'profile.dart';

class ProfilesApi {
  const ProfilesApi(this._session);

  final AuthSession _session;

  /// The saved profile, or null before onboarding.
  Future<Profile?> getProfile() =>
      _session.get<Profile>('/me/profile', Profile.fromJson, absentOn404: true);

  /// Saves [profile] and returns the profile the server saved.
  Future<Profile> putProfile(Profile profile) =>
      _session.put('/me/profile', profile.toJson(), Profile.fromJson);
}
