import 'package:drift/drift.dart' show Value;
import '../../../../core/database/app_database.dart';
import '../dao/program_dao.dart';
import '../dao/workout_dao.dart';
import '../models/program_exercise_model.dart';
import '../models/program_model.dart';
import '../models/program_session_model.dart';
import '../models/program_template_data.dart';
import '../models/workout_set_model.dart';

class ProgramRepository {
  ProgramRepository(this._programDao, this._workoutDao);

  final ProgramDao _programDao;
  final WorkoutDao _workoutDao;

  // ── Programs ──────────────────────────────────────────────────────────────

  /// Stream of all programs with their sessions and exercises loaded.
  Stream<List<ProgramModel>> watchAllPrograms() {
    return _programDao.watchAllPrograms().asyncMap(_hydrateAll);
  }

  /// Stream of the currently active program (null if none).
  Stream<ProgramModel?> watchActiveProgram() {
    return _programDao.watchActiveProgram().asyncMap((row) async {
      if (row == null) return null;
      return _hydrateProgram(row);
    });
  }

  /// Creates a new program and returns its id.
  Future<int> createProgram({
    required String name,
    String? description,
    String splitType = 'rotating',
  }) =>
      _programDao.insertProgram(ProgramsCompanion.insert(
        name: name,
        description: Value(description),
        splitType: Value(splitType),
        createdAt: DateTime.now(),
      ));

  /// Renames / updates a program.
  Future<void> updateProgram({
    required int id,
    String? name,
    String? description,
    String? splitType,
  }) =>
      _programDao.updateProgram(ProgramsCompanion(
        id: Value(id),
        name: name != null ? Value(name) : const Value.absent(),
        description:
            description != null ? Value(description) : const Value.absent(),
        splitType:
            splitType != null ? Value(splitType) : const Value.absent(),
      ));

  /// Sets [id] as the active program, deactivating all others.
  Future<void> setActiveProgram(int id) =>
      _programDao.setActiveProgram(id);

  /// Permanently deletes a program and all its sessions/exercises.
  Future<void> deleteProgram(int id) => _programDao.deleteProgram(id);

  // ── Program sessions ──────────────────────────────────────────────────────

  /// Adds a session type to a program.
  Future<int> addSession({
    required int programId,
    required String name,
    int colorValue = 0xFF6750A4,
    String? weekDays,
    int orderIndex = 0,
  }) =>
      _programDao.insertProgramSession(ProgramSessionsCompanion.insert(
        programId: programId,
        name: name,
        colorValue: Value(colorValue),
        weekDays: Value(weekDays),
        orderIndex: Value(orderIndex),
      ));

  /// Updates a session type.
  Future<void> updateSession(ProgramSessionModel session) =>
      _programDao.updateProgramSession(ProgramSessionsCompanion(
        id: Value(session.id),
        name: Value(session.name),
        colorValue: Value(session.colorValue),
        weekDays: Value(session.weekDays),
        orderIndex: Value(session.orderIndex),
      ));

  /// Deletes a session type and its exercises.
  Future<void> deleteSession(int sessionId) =>
      _programDao.deleteProgramSession(sessionId);

  // ── Program exercises ─────────────────────────────────────────────────────

  /// Adds an exercise to a session type.
  Future<ProgramExerciseModel> addExercise({
    required int programSessionId,
    int? exerciseId,
    required String exerciseName,
    int targetSets = 3,
    int targetReps = 10,
    int restSeconds = 120,
    int orderIndex = 0,
  }) async {
    final int id = await _programDao.insertProgramExercise(
      ProgramExercisesCompanion.insert(
        programSessionId: programSessionId,
        exerciseId: Value(exerciseId),
        exerciseName: exerciseName,
        targetSets: Value(targetSets),
        targetReps: Value(targetReps),
        restSeconds: Value(restSeconds),
        orderIndex: Value(orderIndex),
      ),
    );
    return ProgramExerciseModel(
      id: id,
      programSessionId: programSessionId,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      targetSets: targetSets,
      targetReps: targetReps,
      restSeconds: restSeconds,
      orderIndex: orderIndex,
    );
  }

  /// Updates an exercise slot (sets, reps, rest, order).
  Future<void> updateExercise(ProgramExerciseModel ex) =>
      _programDao.updateProgramExercise(ProgramExercisesCompanion(
        id: Value(ex.id),
        targetSets: Value(ex.targetSets),
        targetReps: Value(ex.targetReps),
        restSeconds: Value(ex.restSeconds),
        orderIndex: Value(ex.orderIndex),
      ));

