import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/features/habits/data/models/habit_model.dart';
import 'package:life_tracker/features/habits/domain/habit_rules.dart';
import 'package:life_tracker/features/habits/domain/habit_types.dart';

import 'habit_test_helpers.dart';

DayState stateOf(HabitModel h, HabitHistory hist, String day) =>
    dayState(h, hist, day, today: kToday, weekStartsSunday: true);

void main() {
  final HabitModel daily = testHabit();

  test('a past day without a tick is missed; today is pending', () {
    expect(stateOf(daily, testHistory({}), '2026-11-03'), DayState.missed);
    expect(stateOf(daily, testHistory({}), kToday), DayState.pending);
  });

  test('a tick makes a day kept', () {
    expect(stateOf(daily, testHistory({'2026-11-03': 1}), '2026-11-03'),
        DayState.kept);
  });

  test('days before the first day are beforeStart', () {
    expect(stateOf(daily, testHistory({}), '2026-09-30'), DayState.beforeStart);
  });

  test('chosen days: the other days are not due', () {
    // Monday, Wednesday and Friday: bits 1, 4 and 16.
    final HabitModel mwf =
        testHabit(schedule: HabitSchedule.weekdays, weekdayMask: 21);
    expect(stateOf(mwf, testHistory({}), '2026-11-03'), DayState.notDue);
    expect(stateOf(mwf, testHistory({}), kToday), DayState.pending);
    expect(stateOf(mwf, testHistory({}), '2026-11-02'), DayState.missed);
  });

  test('a few times a week is done for the week once N is reached', () {
    final HabitModel twice =
        testHabit(schedule: HabitSchedule.perWeek, perWeek: 2);
    final HabitHistory both = testHistory({'2026-11-01': 1, '2026-11-03': 1});
    expect(stateOf(twice, both, kToday), DayState.notDue);
    expect(stateOf(twice, both, '2026-11-03'), DayState.kept);
    expect(stateOf(twice, both, '2026-11-02'), DayState.open);

    final HabitHistory one = testHistory({'2026-11-03': 1});
    expect(stateOf(twice, one, kToday), DayState.pending);
    expect(stateOf(twice, one, '2026-11-02'), DayState.open);
  });

  test('a count under its goal is partial; at the goal it is kept', () {
    final HabitModel water = testHabit(kind: HabitKind.count, goal: 8);
    expect(stateOf(water, testHistory({kToday: 5}), kToday), DayState.partial);
    expect(stateOf(water, testHistory({kToday: 8}), kToday), DayState.kept);
    expect(stateOf(water, testHistory({'2026-11-03': 5}), '2026-11-03'),
        DayState.partial);
  });

  test('rest and sick days are their own state', () {
    expect(
        stateOf(daily, testHistory({}, breaks: {'2026-11-03': EntryStatus.rest}),
            '2026-11-03'),
        DayState.rest);
    expect(
        stateOf(daily, testHistory({}, breaks: {'2026-11-03': EntryStatus.sick}),
            '2026-11-03'),
        DayState.sick);
  });

  test('a pause makes days away, but a tick inside it still counts', () {
    const List<PauseRange> trip = [PauseRange('2026-10-31', '2026-11-01')];
    expect(stateOf(daily, testHistory({}, pauses: trip), '2026-10-31'),
        DayState.away);
    expect(
        stateOf(daily, testHistory({'2026-11-01': 1}, pauses: trip),
            '2026-11-01'),
        DayState.kept);
  });
}
