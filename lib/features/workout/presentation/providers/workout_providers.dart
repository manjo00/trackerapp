import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../data/dao/workout_dao.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/group_score.dart';
import '../../data/models/muscle_groups.dart';
import '../../data/models/program_exercise_model.dart';
import '../../data/models/workout_session_model.dart';
import '../../data/models/workout_set_model.dart';
import '../../data/repositories/workout_repository.dart';

part 'workout_providers.g.dart';

// ── Repository ────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
WorkoutRepository workoutRepository(WorkoutRepositoryRef ref) {
  final dao = WorkoutDao(ref.watch(appDatabaseProvider));
  return WorkoutRepository(dao);
}

// ── Read providers ────────────────────────────────────────────────────────

/// Stream of all workout sessions with their sets, newest first.
@riverpod
Stream<List<WorkoutSessionModel>> allWorkoutSessions(
    AllWorkoutSessionsRef ref) {
  return ref.watch(workoutRepositoryProvider).watchAllSessions();
}

// ── Weekly scoreboard ───────────────────────────────────────────────────────

/// Weekly muscle-group targets (push, pull, …).
@riverpod
Stream<List<MuscleTarget>> weeklyTargets(WeeklyTargetsRef ref) {
  return ref.watch(workoutRepositoryProvider).watchMuscleTargets();
}

/// Sets logged in the current week, with each set's muscle tags.
@riverpod
Stream<List<SetMuscleRow>> weekSets(WeekSetsRef ref) {
  return ref.watch(workoutRepositoryProvider).watchWeekSets();
}

/// Combines targets + this week's logged sets into a per-muscle scoreboard.
/// Each set is credited to its exercise's PRIMARY muscle only (direct work),
/// so assistance involvement never inflates a muscle. A muscle's frequency is
/// the number of distinct sessions that trained it directly.
@riverpod
List<MuscleScore> weeklyScoreboard(WeeklyScoreboardRef ref) {
  final List<MuscleTarget> targets =
      ref.watch(weeklyTargetsProvider).valueOrNull ?? const [];
  final List<SetMuscleRow> sets =
      ref.watch(weekSetsProvider).valueOrNull ?? const [];

  final Map<String, Set<int>> sessionsByMuscle = {
    for (final String m in MuscleGroup.trackedMuscles) m: <int>{},
  };
  final Map<String, int> setsByMuscle = {
    for (final String m in MuscleGroup.trackedMuscles) m: 0,
  };

  for (final SetMuscleRow row in sets) {
    final String? muscle = row.primaryMuscle;
    if (muscle == null || !sessionsByMuscle.containsKey(muscle)) continue;
    (sessionsByMuscle[muscle] ??= <int>{}).add(row.sessionId);
    setsByMuscle[muscle] = (setsByMuscle[muscle] ?? 0) + 1;
  }

  final Map<String, MuscleTarget> targetByKey = {
    for (final MuscleTarget t in targets) t.groupKey: t,
  };

  return [
    for (final String muscle in MuscleGroup.trackedMuscles)
      MuscleScore(
        muscleKey: muscle,
        sessionsDone: sessionsByMuscle[muscle]?.length ?? 0,
        setsDone: setsByMuscle[muscle] ?? 0,
        frequencyTarget: targetByKey[muscle]?.frequency ?? 0,
        setsTarget: (targetByKey[muscle]?.frequency ?? 0) *
            (targetByKey[muscle]?.setsPerSession ?? 0),
      ),
  ];
}

// ── Active workout state ──────────────────────────────────────────────────

/// Holds the current in-progress workout.
/// Null means no workout is active.
class ActiveWorkoutState {
  const ActiveWorkoutState({
    required this.sessionId,
    required this.startedAt,
    this.programSessionId,
    this.programSessionName,
    this.programExercises = const [],
    this.sets = const [],
    this.completedSetIds = const {},
  });

  final int sessionId;
  final DateTime startedAt;

  /// Non-null when this session is driven by a program session type.
  final int? programSessionId;

  /// Human-readable name of the session type, e.g. "Push" or "Legs".
  /// Used to auto-fill the "Finish Workout" name field.
  final String? programSessionName;

  /// Ordered exercises from the program session (may be empty for freeform).
  final List<ProgramExerciseModel> programExercises;

  final List<WorkoutSetModel> sets;

  /// Set ids the user has checked off this session. Runtime-only (the green
  /// ✓ state) — lives here so it survives collapsing/expanding exercise cards.
  final Set<int> completedSetIds;

