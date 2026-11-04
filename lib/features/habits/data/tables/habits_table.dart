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

  /// When set, the habit is archived — hidden from every active view but
  /// recoverable from the Archived screen. NULL = active.
  DateTimeColumn get archivedAt => dateTime().nullable()();

  /// Sent to Recently deleted; really removed 30 days later. NULL = not
  /// deleted. Never set without [archivedAt] — see ArchiveService.
  DateTimeColumn get deletedAt => dateTime().nullable()();

  // ── The habits rebuild (schema 27). Every default is right for a habit
  // made before it: a daily tick with no spare days, in "Any time". ──────────

  /// 'tick' or 'count' (see HabitKind).
  TextColumn get kind => text().withDefault(const Constant('tick'))();

  /// A count habit's daily goal (8 glasses); 1 for a tick.
  IntColumn get goal => integer().withDefault(const Constant(1))();

  /// A count habit's unit ("glasses"); NULL when none.
  TextColumn get unit => text().nullable()();

  /// How much one tap on + adds to a count habit.
  IntColumn get step => integer().withDefault(const Constant(1))();

  /// A Material icon name from the editor's list.
  TextColumn get icon => text().withDefault(const Constant('check_circle'))();

  /// An index into the habit palette (8 colours).
  IntColumn get color => integer().withDefault(const Constant(0))();

  /// 'daily', 'weekdays', 'per_week' or 'shifts' (see HabitSchedule).
  TextColumn get schedule => text().withDefault(const Constant('daily'))();

  /// The chosen days: bit (DateTime.weekday − 1), Monday 1 … Sunday 64.
  IntColumn get weekdayMask => integer().withDefault(const Constant(127))();

  /// "N a week": how many days a week; NULL for other schedules.
  IntColumn get perWeek => integer().nullable()();

  /// "By shift": day off 1, day shift 2, night shift 4.
  IntColumn get shiftMask => integer().withDefault(const Constant(7))();

  /// Spare days a week (0–2): a missed day uses one, the streak lives on.
  IntColumn get sparesPerWeek => integer().withDefault(const Constant(0))();

  /// 'wake', 'any', 'day' or 'sleep' (see HabitSection).
  TextColumn get section => text().withDefault(const Constant('any'))();

  /// "After I …": the cue shown under the name; NULL when none.
  TextColumn get cue => text().withLength(max: 80).nullable()();

  /// Manual order inside a section.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// 'workout' when the habit ticks itself from logged workouts; else NULL.
  TextColumn get autoSource => text().nullable()();
}
