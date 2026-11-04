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
///
/// Since schema 27 the date is the *habit day* (a tick at 02:30 counts for
/// the day before), there is at most one row per habit and day (the unique
/// index), and a row also carries an amount and a status.
@TableIndex(
    name: 'habit_completions_habit_date',
    columns: {#habitId, #date},
    unique: true)
class HabitCompletions extends Table {
  /// Unique row identifier.
  IntColumn get id => integer().autoIncrement()();

  /// Foreign key — which habit was completed.
  /// References [Habits.id]; Drift enforces the constraint at the DB level.
  IntColumn get habitId =>
      integer().references(Habits, #id, onDelete: KeyAction.cascade)();

  /// The calendar date of this completion, e.g. "2026-05-26".
  TextColumn get date => text()();

  /// The amount: 1 for a tick, the count for a count habit (5 glasses), 0 for
  /// a rest or sick day.
  IntColumn get value => integer().withDefault(const Constant(1))();

  /// 'done', 'rest' or 'sick' (see EntryStatus).
  TextColumn get status => text().withDefault(const Constant('done'))();

  /// An optional note for the day; NULL when none.
  TextColumn get note => text().nullable()();

  /// When the row was written; NULL for rows from before schema 27.
  DateTimeColumn get createdAt => dateTime().nullable()();
}
