import 'package:drift/drift.dart' show Value;
import 'package:intl/intl.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/habit_types.dart';
import '../dao/habits_dao.dart';
import '../models/habit_completion_model.dart';
import '../models/habit_model.dart';
import '../models/habit_with_status.dart';

/// Formats a [DateTime] as a date-only string, e.g. `"2026-05-26"`.
final DateFormat _dateFmt = DateFormat('yyyy-MM-dd');

String _dateStr(DateTime dt) => _dateFmt.format(dt);

/// Provides all habit-related operations to the presentation layer.
///
/// Responsibilities:
///   1. Convert raw Drift rows into immutable [HabitModel] / [HabitCompletionModel].
///   2. Combine those into [HabitWithStatus] objects the UI can render directly.
///   3. Expose insert / toggle / delete operations as simple async methods.
///   4. Contain the pure [calculateStreak] function (independently testable).
///
/// The UI layer never imports Drift types — it only depends on this repository
/// and the model classes in `data/models/`.
class HabitsRepository {
  HabitsRepository(this._dao);

  final HabitsDao _dao;

  // ── Streams ───────────────────────────────────────────────────────────────

  /// Emits a fresh list of [HabitWithStatus] whenever any habit or completion
  /// row changes.
  ///
  /// How it works:
  ///   1. Watch every habit row as a stream.
  ///   2. For each emission, fetch the latest completions for every habit.
  ///   3. Map into [HabitWithStatus] (isDoneToday + streak).
  ///
  /// Using [asyncMap] lets us do async work (DB fetch) inside the stream
  /// pipeline without blocking.
  Stream<List<HabitWithStatus>> watchHabitsWithStatus() {
    // A single JOIN-backed stream: re-emits on habit OR completion changes,
    // and "today"/"now" are computed per-emission so a long-open app doesn't
    // get stuck on yesterday's done-state.
    return _dao.watchHabitsWithCompletions().map((rows) {
      final String today = _dateStr(DateTime.now());
      final DateTime now = DateTime.now();

      return rows.map((row) {
        final List<HabitCompletionModel> completions =
            row.completions.map(_completionFromRow).toList();

        final bool isDone = completions.any((c) => c.date == today);
        final int streak =
            HabitsRepository.calculateStreak(completions, now);

        return HabitWithStatus(
          habit: _habitFromRow(row.habit),
          isDoneToday: isDone,
          streak: streak,
        );
      }).toList();
    });
  }

  /// Watches habits with their done/undone status for a specific [date].
  ///
  /// Unlike [watchHabitsWithStatus] (which uses today), this works for any
  /// past, present, or future date — useful for the planner tab. One query
  /// (habits LEFT JOIN that day's ticks), re-emitting when either changes.
  Stream<List<HabitWithStatus>> watchHabitsForDate(String date) {
    return _dao.watchHabitsDoneOn(date).map((rows) => [
          for (final row in rows)
            HabitWithStatus(
              habit: _habitFromRow(row.habit),
              isDoneToday: row.done, // means "isDoneOnDate" in the planner
              streak: 0, // streak not shown in planner view
            ),
        ]);
  }

  /// The habits in use (not archived or deleted), in their list order.
  Stream<List<HabitModel>> watchActiveHabits() => _dao
      .watchActiveHabits()
      .map((rows) => rows.map(_habitFromRow).toList());

  /// Every habit's saved days from [fromDay] on, plus the Away ranges.
  Stream<HabitHistories> watchHistorySince(String fromDay) {
    return _dao.watchHistoryRowsSince(fromDay).map((rows) {
      final Map<int, Map<String, HabitEntry>> byHabit = {};
      final List<PauseRange> pauses = [];
      for (final row in rows) {
        final int? habitId = row.habitId;
        if (habitId == null) {
          pauses.add(PauseRange(row.date, row.endDate ?? row.date));
        } else {
          (byHabit[habitId] ??= {})[row.date] =
              HabitEntry(row.value ?? 1, EntryStatus.fromDb(row.status));
        }
      }
      return HabitHistories(entriesByHabit: byHabit, pauses: pauses);
    });
  }

  // ── Write operations ──────────────────────────────────────────────────────

  /// Adds a new habit.  [targetPerWeek] defaults to 7 (every day).
  Future<void> addHabit(
    String name, {
    int targetPerWeek = 7,
    bool reminderEnabled = false,
    String? reminderTime,
  }) async {
    await _dao.insertHabit(
      HabitsCompanion(
        name: Value(name.trim()),
        createdAt: Value(DateTime.now()),
        targetPerWeek: Value(targetPerWeek),
        reminderEnabled: Value(reminderEnabled),
        reminderTime: Value(reminderTime),
      ),
    );
  }

  /// Ticks [day] (a habit day, 'yyyy-MM-dd') or unticks it, in one
  /// transaction.
  Future<void> toggleTick(int habitId, String day) =>
      _dao.toggleTick(habitId, day);

