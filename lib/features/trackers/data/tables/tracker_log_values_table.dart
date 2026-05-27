import 'package:drift/drift.dart';
import 'tracker_items_table.dart';
import 'tracker_logs_table.dart';

/// The value for one item within one log entry.
///
/// All values are stored as text and interpreted according to [TrackerItems.fieldType]:
///   'checkbox' → "true" | "false"
///   'number'   → numeric string, e.g. "3", "80.5"
///   'text'     → arbitrary string, e.g. "Bench Press"
class TrackerLogValues extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get logId =>
      integer().references(TrackerLogs, #id, onDelete: KeyAction.cascade)();

  IntColumn get itemId =>
      integer().references(TrackerItems, #id, onDelete: KeyAction.cascade)();

  TextColumn get valueText => text()();
}
