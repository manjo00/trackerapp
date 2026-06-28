import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/database/database_provider.dart';
import '../../data/dao/habits_dao.dart';
import '../../data/models/habit_model.dart';
import '../../data/models/habit_with_status.dart';
import '../../data/repositories/habits_repository.dart';

part 'habits_providers.g.dart';

// ── Repository provider ───────────────────────────────────────────────────

/// Provides the [HabitsRepository] wired to the live database.
///
/// Kept alive because the repository is cheap to create and is needed
/// throughout the app session.
@Riverpod(keepAlive: true)
HabitsRepository habitsRepository(HabitsRepositoryRef ref) {
  final dao = HabitsDao(ref.watch(appDatabaseProvider));
  return HabitsRepository(dao);
}

// ── Read provider (stream) ────────────────────────────────────────────────

/// Emits a fresh list of [HabitWithStatus] whenever any habit or completion
/// changes in the database.
///
/// In [HabitListScreen] we use:
/// ```dart
/// final habitsAsync = ref.watch(habitsWithStatusProvider);
/// ```
/// `habitsAsync` is an [AsyncValue] with three states:
///   - `.isLoading`  → show a spinner
///   - `.hasError`   → show an error message
///   - `.hasValue`   → show the list
@riverpod
Stream<List<HabitWithStatus>> habitsWithStatus(HabitsWithStatusRef ref) {
  return ref.watch(habitsRepositoryProvider).watchHabitsWithStatus();
}

// ── Write providers (AsyncNotifier) ──────────────────────────────────────

/// Handles adding a new habit.
///
/// Usage in a widget:
/// ```dart
/// await ref.read(addHabitProvider.notifier).add('Run 5k', targetPerWeek: 5);
/// ```
@riverpod
class AddHabit extends _$AddHabit {
  @override
  Future<void> build() async {}

  Future<void> add(
    String name, {
    int targetPerWeek = 7,
    bool reminderEnabled = false,
    String? reminderTime,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(habitsRepositoryProvider).addHabit(
            name,
            targetPerWeek: targetPerWeek,
            reminderEnabled: reminderEnabled,
            reminderTime: reminderTime,
          ),
    );
  }
}

/// Handles deleting a habit and all its completions.
@riverpod
class DeleteHabit extends _$DeleteHabit {
  @override
  Future<void> build() async {}

  Future<void> delete(int habitId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(habitsRepositoryProvider).deleteHabit(habitId),
    );
    ref.invalidate(habitsWithStatusProvider);
  }
}

/// Handles editing an existing habit's name and target.
@riverpod
class UpdateHabit extends _$UpdateHabit {
  @override
  Future<void> build() async {}

  Future<void> save(HabitModel habit) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(habitsRepositoryProvider).updateHabit(habit),
    );
    ref.invalidate(habitsWithStatusProvider);
  }
}

/// Handles toggling a habit's completion for today.
///
/// Usage in a widget:
/// ```dart
/// ref.read(toggleCompletionProvider.notifier).toggle(habitId);
/// ```
@riverpod
class ToggleCompletion extends _$ToggleCompletion {
  @override
  Future<void> build() async {}

  /// Toggles completion for [habitId] on [date] (defaults to today).
  /// Passing [date] lets the planner toggle any date.
  Future<void> toggle(int habitId, {String? date}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(habitsRepositoryProvider)
          .toggleCompletion(habitId, date: date),
    );
    // No manual invalidation needed: watchHabitsWithStatus() is now backed by
    // a JOIN across habits + habit_completions, so Drift re-emits the stream
    // automatically when this toggle writes to habit_completions.
  }
}
