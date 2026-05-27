import 'package:drift/drift.dart';
import '../tables/habit_completions_table.dart';
import '../tables/habits_table.dart';
import '../../../../core/database/app_database.dart';

// The `part` directive tells Dart that habits_dao.g.dart is an extension of
// this file.  build_runner writes that file; we must not create it manually.
part 'habits_dao.g.dart';

/// All database queries that touch the habits feature.
///
/// Keeping queries here (rather than scattered across the app) means:
///   - One place to look when something breaks.
///   - Easy to swap the underlying database later without touching UI code.
///
/// [DriftAccessor] lists every table this DAO is allowed to query.
@DriftAccessor(tables: [Habits, HabitCompletions])
class HabitsDao extends DatabaseAccessor<AppDatabase> with _$HabitsDaoMixin {
  HabitsDao(super.db);

  // ── Habits ────────────────────────────────────────────────────────────────

  /// Returns a [Stream] of every habit, ordered by creation date.
  ///
  /// A Stream means the UI receives a new list automatically whenever the
  /// habits table changes — no manual refreshing needed.
  Stream<List<Habit>> watchAllHabits() {
    return (select(habits)..orderBy([(h) => OrderingTerm.asc(h.createdAt)]))
        .watch();
  }

  /// Inserts a new habit row and returns its auto-assigned [id].
  Future<int> insertHabit(HabitsCompanion companion) =>
      into(habits).insert(companion);

  /// Permanently removes a habit and (via CASCADE) all its completions.
  Future<int> deleteHabit(int habitId) =>
      (delete(habits)..where((h) => h.id.equals(habitId))).go();

  // ── Completions ───────────────────────────────────────────────────────────

  /// Returns a [Stream] of every completion for [habitId], newest first.
  ///
  /// The repository uses this to calculate the current streak.
  Stream<List<HabitCompletion>> watchCompletionsForHabit(int habitId) {
    return (select(habitCompletions)
          ..where((c) => c.habitId.equals(habitId))
          ..orderBy([(c) => OrderingTerm.desc(c.date)]))
        .watch();
  }

  /// Returns all completion rows for [habitId] as a one-shot [Future].
  ///
  /// Used when we need to calculate the streak synchronously (e.g. in tests).
  Future<List<HabitCompletion>> getCompletionsForHabit(int habitId) {
    return (select(habitCompletions)
          ..where((c) => c.habitId.equals(habitId))
          ..orderBy([(c) => OrderingTerm.desc(c.date)]))
        .get();
  }

  /// Records that [habitId] was completed on [date] (format: "yyyy-MM-dd").
  Future<int> insertCompletion(HabitCompletionsCompanion companion) =>
      into(habitCompletions).insert(companion);

  /// Removes the completion row for [habitId] on [date].
  /// Returns the number of rows deleted (0 or 1).
  Future<int> deleteCompletion(int habitId, String date) =>
      (delete(habitCompletions)
            ..where(
              (c) => c.habitId.equals(habitId) & c.date.equals(date),
            ))
          .go();

  /// Returns all habits as a one-shot [Future].
  /// Used by the planner to compute date-specific status without a stream.
  Future<List<Habit>> getAllHabits() {
    return (select(habits)
          ..orderBy([(h) => OrderingTerm.asc(h.createdAt)]))
        .get();
  }

  /// Updates the name and/or targetPerWeek of an existing habit.
  Future<void> updateHabit(HabitsCompanion companion) =>
      (update(habits)..where((h) => h.id.equals(companion.id.value)))
          .write(companion);

  /// Stream of every completion row across all habits.
  /// The planner watches this so its date views update whenever any
  /// completion changes (insert or delete).
  Stream<List<HabitCompletion>> watchAllCompletions() {
    return select(habitCompletions).watch();
  }

  /// Returns true if [habitId] has a completion row for [date].
  Future<bool> isCompletedOn(int habitId, String date) async {
    final row = await (select(habitCompletions)
          ..where(
            (c) => c.habitId.equals(habitId) & c.date.equals(date),
          )
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }
}
