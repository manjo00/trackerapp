import 'app_database.dart';

/// Writes this window's database connection never hears about.
///
/// The widget's quick-add sheet runs in a window of its own (QuickAddActivity,
/// since 2026-11-03), and the live notification's ✓ and snooze buttons in a
/// background engine. Each opens its own connection to the same database
/// file. SQLite shows every connection the new rows at once, but drift re-runs
/// a screen's queries only after writes made through its own connection, so a
/// screen left open in another window keeps showing the old rows.
extension ChangedElsewhere on AppDatabase {
  /// Re-runs this connection's queries that read tasks or task lists: the
  /// sheet adds tasks (into a list he picks), the live notification completes
  /// them, and the app's list edits change the sheet's list chips.
  void markTasksChangedElsewhere() => markTablesUpdated([tasks, taskLists]);
}
