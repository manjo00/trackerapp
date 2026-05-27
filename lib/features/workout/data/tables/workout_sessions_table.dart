import 'package:drift/drift.dart';
import 'program_sessions_table.dart';

/// One completed (or in-progress) workout session.
///
/// A session is created when the user taps "Start Workout" and finished
/// when they tap "Finish".  All sets are linked to a session via [WorkoutSets].
class WorkoutSessions extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Optional user-given name for the session, e.g. "Push Day A".
  /// NULL until the user names it (or it stays unnamed).
  TextColumn get name => text().nullable()();

  /// Date the session was performed, stored as "yyyy-MM-dd".
  TextColumn get date => text()();

  /// Free-text note for the whole session.
  TextColumn get notes => text().nullable()();

  /// When this session row was first created (= when the workout started).
  DateTimeColumn get createdAt => dateTime()();

  /// Optional link to the program session type this workout follows.
  /// NULL for freeform workouts not based on a program.
  /// SET NULL (not CASCADE) so deleting a session type doesn't erase history.
  IntColumn get programSessionId => integer()
      .references(ProgramSessions, #id, onDelete: KeyAction.setNull)
      .nullable()();
}
