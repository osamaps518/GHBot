import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth/auth_session.dart';
import 'core/api_failure.dart';
import 'core/database.dart';
import 'core/sync_runner.dart';
import 'profiles/profile.dart';
import 'profiles/profiles_api.dart';
import 'targets/targets.dart';
import 'targets/targets_api.dart';

enum AppStage { loading, signIn, onboarding, diary, failed }

/// Gates the app: sign-in, onboarding, the one-time age warning, then the
/// diary (decision 35). Screens read the diary from [database].
///
/// The profile and targets are read from the user's database on the phone and
/// refreshed from the server (decisions 24 and 25).
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

  /// Sends the diary from [database], for the user it belongs to, from
  /// when it opens until the app closes (decision 31).
  SyncRunner? _syncRunner;

  /// The signed-in user's database, open from the diary stage on.
  AppDatabase get database => _database!;

  /// Holds the age-warning mark. It's kept on the phone, so after a reinstall
  /// the warning shows once more.
  final _preferences = SharedPreferencesAsync();

  /// The age-warning mark has one key for each user.
  String get _ageWarningSeenKey => 'age_warning_seen_${_session.userId!}';

  AppStage stage = AppStage.loading;
  Profile? profile;
  Targets? targets;
  Exception? failure;
  bool ageWarningSeen = false;

  /// Each refresh and save takes a number when it starts. The profile and
  /// the targets each keep the number of the result they show, and only a
  /// newer result replaces them. A custom save or reset answers only targets,
  /// so an earlier profile save that answers after it still shows its
  /// profile.
  int _startedVersion = 0;
  int _profileVersion = 0;
  int _targetsVersion = 0;

  /// Set when the app closes. Work still pending then stops before it uses
  /// the database or notifies listeners.
  bool _disposed = false;

  Future<void> start() async {
    final signedIn = await _session.restoreSignIn();
    if (_disposed) return;
    if (signedIn) {
      await load();
    } else {
      stage = AppStage.signIn;
      notifyListeners();
    }
  }

  Future<void> signIn(String name) async {
    await _session.signIn(name);
    if (_disposed) return;
    await load();
  }

  /// Opens the user's database and shows what it holds, then refreshes it in
  /// the background (decision 25). A failed background refresh keeps the
  /// stored data and shows nothing. With nothing stored, it waits for the
  /// server instead. A name stored before IDs were gets its ID from the
  /// server first; without a connection, that fails and the error screen
  /// shows, with Retry.
  Future<void> load() async {
    stage = AppStage.loading;
    notifyListeners();
    try {
      if (_session.userId == null) await _session.fetchUserId();
      if (_disposed) return;
      final database = _database ??= _openDatabase(_session.userId!);
      _syncRunner ??= SyncRunner(
        session: _session,
        userId: _session.userId!,
        database: database,
      )..start();
      ageWarningSeen = await _preferences.getBool(_ageWarningSeenKey) ?? false;
      if (_disposed) return;
      final stored = await database.readProfileAndTargets();
      if (_disposed) return;
      if (stored == null) {
        await _refresh(database);
        return;
      }
      _showDiary(stored.profile, stored.targets);
      unawaited(
        _refresh(database)
            .catchError((_) {}, test: (error) => error is Exception),
      );
    } on Exception catch (error) {
      if (_disposed) return;
      failure = error;
      stage = AppStage.failed;
      notifyListeners();
    }
  }

  /// Gets the profile and targets from the server and stores them. When the
  /// server has no profile, the stored one is cleared and onboarding opens
  /// (decision 24).
  Future<void> _refresh(AppDatabase database) async {
    final version = ++_startedVersion;
    final results = await Future.wait([
      _profilesApi.getProfile(),
      _targetsApi.getTargets(),
    ]);
    final loadedProfile = results[0] as Profile?;
    final loadedTargets = results[1] as Targets?;
    if (_disposed) return;
    if (loadedProfile != null && loadedTargets == null) {
      throw const ServerFailure(404);
    }
    if (loadedProfile == null) {
      if (version < _profileVersion || version < _targetsVersion) return;
      _profileVersion = _targetsVersion = version;
      await database.clearProfileAndTargets();
      if (_disposed) return;
      profile = null;
      targets = null;
      stage = AppStage.onboarding;
      notifyListeners();
      return;
    }
    await _storeNewer(database, version, loadedProfile, loadedTargets!);
  }

  /// Stores and shows [newProfile] and [newTargets] from the work numbered
  /// [version], each only when nothing newer is shown for it. Without
  /// [newProfile], the profile shown stays.
  Future<void> _storeNewer(
    AppDatabase database,
    int version,
    Profile? newProfile,
    Targets newTargets,
  ) async {
    if (_disposed) return;
    final profileNewer = newProfile != null && version > _profileVersion;
    final targetsNewer = version > _targetsVersion;
    if (!profileNewer && !targetsNewer) return;
    if (profileNewer) _profileVersion = version;
    if (targetsNewer) _targetsVersion = version;
    final shownProfile = profileNewer ? newProfile : profile!;
    final shownTargets = targetsNewer ? newTargets : targets!;
    await database.storeProfileAndTargets(shownProfile, shownTargets);
    if (_disposed) return;
    _showDiary(shownProfile, shownTargets);
  }

  void _showDiary(Profile shownProfile, Targets shownTargets) {
    profile = shownProfile;
    targets = shownTargets;
    stage = AppStage.diary;
    notifyListeners();
  }

  /// Saves [changed] on the server, then stores and shows the profile the
  /// server saved and the targets it calculated. Offline, it throws and
  /// stores nothing.
  Future<void> save(Profile changed) async {
    final database = _database!;
    final version = ++_startedVersion;
    final savedProfile = await _profilesApi.putProfile(changed);
    final updatedTargets = await _targetsApi.getTargets();
    if (updatedTargets == null) throw const ServerFailure(404);
    await _storeNewer(database, version, savedProfile, updatedTargets);
  }

  /// Saves custom targets on the server, then stores and shows the targets
  /// it sends back (decision 37). Offline, it throws and stores nothing.
  Future<void> saveCustomTargets(TargetValues values) =>
      _storeTargets(() => _targetsApi.putCustom(values));

  /// Goes back to the recommended targets on the server, then stores and
  /// shows them. Offline, it throws and stores nothing.
  Future<void> resetCustomTargets() => _storeTargets(_targetsApi.resetCustom);

  /// Stores and shows the targets [request] answers, with the profile shown
  /// now, unless newer targets were shown meanwhile.
  Future<void> _storeTargets(Future<Targets> Function() request) async {
    final database = _database!;
    final version = ++_startedVersion;
    final updatedTargets = await request();
    await _storeNewer(database, version, null, updatedTargets);
  }

  Future<void> acceptAgeWarning() async {
    ageWarningSeen = true;
    notifyListeners();
    await _preferences.setBool(_ageWarningSeenKey, true);
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_close());
    super.dispose();
  }

  /// Stops the sync runner, then closes the database it may be writing to.
  Future<void> _close() async {
    await _syncRunner?.close();
    await _database?.close();
  }
}
