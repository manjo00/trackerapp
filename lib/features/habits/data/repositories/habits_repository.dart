import 'package:drift/drift.dart' show Value;
import 'package:intl/intl.dart';
import '../../../../core/database/app_database.dart';
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
    final String today = _dateStr(DateTime.now());

    return _dao.watchAllHabits().asyncMap((rawHabits) async {
      final List<HabitWithStatus> result = [];

      for (final Habit raw in rawHabits) {
        final List<HabitCompletion> rawCompletions =
            await _dao.getCompletionsForHabit(raw.id);

        final List<HabitCompletionModel> completions = rawCompletions
            .map(_completionFromRow)
            .toList();

        final bool isDone = completions.any((c) => c.date == today);
        final int streak = HabitsRepository.calculateStreak(completions, DateTime.now());

        result.add(
          HabitWithStatus(
            habit: _habitFromRow(raw),
            isDoneToday: isDone,
            streak: streak,
          ),
        );
      }

      return result;
    });
  }

  /// Watches habits with their done/undone status for a specific [date].
  ///
  /// Unlike [watchHabitsWithStatus] (which uses today), this works for any
  /// past, present, or future date — useful for the planner tab.
  ///
  /// Driven by [watchAllCompletions] so it re-emits whenever any completion
  /// row changes, regardless of which habit or date was toggled.
  Stream<List<HabitWithStatus>> watchHabitsForDate(String date) {
    return _dao.watchAllCompletions().asyncMap((_) async {
      final List<Habit> rawHabits = await _dao.getAllHabits();
      final List<HabitWithStatus> result = [];

      for (final Habit raw in rawHabits) {
        final bool isDone = await _dao.isCompletedOn(raw.id, date);
        result.add(
          HabitWithStatus(
            habit: _habitFromRow(raw),
            isDoneToday: isDone, // means "isDoneOnDate" in planner context
            streak: 0,           // streak not shown in planner view
          ),
        );
      }

      return result;
    });
  }

  // ── Write operations ──────────────────────────────────────────────────────

  /// Adds a new habit.  [targetPerWeek] defaults to 7 (every day).
  Future<void> addHabit(String name, {int targetPerWeek = 7}) async {
    await _dao.insertHabit(
      HabitsCompanion(
        name: Value(name.trim()),
        createdAt: Value(DateTime.now()),
        targetPerWeek: Value(targetPerWeek),
      ),
    );
  }

  /// Toggles a habit's completion for [date] (defaults to today).
  ///   - If not completed → inserts a completion row.
  ///   - If already completed → deletes the completion row.
  ///
  /// Passing an explicit [date] lets the planner toggle past or future dates.
  Future<void> toggleCompletion(int habitId, {String? date}) async {
    final String targetDate = date ?? _dateStr(DateTime.now());
    final bool alreadyDone = await _dao.isCompletedOn(habitId, targetDate);

    if (alreadyDone) {
      await _dao.deleteCompletion(habitId, targetDate);
    } else {
      await _dao.insertCompletion(
        HabitCompletionsCompanion(
          habitId: Value(habitId),
          date: Value(targetDate),
        ),
      );
    }
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
      );

  HabitCompletionModel _completionFromRow(HabitCompletion row) =>
      HabitCompletionModel(
        id: row.id,
        habitId: row.habitId,
        date: row.date,
      );
}
