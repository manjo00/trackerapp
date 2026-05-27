import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/database/database_provider.dart';
import '../../data/dao/habits_dao.dart';
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

  Future<void> add(String name, {int targetPerWeek = 7}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(habitsRepositoryProvider).addHabit(
            name,
            targetPerWeek: targetPerWeek,
          ),
    );
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

  Future<void> toggle(int habitId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(habitsRepositoryProvider).toggleCompletion(habitId),
    );
    // The habits stream only watches the `habits` table, but a toggle writes
    // to `habit_completions` — a different table — so Drift's stream never
    // re-emits on its own. Invalidating the provider forces Riverpod to
    // resubscribe and get the fresh data immediately.
    ref.invalidate(habitsWithStatusProvider);
  }
}
