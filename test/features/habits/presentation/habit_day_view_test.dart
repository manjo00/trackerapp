import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/features/habits/domain/habit_rules.dart';
import 'package:life_tracker/features/habits/domain/habit_types.dart';
import 'package:life_tracker/features/habits/presentation/models/habit_day_view.dart';

import 'habit_widget_helpers.dart';

/// A day view can stand for a past day picked in the week strip: its state
/// and amount are that day's, while the numbers stay today's.
void main() {
  const String today = '2026-11-04'; // a Wednesday

  HabitDayView picked(HabitDayView v, String day) =>
      v.onDay(day, today: today, weekStartsSunday: true);

  test('a picked day is kept, missed or before the habit began', () {
    final HabitDayView v = testView(
        streak: 3, entries: const {'2026-11-02': HabitEntry(1)});
    expect(v.day, isNull);
    expect(picked(v, '2026-11-02').state, DayState.kept);
    expect(picked(v, '2026-11-03').state, DayState.missed);
    expect(picked(v, '2026-09-30').state, DayState.beforeStart);
    expect(picked(v, '2026-11-03').day, '2026-11-03');
    // The facts line keeps today's numbers.
    expect(picked(v, '2026-11-03').summary.streak, 3);
  });

  test("a count habit's picked day carries that day's amount", () {
    final HabitDayView v = testView(
        kind: HabitKind.count,
        goal: 8,
        today: DayState.partial,
        value: 2,
        entries: const {'2026-11-03': HabitEntry(5)});
    final HabitDayView p = picked(v, '2026-11-03');
    expect((p.state, p.value), (DayState.partial, 5));
    expect((v.state, v.value), (DayState.partial, 2));
  });

  test('picking today keeps today', () {
    final HabitDayView v = testView(today: DayState.pending);
    final HabitDayView p = picked(v, today);
    expect((p.day, p.state, p.value), (null, DayState.pending, 0));
  });
}
