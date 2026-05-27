import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../tables/exercise_library_table.dart';
import '../tables/workout_sessions_table.dart';
import '../tables/workout_sets_table.dart';

part 'workout_dao.g.dart';

@DriftAccessor(tables: [WorkoutSessions, WorkoutSets, ExerciseLibrary])
class WorkoutDao extends DatabaseAccessor<AppDatabase>
    with _$WorkoutDaoMixin {
  WorkoutDao(super.db);

  // ── Sessions ──────────────────────────────────────────────────────────────

  /// Stream of all sessions, newest first.
  Stream<List<WorkoutSession>> watchAllSessions() =>
      (select(workoutSessions)
            ..orderBy([(s) => OrderingTerm.desc(s.createdAt)]))
          .watch();

  /// One-shot list of all sessions (for stats).
  Future<List<WorkoutSession>> getAllSessions() =>
      (select(workoutSessions)
            ..orderBy([(s) => OrderingTerm.desc(s.createdAt)]))
          .get();

  /// Inserts a new session and returns its auto-assigned id.
  Future<int> insertSession(WorkoutSessionsCompanion companion) =>
      into(workoutSessions).insert(companion);

  /// Updates an existing session (name, notes).
  Future<void> updateSession(WorkoutSessionsCompanion companion) =>
      (update(workoutSessions)
            ..where((s) => s.id.equals(companion.id.value)))
          .write(companion);

  /// Permanently deletes a session (cascades to its sets).
  Future<void> deleteSession(int sessionId) =>
      (delete(workoutSessions)..where((s) => s.id.equals(sessionId))).go();

  // ── Sets ──────────────────────────────────────────────────────────────────

  /// All sets for [sessionId], ordered by id (insertion order).
  Future<List<WorkoutSet>> getSetsForSession(int sessionId) =>
      (select(workoutSets)
            ..where((s) => s.sessionId.equals(sessionId))
            ..orderBy([(s) => OrderingTerm.asc(s.id)]))
          .get();

  /// Stream of sets for [sessionId] — used by the active workout screen.
  Stream<List<WorkoutSet>> watchSetsForSession(int sessionId) =>
      (select(workoutSets)
            ..where((s) => s.sessionId.equals(sessionId))
            ..orderBy([(s) => OrderingTerm.asc(s.id)]))
          .watch();

  /// Inserts a set and returns its auto-assigned id.
  Future<int> insertSet(WorkoutSetsCompanion companion) =>
      into(workoutSets).insert(companion);

  /// Updates a set row (reps, weight, restSeconds, isPr, etc.).
  Future<void> updateSet(WorkoutSetsCompanion companion) =>
      (update(workoutSets)
            ..where((s) => s.id.equals(companion.id.value)))
          .write(companion);

  /// Deletes a single set.
  Future<void> deleteSet(int setId) =>
      (delete(workoutSets)..where((s) => s.id.equals(setId))).go();

  /// Returns the heaviest weight ever logged for [exerciseName] in any
  /// session other than [currentSessionId].
  ///
  /// Used by the PR detection logic in the repository.
  Future<double?> getBestWeightForExercise(
      String exerciseName, int currentSessionId) async {
    final rows = await (select(workoutSets)
          ..where((s) =>
              s.exerciseName.equals(exerciseName) &
              s.sessionId.equals(currentSessionId).not() &
              s.weightKg.isNotNull())
          ..orderBy([(s) => OrderingTerm.desc(s.weightKg)]))
        .get();
    return rows.isEmpty ? null : rows.first.weightKg;
  }

  /// Returns all sets for [exerciseName] from the most recent previous
  /// session — used to show "last session" hints in the active workout.
  Future<List<WorkoutSet>> getLastSessionSets(
      String exerciseName, int currentSessionId) async {
    // Find the most recent session (excluding current) that has this exercise.
    final allSets = await (select(workoutSets)
          ..where((s) =>
              s.exerciseName.equals(exerciseName) &
              s.sessionId.equals(currentSessionId).not())
          ..orderBy([(s) => OrderingTerm.desc(s.sessionId)]))
        .get();

    if (allSets.isEmpty) return [];
    final latestSessionId = allSets.first.sessionId;
    return allSets.where((s) => s.sessionId == latestSessionId).toList();
  }

  // ── Exercise library ──────────────────────────────────────────────────────

  /// All exercises, built-in first then custom, alphabetical within each.
  Future<List<ExerciseLibraryData>> getAllExercises() =>
      (select(exerciseLibrary)
            ..orderBy([
              (e) => OrderingTerm.asc(e.isCustom),
              (e) => OrderingTerm.asc(e.name),
            ]))
          .get();

  /// Exercises whose name contains [query] (case-insensitive).
  Future<List<ExerciseLibraryData>> searchExercises(String query) =>
      (select(exerciseLibrary)
            ..where((e) => e.name.like('%$query%'))
            ..orderBy([
              (e) => OrderingTerm.asc(e.isCustom),
              (e) => OrderingTerm.asc(e.name),
            ]))
          .get();

  /// Exercises filtered by [primaryMuscle].  Pass null to get all.
  Future<List<ExerciseLibraryData>> getExercisesByMuscle(
          String? primaryMuscle) =>
      (select(exerciseLibrary)
            ..where((e) => primaryMuscle == null
                ? const Constant(true)
                : e.primaryMuscle.equals(primaryMuscle))
            ..orderBy([
              (e) => OrderingTerm.asc(e.isCustom),
              (e) => OrderingTerm.asc(e.name),
            ]))
          .get();

  /// Inserts a user-created exercise and returns its id.
  Future<int> insertExercise(ExerciseLibraryCompanion companion) =>
      into(exerciseLibrary).insert(companion);
}
