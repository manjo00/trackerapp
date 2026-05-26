import 'package:drift/drift.dart';
import 'habits_table.dart';

/// Defines the [habit_completions] table.
///
/// Each row records that a specific habit was completed on a specific date.
/// Tapping a habit on the list screen inserts a row here; tapping again
/// deletes it (toggle behaviour).
///
/// The date is stored as a plain `TEXT` string in `yyyy-MM-dd` format
/// (e.g. "2026-05-26") rather than a full DateTime.  This makes streak
/// calculations straightforward: we just compare date strings and there
/// is no risk of timezone edge-cases turning "completed at 11 PM" into
/// "completed the next day".
class HabitCompletions extends Table {
  /// Unique row identifier.
  IntColumn get id => integer().autoIncrement()();

  /// Foreign key — which habit was completed.
  /// References [Habits.id]; Drift enforces the constraint at the DB level.
  IntColumn get habitId =>
      integer().references(Habits, #id, onDelete: KeyAction.cascade)();

  /// The calendar date of this completion, e.g. "2026-05-26".
  TextColumn get date => text()();
}
