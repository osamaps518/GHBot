import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth/auth_session.dart';
import 'core/api_failure.dart';
import 'profiles/profile.dart';
import 'profiles/profiles_api.dart';
import 'targets/targets.dart';
import 'targets/targets_api.dart';

enum AppStage { loading, signIn, onboarding, targets, failed }

/// Coordinates sign-in, profile, targets, and the one-time age warning.
class AppFlow extends ChangeNotifier {
  AppFlow(this._session, this._profilesApi, this._targetsApi);

  final AuthSession _session;
  final ProfilesApi _profilesApi;
  final TargetsApi _targetsApi;
  final _preferences = SharedPreferencesAsync();
  static const _ageWarningSeenKey = 'age_warning_seen';

  AppStage stage = AppStage.loading;
  Profile? profile;
  Targets? targets;
  Exception? failure;
  bool ageWarningSeen = false;
  int _saveVersion = 0;
  int _shownVersion = 0;

  Future<void> start() async {
    ageWarningSeen = await _preferences.getBool(_ageWarningSeenKey) ?? false;
    if (await _session.restoreSignIn()) {
      await load();
    } else {
      stage = AppStage.signIn;
      notifyListeners();
    }
  }

  Future<void> signIn(String name) async {
    await _session.signIn(name);
    await load();
  }

  Future<void> load() async {
    stage = AppStage.loading;
    notifyListeners();
    try {
      final results = await Future.wait([
        _profilesApi.getProfile(),
        _targetsApi.getTargets(),
      ]);
      final loadedProfile = results[0] as Profile?;
      final loadedTargets = results[1] as Targets?;
      if (loadedProfile != null && loadedTargets == null) {
        throw const ServerFailure(404);
      }
      profile = loadedProfile;
      targets = loadedTargets;
      stage = loadedProfile == null ? AppStage.onboarding : AppStage.targets;
    } on Exception catch (error) {
      failure = error;
      stage = AppStage.failed;
    }
    notifyListeners();
  }

  Future<void> save(Profile changed) async {
    final version = ++_saveVersion;
    await _profilesApi.putProfile(changed);
    final updatedTargets = await _targetsApi.getTargets();
    if (updatedTargets == null) throw const ServerFailure(404);
    if (version < _shownVersion) return;
    _shownVersion = version;
    profile = changed;
    targets = updatedTargets;
    stage = AppStage.targets;
    notifyListeners();
  }

  Future<void> acceptAgeWarning() async {
    ageWarningSeen = true;
    notifyListeners();
    await _preferences.setBool(_ageWarningSeenKey, true);
  }
}
