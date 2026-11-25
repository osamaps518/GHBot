import '../auth/auth_session.dart';
import '../food_log/food_log_api.dart';
import 'api_failure.dart';
import 'database.dart';

/// Sends one user's unsent diary entries from their database to the server,
/// each with its own call (docs/decisions.md, 31).
class SyncRunner {
  /// Callers pass `database:`; a private named parameter keeps the field
  /// private.
  SyncRunner({
    required AuthSession session,
    required this.userId,
    required this._database,
  }) : _foodLogApi = FoodLogApi(session);

  /// The user whose database this is.
  final String userId;
  final AppDatabase _database;
  final FoodLogApi _foodLogApi;

  /// Sends each unsent entry in turn. A failed call stops the run, so the
  /// rest wait for the next one.
  Future<void> run() async {
    for (final entry in await _database.unsentEntries()) {
      try {
        await _foodLogApi.send(_database, entry);
      } on ApiFailure {
        return;
      }
    }
  }
}
