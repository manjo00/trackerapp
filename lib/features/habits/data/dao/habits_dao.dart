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
    return (select(habits)
          ..where((h) => h.archivedAt.isNull())
          ..orderBy([(h) => OrderingTerm.asc(h.createdAt)]))
        .watch();
  }

  /// Archived habits, most-recently-archived first (Archived screen).
  Stream<List<Habit>> watchArchivedHabits() {
    return (select(habits)
          ..where((h) => h.archivedAt.isNotNull())
          ..orderBy([(h) => OrderingTerm.desc(h.archivedAt)]))
        .watch();
  }

  /// Sets/clears a habit's archived state ([at] = null unarchives).
  Future<void> setHabitArchived(int habitId, DateTime? at) =>
      (update(habits)..where((h) => h.id.equals(habitId)))
          .write(HabitsCompanion(archivedAt: Value(at)));

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
          ..where((h) => h.archivedAt.isNull())
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

  /// Streams every habit together with all its completions, grouped per habit.
  ///
  /// Because this is a JOIN across both tables, Drift re-emits whenever EITHER
  /// `habits` or `habit_completions` changes — so toggling a completion updates
  /// the stream automatically (no manual provider invalidation needed), and it
  /// avoids the previous N+1 (one completion query per habit).
  Stream<List<({Habit habit, List<HabitCompletion> completions})>>
      watchHabitsWithCompletions() {
    final query = select(habits).join([
      leftOuterJoin(
        habitCompletions,
        habitCompletions.habitId.equalsExp(habits.id),
      ),
    ])
      ..where(habits.archivedAt.isNull())
      ..orderBy([OrderingTerm.asc(habits.createdAt)]);

    return query.watch().map((rows) {
      final Map<int, Habit> habitById = {};
      final Map<int, List<HabitCompletion>> completionsByHabit = {};
      final List<int> order = [];

      for (final row in rows) {
        final Habit h = row.readTable(habits);
        if (!habitById.containsKey(h.id)) {
          habitById[h.id] = h;
          completionsByHabit[h.id] = [];
          order.add(h.id);
        }
        final HabitCompletion? c = row.readTableOrNull(habitCompletions);
        if (c != null) completionsByHabit[h.id]!.add(c);
      }

      return order
          .map((id) =>
              (habit: habitById[id]!, completions: completionsByHabit[id]!))
          .toList();
    });
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