  ActiveWorkoutState copyWith({
    List<WorkoutSetModel>? sets,
    List<ProgramExerciseModel>? programExercises,
    Set<int>? completedSetIds,
  }) =>
      ActiveWorkoutState(
        sessionId: sessionId,
        startedAt: startedAt,
        programSessionId: programSessionId,
        programSessionName: programSessionName,
        programExercises: programExercises ?? this.programExercises,
        sets: sets ?? this.sets,
        completedSetIds: completedSetIds ?? this.completedSetIds,
      );

  bool get isProgramDriven => programSessionId != null;

  /// Whether [setId] has been checked off.
  bool isCompleted(int setId) => completedSetIds.contains(setId);

  /// Completed-set count for [exerciseName].
  int completedCountFor(String exerciseName) => sets
      .where((s) =>
          s.exerciseName == exerciseName && completedSetIds.contains(s.id))
      .length;

  /// Sets grouped by exercise name, preserving insertion order.
  Map<String, List<WorkoutSetModel>> get setsByExercise {
    final map = <String, List<WorkoutSetModel>>{};
    for (final s in sets) {
      (map[s.exerciseName] ??= []).add(s);
    }
    return map;
  }

  /// All exercise names to display:
  /// - If program-driven: program order, then any extras the user added.
  /// - If freeform: order first logged.
  List<String> get exerciseNames {
    if (isProgramDriven) {
      final programNames =
          programExercises.map((e) => e.exerciseName).toList();
      // Add any freeform exercises the user added during the session.
      final seen = <String>{...programNames};
      for (final s in sets) {
        if (seen.add(s.exerciseName)) programNames.add(s.exerciseName);
      }
      return programNames;
    }
    // Freeform: insertion order.
    final seen = <String>{};
    final names = <String>[];
    for (final s in sets) {
      if (seen.add(s.exerciseName)) names.add(s.exerciseName);
    }
    return names;
  }

  /// Returns the [ProgramExerciseModel] for [exerciseName], or null.
  ProgramExerciseModel? programExerciseFor(String exerciseName) {
    try {
      return programExercises
          .firstWhere((e) => e.exerciseName == exerciseName);
    } catch (_) {
      return null;
    }
  }
}

/// Manages the currently active workout session.
///
/// - Kept alive so the session survives navigation (e.g. going to the
///   exercise picker and back).
/// - Writes to the DB on every change so a crash doesn't lose data.
@Riverpod(keepAlive: true)
class ActiveWorkout extends _$ActiveWorkout {
  @override
  Future<ActiveWorkoutState?> build() async => null;

  /// Starts a new workout session.
  ///
  /// [programSessionId] links the session to a program session type.
  /// [programExercises] is the ordered exercise list from that session type —
  /// passed in from the UI layer so the provider doesn't need to import
  /// the program repository directly.
  Future<void> start({
    int? programSessionId,
    List<ProgramExerciseModel> programExercises = const [],
    String? programSessionName,
  }) async {
    state = const AsyncLoading();
    final repo = ref.read(workoutRepositoryProvider);
    final int sessionId = await repo.createSession(
      programSessionId: programSessionId,
    );
    state = AsyncData(ActiveWorkoutState(
      sessionId: sessionId,
      startedAt: DateTime.now(),
      programSessionId: programSessionId,
      programSessionName: programSessionName,
      programExercises: programExercises,
    ));
  }

  /// Adds a set for [exerciseName], auto-detects PR, and updates state.
  Future<WorkoutSetModel?> addSet({
    required String exerciseName,
    int? exerciseId,
    int? reps,
    double? weightKg,
    bool isWarmup = false,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return null;

    // Determine the next set number for this exercise.
    final int setNumber = current.sets
            .where((s) => s.exerciseName == exerciseName)
            .length +
        1;

    final repo = ref.read(workoutRepositoryProvider);
    final WorkoutSetModel newSet = await repo.addSet(
      sessionId: current.sessionId,
      exerciseName: exerciseName,
      exerciseId: exerciseId,
      setNumber: setNumber,
      reps: reps,
      weightKg: weightKg,
      isWarmup: isWarmup,
    );

    // Re-read after the await so we don't clobber concurrent changes
    // (e.g. a set being checked off while this insert was in flight).
    final latest = state.valueOrNull ?? current;
    state = AsyncData(latest.copyWith(
      sets: [...latest.sets, newSet],
    ));
    return newSet;
  }

  /// Updates an existing set (reps, weight, rest, etc.) and writes to DB.
  ///
  /// Recomputes the PR flag from the new weight — sets are created empty, so
  /// PR can't be decided at insert time.
  Future<void> updateSet(WorkoutSetModel updated) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final repo = ref.read(workoutRepositoryProvider);
    final bool isPr = !updated.isWarmup &&
        await repo.isPrWeight(
            updated.exerciseName, updated.weightKg, current.sessionId);
    final WorkoutSetModel withPr = updated.copyWith(isPr: isPr);
    await repo.updateSet(withPr);
    // Re-read after the await so the PR write doesn't clobber a completion
    // that was toggled while the async PR check was running.
    final latest = state.valueOrNull ?? current;
    state = AsyncData(latest.copyWith(
      sets: latest.sets.map((s) => s.id == withPr.id ? withPr : s).toList(),
    ));
  }

