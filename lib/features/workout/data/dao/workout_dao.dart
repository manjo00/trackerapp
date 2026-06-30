import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../tables/exercise_library_table.dart';
import '../tables/muscle_targets_table.dart';
import '../tables/workout_sessions_table.dart';
import '../tables/workout_sets_table.dart';

part 'workout_dao.g.dart';

/// One logged set with the muscle tags of its exercise (looked up by name),
/// used to credit the set to a muscle group on the weekly scoreboard.
typedef SetMuscleRow = ({
  int sessionId,
  String? primaryMuscle,
  String? secondaryMuscles,
});

@DriftAccessor(
    tables: [WorkoutSessions, WorkoutSets, ExerciseLibrary, MuscleTargets])
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

  /// Past sets for [exerciseName] across all sessions except
  /// [currentSessionId], joined to their session date, newest first.
  /// Used by the per-set history picker ("Recent" tab).
  Future<List<({String date, double? weightKg, int? reps, int setNumber, bool isPr})>>
      getExerciseHistory(String exerciseName, int currentSessionId,
          {int limit = 50}) async {
    final query = select(workoutSets).join([
      innerJoin(workoutSessions,
          workoutSessions.id.equalsExp(workoutSets.sessionId)),
    ])
      ..where(workoutSets.exerciseName.equals(exerciseName) &
          workoutSets.sessionId.equals(currentSessionId).not())
      ..orderBy([
        OrderingTerm.desc(workoutSessions.date),
        OrderingTerm.desc(workoutSets.sessionId),
        OrderingTerm.asc(workoutSets.setNumber),
      ])
      ..limit(limit);

    final rows = await query.get();
    return rows.map((r) {
      final s = r.readTable(workoutSets);
      final sess = r.readTable(workoutSessions);
      return (
        date: sess.date,
        weightKg: s.weightKg,
        reps: s.reps,
        setNumber: s.setNumber,
        isPr: s.isPr,
      );
    }).toList();
  }

  /// Heaviest sets ever logged for [exerciseName] (excluding the current
  /// session), heaviest first. Used by the history picker ("Max" tab).
  Future<List<({String date, double? weightKg, int? reps, int setNumber, bool isPr})>>
      getTopSets(String exerciseName, int currentSessionId,
          {int limit = 10}) async {
    final query = select(workoutSets).join([
      innerJoin(workoutSessions,
          workoutSessions.id.equalsExp(workoutSets.sessionId)),
    ])
      ..where(workoutSets.exerciseName.equals(exerciseName) &
          workoutSets.sessionId.equals(currentSessionId).not() &
          workoutSets.weightKg.isNotNull())
      ..orderBy([OrderingTerm.desc(workoutSets.weightKg)])
      ..limit(limit);

    final rows = await query.get();
    return rows.map((r) {
      final s = r.readTable(workoutSets);
      final sess = r.readTable(workoutSessions);
      return (
        date: sess.date,
        weightKg: s.weightKg,
        reps: s.reps,
        setNumber: s.setNumber,
        isPr: s.isPr,
      );
    }).toList();
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

  // ── Weekly scoreboard ───────────────────────────────────────────────────────

  /// Streams every set logged in sessions dated [startDate]..[endDate]
  /// (inclusive, "yyyy-MM-dd"), each carrying its exercise's muscle tags
  /// (left-joined by name, so cached/custom names still resolve when possible).
  Stream<List<SetMuscleRow>> watchSetsInRange(String startDate, String endDate) {
    final query = select(workoutSets).join([
      innerJoin(workoutSessions,
          workoutSessions.id.equalsExp(workoutSets.sessionId)),
      leftOuterJoin(exerciseLibrary,
          exerciseLibrary.name.equalsExp(workoutSets.exerciseName)),
    ])
      ..where(workoutSessions.date.isBiggerOrEqualValue(startDate) &
          workoutSessions.date.isSmallerOrEqualValue(endDate));

    return query.watch().map((rows) {
      return rows.map((r) {
        final set = r.readTable(workoutSets);
        final ex = r.readTableOrNull(exerciseLibrary);
        return (
          sessionId: set.sessionId,
          primaryMuscle: ex?.primaryMuscle,
          secondaryMuscles: ex?.secondaryMuscles,
        );
      }).toList();
    });
  }

  /// Streams the weekly muscle-group targets, in display order.
  Stream<List<MuscleTarget>> watchMuscleTargets() =>
      (select(muscleTargets)
            ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
          .watch();

  /// One-shot read of the targets (for editing).
  Future<List<MuscleTarget>> getMuscleTargets() =>
      (select(muscleTargets)
            ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
          .get();

  /// Updates a single target row.
  Future<void> updateMuscleTarget(MuscleTargetsCompanion companion) =>
      (update(muscleTargets)..where((t) => t.id.equals(companion.id.value)))
          .write(companion);
}
