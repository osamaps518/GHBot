import 'dart:async';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:flutter/widgets.dart';

import '../auth/auth_session.dart';
import '../food_log/food_log_api.dart';
import 'api_failure.dart';
import 'database.dart';

/// Sends one user's unsent diary entries from their database to the server,
/// each with its own call, then brings down what changed there (decision 31).
class SyncRunner {
  /// Callers pass `session:` and `database:`; private named parameters keep
  /// the fields private.
  SyncRunner({
    required this._session,
    required this.userId,
    required this._database,
  }) : _foodLogApi = FoodLogApi(_session);

  final AuthSession _session;

  /// The user whose database this is.
  final String userId;
  final AppDatabase _database;
  final FoodLogApi _foodLogApi;

  /// The run in progress, if any.
  Future<void>? _running;

  /// Set when a run is asked for during one: one more run follows it.
  var _again = false;

  /// After a failed run, the next one starts on this timer. The wait starts
  /// at 30 s and doubles up to 5 min, and starts over after a run that
  /// succeeds.
  Timer? _retry;
  var _retryAfter = _firstRetry;
  static const _firstRetry = Duration(seconds: 30);
  static const _lastRetry = Duration(minutes: 5);

  /// Set by [close]: no call or run starts after it.
  var _closed = false;

  StreamSubscription<void>? _localChanges;
  Timer? _afterChange;
  AppLifecycleListener? _lifecycle;

  /// Runs now, then whenever the app returns to the foreground, and 2 s
  /// after the last local change to the diary, its own writes included,
  /// until [close]. There is no background job: the app runs it only while
  /// open.
  void start() {
    _localChanges = _database
        .tableUpdates(TableUpdateQuery.onTable(_database.foodLogEntryTable))
        .listen((_) {
          _afterChange?.cancel();
          _afterChange = Timer(const Duration(seconds: 2), run);
        });
    _lifecycle = AppLifecycleListener(onResume: run);
    run();
  }

  /// Sends the unsent entries, then pulls, one run at a time. Asked for
  /// during a run, it makes one more run after that one, however often it
  /// was asked. The future completes when no run is left.
  Future<void> run() {
    if (_closed) return Future.value();
    if (_running case final running?) {
      _again = true;
      return running;
    }
    return _running = _runUntilDone();
  }

  /// Stops the runner. The future completes when the call in progress, if
  /// any, has finished, so the database can close after it.
  Future<void> close() {
    _closed = true;
    _retry?.cancel();
    _afterChange?.cancel();
    _lifecycle?.dispose();
    unawaited(_localChanges?.cancel());
    return _running ?? Future.value();
  }

  Future<void> _runUntilDone() async {
    try {
      do {
        _again = false;
        await _runOnce();
      } while (_again && !_closed);
    } finally {
      _running = null;
    }
  }

  /// Sends each unsent entry in turn, then pulls. A failed call stops the
  /// run, and the retry timer starts: after a failed send, the pull waits
  /// for the next run. Another user's sign-in stops it too: this user's
  /// entries are never sent or pulled with it.
  Future<void> _runOnce() async {
    _retry?.cancel();
    try {
      for (final entry in await _database.unsentEntries()) {
        if (_closed || _session.userId != userId) return;
        await _foodLogApi.send(_database, entry);
      }
      if (_closed || _session.userId != userId) return;
      await _foodLogApi.pull(_database, userId);
    } on ApiFailure {
      if (!_closed) _retryLater();
      return;
    }
    _retryAfter = _firstRetry;
  }

  void _retryLater() {
    _retry = Timer(_retryAfter, run);
    final doubled = _retryAfter * 2;
    _retryAfter = doubled < _lastRetry ? doubled : _lastRetry;
  }
}
