import '../auth/auth_session.dart';
import '../food_log/food_log_api.dart';
import 'api_failure.dart';
import 'database.dart';

/// Sends one user's unsent diary entries from their database to the server,
/// each with its own call (docs/decisions.md, 31).
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

  /// Sends the unsent entries, one run at a time. Asked for during a run,
  /// it makes one more run after that one, however often it was asked.
  /// The future completes when no run is left.
  Future<void> run() {
    if (_running case final running?) {
      _again = true;
      return running;
    }
    return _running = _runUntilDone();
  }

  Future<void> _runUntilDone() async {
    try {
      do {
        _again = false;
        await _runOnce();
      } while (_again);
    } finally {
      _running = null;
    }
  }

  /// Sends each unsent entry in turn. A failed call stops the run, so the
  /// rest wait for the next one. So does another user's sign-in: this
  /// user's entries are never sent with it.
  Future<void> _runOnce() async {
    for (final entry in await _database.unsentEntries()) {
      if (_session.userId != userId) return;
      try {
        await _foodLogApi.send(_database, entry);
      } on ApiFailure {
        return;
      }
    }
  }
}
