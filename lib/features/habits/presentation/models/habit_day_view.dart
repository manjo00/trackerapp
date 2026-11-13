import '../../data/models/habit_model.dart';
import '../../domain/habit_rules.dart';
import '../../domain/habit_stats.dart';
import '../../domain/habit_types.dart';

/// One habit as every habit screen shows it: the habit, its recent history
/// (for the week strip) and today's state and numbers. On the Habits screen
/// it can also stand for a past day picked in the week strip ([onDay]).
class HabitDayView {
  const HabitDayView({
    required this.habit,
    required this.history,
    required this.summary,
  })  : day = null,
        _state = null,
        _value = null;

  HabitDayView._picked(
      HabitDayView base, String this.day, DayState state, int value)
      : habit = base.habit,
        history = base.history,
        summary = base.summary,
        _state = state,
        _value = value;

  final HabitModel habit;
  final HabitHistory history;

  /// Today's state and numbers. The streak, spare days and this week's count
  /// stay today's even for a picked day, so a late tick shows its effect.
  final HabitSummary summary;

  /// The past day picked in the week strip, or null for today. A row shows
  /// this day, and its round button, + and typed amount act on it.
  final String? day;

  final DayState? _state;
  final int? _value;

  /// What the row shows: the picked day's state, or today's.
  DayState get state => _state ?? summary.today;

  /// The amount the row shows (a count habit's progress) for the same day.
  int get value => _value ?? summary.todayValue;

  /// This habit on [day], a past day picked in the week strip; picking
  /// [today] gives today's view.
  HabitDayView onDay(String day,
      {required String today, required bool weekStartsSunday}) {
    if (day == today) {
      return HabitDayView(habit: habit, history: history, summary: summary);
    }
    final int value = switch (history.entries[day]) {
      HabitEntry(status: EntryStatus.done, :final int value) => value,
      _ => 0,
    };
    return HabitDayView._picked(
      this,
      day,
      dayState(habit, history, day,
          today: today, weekStartsSunday: weekStartsSunday),
      value,
    );
  }
}