  /// Saves a count habit's amount for [day]; 0 or less removes the day.
  Future<void> setValue(int habitId, String day, int value) =>
      _dao.setValue(habitId, day, value);

  /// Adds [amount] to a count habit's [day] in one statement.
  Future<void> addToValue(int habitId, String day, int amount) =>
      _dao.addToValue(habitId, day, amount);

  /// Inserts [habit] when its id is 0 (returns the new id), else updates
  /// every field. The old target column mirrors "N a week" (7 otherwise).
  Future<int> saveHabit(HabitModel habit) async {
    final HabitsCompanion fields = HabitsCompanion(
      name: Value(habit.name.trim()),
      targetPerWeek: Value(habit.perWeek ?? 7),
      reminderEnabled: Value(habit.reminderEnabled),
      reminderTime: Value(habit.reminderTime),
      kind: Value(habit.kind.db),
      goal: Value(habit.goal),
      unit: Value(habit.unit),
      step: Value(habit.step),
      icon: Value(habit.icon),
      color: Value(habit.color),
      schedule: Value(habit.schedule.db),
      weekdayMask: Value(habit.weekdayMask),
      perWeek: Value(habit.perWeek),
      shiftMask: Value(habit.shiftMask),
      sparesPerWeek: Value(habit.sparesPerWeek),
      section: Value(habit.section.db),
      cue: Value(habit.cue),
      sortOrder: Value(habit.sortOrder),
      autoSource: Value(habit.autoSource),
    );
    if (habit.id == 0) {
      return _dao.insertHabit(
          fields.copyWith(createdAt: Value(habit.createdAt)));
    }
    await _dao.updateHabit(fields.copyWith(id: Value(habit.id)));
    return habit.id;
  }

  /// Updates a habit's name, target-per-week, and reminder settings.
  Future<void> updateHabit(HabitModel habit) async {
    await _dao.updateHabit(
      HabitsCompanion(
        id: Value(habit.id),
        name: Value(habit.name.trim()),
        targetPerWeek: Value(habit.targetPerWeek),
        reminderEnabled: Value(habit.reminderEnabled),
        reminderTime: Value(habit.reminderTime),
      ),
    );
  }

  /// Returns all habits as a one-shot list (used by rescheduleAll in app.dart).
  Future<List<HabitModel>> getAllHabits() async {
    final rows = await _dao.getAllHabits();
    return rows.map(_habitFromRow).toList();
  }

  /// Permanently deletes a habit and all its completions.
  Future<void> deleteHabit(int habitId) => _dao.deleteHabit(habitId);

  // ── Streak logic (pure static — no DB calls, easy to unit-test) ─────────

  /// Calculates the current streak for a habit given its [completions].
  ///
  /// Rules:
  ///   - Walk backwards from [today], one day at a time.
  ///   - Count each day that has at least one completion row.
  ///   - Stop as soon as a day has no completion (gap breaks the streak).
  ///   - If [today] itself has no completion, streak is 0.
  ///
  /// [completions] can be in any order — the function handles sorting.
  ///
  /// Declared `static` because it is a pure function: it only depends on its
  /// arguments, never on instance state.  Tests can call it directly as
  /// `HabitsRepository.calculateStreak(...)` without constructing a repo.
  static int calculateStreak(
    List<HabitCompletionModel> completions,
    DateTime today,
  ) {
    if (completions.isEmpty) return 0;

    // Build a set of date strings for O(1) lookup.
    final Set<String> completedDates =
        completions.map((c) => c.date).toSet();

    int streak = 0;
    DateTime cursor = today;

    while (true) {
      final String dateKey = _dateStr(cursor);
      if (completedDates.contains(dateKey)) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  // ── Private converters ────────────────────────────────────────────────────

  HabitModel _habitFromRow(Habit row) => HabitModel(
        id: row.id,
        name: row.name,
        createdAt: row.createdAt,
        targetPerWeek: row.targetPerWeek,
        reminderEnabled: row.reminderEnabled,
        reminderTime: row.reminderTime,
        kind: HabitKind.fromDb(row.kind),
        goal: row.goal,
        unit: row.unit,
        step: row.step,
        icon: row.icon,
        color: row.color,
        schedule: HabitSchedule.fromDb(row.schedule),
        weekdayMask: row.weekdayMask,
        perWeek: row.perWeek,
        shiftMask: row.shiftMask,
        sparesPerWeek: row.sparesPerWeek,
        section: HabitSection.fromDb(row.section),
        cue: row.cue,
        sortOrder: row.sortOrder,
        autoSource: row.autoSource,
      );

  HabitCompletionModel _completionFromRow(HabitCompletion row) =>
      HabitCompletionModel(
        id: row.id,
        habitId: row.habitId,
        date: row.date,
      );
}
