import 'package:drift/drift.dart';
import 'exercise_library_table.dart';
import 'program_sessions_table.dart';

/// An exercise slot within a [ProgramSessions] row.
///
/// Stores the planned volume (sets × reps) and the rest time for this
/// exercise in this particular session type.  The rest time here is
/// saved and auto-starts the rest timer during logging.
class ProgramExercises extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// The session type this exercise belongs to.
  IntColumn get programSessionId => integer().references(
        ProgramSessions,
        #id,
        onDelete: KeyAction.cascade,
      )();

  /// Optional link to the exercise library.
  /// SET NULL when the library entry is deleted so the name cache below
  /// keeps the history readable.
  IntColumn get exerciseId => integer()
      .references(ExerciseLibrary, #id, onDelete: KeyAction.setNull)
      .nullable()();

  /// Exercise name at definition time — always populated.
  TextColumn get exerciseName => text().withLength(min: 1, max: 150)();

  /// Planned number of working sets.
  IntColumn get targetSets =>
      integer().withDefault(const Constant(3))();

  /// Planned reps per set.
  IntColumn get targetReps =>
      integer().withDefault(const Constant(10))();

  /// Rest between sets in seconds.  Default = 2 minutes (120 s).
  IntColumn get restSeconds =>
      integer().withDefault(const Constant(120))();

  /// Display order within the session (0-based).
  IntColumn get orderIndex =>
      integer().withDefault(const Constant(0))();
}