  /// Deletes a set from the DB and removes it from state + completion set.
  Future<void> deleteSet(int setId) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await ref.read(workoutRepositoryProvider).deleteSet(setId);
    final latest = state.valueOrNull ?? current;
    state = AsyncData(latest.copyWith(
      sets: latest.sets.where((s) => s.id != setId).toList(),
      completedSetIds: {...latest.completedSetIds}..remove(setId),
    ));
  }

  /// Toggles the checked-off state of [setId]. Returns the new state
  /// (true = now completed) so the UI can decide whether to start rest.
  bool toggleSetComplete(int setId) {
    final current = state.valueOrNull;
    if (current == null) return false;
    final next = {...current.completedSetIds};
    final bool nowDone = !next.contains(setId);
    if (nowDone) {
      next.add(setId);
    } else {
      next.remove(setId);
    }
    state = AsyncData(current.copyWith(completedSetIds: next));
    return nowDone;
  }

  /// Ensures [exerciseName] has at least [targetSets] rows (empty, so the
  /// previous-session hint shows and untouched rows can be pruned on finish).
  /// No-op if the exercise already has any sets.
  Future<void> ensureTargetSets(String exerciseName, int targetSets) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final existing =
        current.sets.where((s) => s.exerciseName == exerciseName).length;
    if (existing > 0) return;
    final int count = targetSets < 1 ? 1 : targetSets;
    for (int i = 0; i < count; i++) {
      await addSet(exerciseName: exerciseName);
    }
  }

  /// Finalises the session (sets name/notes) and clears active state.
  /// Prunes untouched (empty) auto-created sets so history stays clean.
  Future<void> finish({String? name, String? notes}) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final repo = ref.read(workoutRepositoryProvider);
    await _pruneEmptySets(current, repo);
    await repo.finishSession(current.sessionId, name: name, notes: notes);
    state = const AsyncData(null);
    ref.invalidate(allWorkoutSessionsProvider);
  }

  /// Discards the active state. Prunes empty sets but keeps the session in
  /// history as an unnamed entry.
  Future<void> discard() async {
    final current = state.valueOrNull;
    if (current != null) {
      await _pruneEmptySets(current, ref.read(workoutRepositoryProvider));
    }
    state = const AsyncData(null);
    ref.invalidate(allWorkoutSessionsProvider);
  }

  /// Deletes auto-created sets the user never filled in (no weight and no reps).
  Future<void> _pruneEmptySets(
      ActiveWorkoutState s, WorkoutRepository repo) async {
    for (final set in s.sets) {
      if (set.weightKg == null && set.reps == null) {
        await repo.deleteSet(set.id);
      }
    }
  }
}

// ── Rest timer ────────────────────────────────────────────────────────────

/// Counts down from a set number of seconds.
/// State = remaining seconds (0 = not running / finished).
///
/// Kept alive so the countdown survives tab switches. It is *universal* — one
/// timer for the whole active workout, surfaced by the top [RestTimerBar].
/// When it reaches zero it fires a haptic + local notification.
///
/// Use [ref.watch(restTimerProvider)] for remaining seconds, and
/// [ref.read(restTimerProvider.notifier)] for [start]/[cancel]/[addSeconds]/[restart].
@Riverpod(keepAlive: true)
class RestTimer extends _$RestTimer {
  Timer? _timer;

  /// The most recent duration started, so [restart] can re-run it.
  int _lastDuration = 0;

