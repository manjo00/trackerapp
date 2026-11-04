import 'package:drift/drift.dart' show Value;
import '../../../../core/database/app_database.dart';
import '../../domain/habit_types.dart';
import '../dao/habits_dao.dart';
import '../models/habit_model.dart';
import '../models/habit_with_status.dart';

/// Provides all habit-related operations to the presentation layer.
///
/// Responsibilities:
///   1. Convert raw Drift rows into immutable [HabitModel]s and histories.
///   2. Expose insert / tick / count / delete operations as async methods.
///
/// The rules (what a day is, the streak, the strength) live as pure Dart in
/// `domain/`; the UI layer never imports Drift types.
class HabitsRepository {
  HabitsRepository(this._dao);

  final HabitsDao _dao;

  // ── Streams ───────────────────────────────────────────────────────────────

  /// Watches habits with their done/undone status for a specific [date].
  ///
  /// It works for any
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

  /// Returns all habits as a one-shot list (used by rescheduleAll in app.dart).
  Future<List<HabitModel>> getAllHabits() async {
    final rows = await _dao.getAllHabits();
    return rows.map(_habitFromRow).toList();
  }

  /// Permanently deletes a habit and all its completions.
  Future<void> deleteHabit(int habitId) => _dao.deleteHabit(habitId);

  // ── Private converters ────────────────────────────────────────────────────

  HabitModel _habitFromRow(Habit row) => HabitModel(
        id: row.id,
        name: row.name,
        createdAt: row.createdAt,
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
}