  /// Deletes an exercise slot.
  Future<void> deleteExercise(int id) =>
      _programDao.deleteProgramExercise(id);

  // ── Template creation ─────────────────────────────────────────────────────

  /// Creates a program from a built-in template, sets it as active, and
  /// returns the fully-hydrated [ProgramModel].
  Future<ProgramModel> createFromTemplate(
      ProgramTemplateData template) async {
    // Create the program row.
    final int programId = await createProgram(
      name: template.name,
      description: template.description,
      splitType: template.splitType,
    );
    // Set it as the active program.
    await setActiveProgram(programId);

    // Create each session type and its exercises.
    for (final sessionTpl in template.sessions) {
      final int sessionId = await addSession(
        programId: programId,
        name: sessionTpl.name,
        colorValue: sessionTpl.colorValue,
        weekDays: sessionTpl.weekDays,
        orderIndex: sessionTpl.orderIndex,
      );
      for (int i = 0; i < sessionTpl.exercises.length; i++) {
        final ex = sessionTpl.exercises[i];
        await addExercise(
          programSessionId: sessionId,
          exerciseName: ex.exerciseName,
          targetSets: ex.targetSets,
          targetReps: ex.targetReps,
          restSeconds: ex.restSeconds,
          orderIndex: i,
        );
      }
    }

    // Load and return the full model.
    final rows = await _programDao.getAllPrograms();
    final row = rows.firstWhere((p) => p.id == programId);
    return _hydrateProgram(row);
  }

  // ── Scheduling helpers ────────────────────────────────────────────────────

  /// For rotating programs: returns the next session to train based on
  /// how many sessions have already been completed under this program.
  Future<ProgramSessionModel?> getNextRotatingSession(
      ProgramModel program) async {
    if (program.sessions.isEmpty) return null;
    final count =
        await _programDao.countCompletedSessionsForProgram(program.id);
    return program.nextRotatingSession(count);
  }

  /// For weekly programs: returns today's sessions (may be multiple or none).
  List<ProgramSessionModel> getTodaysSessions(ProgramModel program) {
    final int weekday = DateTime.now().weekday; // 1=Mon, 7=Sun
    return program.todaysSessions(weekday);
  }

  // ── Last-session hints ────────────────────────────────────────────────────

  /// Returns the sets from the most recent logged session for [exerciseName],
  /// excluding [currentSessionId].  Used for weight/rep pre-fill.
  Future<List<WorkoutSetModel>> getLastSetsForExercise(
    String exerciseName, {
    int? currentSessionId,
  }) async {
    final rows = await _workoutDao.getLastSessionSets(
      exerciseName,
      currentSessionId ?? -1,
    );
    return rows
        .map((r) => WorkoutSetModel(
              id: r.id,
              sessionId: r.sessionId,
              exerciseId: r.exerciseId,
              exerciseName: r.exerciseName,
              setNumber: r.setNumber,
              reps: r.reps,
              weightKg: r.weightKg,
              durationSeconds: r.durationSeconds,
              restSeconds: r.restSeconds,
              rpe: r.rpe,
              isWarmup: r.isWarmup,
              isPr: r.isPr,
            ))
        .toList();
  }

  // ── Private hydration ─────────────────────────────────────────────────────

  Future<List<ProgramModel>> _hydrateAll(List<Program> rows) async {
    final result = <ProgramModel>[];
    for (final row in rows) {
      result.add(await _hydrateProgram(row));
    }
    return result;
  }

  Future<ProgramModel> _hydrateProgram(Program row) async {
    final sessionRows =
        await _programDao.getSessionsForProgram(row.id);
    final sessions = <ProgramSessionModel>[];
    for (final sRow in sessionRows) {
      final exRows =
          await _programDao.getExercisesForSession(sRow.id);
      sessions.add(ProgramSessionModel(
        id: sRow.id,
        programId: sRow.programId,
        name: sRow.name,
        colorValue: sRow.colorValue,
        orderIndex: sRow.orderIndex,
        weekDays: sRow.weekDays,
        exercises: exRows
            .map((e) => ProgramExerciseModel(
                  id: e.id,
                  programSessionId: e.programSessionId,
                  exerciseId: e.exerciseId,
                  exerciseName: e.exerciseName,
                  targetSets: e.targetSets,
                  targetReps: e.targetReps,
                  restSeconds: e.restSeconds,
                  orderIndex: e.orderIndex,
                ))
            .toList(),
      ));
    }
    return ProgramModel(
      id: row.id,
      name: row.name,
      description: row.description,
      isActive: row.isActive,
      splitType: row.splitType,
      createdAt: row.createdAt,
      sessions: sessions,
    );
  }
}
