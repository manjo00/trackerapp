import 'package:drift/drift.dart';

/// Defines the [habits] table in SQLite.
///
/// Drift reads this class at build time and generates:
///   - A [Habit] data class (one Dart object per row)
///   - A [HabitsCompanion] used when inserting / updating rows
///   - The SQL `CREATE TABLE` statement
///
/// Column rules:
///   - Every column is NOT NULL by default in Drift.
///   - Use `.nullable()` to allow NULL.
///   - `autoIncrement()` implies the primary key.
class Habits extends Table {
  /// Unique row identifier — auto-assigned by SQLite on insert.
  IntColumn get id => integer().autoIncrement()();

  /// Human-readable habit name, e.g. "Go for a run".
  TextColumn get name => text().withLength(min: 1, max: 120)();

  /// When this habit was created (stored as UTC milliseconds since epoch).
  DateTimeColumn get createdAt => dateTime()();

  /// How many days per week the user wants to hit this habit (1–7).
  IntColumn get targetPerWeek => integer().withDefault(const Constant(7))();

  /// Whether a daily reminder is scheduled for this habit.
  BoolColumn get reminderEnabled =>
      boolean().withDefault(const Constant(false))();

  /// Time-of-day for the reminder, stored as "HH:mm" (e.g. "07:00").
  /// NULL means no time has been set (reminder won't fire even if enabled).
  TextColumn get reminderTime => text().nullable()();
}
