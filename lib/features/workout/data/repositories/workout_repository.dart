import 'package:drift/drift.dart' show Value;
import 'package:intl/intl.dart';
import '../../../../core/database/app_database.dart';
import '../dao/workout_dao.dart';
import '../models/exercise_model.dart';
import '../models/workout_session_model.dart';
import '../models/workout_set_model.dart';

final DateFormat _dateFmt = DateFormat('yyyy-MM-dd');
String _today() => _dateFmt.format(DateTime.now());

class WorkoutRepository {
  WorkoutRepository(this._dao);

  final WorkoutDao _dao;

  // ── Sessions ──────────────────────────────────────────────────────────────

  /// Stream of all sessions with their sets, newest first.
  Stream<List<WorkoutSessionModel>> watchAllSessions() {
    return _dao.watchAllSessions().asyncMap((rows) async {
      final List<WorkoutSessionModel> result = [];
      for (final row in rows) {
        final sets = await _dao.getSetsForSession(row.id);
        result.add(_sessionFromRow(row, sets));
      }
      return result;
    });
  }

  /// Creates a new workout session and returns its id.
  Future<int> createSession({String? name, int? programSessionId}) =>
      _dao.insertSession(WorkoutSessionsCompanion(
        name: Value(name),
        date: Value(_today()),
        createdAt: Value(DateTime.now()),
        programSessionId: Value(programSessionId),
      ));

  /// Finalises a session by setting its name and/or notes.
  Future<void> finishSession(
    int sessionId, {
    String? name,
    String? notes,
  }) =>
      _dao.updateSession(WorkoutSessionsCompanion(
        id: Value(sessionId),
        name: Value(name),
        notes: Value(notes),
      ));

  /// Deletes a session and all its sets (CASCADE).
  Future<void> deleteSession(int sessionId) =>
      _dao.deleteSession(sessionId);

  /// One-shot fetch of all sessions with sets (for stats).
  Future<List<WorkoutSessionModel>> getAllSessions() async {
    final rows = await _dao.getAllSessions();
    final List<WorkoutSessionModel> result = [];
    for (final row in rows) {
      final sets = await _dao.getSetsForSession(row.id);
      result.add(_sessionFromRow(row, sets));
    }
    return result;
  }

  // ── Sets ──────────────────────────────────────────────────────────────────

  /// Adds a set, auto-detects PR, and returns the saved model.
  Future<WorkoutSetModel> addSet({
    required int sessionId,
    required String exerciseName,
    int? exerciseId,
    required int setNumber,
    int? reps,
    double? weightKg,
    bool isWarmup = false,
  }) async {
    final bool pr =
        !isWarmup && await _isPr(exerciseName, weightKg, sessionId);

    final int id = await _dao.insertSet(WorkoutSetsCompanion(
      sessionId: Value(sessionId),
      exerciseId: Value(exerciseId),
      exerciseName: Value(exerciseName),
      setNumber: Value(setNumber),
      reps: Value(reps),
      weightKg: Value(weightKg),
      isWarmup: Value(isWarmup),
      isPr: Value(pr),
    ));

    return WorkoutSetModel(
      id: id,
      sessionId: sessionId,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      setNumber: setNumber,
      reps: reps,
      weightKg: weightKg,
      isWarmup: isWarmup,
      isPr: pr,
    );
  }

  /// Updates an existing set in the database.
  Future<void> updateSet(WorkoutSetModel set) => _dao.updateSet(
        WorkoutSetsCompanion(
          id: Value(set.id),
          reps: Value(set.reps),
          weightKg: Value(set.weightKg),
          restSeconds: Value(set.restSeconds),
          rpe: Value(set.rpe),
          isWarmup: Value(set.isWarmup),
          isPr: Value(set.isPr),
        ),
      );

  /// Deletes a single set.
  Future<void> deleteSet(int setId) => _dao.deleteSet(setId);

  /// Returns the sets from the most recent previous session for [exerciseName].
  /// Used to populate "last session" hint text in the active workout.
  Future<List<WorkoutSetModel>> getLastSessionHints(
      String exerciseName, int currentSessionId) async {
    final rows =
        await _dao.getLastSessionSets(exerciseName, currentSessionId);
    return rows.map(_setFromRow).toList();
  }

  // ── Exercises ─────────────────────────────────────────────────────────────

  /// All exercises, built-in first then custom.
  Future<List<ExerciseModel>> getAllExercises() async {
    final rows = await _dao.getAllExercises();
    return rows.map(_exerciseFromRow).toList();
  }

  /// Exercises whose name contains [query].
  Future<List<ExerciseModel>> searchExercises(String query) async {
    final rows = await _dao.searchExercises(query);
    return rows.map(_exerciseFromRow).toList();
  }

  /// Exercises filtered by primary muscle. Pass null to get all.
  Future<List<ExerciseModel>> getExercisesByMuscle(String? muscle) async {
    final rows = await _dao.getExercisesByMuscle(muscle);
    return rows.map(_exerciseFromRow).toList();
  }

  /// Creates a user-defined exercise and returns the new model.
  Future<ExerciseModel> addCustomExercise({
    required String name,
    required String primaryMuscle,
    required String equipment,
  }) async {
    final int id = await _dao.insertExercise(ExerciseLibraryCompanion(
      name: Value(name.trim()),
      primaryMuscle: Value(primaryMuscle),
      equipment: Value(equipment),
      isCustom: const Value(true),
    ));
    return ExerciseModel(
      id: id,
      name: name.trim(),
      primaryMuscle: primaryMuscle,
      equipment: equipment,
      isCustom: true,
    );
  }

  // ── PR detection (pure logic) ─────────────────────────────────────────────

  /// Returns true if [weightKg] is >= the best weight ever recorded for
  /// [exerciseName] outside [currentSessionId].
  ///
  /// A null [weightKg] (bodyweight exercise) is never a PR.
  /// The very first set for a new exercise IS a PR.
  Future<bool> _isPr(
      String exerciseName, double? weightKg, int currentSessionId) async {
    if (weightKg == null) return false;
    final double? best =
        await _dao.getBestWeightForExercise(exerciseName, currentSessionId);
    // No previous record → this is the first time → PR
    if (best == null) return true;
    return weightKg >= best;
  }

  // ── Private converters ────────────────────────────────────────────────────

  WorkoutSessionModel _sessionFromRow(
          WorkoutSession row, List<WorkoutSet> sets) =>
      WorkoutSessionModel(
        id: row.id,
        name: row.name,
        date: row.date,
        notes: row.notes,
        createdAt: row.createdAt,
        programSessionId: row.programSessionId,
        sets: sets.map(_setFromRow).toList(),
      );

  WorkoutSetModel _setFromRow(WorkoutSet row) => WorkoutSetModel(
        id: row.id,
        sessionId: row.sessionId,
        exerciseId: row.exerciseId,
        exerciseName: row.exerciseName,
        setNumber: row.setNumber,
        reps: row.reps,
        weightKg: row.weightKg,
        durationSeconds: row.durationSeconds,
        restSeconds: row.restSeconds,
        rpe: row.rpe,
        isWarmup: row.isWarmup,
        isPr: row.isPr,
      );

  ExerciseModel _exerciseFromRow(ExerciseLibraryData row) => ExerciseModel(
        id: row.id,
        name: row.name,
        primaryMuscle: row.primaryMuscle,
        secondaryMuscles: row.secondaryMuscles,
        equipment: row.equipment,
        isCustom: row.isCustom,
      );
}
