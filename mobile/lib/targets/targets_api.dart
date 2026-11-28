import '../auth/auth_session.dart';
import 'targets.dart';

class TargetsApi {
  const TargetsApi(this._session);

  final AuthSession _session;

  /// Today's targets, or null before onboarding.
  Future<Targets?> getTargets() =>
      _session.get<Targets>('/me/targets', Targets.fromJson, absentOn404: true);

  /// Saves custom targets and gives the targets now in effect.
  Future<Targets> putCustom(TargetValues values) =>
      _session.put('/me/targets/custom', {
        'calories': values.calories,
        'protein_g': values.proteinG,
        'fat_g': values.fatG,
        'carbs_g': values.carbsG,
      }, Targets.fromJson);

  /// Removes custom targets and gives the recommended ones. Resetting twice
  /// is harmless: the server changes nothing the second time.
  Future<Targets> resetCustom() =>
      _session.delete('/me/targets/custom', Targets.fromJson);
}
