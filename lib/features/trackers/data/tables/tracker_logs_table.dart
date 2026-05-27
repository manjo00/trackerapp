import 'package:drift/drift.dart';
import 'custom_trackers_table.dart';

/// One log entry for a tracker — one per day (checklist) or per session (log).
///
/// For 'daily_checklist': at most one row per tracker per date.
/// For 'session_log': multiple rows allowed per date (one per exercise row).
class TrackerLogs extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get trackerId =>
      integer().references(CustomTrackers, #id, onDelete: KeyAction.cascade)();

  /// Date this entry was logged: "yyyy-MM-dd".
  TextColumn get loggedDate => text()();

  /// Optional free-text note attached to this entry.
  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
}
