import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../tables/program_exercises_table.dart';
import '../tables/program_sessions_table.dart';
import '../tables/programs_table.dart';

part 'program_dao.g.dart';

@DriftAccessor(tables: [Programs, ProgramSessions, ProgramExercises])
class ProgramDao extends DatabaseAccessor<AppDatabase>
    with _$ProgramDaoMixin {
  ProgramDao(super.db);

  // ── Programs ──────────────────────────────────────────────────────────────

  /// Stream of all programs, newest first.
  Stream<List<Program>> watchAllPrograms() =>
      (select(programs)
            ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]))
          .watch();

  /// One-shot list of all programs.
  Future<List<Program>> getAllPrograms() =>
      (select(programs)
            ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]))
          .get();

  /// Inserts a program and returns its id.
  Future<int> insertProgram(ProgramsCompanion companion) =>
      into(programs).insert(companion);

  /// Updates a program row.
  Future<void> updateProgram(ProgramsCompanion companion) =>
      (update(programs)
            ..where((p) => p.id.equals(companion.id.value)))
          .write(companion);

  /// Permanently deletes a program (cascades to sessions + exercises).
  Future<void> deleteProgram(int id) =>
      (delete(programs)..where((p) => p.id.equals(id))).go();

  /// Deactivates all programs, then activates the one with [id].
  Future<void> setActiveProgram(int id) async {
    // Clear all active flags.
    await (update(programs)).write(
      const ProgramsCompanion(isActive: Value(false)),
    );
    // Set the chosen one active.
    await (update(programs)..where((p) => p.id.equals(id))).write(
      const ProgramsCompanion(isActive: Value(true)),
    );
  }

  /// Stream that emits the currently active program or null.
  Stream<Program?> watchActiveProgram() => (select(programs)
        ..where((p) => p.isActive.equals(true))
        ..limit(1))
      .watchSingleOrNull();

  // ── Program sessions ──────────────────────────────────────────────────────

  /// All session types for [programId], ordered by [orderIndex].
  Future<List<ProgramSession>> getSessionsForProgram(int programId) =>
      (select(programSessions)
            ..where((s) => s.programId.equals(programId))
            ..orderBy([(s) => OrderingTerm.asc(s.orderIndex)]))
          .get();

  /// Stream of session types for [programId].
  Stream<List<ProgramSession>> watchSessionsForProgram(int programId) =>
      (select(programSessions)
            ..where((s) => s.programId.equals(programId))
            ..orderBy([(s) => OrderingTerm.asc(s.orderIndex)]))
          .watch();

  /// Inserts a session type and returns its id.
  Future<int> insertProgramSession(ProgramSessionsCompanion companion) =>
      into(programSessions).insert(companion);

  /// Updates a session type row.
  Future<void> updateProgramSession(ProgramSessionsCompanion companion) =>
      (update(programSessions)
            ..where((s) => s.id.equals(companion.id.value)))
          .write(companion);

  /// Deletes a session type (cascades to exercises).
  Future<void> deleteProgramSession(int id) =>
      (delete(programSessions)..where((s) => s.id.equals(id))).go();

  /// Fetches a single session type by id.
  Future<ProgramSession?> getProgramSessionById(int id) =>
      (select(programSessions)..where((s) => s.id.equals(id)))
          .getSingleOrNull();

  // ── Program exercises ─────────────────────────────────────────────────────

  /// All exercises for [programSessionId], ordered by [orderIndex].
  Future<List<ProgramExercise>> getExercisesForSession(
          int programSessionId) =>
      (select(programExercises)
            ..where((e) => e.programSessionId.equals(programSessionId))
            ..orderBy([(e) => OrderingTerm.asc(e.orderIndex)]))
          .get();

  /// Stream of exercises for [programSessionId].
  Stream<List<ProgramExercise>> watchExercisesForSession(
          int programSessionId) =>
      (select(programExercises)
            ..where((e) => e.programSessionId.equals(programSessionId))
            ..orderBy([(e) => OrderingTerm.asc(e.orderIndex)]))
          .watch();

  /// Inserts a program exercise and returns its id.
  Future<int> insertProgramExercise(
          ProgramExercisesCompanion companion) =>
      into(programExercises).insert(companion);

  /// Updates a program exercise row.
  Future<void> updateProgramExercise(
          ProgramExercisesCompanion companion) =>
      (update(programExercises)
            ..where((e) => e.id.equals(companion.id.value)))
          .write(companion);

  /// Deletes a program exercise.
  Future<void> deleteProgramExercise(int id) =>
      (delete(programExercises)..where((e) => e.id.equals(id))).go();

  /// Counts how many logged workout sessions reference a session type that
  /// belongs to [programId].  Used to determine the rotation position.
  Future<int> countCompletedSessionsForProgram(int programId) async {
    final sessionIds = (await getSessionsForProgram(programId))
        .map((s) => s.id)
        .toSet();
    if (sessionIds.isEmpty) return 0;
    // Load all workout sessions (small table in practice) and filter in Dart.
    final allLogged = await (db.select(db.workoutSessions)).get();
    return allLogged
        .where((ws) =>
            ws.programSessionId != null &&
            sessionIds.contains(ws.programSessionId))
        .length;
  }
}
