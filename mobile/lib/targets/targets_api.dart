import '../auth/auth_session.dart';
import 'targets.dart';

class TargetsApi {
  const TargetsApi(this._session);

  final AuthSession _session;

  /// Today's targets, or null before onboarding.
  Future<Targets?> getTargets() =>
      _session.get<Targets>('/me/targets', Targets.fromJson, absentOn404: true);
}
