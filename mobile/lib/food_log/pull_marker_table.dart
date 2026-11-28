import 'package:drift/drift.dart';

/// The marker the server sent with the last pull the phone stored, sent back
/// with the next pull (docs/decisions.md, 31). One row at most; with none,
/// the next pull asks for everything.
class PullMarkerTable extends Table {
  @override
  String get tableName => 'pull_marker';

  /// Kept exactly as the server sent it: the phone never reads it.
  TextColumn get marker => text()();
}
