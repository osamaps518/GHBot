import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth/auth_session.dart';
import 'core/api_failure.dart';
import 'core/database.dart';
import 'profiles/profile.dart';
import 'profiles/profiles_api.dart';
import 'targets/targets.dart';
import 'targets/targets_api.dart';

enum AppStage { loading, signIn, onboarding, targets, failed }

/// Coordinates sign-in, profile, targets, and the one-time age warning.
///
/// The profile and targets are read from the user's database on the phone and
/// refreshed from the server (docs/decisions.md, 24 and 25).
class AppFlow extends ChangeNotifier {
  AppFlow(
    this._session,
    this._profilesApi,
    this._targetsApi,
    this._openDatabase,
  );

  final AuthSession _session;
  final ProfilesApi _profilesApi;
  final TargetsApi _targetsApi;
  final AppDatabase Function(String userId) _openDatabase;
  AppDatabase? _database;
  // Kept on the phone, so after a reinstall the warning shows once more.
  final _preferences = SharedPreferencesAsync();
  static const _ageWarningSeenKey = 'age_warning_seen';

  AppStage stage = AppStage.loading;
  Profile? profile;
  Targets? targets;
  Exception? failure;
  bool ageWarningSeen = false;
  // Each refresh and save takes a number when it starts. Only results newer
  // than the ones shown are stored and shown.
  int _startedVersion = 0;
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

  /// Opens the user's database and shows what it holds, then refreshes it in
  /// the background. With nothing stored, it waits for the server instead.
  Future<void> load() async {
    stage = AppStage.loading;
    notifyListeners();
    try {
      if (_session.userId == null) await _session.fetchUserId();
      final database = _database ??= _openDatabase(_session.userId!);
      final stored = await database.readProfileAndTargets();
      if (stored == null) {
        await _refresh(database);
        return;
      }
      _showTargets(stored.profile, stored.targets);
      // A failed refresh keeps the stored data and shows nothing.
      unawaited(
        _refresh(database)
            .catchError((_) {}, test: (error) => error is Exception),
      );
    } on Exception catch (error) {
      failure = error;
      stage = AppStage.failed;
      notifyListeners();
    }
  }

  /// Gets the profile and targets from the server and stores them.
  Future<void> _refresh(AppDatabase database) async {
    final version = ++_startedVersion;
    final results = await Future.wait([
      _profilesApi.getProfile(),
      _targetsApi.getTargets(),
    ]);
    final loadedProfile = results[0] as Profile?;
    final loadedTargets = results[1] as Targets?;
    if (loadedProfile != null && loadedTargets == null) {
      throw const ServerFailure(404);
    }
    if (version < _shownVersion) return;
    _shownVersion = version;
    if (loadedProfile == null) {
      // The server is the authority for the profile.
      await database.clearProfileAndTargets();
      profile = null;
      targets = null;
      stage = AppStage.onboarding;
      notifyListeners();
      return;
    }
    await database.storeProfileAndTargets(loadedProfile, loadedTargets!);
    _showTargets(loadedProfile, loadedTargets);
  }

  void _showTargets(Profile shownProfile, Targets shownTargets) {
    profile = shownProfile;
    targets = shownTargets;
    stage = AppStage.targets;
    notifyListeners();
  }

  /// Saves on the server, then stores and shows what it returned. Offline,
  /// it throws and stores nothing.
  Future<void> save(Profile changed) async {
    final database = _database!;
    final version = ++_startedVersion;
    await _profilesApi.putProfile(changed);
    final updatedTargets = await _targetsApi.getTargets();
    if (updatedTargets == null) throw const ServerFailure(404);
    if (version < _shownVersion) return;
    _shownVersion = version;
    await database.storeProfileAndTargets(changed, updatedTargets);
    _showTargets(changed, updatedTargets);
  }

  Future<void> acceptAgeWarning() async {
    ageWarningSeen = true;
    notifyListeners();
    await _preferences.setBool(_ageWarningSeenKey, true);
  }

  @override
  void dispose() {
    _database?.close();
    super.dispose();
  }
}
