import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/settings/settings_provider.dart';
import '../../domain/habit_day.dart';
import '../../domain/habit_stats.dart';
import '../../domain/habit_types.dart';
import '../models/habit_day_view.dart';
import '../models/habit_units.dart';
import '../../data/dao/habits_dao.dart';
import '../../data/models/habit_model.dart';
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

// ── Write providers (AsyncNotifier) ──────────────────────────────────────

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
    // The habit streams re-emit by themselves (Drift watches the tables).
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
          .toggleTick(habitId, date ?? ref.read(habitTodayProvider)),
    );
    // No manual invalidation needed: the habit streams watch the tables, so
    // Drift re-emits them when this toggle writes to habit_completions.
  }
}

// ── The habits rebuild: today's day views ─────────────────────────────────

/// The clock the habit screens read. Tests override it.
final habitClockProvider =
    Provider<DateTime Function()>((ref) => DateTime.now);

/// Today's habit day ('yyyy-MM-dd'; the day starts at 04:00). It moves on by
/// itself at the next 04:00, and whenever app.dart refreshes the providers
/// anchored to the date (resume, the midnight refresh).
final habitTodayProvider =
    NotifierProvider<HabitToday, String>(HabitToday.new);

class HabitToday extends Notifier<String> {
  @override
  String build() {
    final DateTime now = ref.watch(habitClockProvider)();
    final DateTime next = DateTime(now.year, now.month, now.day)
        .add(const Duration(minutes: kHabitDayStartMinutes));
    final DateTime flip = now.isBefore(next)
        ? next
        : DateTime(now.year, now.month, now.day + 1)
            .add(const Duration(minutes: kHabitDayStartMinutes));
    final Timer timer = Timer(flip.difference(now), ref.invalidateSelf);
    ref.onDispose(timer.cancel);
    return habitDayOf(now);
  }
}

/// The habits in use, in their list order.
final activeHabitsProvider = StreamProvider<List<HabitModel>>(
    (ref) => ref.watch(habitsRepositoryProvider).watchActiveHabits());

/// Every habit's saved days over the window the numbers use, plus the Away
/// ranges: one query, re-emitting whenever a tick or a pause changes.
final habitHistoriesProvider = StreamProvider<HabitHistories>((ref) {
  final String today = ref.watch(habitTodayProvider);
  return ref
      .watch(habitsRepositoryProvider)
      .watchHistorySince(addDays(today, -kHabitWindowDays));
});

/// Every habit as the screens show it today, ordered by part of the day
/// (wake-up, any time, daytime, before sleep), then its own order.
final habitDayViewsProvider = Provider<AsyncValue<List<HabitDayView>>>((ref) {
  final AsyncValue<List<HabitModel>> habits = ref.watch(activeHabitsProvider);
  final AsyncValue<HabitHistories> histories =
      ref.watch(habitHistoriesProvider);
  final String today = ref.watch(habitTodayProvider);
  final bool weekStartsSunday =
      ref.watch(settingsProvider.select((s) => s.weekStartsSunday));
  if (habits case AsyncError(:final Object error, :final StackTrace stackTrace)) {
    return AsyncError(error, stackTrace);
  }
  if (histories
      case AsyncError(:final Object error, :final StackTrace stackTrace)) {
    return AsyncError(error, stackTrace);
  }
  final List<HabitModel>? list = habits.valueOrNull;
  final HabitHistories? book = histories.valueOrNull;
  if (list == null || book == null) return const AsyncLoading();
  final List<HabitDayView> views = [
    for (final HabitModel h in list)
      HabitDayView(
        habit: h,
        history: book.of(h.id),
        summary: summarize(h, book.of(h.id),
            today: today, weekStartsSunday: weekStartsSunday),
      ),
  ]..sort((a, b) {
      final int bySection =
          a.habit.section.index.compareTo(b.habit.section.index);
      if (bySection != 0) return bySection;
      final int byOrder = a.habit.sortOrder.compareTo(b.habit.sortOrder);
      return byOrder != 0 ? byOrder : a.habit.id.compareTo(b.habit.id);
    });
  return AsyncData(views);
});

/// What the habit screens do: tick, add to a count, type an amount, save.
final habitActionsProvider = Provider<HabitActions>(HabitActions.new);

class HabitActions {
  HabitActions(this._ref);

  final Ref _ref;

  HabitsRepository get _repo => _ref.read(habitsRepositoryProvider);
  String get _today => _ref.read(habitTodayProvider);

  /// Ticks or unticks [day] (a past day picked in the week strip), or today.
  Future<void> tick(int habitId, {String? day}) =>
      _repo.toggleTick(habitId, day ?? _today);

  /// Adds [amount] to [day]'s count, or today's (the + button adds the
  /// habit's step).
  Future<void> addAmount(int habitId, int amount, {String? day}) =>
      _repo.addToValue(habitId, day ?? _today, amount);

  /// Saves a typed amount for [day]. A blank, negative or non-number entry,
  /// or one above [kMaxHabitAmount], changes nothing and returns false; 0
  /// removes the day.
  Future<bool> setAmount(int habitId, String day, String typed) async {
    final int? value = int.tryParse(typed.trim());
    if (value == null || value < 0 || value > kMaxHabitAmount) return false;
    await _repo.setValue(habitId, day, value);
    return true;
  }

  /// Inserts a new habit (id 0; returns its id) or updates one.
  Future<int> save(HabitModel habit) => _repo.saveHabit(habit);
}
