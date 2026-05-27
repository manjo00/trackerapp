import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/database/database_provider.dart';
import '../../data/dao/program_dao.dart';
import '../../data/dao/workout_dao.dart';
import '../../data/models/program_model.dart';
import '../../data/models/program_session_model.dart';
import '../../data/repositories/program_repository.dart';

part 'program_providers.g.dart';

// ── Repository ────────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
ProgramRepository programRepository(ProgramRepositoryRef ref) {
  final db = ref.watch(appDatabaseProvider);
  return ProgramRepository(ProgramDao(db), WorkoutDao(db));
}

// ── All programs stream ───────────────────────────────────────────────────────

@riverpod
Stream<List<ProgramModel>> allPrograms(AllProgramsRef ref) =>
    ref.watch(programRepositoryProvider).watchAllPrograms();

// ── Active program stream ─────────────────────────────────────────────────────

/// Emits the currently active program, or null if none is set.
@riverpod
Stream<ProgramModel?> activeProgram(ActiveProgramRef ref) =>
    ref.watch(programRepositoryProvider).watchActiveProgram();

// ── Today's suggested session ─────────────────────────────────────────────────

/// Returns the session the user should train today based on their active
/// program.  Returns null if there is no active program or no session
/// scheduled for today.
@riverpod
Future<ProgramSessionModel?> todaysSuggestedSession(
    TodaysSuggestedSessionRef ref) async {
  final program = await ref.watch(activeProgramProvider.future);
  if (program == null) return null;

  final repo = ref.read(programRepositoryProvider);

  if (program.isWeekly) {
    final sessions = repo.getTodaysSessions(program);
    return sessions.isEmpty ? null : sessions.first;
  } else {
    return repo.getNextRotatingSession(program);
  }
}
