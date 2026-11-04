import 'package:drift/drift.dart';
import '../tables/habit_completions_table.dart';
import '../tables/habit_pauses_table.dart';
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
@DriftAccessor(tables: [Habits, HabitCompletions, HabitPauses])
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
  /// Deleted rows are excluded — they belong to the Recently deleted tab.
  Stream<List<Habit>> watchArchivedHabits() {
    return (select(habits)
          ..where((h) => h.archivedAt.isNotNull() & h.deletedAt.isNull())
          ..orderBy([(h) => OrderingTerm.desc(h.archivedAt)]))
        .watch();
  }

  /// Habits in Recently deleted, most-recently-deleted first.
  Stream<List<Habit>> watchDeletedHabits() {
    return (select(habits)
          ..where((h) => h.deletedAt.isNotNull())
          ..orderBy([(h) => OrderingTerm.desc(h.deletedAt)]))
        .watch();
  }

  /// Sets/clears a habit's archived state ([at] = null unarchives).
  Future<void> setHabitArchived(int habitId, DateTime? at) =>
      (update(habits)..where((h) => h.id.equals(habitId)))
          .write(HabitsCompanion(archivedAt: Value(at)));

  /// One-shot fetch of a single habit (null if it doesn't exist). Restore reads
  /// it to see whether the habit was live or already archived when deleted.
  Future<Habit?> getHabit(int id) =>
      (select(habits)..where((h) => h.id.equals(id))).getSingleOrNull();

  /// Sets/clears a habit's deleted state ([at] = null restores it from the bin).
  Future<void> setHabitDeleted(int habitId, DateTime? at) =>
      (update(habits)..where((h) => h.id.equals(habitId)))
          .write(HabitsCompanion(deletedAt: Value(at)));

  /// Really removes habits binned before [cutoff] (CASCADE takes their
  /// completions with them). Runs on launch.
  Future<int> purgeHabitsDeletedBefore(DateTime cutoff) =>
      (delete(habits)..where((h) => h.deletedAt.isSmallerThanValue(cutoff)))
          .go();

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

  // ── The habits rebuild (schema 27) ────────────────────────────────────────

  /// The habits in use (not archived, not deleted), in their list order.
  Stream<List<Habit>> watchActiveHabits() => (select(habits)
        ..where((h) => h.archivedAt.isNull() & h.deletedAt.isNull())
        ..orderBy([
          (h) => OrderingTerm.asc(h.sortOrder),
          (h) => OrderingTerm.asc(h.id),
        ]))
      .watch();

  /// Every saved day from [fromDay] on and every Away range, from ONE query,
  /// so it re-emits when either table changes. A pause row has a null
  /// habitId; its start is in `date`.
  Stream<
      List<
          ({
            int? habitId,
            String date,
            int? value,
            String? status,
            String? endDate
          })>> watchHistoryRowsSince(String fromDay) {
    return customSelect(
      'SELECT habit_id, date, value, status, NULL AS end_date '
      'FROM habit_completions WHERE date >= ?1 '
      'UNION ALL '
      'SELECT NULL, start_date, NULL, NULL, end_date FROM habit_pauses',
      variables: [Variable.withString(fromDay)],
      readsFrom: {habitCompletions, habitPauses},
    ).watch().map((rows) => [
          for (final QueryRow r in rows)
            (
              habitId: r.readNullable<int>('habit_id'),
              date: r.read<String>('date'),
              value: r.readNullable<int>('value'),
              status: r.readNullable<String>('status'),
              endDate: r.readNullable<String>('end_date'),
            ),
        ]);
  }

  /// The habits in use with whether [day] is done (a done row at its goal),
  /// for the Planner. One query, re-emitting on habit or tick changes.
  Stream<List<({Habit habit, bool done})>> watchHabitsDoneOn(String day) {
    return customSelect(
      'SELECT h.*, (c.id IS NOT NULL AND c.status = \'done\' '
      'AND c.value >= h.goal) AS done_on_day '
      'FROM habits h LEFT JOIN habit_completions c '
      'ON c.habit_id = h.id AND c.date = ?1 '
      'WHERE h.archived_at IS NULL AND h.deleted_at IS NULL '
      'ORDER BY h.sort_order, h.id',
      variables: [Variable.withString(day)],
      readsFrom: {habits, habitCompletions},
    ).watch().map((rows) => [
          for (final QueryRow r in rows)
            (habit: habits.map(r.data), done: r.read<bool>('done_on_day')),
        ]);
  }

  /// Ticks [day] if it isn't, unticks it if it is — in one transaction, so
  /// two quick taps can't leave two rows.
  Future<void> toggleTick(int habitId, String day) => transaction(() async {
        final int removed = await (delete(habitCompletions)
              ..where((c) => c.habitId.equals(habitId) & c.date.equals(day)))
            .go();
        if (removed == 0) {
          await into(habitCompletions).insert(HabitCompletionsCompanion.insert(
              habitId: habitId, date: day, createdAt: Value(DateTime.now())));
        }
      });

  /// Adds [amount] to [day]'s value in one statement (a new day starts at
  /// [amount]), so two quick taps on + both count.
  Future<void> addToValue(int habitId, String day, int amount) =>
      into(habitCompletions).insert(
        HabitCompletionsCompanion.insert(
            habitId: habitId,
            date: day,
            value: Value(amount),
            createdAt: Value(DateTime.now())),
        onConflict: DoUpdate(
          (old) => HabitCompletionsCompanion.custom(
              value: old.value + Constant(amount),
              status: const Constant('done')),
          target: [habitCompletions.habitId, habitCompletions.date],
        ),
      );

  /// Saves [value] for [day] (one row per day); 0 or less removes the day.
  Future<void> setValue(int habitId, String day, int value) async {
    if (value <= 0) {
      await (delete(habitCompletions)
            ..where((c) => c.habitId.equals(habitId) & c.date.equals(day)))
          .go();
      return;
    }
    await into(habitCompletions).insert(
      HabitCompletionsCompanion.insert(
          habitId: habitId,
          date: day,
          value: Value(value),
          createdAt: Value(DateTime.now())),
      onConflict: DoUpdate(
        (old) => HabitCompletionsCompanion(
            value: Value(value), status: const Value('done')),
        target: [habitCompletions.habitId, habitCompletions.date],
      ),
    );
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