  /// Total seconds of the current/last rest period — for progress display.
  int get totalSeconds => _lastDuration;

  @override
  int build() {
    // Cancel timer when the provider is disposed (app exit / test teardown).
    ref.onDispose(() => _timer?.cancel());
    return 0;
  }

  /// Starts a countdown from [seconds]. Remembered for [restart].
  void start([int seconds = 90]) {
    _timer?.cancel();
    if (seconds <= 0) {
      state = 0;
      return;
    }
    _lastDuration = seconds;
    state = seconds;
    _run();
  }

  /// Adjusts the remaining time by [delta] seconds (e.g. +15 / −15).
  /// Dropping to zero or below cancels the timer; raising from idle restarts it.
  void addSeconds(int delta) {
    final int next = state + delta;
    if (next <= 0) {
      cancel();
      return;
    }
    state = next;
    if (next > _lastDuration) _lastDuration = next;
    if (_timer == null || !_timer!.isActive) _run();
  }

  /// Re-runs the last duration (for "skipped by mistake" / "need more rest").
  void restart() {
    if (_lastDuration > 0) start(_lastDuration);
  }

  /// Entry point for the AppBar timer button when the bar is hidden:
  /// restart the last rest, or a 2:00 default if none has run yet.
  void reinitiate() => start(_lastDuration > 0 ? _lastDuration : 120);

  /// Cancels the countdown and resets to 0.
  void cancel() {
    _timer?.cancel();
    state = 0;
  }

  void _run() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final int next = state - 1;
      if (next <= 0) {
        state = 0;
        _timer?.cancel();
        _onFinished();
      } else {
        state = next;
      }
    });
  }

  void _onFinished() {
    HapticFeedback.heavyImpact();
    // Fire-and-forget; a failed notification must not crash the timer.
    NotificationService.instance.showRestComplete();
  }
}

// ── Exercise search ───────────────────────────────────────────────────────

/// Holds the current search query + muscle filter for the exercise picker.
@riverpod
class ExerciseFilter extends _$ExerciseFilter {
  @override
  ({String query, String? muscle}) build() => (query: '', muscle: null);

  void setQuery(String q) => state = (query: q, muscle: state.muscle);
  void setMuscle(String? m) => state = (query: state.query, muscle: m);
  void reset() => state = (query: '', muscle: null);
}

/// Filtered exercise list based on [exerciseFilterProvider] state.
@riverpod
Future<List<ExerciseModel>> filteredExercises(
    FilteredExercisesRef ref) async {
  final filter = ref.watch(exerciseFilterProvider);
  final repo = ref.read(workoutRepositoryProvider);

  if (filter.query.isNotEmpty) {
    return repo.searchExercises(filter.query);
  }
  return repo.getExercisesByMuscle(filter.muscle);
}

// ── Last-session hints ────────────────────────────────────────────────────

/// Previous-session sets for [exerciseName], used as hint text in set rows.
@riverpod
Future<List<WorkoutSetModel>> lastSessionHints(
    LastSessionHintsRef ref, String exerciseName) async {
  final active = ref.watch(activeWorkoutProvider).valueOrNull;
  if (active == null) return [];
  return ref.read(workoutRepositoryProvider).getLastSessionHints(
        exerciseName,
        active.sessionId,
      );
}

// ── Week stats ────────────────────────────────────────────────────────────

/// Number of sessions started in the current ISO week.
@riverpod
Future<int> sessionsThisWeek(SessionsThisWeekRef ref) async {
  final sessions = await ref
      .watch(workoutRepositoryProvider)
      .getAllSessions();

  final DateTime now = DateTime.now();
  // ISO week starts on Monday.
  final DateTime weekStart =
      now.subtract(Duration(days: now.weekday - 1));
  final DateTime weekStartDate =
      DateTime(weekStart.year, weekStart.month, weekStart.day);

  return sessions
      .where((s) => DateTime.parse(s.date).isAfter(
            weekStartDate.subtract(const Duration(seconds: 1)),
          ))
      .length;
}

// ── Format helpers (used across workout screens) ──────────────────────────

/// Formats a [TimeOfDay]-style duration into "mm:ss" string.
String formatElapsed(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$m:$s';
}

/// Formats [weightKg] as a short display string, e.g. "80 kg" or "80.5 kg".
String formatWeight(double? kg) {
  if (kg == null) return '–';
  return kg == kg.truncateToDouble()
      ? '${kg.toInt()} kg'
      : '$kg kg';
}
