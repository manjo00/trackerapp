import 'package:drift/drift.dart';
import 'exercise_library_table.dart';
import 'workout_sessions_table.dart';

/// One set within a workout session.
///
/// A set belongs to exactly one [WorkoutSessions] row and optionally
/// references an [ExerciseLibrary] entry.  [exerciseName] is always
/// populated (even for custom exercises) so the history stays readable
/// even if an exercise is later deleted.
class WorkoutSets extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// The session this set belongs to.  Deleting a session cascades here.
  IntColumn get sessionId => integer().references(WorkoutSessions, #id,
      onDelete: KeyAction.cascade)();

  /// Optional link to the exercise library.
  /// NULL for exercises the user typed freely without picking from the library.
  IntColumn get exerciseId => integer()
      .references(ExerciseLibrary, #id, onDelete: KeyAction.setNull)
      .nullable()();

  /// Exercise name at the time of logging — copied from the library so
  /// history remains accurate if the library entry is renamed or deleted.
  TextColumn get exerciseName => text().withLength(min: 1, max: 150)();

  /// Set number within this exercise in this session (1, 2, 3, …).
  IntColumn get setNumber => integer()();

  /// Reps performed. NULL for purely timed exercises (e.g. plank).
  IntColumn get reps => integer().nullable()();

  /// Weight in kilograms. NULL for bodyweight-only exercises.
  RealColumn get weightKg => real().nullable()();

  /// Duration in seconds. NULL for non-timed exercises.
  IntColumn get durationSeconds => integer().nullable()();

  /// Rest taken after completing this set, in seconds.
  /// Recorded by the rest timer; NULL if timer was skipped.
  IntColumn get restSeconds => integer().nullable()();

  /// Rate of Perceived Exertion: 1 (very easy) – 10 (maximum).
  IntColumn get rpe => integer().nullable()();

  /// True if this was a warm-up set (displayed differently in the UI).
  BoolColumn get isWarmup =>
      boolean().withDefault(const Constant(false))();

  /// True if this set was a personal record at the time it was logged.
  /// Automatically detected by the repository on save.
  BoolColumn get isPr =>
      boolean().withDefault(const Constant(false))();
}
