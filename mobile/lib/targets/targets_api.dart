import '../auth/auth_session.dart';
import '../core/api_client.dart';
import 'targets.dart';

class TargetsApi {
  const TargetsApi(this._client, this._session);

  final ApiClient _client;
  final AuthSession _session;

  /// Today's targets, or null before onboarding.
  Future<Targets?> getTargets() async {
    final response = await _session.sendAuthorized('GET', '/me/targets');
    if (response.statusCode == 404) return null;
    return Targets.fromJson(_client.decode(response));
  }
}
