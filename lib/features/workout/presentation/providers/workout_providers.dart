import 'dart:async';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/database/database_provider.dart';
import '../../data/dao/workout_dao.dart';
import '../../data/models/exercise_model.dart';
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

// ── Active workout state ──────────────────────────────────────────────────

/// Holds the current in-progress workout.
/// Null means no workout is active.
class ActiveWorkoutState {
  const ActiveWorkoutState({
    required this.sessionId,
    required this.startedAt,
    this.sets = const [],
  });

  final int sessionId;
  final DateTime startedAt;
  final List<WorkoutSetModel> sets;

  ActiveWorkoutState copyWith({
    List<WorkoutSetModel>? sets,
  }) =>
      ActiveWorkoutState(
        sessionId: sessionId,
        startedAt: startedAt,
        sets: sets ?? this.sets,
      );

  /// Sets grouped by exercise name, preserving insertion order.
  Map<String, List<WorkoutSetModel>> get setsByExercise {
    final map = <String, List<WorkoutSetModel>>{};
    for (final s in sets) {
      (map[s.exerciseName] ??= []).add(s);
    }
    return map;
  }

  /// Unique exercise names in the order they were first logged.
  List<String> get exerciseNames {
    final seen = <String>{};
    final names = <String>[];
    for (final s in sets) {
      if (seen.add(s.exerciseName)) names.add(s.exerciseName);
    }
    return names;
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

  /// Starts a new workout session and stores it in the DB.
  Future<void> start() async {
    state = const AsyncLoading();
    final repo = ref.read(workoutRepositoryProvider);
    final int sessionId = await repo.createSession();
    state = AsyncData(ActiveWorkoutState(
      sessionId: sessionId,
      startedAt: DateTime.now(),
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

    state = AsyncData(current.copyWith(
      sets: [...current.sets, newSet],
    ));
    return newSet;
  }

  /// Updates an existing set (reps, weight, rest, etc.) and writes to DB.
  Future<void> updateSet(WorkoutSetModel updated) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await ref.read(workoutRepositoryProvider).updateSet(updated);
    state = AsyncData(current.copyWith(
      sets: current.sets.map((s) => s.id == updated.id ? updated : s).toList(),
    ));
  }

  /// Deletes a set from the DB and removes it from state.
  Future<void> deleteSet(int setId) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await ref.read(workoutRepositoryProvider).deleteSet(setId);
    state = AsyncData(current.copyWith(
      sets: current.sets.where((s) => s.id != setId).toList(),
    ));
  }

  /// Finalises the session (sets name/notes) and clears active state.
  Future<void> finish({String? name, String? notes}) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await ref
        .read(workoutRepositoryProvider)
        .finishSession(current.sessionId, name: name, notes: notes);
    state = const AsyncData(null);
    ref.invalidate(allWorkoutSessionsProvider);
  }

  /// Discards the active state without deleting DB data.
  /// (The session stays in history as an unnamed entry.)
  void discard() {
    state = const AsyncData(null);
    ref.invalidate(allWorkoutSessionsProvider);
  }
}

// ── Rest timer ────────────────────────────────────────────────────────────

/// Counts down from a set number of seconds.
/// State = remaining seconds (0 = not running / finished).
///
/// Kept alive so the countdown survives tab switches.
/// Use [ref.watch(restTimerProvider)] to read the remaining seconds, and
/// [ref.read(restTimerProvider.notifier)] to call [start] / [cancel].
@Riverpod(keepAlive: true)
class RestTimer extends _$RestTimer {
  Timer? _timer;

  @override
  int build() {
    // Cancel timer when the provider is disposed (app exit / test teardown).
    ref.onDispose(() => _timer?.cancel());
    return 0;
  }

  /// Starts a countdown from [seconds].
  void start([int seconds = 90]) {
    _timer?.cancel();
    state = seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state > 0) {
        state = state - 1;
      } else {
        _timer?.cancel();
      }
    });
  }

  /// Cancels the countdown and resets to 0.
  void cancel() {
    _timer?.cancel();
    state = 0;
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
